//
//  ListTools.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to list available tools from the server
public struct ListToolsRequest: PaginatableRequest {
    /// The method identifier for the tools/list request
    public let method: ClientRequest.Method
    
    public let params: PaginationParameters
    
    public init(params: PaginationParameters = PaginationParameters()) {
        self.params = params
        self.method = .listTools
    }
}

/// The response containing available tools from the server
public struct ListToolsResult: Result {
    
    /// Token for accessing the next page of results
    public let nextCursor: String?
    
    /// Array of available tools
    public let tools: [Tool]
    
    public let _meta: ResultMetadata?
    
    public init(tools: [Tool], nextCursor: String? = nil, meta: ResultMetadata? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
        self._meta = meta
    }
}
