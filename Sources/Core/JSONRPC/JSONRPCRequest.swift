//
//  JSONRPCRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

import Foundation

/// A request that expects a response.
public struct JSONRPCRequest: AnyJSONRPCMessage, Equatable {
    
    // MARK: Properties
    public let jsonrpc: String
    public let id: RequestID
    public let method: String
    public let params: [String: DynamicValue]?
    
    public var debugDescription: String {
        "jsonRPC: \(jsonrpc), id: \(id), method: \(method), params: \(params?.debugDescription ?? "nil")"
    }
    
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
    public func asRequest<T: Request>(_ requestType: T.Type) throws -> T {
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
