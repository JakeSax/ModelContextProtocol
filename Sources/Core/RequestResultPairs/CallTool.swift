//
//  CallTool.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Used by the client to invoke a tool provided by the server.
public struct CallToolRequest: Codable, Sendable {
    /// The method identifier for tool calls
    public let method: ClientRequest.Method
    
    /// Parameters for the tool call
    public let params: Parameters
    
    public struct Parameters: Codable, Sendable {
        /// Name of the tool to call
        public let name: String
        
        /// Arguments to pass to the tool
        public let arguments: [String: DynamicValue]?
        
        public init(name: String, arguments: [String: DynamicValue]? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .callTool
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
public struct CallToolResult: Codable, Sendable {
    /// Additional metadata attached to the response
    public let meta: Parameters?
    
    /// Content returned by the tool
    public let content: [MessageContent]
    
    /// Whether the tool call ended in an error
    public let isError: Bool?
    
    public init(
        meta: Parameters? = nil,
        content: [MessageContent],
        isError: Bool? = nil
    ) {
        self.meta = meta
        self.content = content
        self.isError = isError
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "_meta"
        case content
        case isError
    }
}
