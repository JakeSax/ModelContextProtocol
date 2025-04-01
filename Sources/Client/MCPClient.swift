//
//  MCPClient.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation
import MCPCore
import OSLog

/// A client for communicating with an MCP server using JSON-RPC over a transport mechanism.
///
/// This actor-based client manages a connection to an MCP server through a configured transport,
/// tracks request states, and processes message streams. It handles the entire client lifecycle
/// including connection, initialization, message exchange, and shutdown.
///
/// Example usage:
/// ```swift
/// let config = MCPClient.Configuration(...)
/// let client = MCPClient(configuration: config)
/// try await client.connect()
/// let response = try await client.sendRequest(myRequest, requestID: 123)
/// ```
///
/// The client automatically manages the underlying transport connection and maintains
/// the protocol state according to the MCP specification.
public actor MCPClient {
    
    // MARK: - Properties
    
    /// Configuration for this client instance.
    ///
    /// Contains settings that define the client's behavior, server connection parameters,
    /// and protocol options.
    nonisolated public let configuration: Configuration
    
    /// The current state of the client.
    ///
    /// This property reflects where the client is in its lifecycle: disconnected,
    /// connecting, initializing, running, or failed.
    public private(set) var state: State
    
    public var notifications: AsyncStream<ServerNotification>
    private let notificationsContinuation: AsyncStream<ServerNotification>.Continuation
    
    /// A handler that may be configured to observe progress for requests, if the server
    /// chooses to provide ProgressNotifications.
    public var progressHandler: ProgressHandler?
    
    /// A dictionary mapping request IDs to their corresponding pending requests.
    ///
    /// Used to track in-flight requests that are awaiting responses from the server.
    var pendingRequests: [RequestID : any PendingRequestProtocol]
    
    /// The stream of raw data messages from the transport.
    ///
    /// This stream is created when the client connects and is used to process
    /// incoming messages from the server.
    private(set) var messageStream: MessageStream?
    
    /// The task responsible for processing incoming messages.
    ///
    /// This long-running task reads from the message stream and dispatches messages
    /// to appropriate handlers based on their type.
    private(set) var messageProcessingTask: Task<Void, Error>?
    
    /// The unique collection of requests that the client has requested progress updates for.
    private var progressRequests: [ProgressRequest] = []
    
    /// The client's implementation of message creation sampling, if the client supports it.
    private let createMessage: CreateMessageHandler?
    
    /// The client's implementation of listing the root URIs available on the client, if the
    /// client supports it.
    private let listRoots: ListRootsHandler?

    /// The stream of raw data messages from the transport.
    typealias MessageStream = AsyncThrowingStream<Data, Error>
    
    /// The action for the client to perform on receiving a ``CreateMessageRequest``.
    public typealias CreateMessageHandler = @Sendable (CreateMessageRequest.Parameters) async throws -> CreateMessageRequest.Result
    
    /// The action for the client to perform on receiving a ``ListRootsRequest``.
    public typealias ListRootsHandler = @Sendable (ListRootsRequest.Parameters) async throws -> ListRootsRequest.Result
    
    public typealias ProgressHandler = @Sendable (ProgressNotification.Parameters) -> Void
    
    /// A logger for recording events and errors.
    ///
    /// Used throughout the client to provide diagnostic information about the
    /// client's operation and any issues encountered.
    nonisolated private let logger: Logger
    
    /// The ``RequestID`` reserved for the initialization request: `1`.
    nonisolated public static let initializationRequestID: RequestID = 1
    
    // MARK: - Initialization
    /// Creates a new MCPClient instance configured to communicate with an MCP server.
    /// 
    /// The client will not connect to the server until `connect()` is called.
    /// 
    /// - Parameters:
    ///   - configuration: The configuration specifying how to connect to and interact
    ///     with the MCP server.
    ///   - createMessage: The action for the client to perform on receiving a
    ///    ``CreateMessageRequest``, if the client supports it. Defaults to nil.
    ///   - listRoots: The action for the client to perform on receiving a
    ///   ``ListRootsRequest``, if the client supports it. Defaults to nil.
    ///   - logger: The OSLog Logger for recording events and errors. Defaults to a Logger
    ///     with subsystem `"MCPClient"` and the client's name from the configuration.
    public init(
        configuration: Configuration,
        createMessage: CreateMessageHandler? = nil,
        listRoots: ListRootsHandler? = nil,
        progressHandler: ProgressHandler? = nil,
        logger: Logger? = nil
    ) {
        self.configuration = configuration
        self.createMessage = createMessage
        self.progressHandler = progressHandler
        self.listRoots = listRoots
        self.state = .disconnected
        self.pendingRequests = [:]
        self.messageStream = nil
        self.messageProcessingTask = nil
        
        let (notifications, notificationsContinuation) = AsyncStream.makeStream(
            of: (ServerNotification).self)
        self.notifications = notifications
        self.notificationsContinuation = notificationsContinuation
        
        self.logger = logger ?? Logger(
            subsystem: "MCPClient",
            category: configuration.initialization.clientInfo.name
        )
    }
    
    // MARK: - Connection Management
    
    /// Connects to the MCP server and initializes the client.
    ///
    /// This method performs the full connection sequence:
    /// 1. Establishes the transport connection
    /// 2. Sets up message streaming
    /// 3. Performs the initialization handshake with the server
    /// 4. Sends the initialized notification
    ///
    /// After successful completion, the client transitions to the `.running` state
    /// and is ready to send requests and receive responses.
    ///
    /// - Throws: An error if any part of the connection process fails. In case of failure,
    ///   the client transitions to the `.failed` state.
    public func connect() async throws {
        guard state != .connecting, state != .initializing, !state.isRunning else {
            logger.warning("Not beginning connection, already connected, connecting or initializing")
            return
        }
        logger.info("Connecting...")
        
        state = .connecting
        
        do {
            // Initialize and connect the transport to the server
            try await transport.start()
            
            try await beginMessageStreaming()
            
            // Once connected, begin initialization
            logger.info("Transport is connected, initializing...")
            state = .initializing
            
            let request = InitializeRequest(params: configuration.initialization)
            let requestID: RequestID = Self.initializationRequestID
            
            let response = try await sendRequest(request, withID: requestID)
            
            // Ensure the client supports the server's JSON-RPC version
            guard response.protocolVersion == self.configuration.initialization.protocolVersion else {
                throw MCPClientError.unsupportedJSONRPCVersion
            }
            logger.info("Received initialization resopnse, emitting initialized notification...")
            
            // Send initialization notification
            try await sendNotification(.initialized(InitializedNotification()))
            
            state = .running(serverCapabilities: response.capabilities)
            logger.info("Client is running")
        } catch {
            logger.error("Client failed to connect with error: \(error)")
            state = .failed(error)
            throw error
        }
    }
    
    /// Begins streaming and processing messages from the transport.
    ///
    /// This private method configures the message streaming pipeline by:
    /// 1. Verifying the transport is in a connected state
    /// 2. Obtaining a message stream from the transport
    /// 3. Starting a task to process incoming messages
    ///
    /// The message processing task handles the different types of JSON-RPC messages
    /// (requests, notifications, responses, and errors) by dispatching them to
    /// appropriate handlers.
    ///
    /// - Throws: `MCPClientError.transportNotConnected` if the transport is not
    ///   in the connected state.
    private func beginMessageStreaming() async throws {
        
        // ensure the transport is connected
        guard await transport.state == .connected else {
            throw MCPClientError.transportNotConnected
        }
        
        // begin the message stream over the transport
        let transportMessageStream = await transport.messages()
        
        // persist the stream
        self.messageStream = transportMessageStream
        
        // start processing messages from stream
        self.messageProcessingTask = Task {
            for try await messageData in transportMessageStream {
                try Task.checkCancellation()
                do {
                    try await processMessage(messageData)
                } catch {
                    logger.error("Error processing message: \(error.localizedDescription)")
                    #warning("are there instances where we shouldn't throw the error and should keep processing?")
                    throw error
                }
            }
        }
    }
    
}

