//
//  ListResourceTemplates.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available resource templates from the server.
public struct ListResourceTemplatesRequest: PaginatableRequest {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: PaginationParameters
    
    public init(params: PaginationParameters = PaginationParameters()) {
        self.params = params
        self.method = .listResourceTemplates
    }
}

/// The server's response to a resources/templates/list request.
public struct ListResourceTemplatesResult: Result {
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: String?
    
    /// The list of returned resource templates.
    public let resourceTemplates: [ResourceTemplate]
    
    public let _meta: ResultMetadata?
    
    public init(
        nextCursor: String? = nil,
        resourceTemplates: [ResourceTemplate],
        meta: ResultMetadata? = nil
    ) {
        self.nextCursor = nextCursor
        self.resourceTemplates = resourceTemplates
        self._meta = meta
    }
}
