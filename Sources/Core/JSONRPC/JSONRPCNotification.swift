//
//  JSONRPCNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

import Foundation

/// A notification which does not expect a response.
public struct JSONRPCNotification: AnyJSONRPCMessage, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let method: String
    public let params: [String: DynamicValue]?
    
    public var debugDescription: String {
        "jsonRPC: \(jsonrpc), method: \(method), params: \(params?.debugDescription ?? "nil")"
    }
    
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