// MARK: - Sending Messages
public extension MCPClient {
    
    /// Sends a JSON-RPC request to the MCP server.
    ///
    /// This method encodes the provided request into a JSON-RPC formatted message
    /// and transmits it through the configured transport. The request is tracked
    /// until a corresponding response is received.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - requestID: A unique identifier for the request, used to correlate
    ///     the response and track the request's lifecycle.
    ///
    /// - Throws:
    ///   - `MCPClientError.transportNotConnected` if the transport is not in a connected state.
    ///   - `MCPClientError.notConnected` if the client is not in a running or initializing state,
    ///     or if a non-initialization request is sent during initialization.
    ///   - `MCPClientError.duplicateRequestID` if a request with the same ID is already pending.
    ///   - Encoding errors if the request cannot be properly encoded to JSON.
    ///   - Transport errors if the transport fails to send the data.
    func sendRequest<T: AnyClientRequest>(
        _ request: T,
        withID requestID: RequestID = RequestID(UUID())
    ) async throws -> T.Result {
        
        if request.method != .initialize, requestID == Self.initializationRequestID {
            logger.error("Cannot send request with ID: \"\(Self.initializationRequestID)\", this ID is reserved for initialization.")
            throw MCPClientError.reusedRequestID(Self.initializationRequestID)
        }
        
        let requestDescription = "request with method: \"\(request.method.rawValue)\" and ID: \(requestID.description)"
        
        logger.info("Preparing to send \(requestDescription)")
        
        guard await transport.state == .connected else {
            logger.error("Cannot send \(requestDescription), transport is not connected")
            throw MCPClientError.transportNotConnected
        }
        
        // Ensure only the initialization notification is being sent if initializing
        if state == .initializing, request.method != .initialize {
            logger.error("Cannot send non-initialization \(requestDescription) while initializing")
            throw MCPClientError.notConnected
        }
        
        // Ensure the client is running (or initializing as previously handled)
        guard state.isRunning || state == .initializing else {
            logger.error("Cannot send \(requestDescription), Client is not running")
            throw MCPClientError.notConnected
        }
        
        // Ensure a request with the same ID is not already in progress
        guard !pendingRequests.keys.contains(where: { $0 == requestID }) else {
            logger.error("Cannot send a request with the same ID twice: \(requestID.description)")
            throw MCPClientError.duplicateRequestID(requestID)
        }
        
        // Convert to JSONRPCRequest and encode it.
        let jsonRPCRequest: JSONRPCRequest = try JSONRPCRequest(id: requestID, request: request)
        let encodedRequest: Data = try encoder.encode(jsonRPCRequest)
        
        logger.info("Sending \(requestDescription)")
        
        if let progressToken = request.params._meta?.progressToken {
            if let existingProgressRequest = progressRequests.first(where: { $0.token == progressToken }) {
                logger.warning("Duplicate progress token: \(progressToken.description) for existing request: \(existingProgressRequest.requestID.description), not registering new progress token")
            } else {
                logger.info("Registering progress request for token: \(progressToken.description) and requestID: \(requestID.description)")
                progressRequests.append(ProgressRequest(token: progressToken, requestID: requestID))
            }
        }
        
        let timeout: Duration = await transport.configuration.sendTimeout
        
        return try await withCheckedThrowingContinuation { continuation in

            // Add request to the pending requests and track continuation
            pendingRequests[requestID] = PendingRequest(
                request: request,
                requestID: requestID,
                continuation: continuation,
                timeoutDuration: timeout
            )

            // Send the request over transport
            Task {
                do {
                    try await transport.send(encodedRequest, timeout: nil)
                    logger.info("Sent \(requestDescription)")
                    
                } catch {
                    logger.error("Error sending \(requestDescription)")
                    
                    // Remove any progress requests for the request
                    progressRequests.removeAll(where: { $0.requestID == requestID })
                    
                    // Fail the pending request
                    if let pendingRequest = self.pendingRequests.removeValue(forKey: requestID) {
                        await pendingRequest.fail(withError: error)
                    }
                    throw error
                }
            }
        }
    }
    
