//
//  MCPClient.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation
import MCPCore
import OSLog

/// A client for communicating with an MCP server using JSON-RPC over HTTP.
///
/// This client converts a generic request into a JSON-RPC formatted message, encodes it,
/// sends it to the specified MCP server URL, and decodes the server's JSON-RPC response.
/// It supports adding custom HTTP header fields and logs significant events and errors.
public actor MCPClient {
    
    // MARK: Properties
    let configuration: Configuration
    
    var transport: any Transport { configuration.transport }
    
    private(set) var state: State
    
    private(set) var pendingRequests: [RequestID : any AnyClientRequest]
    
    private(set) var messageStream: AsyncThrowingStream<Data, any Error>?
    private(set) var messageProcessingTask: Task<Void,Error>?
    
    /// A logger for recording events and errors.
    nonisolated private let logger: Logger
    
    // MARK: Initialization
    /// Creates a new MCPClient instance configured to communicate with the MCP server.
    ///
    /// - Parameters:
    ///   - logger: The OSLog Logger for logging errors and debug information.
    ///    Defaults to a Logger with subsystem `"MCPClient"` and the client's name.
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
    
    // MARK: Startup Methods
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
    
    /// Sends a JSON-RPC request to the MCP server via encodeing the provided generic
    /// request into a JSON-RPC format and sending it via `transport`
    ///
    /// - Parameters:
    ///   - request: The generic request conforming to `Request` which holds the
    ///   details of the RPC call.
    ///   - requestID: A unique identifier for the request, used to correlate the response.
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
    
    func handleResponse(_ response: JSONRPCResponse) async throws {
        // try to match response.id with
        guard let pendingRequest: any AnyClientRequest = pendingRequests[response.id] else {
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
    
    func handleError(_ error: JSONRPCError) async throws {
#warning("do something here")
    }
    
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

// MARK: Helpers
extension MCPClient {
    private var encoder: JSONEncoder { configuration.encoder }
    private var decoder: JSONDecoder { configuration.decoder }
    /// The client's supported capabilities
    var capabilities: ClientCapabilities { configuration.initialization.capabilities }
}
