//
//  ListResources.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available resources from the server.
public struct ListResourcesRequest: PaginatableRequest {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: PaginationParameters
    
    public init(params: PaginationParameters = PaginationParameters()) {
        self.params = params
        self.method = .listResources
    }
}

/// The server's response to a resources/list request.
public struct ListResourcesResult: Codable, Sendable {
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: String?
    
    /// The list of returned resources.
    public let resources: [Resource]
    
    /// Reserved metadata field for additional response information.
    public let meta: OldParameters?
    
    public init(
        nextCursor: String? = nil,
        resources: [Resource],
        meta: [String: DynamicValue]? = nil
    ) {
        self.meta = meta
        self.nextCursor = nextCursor
        self.resources = resources
    }
}

/// An optional notification from the server to the client, informing it that the list of resources
/// it can read from has changed. This may be issued by servers without any previous subscription
/// from the client.
public struct ResourceListChangedNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .resourceListChanged
    /// The method identifier for this notification.
    public let method: ServerNotification.Method
    
    public var params: OldParameters?
    
    public init(params: OldParameters? = nil) {
        self.params = params
        self.method = Self.method
    }
}
