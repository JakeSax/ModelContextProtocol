//
//  ListResources.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available resources from the server.
public struct ListResourcesRequest: PaginatedRequest {
    
    public static let method: ClientRequest.Method = .listResources
    
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
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

/// The server's response to a resources/list request.
public struct ListResourcesResult: PaginatedResult {
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: Cursor?
    
    /// The list of returned resources.
    public let resources: [Resource]
    
    public let _meta: ResultMetadata?
    
    public init(
        nextCursor: Cursor? = nil,
        resources: [Resource],
        meta: [String: DynamicValue]? = nil
    ) {
        self.nextCursor = nextCursor
        self.resources = resources
        self._meta = meta
    }
}

/// An optional notification from the server to the client, informing it that the list of resources
/// it can read from has changed. This may be issued by servers without any previous subscription
/// from the client.
public struct ResourceListChangedNotification: AnyServerNotification {
    
    public static let method: ServerNotification.Method = .resourceListChanged
    
    /// The method identifier for this notification.
    public let method: ServerNotification.Method
    
    public var params: DefaultNotificationParameters
    
    public init(params: DefaultNotificationParameters = .init()) {
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
