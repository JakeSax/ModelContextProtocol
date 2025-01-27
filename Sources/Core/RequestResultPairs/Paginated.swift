//
//  Paginated.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Cursor type for pagination
public typealias Cursor = String

/// A paginated request implementation
public protocol PaginatableRequest: Request where Parameters == PaginationParameters {}

/// Parameters for paginated requests
public struct PaginationParameters: RequestParameters {
    /// An opaque token representing the current pagination position
    public let cursor: Cursor?
    
    public let _meta: RequestMetadata?
    
    public init(cursor: Cursor? = nil, meta: RequestMetadata? = nil) {
        self.cursor = cursor
        self._meta = meta
    }
}

/// A paginated result implementation
public protocol PaginatedResult: Codable, Sendable {
    /// Next page cursor token, if more results exist
    var nextCursor: Cursor? { get }
    
    /// Optional metadata for the result
    var _meta: DynamicValue? { get }
}
