//
//  GetPrompt.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to get a prompt from the server
public struct GetPromptRequest: Codable, Sendable {
    public let method: ClientRequest.Method
    public let params: Parameters
    
    public struct Parameters: Codable, Sendable {
        public let name: String
        public let arguments: [String: String]?
        
        public init(name: String, arguments: [String: String]? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .getPrompt
    }
}

/// The server's response to a `prompts/get` request from the client.
public struct GetPromptResult: Codable, Sendable {
    /// An optional description for the prompt.
    public let messages: [PromptMessage]
    public let description: String?
    public let meta: Parameters?
    
    public init(
        meta: [String: DynamicValue]? = nil,
        messages: [PromptMessage],
        description: String? = nil
    ) {
        self.meta = meta
        self.messages = messages
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "_meta"
        case messages
        case description
    }
}
