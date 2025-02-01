//
//  SharedResults.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A non-distinct result type that allows for additional metadata in responses. It must
/// reserve the key `_meta` to allow clients and servers to attach additional metadata
/// to their results/notifications.
public protocol Result: Codable, Sendable, Equatable {
    /// This property is reserved by MCP to allow clients and servers to attach
    /// additional metadata to their messages.
    var _meta: ResultMetadata? { get }
}
public typealias ResultMetadata = [String: DynamicValue]

public typealias AnyResult = [String: DynamicValue]

extension AnyResult: Result {}

/// Empty result type
public typealias EmptyResult = AnyResult

