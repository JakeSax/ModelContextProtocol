//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// A structure containing JSON-RPC protocol constants.
/// This includes the latest protocol version and the JSON-RPC version being used.
public struct JSONRPC {
    /// The latest version of the MCP protocol.
    public static let latestProtocolVersion = "2024-11-05"
    
    /// The JSON-RPC version being used.
    public static let jsonrpcVersion = "2.0"
}


/// Handles encoding and decoding of JSON-RPC messages.
public struct JSONRPCMessageHandler {
    /// Encodes a JSON-RPC message to JSON data.
    public static func encode<T: Codable>(_ message: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(message)
    }
    
    /// Decodes JSON data into a JSON-RPC message.
    public static func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}


/// Represents a JSON-RPC request message that expects a response.
public struct JSONRPCRequest: Codable {
    public var jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String
    public let params: [String: DynamicValue]?
}

/// Represents a JSON-RPC notification, which does not expect a response.
public struct JSONRPCNotification: Codable {
    public var jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String
    public let params: [String: DynamicValue]?
}

/// Represents a successful JSON-RPC response to a request.
public struct JSONRPCResponse: Codable {
    public var jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let result: DynamicValue
}

/// Represents an error response in JSON-RPC.
public struct JSONRPCError: Codable {
    /// Contains details about an error, including a code, message, and optional data.
    public struct ErrorDetail: Codable {
        public let code: Int
        public let message: String
        public let data: DynamicValue?
    }
    public var jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue?
    public let error: ErrorDetail
}