    /// Sends a JSON-RPC response to the server.
    ///
    /// This method is used to respond to server-to-client requests. It encodes
    /// the response and transmits it through the configured transport.
    ///
    /// - Parameter response: The JSON-RPC response to send to the server.
    ///
    /// - Throws:
    ///   - `MCPClientError.notConnected` if the client is not in a running state.
    ///   - `MCPClientError.transportNotConnected` if the transport is not connected.
    ///   - Encoding errors if the response cannot be properly encoded to JSON.
    ///   - Transport errors if the transport fails to send the data.
    func sendResponse(
        forRequestID requestID: RequestID,
        withResult result: ClientResult
    ) async throws {
        // Ensure the client is running
        guard state.isRunning else {
            logger.error("Cannot send response, client is not running")
            throw MCPClientError.notConnected
        }
        
        // Ensure the transport is connected
        guard await transport.state == .connected else {
            logger.error("Cannot send response, transport is not connected")
            throw MCPClientError.transportNotConnected
        }
        
        // Send the response using default timeout
        logger.info("Sending Response: \(requestID.description)")
        let response = try JSONRPCResponse(id: requestID, result: result.result)
        try await transport.send(try encoder.encode(response), timeout: nil)
    }
    
    /// Sends a JSON-RPC notification to the server.
    ///
    /// Notifications are similar to requests but do not expect a response.
    /// This method encodes the notification and transmits it through the
    /// configured transport.
    ///
    /// - Parameter notification: The notification to send to the server.
    ///
    /// - Throws:
    ///   - `MCPClientError.notConnected` if the client is not in a running or initializing state,
    ///     or if a non-initialization notification is sent during initialization.
    ///   - `MCPClientError.transportNotConnected` if the transport is not connected.
    ///   - Encoding errors if the notification cannot be properly encoded to JSON.
    ///   - Transport errors if the transport fails to send the data.
    func sendNotification(_ notification: ClientNotification) async throws {
        // Ensure only the initialization notification is being sent if initializing
        if state == .initializing, notification.method != .initialized {
            logger.error("Cannot emit non-initialization notification while initializing")
            throw MCPClientError.notConnected
        }
        
        // Ensure the client is running (or initializing as previously handled)
        guard state.isRunning || state == .initializing else {
            logger.error("Cannot send notification, client is not connected")
            throw MCPClientError.notConnected
        }
        
        // Ensure the transport is connected
        guard await transport.state == .connected else {
            logger.error("Cannot send notification: transport is not connected")
            throw MCPClientError.transportNotConnected
        }
        
        // Send the notification using default timeout
        logger.info("Sending notification: \(notification.method.rawValue)")
        try await transport.send(
            try encoder.encode(notification),
            timeout: nil
        )
    }
}

