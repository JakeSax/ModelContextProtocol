//
//  CreateMessage.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request from the server to sample an LLM via the client. The client has full
/// discretion over which model to select. The client should also inform the user
/// before beginning sampling, to allow them to inspect the request (human in
/// the loop) and decide whether to approve it.
public struct CreateMessageRequest: Request {
    public static let method: ServerRequest.Method = .createMessage
    
    // MARK: Properties
    public let method: ServerRequest.Method
    public let params: MessageParameters
    
    // MARK: Initialization
    init(params: MessageParameters) {
        self.method = .createMessage
        self.params = params
    }
    
    // MARK: Data Structures
    public struct MessageParameters: RequestParameters {
        /// Maximum tokens to sample. Client may sample fewer.
        public let maxTokens: Int
        
        /// Messages to include in the sampling request
        public let messages: [SamplingMessage]
        
        /// Request to include context from MCP servers
        public let includeContext: ContextInclusion?
        
        /// Provider-specific metadata to pass through
        public let metadata: OldParameters?
        
        /// Server's model preferences (client may ignore)
        public let modelPreferences: ModelPreferences?
        
        /// Sequences that will stop sampling when encountered
        public let stopSequences: [String]?
        
        /// Optional system prompt (client may modify/omit)
        public let systemPrompt: String?
        
        /// Temperature for sampling
        public let temperature: Double?
        
        public let _meta: RequestMetadata?
    }
    
    /// Available context inclusion options for message creation
    public enum ContextInclusion: String, Codable, Sendable {
        case allServers
        case none
        case thisServer
    }
}

/// The client's response to a sampling/create_message request from the server.
public struct CreateMessageResult: Codable, Sendable {
    /// Additional metadata attached to the response.
    public let meta: OldParameters?
    
    /// The content of the generated message.
    public let content: MessageContent
    
    /// The name of the model that generated the message.
    public let model: String
    
    /// The role of the message sender.
    public let role: Role
    
    /// The reason why sampling stopped, if known.
    public let stopReason: String?
    
    public init(
        content: MessageContent,
        model: String,
        role: Role,
        stopReason: String? = nil,
        meta: [String: DynamicValue]? = nil
    ) {
        self.content = content
        self.model = model
        self.role = role
        self.stopReason = stopReason
        self.meta = meta
    }
}
