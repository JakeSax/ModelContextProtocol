//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Represents a paginated request.
public struct PaginatedRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String
    public let params: [String: DynamicValue]?
    public let cursor: Cursor?
}

/// Represents a paginated result.
public struct PaginatedResult: Codable {
    public let nextCursor: Cursor?
}