// MARK: - Handling Messages
private extension MCPClient {
    
    /// Attempts to decode the incoming message as a `JSONRPCMessage` and
    /// process it.
    ///
    /// - Parameter messageData: The raw data retrieved from the `transport`'s
    /// message stream.
    func processMessage(_ messageData: Data) async throws {
        let message = try decoder.decode(JSONRPCMessage.self, from: messageData)
        
        switch message {
            
        case .request(let request):
            try await handleRequest(request)
            
        case .notification(let notification):
            try await handleNotification(notification)
            
        case .response(let response):
            try await handleResponse(response)
            
        case .error(let error):
            try await handleError(error)
        }
    }
    
    /// Processes incoming JSON-RPC requests from the server.
    ///
    /// This method handles various server-to-client requests by:
    /// 1. Validating the request method is recognized
    /// 2. Checking that the client has the necessary capabilities to respond
    /// 3. Decoding the request parameters
    /// 4. Performing the requested operation
    /// 5. Sending an appropriate response
    ///
    /// - Parameter request: The decoded JSON-RPC request from the server.
    ///
    /// - Throws:
    ///   - `MCPClientError.unknownRequestMethod` if the request method is not recognized.
    ///   - `MCPClientError.unsupportedCapability` if the client lacks a capability required by the request.
    ///   - Decoding errors if the request parameters cannot be properly decoded.
    ///   - Transport errors if sending the response fails.
    func handleRequest(_ request: JSONRPCRequest) async throws {
        guard let serverRequestMethod = ServerRequest.Method(rawValue: request.method) else {
            throw MCPClientError.unknownRequestMethod(request.method)
        }
        
        switch serverRequestMethod {
        case .ping:
            // Send an empty response to acknowledge ping
            try await sendResponse(
                forRequestID: request.id, withResult: .result(ServerPingRequest.Result())
            )
            
        case .createMessage:
            guard capabilities.supportsSampling, let createMessage else {
                throw MCPClientError.unsupportedCapability(method: serverRequestMethod)
            }
            let createMessageRequest = try request.asRequest(CreateMessageRequest.self)

            let result = try await createMessage(createMessageRequest.params)
            
            try await sendResponse(forRequestID: request.id, withResult: .createMessage(result))
            
        case .listRoots:
            guard capabilities.supportsRootListing, let listRoots else {
                throw MCPClientError.unsupportedCapability(method: serverRequestMethod)
            }
            let listRootsRequest = try request.asRequest(ListRootsRequest.self)

            let result = try await listRoots(listRootsRequest.params)
            
            try await sendResponse(forRequestID: request.id, withResult: .listRoots(result))
        }
    }
    
