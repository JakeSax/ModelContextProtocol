//
//  JSONRPC.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// A structure containing JSON-RPC protocol constants.
/// This includes the latest protocol version and the JSON-RPC version being used.
public enum JSONRPC {
    /// The latest version of the MCP protocol.
    public static let latestProtocolVersion: String = "2024-11-05"
    
    /// The JSON-RPC version being used, `2.0` in this case.
    public static let jsonrpcVersion: String = "2.0"
}

/// Any Message that includes the JSON-RPC version being used.
public protocol AnyJSONRPCMessage: Codable, Sendable {
    /// The version of JSON-RPC being used, defaults to "2.0"
    var jsonrpc: String { get }
}

extension AnyJSONRPCMessage {
    /// The JSON-RPC version being used, `2.0` in this case.
    public static var jsonrpcVersion: String { JSONRPC.jsonrpcVersion }
}

