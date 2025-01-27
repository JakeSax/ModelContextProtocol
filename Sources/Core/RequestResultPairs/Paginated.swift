//
//  Paginated.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Cursor type for pagination
public typealias Cursor = String

/// A paginated request implementation
public struct PaginatedRequest: Codable, Sendable {
    /// The request method name
    public let method: String
    /// Optional pagination parameters
    public let params: PaginationParams?
    
    public init(method: String, params: PaginationParams? = nil) {
        self.method = method
        self.params = params
    }
    
    /// Parameters for paginated requests
    public struct PaginationParams: Codable, Sendable {
        /// An opaque token representing the current pagination position
        public let cursor: Cursor?
        
        public init(cursor: Cursor? = nil) {
            self.cursor = cursor
        }
    }
}


/// A paginated result implementation
public struct PaginatedResult: Codable, Sendable {
    /// Next page cursor token, if more results exist
    public let nextCursor: Cursor?
    
    /// Optional metadata for the result
    public var _meta: DynamicValue?
    
    public init(nextCursor: Cursor? = nil, meta: DynamicValue? = nil) {
        self.nextCursor = nextCursor
        self._meta = meta
    }
}
