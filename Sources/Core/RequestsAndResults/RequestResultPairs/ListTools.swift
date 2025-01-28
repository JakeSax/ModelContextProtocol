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
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
}

/// The response containing available tools from the server
public struct ListToolsResult: PaginatedResult {
    
    /// Token for accessing the next page of results
    public let nextCursor: Cursor?
    
    /// Array of available tools
    public let tools: [Tool]
    
    public let _meta: ResultMetadata?
    
    public init(
        nextCursor: Cursor? = nil,
        tools: [Tool],
        meta: ResultMetadata? = nil
    ) {
        self.tools = tools
        self.nextCursor = nextCursor
        self._meta = meta
    }
}