    /// Processes incoming JSON-RPC responses from the server.
    ///
    /// This method handles responses to client-initiated requests by:
    /// 1. Matching the response ID to a pending request
    /// 2. Decoding the response result based on the original request type
    /// 3. Fulfilling the promise for the waiting caller or triggering appropriate callback
    ///
    /// - Parameter response: The decoded JSON-RPC response from the server.
    ///
    /// - Throws:
    ///   - `MCPClientError.unknownResponseID` if the response ID doesn't match any pending request.
    ///   - Decoding errors if the response result cannot be properly decoded.
    func handleResponse(_ response: JSONRPCResponse) async throws {
        guard let pendingRequest: any PendingRequestProtocol = pendingRequests.removeValue(
            forKey: response.id
        ) else {
            throw MCPClientError.unknownResponseID(response.id)
        }
        
//#warning("should we just complete or should we handle individual responses differently?")
        try await pendingRequest.complete(withResponse: response)
    }
    
    /// Processes incoming JSON-RPC notifications from the server.
    ///
    /// Notifications are one-way messages that don't require a response.
    /// This method handles various types of notifications by:
    /// 1. Validating the notification method is recognized
    /// 2. Decoding the notification parameters
    /// 3. Updating client state or triggering appropriate callbacks based on notification type
    ///
    /// - Parameter notification: The decoded JSON-RPC notification from the server.
    ///
    /// - Throws:
    ///   - `MCPClientError.unknownNotificationMethod` if the notification method is not recognized.
    ///   - Decoding errors if the notification parameters cannot be properly decoded.
    func handleNotification(_ notification: JSONRPCNotification) async throws {
        guard let notificationMethod = ServerNotification.Method(
            rawValue: notification.method
        ) else {
            logger.warning("Receive unknown notification method: \(notification.method)")
            throw MCPClientError.unknownNotificationMethod(notification.method)
        }
        
        switch notificationMethod {
        case .cancelled:
            let cancelledNotification = try notification.asNotification(CancelledNotification.self)
            try await cancelRequest(
                withID: cancelledNotification.params.requestID,
                forReason: cancelledNotification.params.reason
            )
            
        case .progress:
            let progressNotification = try notification.asNotification(ProgressNotification.self)
            
            guard progressRequests.contains(
                where: { $0.token == progressNotification.params.progressToken }
            ) else {
                logger.warning("Received progress notification for unknown progress token: \(progressNotification.params.progressToken)")
                return
            }
            
            progressHandler?(progressNotification.params)
            
        case .resourceListChanged:
            let resourceNotification = try notification.asNotification(ResourceListChangedNotification.self)
            notificationsContinuation.yield(.resourceListChanged(resourceNotification))
            
        case .resourceUpdated:
            let resourceNotification = try notification.asNotification(ResourceUpdatedNotification.self)
            notificationsContinuation.yield(.resourceUpdated(resourceNotification))
            
        case .promptListChanged:
            let promptNotification = try notification.asNotification(PromptListChangedNotification.self)
            notificationsContinuation.yield(.promptListChanged(promptNotification))
            
        case .toolListChanged:
            let toolNotification = try notification.asNotification(ToolListChangedNotification.self)
            notificationsContinuation.yield(.toolListChanged(toolNotification))
            
        case .loggingMessage:
            let logNotification = try notification.asNotification(LoggingMessageNotification.self)
            notificationsContinuation.yield(.loggingMessage(logNotification))
            logger.log(
                level: logNotification.params.level.osLogType,
                "Received Server Logging Message Notification - logger: \(logNotification.params.logger ?? "nil"), message: \(logNotification.params.data.debugDescription)"
            )
        }
    }
    
