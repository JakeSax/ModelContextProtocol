//
//  JSONRPCError.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

/// A response to a request that indicates an error occurred.
public struct JSONRPCError: AnyJSONRPCMessage, Error, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID?
    public let error: ErrorDetails
    
    public var debugDescription: String {
        "jsonRPC: \(jsonrpc), id: \(id?.description ?? "nil"), error: \(error.debugDescription)"
    }
    
    // MARK: Initialization
    public init(id: RequestID?, error: ErrorDetails) {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.error = error
    }
    
    // MARK: Data Structures
    public struct ErrorDetails: Codable, Sendable, Equatable, CustomDebugStringConvertible {
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
        
        public var debugDescription: String {
            "code: \(code), jsonRPCError: \(jsonrpcErrorCode?.localizedDescription ?? "nil"), message: \(message), data: \(String(describing: data)))"
        }
        
        public init(code: Int, message: String, data: DynamicValue? = nil) {
            self.code = code
            self.message = message
            self.data = data
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
