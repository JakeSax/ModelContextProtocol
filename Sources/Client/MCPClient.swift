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
    
    // MARK: Properties
    
    /// Configuration for this client instance.
    ///
    /// Contains settings that define the client's behavior, server connection parameters,
    /// and protocol options.
    public let configuration: Configuration
    
    /// The current state of the client.
    ///
    /// This property reflects where the client is in its lifecycle: disconnected,
    /// connecting, initializing, running, or failed.
    public private(set) var state: State
    
    /// A dictionary mapping request IDs to their corresponding pending requests.
    ///
    /// Used to track in-flight requests that are awaiting responses from the server.
    private(set) var pendingRequests: [RequestID : any AnyClientRequest]
    
    /// The stream of raw data messages from the transport.
    ///
    /// This stream is created when the client connects and is used to process
    /// incoming messages from the server.
    private(set) var messageStream: AsyncThrowingStream<Data, any Error>?
    
    /// The task responsible for processing incoming messages.
    ///
    /// This long-running task reads from the message stream and dispatches messages
    /// to appropriate handlers based on their type.
    private(set) var messageProcessingTask: Task<Void, Error>?
    
    /// A logger for recording events and errors.
    ///
    /// Used throughout the client to provide diagnostic information about the
    /// client's operation and any issues encountered.
    nonisolated private let logger: Logger
    
    // MARK: Initialization
    /// Creates a new MCPClient instance configured to communicate with an MCP server.
    ///
    /// The client will not connect to the server until `connect()` is called.
    ///
    /// - Parameters:
    ///   - configuration: The configuration specifying how to connect to and interact
    ///     with the MCP server.
    ///   - logger: The OSLog Logger for recording events and errors. Defaults to a Logger
    ///     with subsystem `"MCPClient"` and the client's name from the configuration.
    public init(
        configuration: Configuration,
        logger: Logger? = nil
    ) {
        self.configuration = configuration
        self.state = .disconnected
        self.pendingRequests = [:]
        self.messageStream = nil
        self.messageProcessingTask = nil
        self.logger = logger ?? Logger(
            subsystem: "MCPClient",
            category: configuration.initialization.clientInfo.name
        )
    }
    
    // MARK: Connection Management
    
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
        guard state != .connecting, state != .initializing else {
            logger.warning("Not beginning connection, already connecting or initializing")
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
            let requestID: RequestID = 1
            
            try await sendRequest(request, requestID: requestID)
            
            let response = try await response(
                forRequestType: type(of: request),
                withID: requestID
            )
            
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
    ///   - request: The request to send, conforming to `AnyClientRequest`.
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
    func sendRequest<R: AnyClientRequest>(
        _ request: R,
        requestID: RequestID
    ) async throws {
        
        guard await transport.state == .connected else {
            throw MCPClientError.transportNotConnected
        }
        
        // Ensure only the initialization notification is being sent if initializing
        if state == .initializing, request.method != .initialize {
            logger.error("Cannot send non-initialization request while initializing")
            throw MCPClientError.notConnected
        }
        
        // Ensure the client is running (or initializing as previously handled)
        guard state.isRunning || state == .initializing else {
            logger.error("Client is not running")
            throw MCPClientError.notConnected
        }
        
        logger.info("Preparing to send request with method: \(request.method.rawValue), and ID: \(requestID.description)")
        
        guard !pendingRequests.keys.contains(requestID) else {
            logger.error("Cannot send a request with the same ID twice: \(requestID.description)")
            throw MCPClientError.duplicateRequestID(requestID)
        }
        
        // Convert to JSONRPCRequest and encode it.
        let jsonRPCRequest = try JSONRPCRequest(id: requestID, request: request)
        let encodedRequest = try encoder.encode(jsonRPCRequest)
        
        // Send the request over transport
        try await transport.send(encodedRequest, timeout: nil)
        
        pendingRequests[requestID] = request
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
    func sendResponse(_ response: JSONRPCResponse) async throws {
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
        logger.info("Sending Response: \(response.id.description)")
        try await transport.send(
            try encoder.encode(response),
            timeout: nil
        )
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
        logger.info("Emitting notification: \(notification.method.rawValue)")
        try await transport.send(
            try encoder.encode(notification),
            timeout: nil
        )
    }
}

// MARK: - Handling Messages
private extension MCPClient {
    
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
            try await sendResponse(JSONRPCResponse(id: request.id, result: PingRequest.Response()))
            
        case .createMessage:
            guard capabilities.supportsSampling else {
                throw MCPClientError.unsupportedCapability(method: serverRequestMethod)
            }
            let createMessageRequest = try request.asRequest(CreateMessageRequest.self)
#warning("do something here")
            
        case .listRoots:
            guard capabilities.supportsRootListing else {
                throw MCPClientError.unsupportedCapability(method: serverRequestMethod)
            }
            let listRootsRequest = try request.asRequest(ListRootsRequest.self)
#warning("do something here")
        }
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
        guard let notificationMethod = ServerNotification.Method(rawValue: notification.method) else {
            throw MCPClientError.unknownNotificationMethod(notification.method)
        }
        
        switch notificationMethod {
        case .cancelled:
            let cancelledNotification = try notification.asNotification(CancelledNotification.self)
#warning("do something here")
            
        case .progress:
            let progressNotification = try notification.asNotification(ProgressNotification.self)
#warning("do something here")
            
        case .resourceListChanged:
            let resourceListChangedNotification = try notification.asNotification(ResourceListChangedNotification.self)
#warning("do something here")
            
        case .resourceUpdated:
            let resourceUpdatedNotification = try notification.asNotification(ResourceUpdatedNotification.self)
#warning("do something here")
            
        case .promptListChanged:
            let promptListChangedNotification = try notification.asNotification(PromptListChangedNotification.self)
#warning("do something here")
            
        case .toolListChanged:
            let toolListChangedNotification = try notification.asNotification(ToolListChangedNotification.self)
#warning("do something here")
            
        case .loggingMessage:
            let logNotification = try notification.asNotification(LoggingMessageNotification.self)
            logger.log(
                level: logNotification.params.level.osLogType,
                "Received Server Logging Message Notification - logger: \(logNotification.params.logger ?? "nil"), message: \(logNotification.params.data.debugDescription)"
            )
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
    ///   - `MCPClientError.mismatchedRequestID` if the response ID doesn't match any pending request.
    ///   - Decoding errors if the response result cannot be properly decoded.
    func handleResponse(_ response: JSONRPCResponse) async throws {
        guard let pendingRequest: any AnyClientRequest = pendingRequests.removeValue(forKey: response.id) else {
            throw MCPClientError.mismatchedRequestID
        }
        
        switch pendingRequest.method {
        case .initialize:
            let result = try response.asResult(InitializeRequest.Response.self)
#warning("do something here")
            
        case .ping:
            let result = try response.asResult(PingRequest.Response.self)
#warning("do something here")
            
        case .listResources:
            let result = try response.asResult(ListResourcesRequest.Response.self)
#warning("do something here")
            
        case .listResourceTemplates:
            let result = try response.asResult(ListResourceTemplatesRequest.Response.self)
#warning("do something here")
            
        case .readResource:
            let result = try response.asResult(ReadResourceRequest.Response.self)
#warning("do something here")
            
        case .subscribe:
            let result = try response.asResult(SubscribeRequest.Response.self)
#warning("do something here")
            
        case .unsubscribe:
            let result = try response.asResult(UnsubscribeRequest.Response.self)
#warning("do something here")
            
        case .listPrompts:
            let result = try response.asResult(ListPromptsRequest.Response.self)
#warning("do something here")
            
        case .getPrompt:
            let result = try response.asResult(GetPromptRequest.Response.self)
#warning("do something here")
            
        case .listTools:
            let result = try response.asResult(ListToolsRequest.Response.self)
#warning("do something here")
            
        case .callTool:
            let result = try response.asResult(CallToolRequest.Response.self)
#warning("do something here")
            
        case .setLevel:
            let result = try response.asResult(SetLevelRequest.Response.self)
#warning("do something here")
            
        case .complete:
            let result = try response.asResult(CompleteRequest.Response.self)
#warning("do something here")
            
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
#warning("do something here")
    }
    
    /// Waits for a specific response matching the given request type and ID.
    ///
    /// This method monitors the message stream for a response that matches
    /// the provided request ID, then decodes it according to the expected
    /// response type for the given request type.
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
    func response<R: AnyClientRequest>(
        forRequestType requestType: R.Type,
        withID requestID: RequestID
    ) async throws -> R.Response {
        guard let messageStream else {
            logger.error("Cannot wait for response, messageStream is nil")
            throw MCPClientError.notConnected
        }
#warning("if we keep it this way, need to add timeout")
        for try await messageData in messageStream {
            let message = try decoder.decode(JSONRPCMessage.self, from: messageData)
            guard case .response(let response) = message else {
                continue
            }
            guard response.id == requestID else {
                continue
            }
            return try response.asResult(R.Response.self)
        }
        throw MCPClientError.noResponse(forRequestID: requestID)
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