    /// Processes incoming JSON-RPC error responses from the server.
    ///
    /// This method handles error responses by:
    /// 1. Associating the error with the corresponding request if possible
    /// 2. Logging the error details
    /// 3. Updating client state if needed
    /// 4. Propagating the error to the waiting caller
    ///
    /// - Parameter error: The decoded JSON-RPC error from the server.
    ///
    /// - Throws: May rethrow the error after processing it.
    func handleError(_ error: JSONRPCError) async throws {
        logger.error("Received JSON-RPC error: \(error)")
#warning("do something here")
    }
    
    /// Waits for a specific response matching the given request type and ID.
    ///
    /// This method monitors the message stream for a response that matches
    /// the provided request ID, then decodes it according to the expected
    /// response type for the given rCequest type.
    ///
    /// - Parameters:
    ///   - requestType: The type of request whose response is expected.
    ///   - requestID: The ID of the request to match.
    ///
    /// - Returns: The decoded response of the expected type.
    ///
    /// - Throws:
    ///   - `MCPClientError.notConnected` if the message stream is not available.
    ///   - `MCPClientError.noResponse` if the stream ends without a matching response.
    ///   - Decoding errors if the response cannot be decoded to the expected type.
//    func response<R: AnyClientRequest>(
//        forRequestType requestType: R.Type,
//        withID requestID: RequestID
//    ) async throws -> R.Result {
//        guard let messageStream else {
//            logger.error("Cannot wait for response, messageStream is nil")
//            throw MCPClientError.notConnected
//        }
//#warning("if we keep it this way, need to add timeout")
//        for try await messageData in messageStream {
//            let message = try decoder.decode(JSONRPCMessage.self, from: messageData)
//            guard case .response(let response) = message else {
//                continue
//            }
//            guard response.id == requestID else {
//                continue
//            }
//            return try response.asResult(R.Result.self)
//        }
//        throw MCPClientError.noResponse(forRequestID: requestID)
//    }
//    
    
    func cancelRequest(
        withID requestID: RequestID,
        forReason reason: String?
    ) async throws {
        logger.info("Cancelling request with id: \(requestID.description), for reason: \(reason ?? "nil")")
        
        // Initialization requests cannot be cancelled, per the spec
        guard requestID != Self.initializationRequestID else {
            logger.error("Cannot cancel initialization request")
            return
        }
        
        progressRequests.removeAll(where: { $0.requestID == requestID })
        
        guard let pendingRequest = pendingRequests.removeValue(forKey: requestID) else {
            logger.warning("No pending request found with ID: \(requestID.description)")
            throw MCPClientError.unknownRequestID(requestID)
        }
        
        try await pendingRequest.cancel()
    }
}

// MARK: - Helpers
extension MCPClient {
    
    private var encoder: JSONEncoder { configuration.encoder }
    
    private var decoder: JSONDecoder { configuration.decoder }
    
    /// The client's supported capabilities.
    public var capabilities: ClientCapabilities { configuration.initialization.capabilities }
    
    /// The underlying transport mechanism used for network communication.
    ///
    /// The transport handles the actual sending and receiving of data, while the client
    /// manages the higher-level protocol logic.
    public var transport: any Transport { configuration.transport }
}

