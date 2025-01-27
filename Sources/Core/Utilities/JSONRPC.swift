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
    public static let latestProtocolVersion = "2024-11-05"
    
    /// The JSON-RPC version being used.
    public static let jsonrpcVersion = "2.0"
}

/// Any Message that includes the JSON-RPC version being used.
public protocol AnyJSONRPCMessage: Codable, Sendable {
    /// The version of JSON-RPC being used, defaults to "2.0"
    var jsonrpc: String { get }
}

extension AnyJSONRPCMessage {
    public var jsonrpc: String { JSONRPC.jsonrpcVersion }
}

// MARK: JSON-RPC Message Types
public enum JSONRPCMessage: Codable {
    case request(JSONRPCRequest)
    case notification(JSONRPCNotification)
    case response(JSONRPCResponse)
    case error(JSONRPCError)
}

/// A request that expects a response.
public struct JSONRPCRequest: AnyJSONRPCMessage, SupportsProgressToken {
    public let id: RequestID
    public let method: String
    public let params: Parameters?
}

/// A notification which does not expect a response.
public struct JSONRPCNotification: AnyJSONRPCMessage {
    public let method: String
    public let params: Parameters?
}

/// A successful (non-error) response to a request.
public struct JSONRPCResponse: AnyJSONRPCMessage {
    public let id: RequestID
    public let result: Result
}

/// A response to a request that indicates an error occurred.
public struct JSONRPCError: AnyJSONRPCMessage {
    public let id: RequestID
    public let error: ErrorDetails
    
    public struct ErrorDetails: Codable ,Sendable {
        /// The error type that occurred.
        public let code: Int
        
        /// A short description of the error. The message SHOULD be limited to a concise
        /// single sentence.
        public let message: String
        
        /// Additional information about the error. The value of this member is defined
        /// by the sender (e.g. detailed error information, nested errors etc.).
        public let data: DynamicValue?
        
        public var jsonrpcErrorCode: ErrorCode? {
            .init(rawValue: code)
        }
    }
    
    /// The set of pre-defined errors by the JSON-RPC spec.
    public enum ErrorCode: Int, Error {
        /// Invalid JSON was received by the server.
        /// An error occurred on the server while parsing the JSON text.
        case parseError = -32700
        /// The JSON sent is not a valid Request object.
        case invalidRequest = -32600
        /// The method does not exist / is not available.
        case methodNotFound = -32601
        /// Invalid method parameter(s).
        case invalidParams = -32602
        /// Internal JSON-RPC error.
        case internalError = -32603
    }
    
}
