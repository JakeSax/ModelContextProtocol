//
//  JSONRPCResponse.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

import Foundation

/// A successful (non-error) response to a request.
public struct JSONRPCResponse: AnyJSONRPCResponse, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID
    public let result: DynamicValue
    
    public var debugDescription: String {
        "jsonRPC: \(jsonrpc), id: \(id), result: \(result.debugDescription)"
    }
    
    // MARK: Initialization
    public init(id: RequestID, result: DynamicValue) {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.result = result
    }
    
    public init<T: Result>(id: RequestID, result: T) throws {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.result = try result.toDynamicValue()
    }
    
    // MARK: Methods
    /// Attempts to convert this ``JSONRPCResult`` into a ``Result`` of the provided type.
    /// - Parameter request: The type of ``Result`` to convert `self` to.
    /// - Returns: `self` converted to the provided type, if successful.
    public func asResult<T: Result>(_ resultType: T.Type) throws -> T {
        let encodedResult = try JSONEncoder().encode(self.result)
        return try JSONDecoder().decode(T.self, from: encodedResult)
    }
}
