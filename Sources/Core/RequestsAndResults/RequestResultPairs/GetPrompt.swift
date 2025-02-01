//
//  GetPrompt.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to get a prompt from the server
public struct GetPromptRequest: Request {
        
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .getPrompt
    public typealias Response = GetPromptResult
    
    // MARK: Properties
    public let method: ClientRequest.Method
    public let params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
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
    
    // MARK: Codable Conformance
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
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
