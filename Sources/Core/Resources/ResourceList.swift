//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation

// MARK: - List Resource Templates

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

// MARK: - List Resources

/// A request to retrieve available resources from the server.
public struct ListResourcesRequest: Codable, Sendable {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: Params?
    
    /// Parameters for configuring the resources list request.
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
    public let meta: Parameters?
    
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
    
    public var params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.params = params
        self.method = Self.method
    }
}
