//
//  CallTool.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Used by the client to invoke a tool provided by the server.
public struct CallToolRequest: Request {
    
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .callTool
    
    // MARK: Properties
    /// The method identifier for tool calls
    public let method: ClientRequest.Method
    
    /// Parameters for the tool call
    public let params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    public struct Parameters: RequestParameters {
        /// Name of the tool to call
        public let name: String
        
        /// Arguments to pass to the tool
        public let arguments: [String: DynamicValue]?
        
        public let _meta: RequestMetadata?
        
        public init(
            name: String,
            arguments: [String: DynamicValue]? = nil,
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

/// The server's response to a tool call.
///
/// Any errors that originate from the tool SHOULD be reported inside the result
/// object, with `isError` set to true, _not_ as an MCP protocol-level error
/// response. Otherwise, the LLM would not be able to see that an error occurred
/// and self-correct.
///
/// However, any errors in _finding_ the tool, an error indicating that the
/// server does not support tool calls, or any other exceptional conditions,
/// should be reported as an MCP error response.
public struct CallToolResult: Result {
    
    /// Content returned by the tool
    public let content: [MessageContent]
    
    /// Whether the tool call ended in an error
    public let isError: Bool?
    
    public let _meta: ResultMetadata?
    
    public init(
        content: [MessageContent],
        isError: Bool? = nil,
        meta: ResultMetadata? = nil
    ) {
        self.content = content
        self.isError = isError
        self._meta = meta
    }
}
