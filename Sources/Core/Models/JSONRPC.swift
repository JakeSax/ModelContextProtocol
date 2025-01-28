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

// MARK: JSON-RPC Message Types
public enum JSONRPCMessage: Codable, Sendable, Equatable {
    case request(JSONRPCRequest)
    case notification(JSONRPCNotification)
    case response(JSONRPCResponse)
    case error(JSONRPCError)
    
    var value: any AnyJSONRPCMessage {
        switch self {
        case .request(let request): request
        case .notification(let notification): notification
        case .response(let response): response
        case .error(let error): error
        }
    }
    
    // MARK: Codable Conformance
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .request(let request): try container.encode(request)
        case .notification(let notification): try container.encode(notification)
        case .response(let response): try container.encode(response)
        case .error(let error): try container.encode(error)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let jsonObject = try container.decode([String: DynamicValue].self)
        
        // Ensure this is a valid JSON-RPC message
        guard let jsonrpc = jsonObject["jsonrpc"]?.stringValue else {
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Missing JSON-RPC version",
                    data: nil
                )
            )
        }
        guard jsonrpc == JSONRPC.jsonrpcVersion else {
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Invalid JSON-RPC version",
                    data: nil
                )
            )
        }
        
        if jsonObject["id"] != nil, jsonObject["method"] != nil {
            // This is a **request** (has an `id` and `method`)
            self = .request(try container.decode(JSONRPCRequest.self))
        } else if jsonObject["method"] != nil {
            // This is a **notification** (has a `method` but no `id`)
            self = .notification(try container.decode(JSONRPCNotification.self))
        } else if jsonObject["id"] != nil, jsonObject["result"] != nil {
            // This is a **response** (has an `id` and a `result`)
            self = .response(try container.decode(JSONRPCResponse.self))
        } else if jsonObject["id"] != nil, jsonObject["error"] != nil {
            // This is an **error** response (has an `id` and an `error` object)
            self = .error(try container.decode(JSONRPCError.self))
        } else {
            // The JSON structure doesn’t match any valid JSON-RPC message type
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Invalid JSON-RPC message",
                    data: nil
                )
            )
        }
    }
}

/// A request that expects a response.
public struct JSONRPCRequest: AnyJSONRPCMessage, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID
    public let method: String
    public let params: [String: DynamicValue]?
    
    // MARK: Initialization
    public init(id: RequestID, method: String, params: [String : DynamicValue]?) {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.method = method
        self.params = params
    }
    
    public init<T: Request>(id: RequestID, request: T) throws {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.method = request.method.rawValue
        self.params = try request.params.toOptionalDynamicDictionary()
    }
    
    // MARK: Methods
    /// Attempts to convert this ``JSONRPCRequest`` into a ``Request`` of the provided type.
    /// - Parameter request: The type of ``Request`` to convert `self` to.
    /// - Returns: `self` converted to the provided type, if successful.
    func asRequest<T: Request>(_ requestType: T.Type) throws -> T {
        guard let method = T.MethodIdentifier(rawValue: self.method),
              method == T.method else {
            throw RequestConversionError.invalidMethod
        }
        let encodedParams = try JSONEncoder().encode(params ?? [:])
        let requestParams = try JSONDecoder().decode(T.Parameters.self, from: encodedParams)
        return T(params: requestParams)
    }
    
    private enum RequestConversionError: Error {
        case invalidMethod
    }
}

/// A notification which does not expect a response.
public struct JSONRPCNotification: AnyJSONRPCMessage, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let method: String
    public let params: [String: DynamicValue]?
    
    // MARK: Initialization
    public init(method: String, params: [String: DynamicValue]?) {
        self.jsonrpc = Self.jsonrpcVersion
        self.method = method
        self.params = params
    }
    
    public init<T: Notification>(notification: T) throws {
        self.jsonrpc = Self.jsonrpcVersion
        self.method = notification.method.rawValue
        self.params = try notification.params.toOptionalDynamicDictionary()
    }
    
    // MARK: Methods
    /// Attempts to convert this ``JSONRPCNotification`` into a ``Notification`` of the provided type.
    /// - Parameter request: The type of ``Notification`` to convert `self` to.
    /// - Returns: `self` converted to the provided type, if successful.
    func asNotification<T: Notification>(_ notificationType: T.Type) throws -> T {
        guard let method = T.MethodIdentifier(rawValue: self.method),
              method == T.method else {
            throw NotificationConversionError.invalidMethod
        }
        let encodedParams = try JSONEncoder().encode(params ?? [:])
        let notificationParams = try JSONDecoder().decode(T.Parameters.self, from: encodedParams)
        return T(params: notificationParams)
    }
    
    private enum NotificationConversionError: Error {
        case invalidMethod
    }
}

/// A successful (non-error) response to a request.
public struct JSONRPCResponse: AnyJSONRPCMessage, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID
    public let result: DynamicValue
    
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
    func asResult<T: Result>(_ resultType: T.Type) throws -> T {
        let encodedResult = try JSONEncoder().encode(self.result)
        return try JSONDecoder().decode(T.self, from: encodedResult)
    }
}

/// A response to a request that indicates an error occurred.
public struct JSONRPCError: AnyJSONRPCMessage, Error, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID?
    public let error: ErrorDetails
    
    // MARK: Initialization
    public init(id: RequestID?, error: ErrorDetails) {
        self.jsonrpc = Self.jsonrpcVersion
        self.id = id
        self.error = error
    }
    
    // MARK: Data Structures
    public struct ErrorDetails: Codable, Sendable, Equatable {
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
