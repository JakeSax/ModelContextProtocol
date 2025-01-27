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
public struct CreateMessageRequest: Codable, Sendable {
    public static let method: ServerRequest.Method = .createMessage
    public let method: ServerRequest.Method
    public let params: MessageParameters
    
    init(params: MessageParameters) {
        self.method = .createMessage
        self.params = params
    }
    
    public struct MessageParameters: Codable, Sendable {
        /// Maximum tokens to sample. Client may sample fewer.
        public let maxTokens: Int
        
        /// Messages to include in the sampling request
        public let messages: [SamplingMessage]
        
        /// Request to include context from MCP servers
        public var includeContext: ContextInclusion?
        
        /// Provider-specific metadata to pass through
        public var metadata: Parameters?
        
        /// Server's model preferences (client may ignore)
        public var modelPreferences: ModelPreferences?
        
        /// Sequences that will stop sampling when encountered
        public var stopSequences: [String]?
        
        /// Optional system prompt (client may modify/omit)
        public var systemPrompt: String?
        
        /// Temperature for sampling
        public var temperature: Double?
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
    public let meta: Parameters?
    
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
