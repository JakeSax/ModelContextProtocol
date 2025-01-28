//
//  Paginated.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Cursor type for pagination
public typealias Cursor = String

/// A ``Request`` that may use pagination, using a String as a cursor.
public protocol PaginatedRequest: Request where Parameters == PaginationParameters {}

/// Parameters for paginated requests
public struct PaginationParameters: RequestParameters {
    /// An opaque token representing the current pagination position.
    public let cursor: Cursor?
    
    public let _meta: RequestMetadata?
    
    public init(cursor: Cursor? = nil, meta: RequestMetadata? = nil) {
        self.cursor = cursor
        self._meta = meta
    }
}

/// A ``Result`` that may use pagination, using a String as a cursor.
public protocol PaginatedResult: Result {
    /// Next page cursor token, if more results exist
    var nextCursor: Cursor? { get }
}
