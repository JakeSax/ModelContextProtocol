//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Represents an available resource, such as an external dataset.
public struct Resource: Codable {
    public let name: String
    public let data: DynamicValue
}

/// Represents a request to list available resources.
public struct ListResourcesRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "resources/list"
    public let params: [String: DynamicValue]?
}

/// Represents a response to list available resources.
public struct ListResourcesResult: Codable {
    public let resources: [Resource]
    public let nextCursor: Cursor?
}

/// Represents a request to retrieve a resource.
public struct ReadResourceRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "resources/read"
    public let params: [String: DynamicValue]
}

/// Represents a response to a resource read request.
public struct ReadResourceResult: Codable {
    public let contents: [DynamicValue]
}

/// Notification for resource updates.
public struct ResourceUpdatedNotification: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/resources/updated"
    public let params: [String: DynamicValue]
}
