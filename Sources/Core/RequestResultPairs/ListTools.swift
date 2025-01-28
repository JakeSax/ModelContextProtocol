//
//  ListTools.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to list available tools from the server
public struct ListToolsRequest: PaginatedRequest {
    
    public static let method: ClientRequest.Method = .listTools
    
    /// The method identifier for the tools/list request
    public let method: ClientRequest.Method
    
    public let params: PaginationParameters
    
    public init(params: PaginationParameters = PaginationParameters()) {
        self.method = Self.method
        self.params = params
    }
}

/// The response containing available tools from the server
public struct ListToolsResult: PaginatedResult {
    
    /// Array of available tools
    public let tools: [Tool]
    
    /// Token for accessing the next page of results
    public let nextCursor: Cursor?
    
    public let _meta: ResultMetadata?
    
    public init(
        tools: [Tool],
        nextCursor: Cursor? = nil,
        meta: ResultMetadata? = nil
    ) {
        self.tools = tools
        self.nextCursor = nextCursor
        self._meta = meta
    }
}
