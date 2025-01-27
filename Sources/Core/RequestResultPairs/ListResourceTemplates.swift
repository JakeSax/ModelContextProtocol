//
//  ListResourceTemplates.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available resource templates from the server.
public struct ListResourceTemplatesRequest: Codable, Sendable {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: Params?
    
    /// Parameters for configuring the resource templates list request.
    public struct Params: Codable, Sendable {
        /// An opaque token representing the current pagination position.
        /// If provided, the server will return results starting after this cursor.
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
    
    public init(params: Params? = nil) {
        self.params = params
        self.method = .listResourceTemplates
    }
}

/// The server's response to a resources/templates/list request.
public struct ListResourceTemplatesResult: Codable, Sendable {
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: String?
    
    /// The list of returned resource templates.
    public let resourceTemplates: [ResourceTemplate]
    
    /// Reserved metadata field for additional response information.
    public let meta: Parameters?
    
    public init(
        nextCursor: String? = nil,
        resourceTemplates: [ResourceTemplate],
        meta: [String: DynamicValue]? = nil
    ) {
        self.nextCursor = nextCursor
        self.resourceTemplates = resourceTemplates
        self.meta = meta
    }
}
