//
//  ListTools.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to list available tools from the server
public struct ListToolsRequest: Codable, Sendable {
    /// The method identifier for the tools/list request
    public let method: ClientRequest.Method
    
    public let params: Params
    
    /// Parameters for pagination and filtering
    public struct Params: Codable, Sendable {
        /// Opaque token for pagination position
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
    
    public init(params: Params = Params()) {
        self.params = params
        self.method = .listTools
    }
}

/// The response containing available tools from the server
public struct ListToolsResult: Codable, Sendable {
    
    /// Token for accessing the next page of results
    public let nextCursor: String?
    
    /// Array of available tools
    public let tools: [Tool]
    
    /// Additional metadata attached to the response
    public let meta: Parameters?
    
    public init(tools: [Tool], nextCursor: String? = nil, meta: Parameters? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
        self.meta = meta
    }
}
