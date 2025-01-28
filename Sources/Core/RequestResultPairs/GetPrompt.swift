//
//  GetPrompt.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to get a prompt from the server
public struct GetPromptRequest: Request {
    public let method: ClientRequest.Method
    public let params: Parameters
    
    public struct Parameters: RequestParameters {
        public let name: String
        public let arguments: [String: String]?
        public let _meta: RequestMetadata?
        
        public init(
            name: String,
            arguments: [String: String]? = nil,
            meta: RequestMetadata? = nil
        ) {
            self.name = name
            self.arguments = arguments
            self._meta = meta
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .getPrompt
    }
}

/// The server's response to a `prompts/get` request from the client.
public struct GetPromptResult: Result {
    
    public let messages: [PromptMessage]
    
    /// An optional description for the prompt.
    public let description: String?
    
    public let _meta: ResultMetadata?
    
    public init(
        messages: [PromptMessage],
        description: String? = nil,
        meta: ResultMetadata? = nil
    ) {
        self.messages = messages
        self.description = description
        self._meta = meta
    }
    
}
