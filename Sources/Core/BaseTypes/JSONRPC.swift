//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// A structure containing JSON-RPC protocol constants.
/// This includes the latest protocol version and the JSON-RPC version being used.
public enum JSONRPC {
    /// The latest version of the MCP protocol.
    public static let latestProtocolVersion = "2024-11-05"
    
    /// The JSON-RPC version being used.
    public static let jsonrpcVersion = "2.0"
}

//protocol JSONRPCMessage: Codable, Sendable {
//    var jsonrpc: String { get }
//}
//
//extension JSONRPCMessage {
//    var jsonrpc: String { JSONRPC.jsonrpcVersion }
//}
//
///// Represents a JSON-RPC request message that expects a response.
//protocol JSONRPCRequest: JSONRPCMessage {
//    var id: RequestID { get }
//    var method: String { get }
//    var params: [String: DynamicValue]? { get }
//}

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
//public struct JSONRPCRequest: JSONRPCMessage {
//    
//    // MARK: Properties
//    public let id: RequestID
//    public let method: String
//    public let params: [String: DynamicValue]?
//    
//    // MARK: Initialization
//    public init(id: RequestID, method: String, params: [String : DynamicValue]?) {
//        self.id = id
//        self.method = method
//        self.params = params
//    }
//}

/// Represents a JSON-RPC notification, which does not expect a response.
//public struct JSONRPCNotification: JSONRPCMessage {
//    public let method: String
//    public let params: [String: DynamicValue]?
//    
//    /// Represents an initialization notification.
//    static let initialized: JSONRPCNotification = .init(
//        method: "notifications/initialized",
//        params: nil
//    )
//}
//
///// Represents a successful JSON-RPC response to a request.
//public struct JSONRPCResponse: JSONRPCMessage {
//    public let id: RequestID
//    public let result: DynamicValue
//}
//
///// Represents an error response in JSON-RPC.
//public struct JSONRPCError: Codable {
//    /// Contains details about an error, including a code, message, and optional data.
//    public struct ErrorDetail: Codable {
//        public let code: Int
//        public let message: String
//        public let data: DynamicValue?
//    }
//    public var jsonrpc: String = JSONRPC.jsonrpcVersion
//    public let id: RequestID?
//    public let error: ErrorDetail
//}

enum JSONRPCErrorCode: Int, Error {
    // Standard JSON-RPC error codes
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
}
