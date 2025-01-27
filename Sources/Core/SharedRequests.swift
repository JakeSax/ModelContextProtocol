//
//  SharedRequests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A ping, issued by either the server or the client, to check that the other party is still alive.
/// The receiver must promptly respond, or else may be disconnected.
public struct PingRequest: AnyServerRequest, SupportsProgressToken {
    public static let method: ServerRequest.Method = .ping
    public let method: ServerRequest.Method
    public let params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.params = params
        self.method = Self.method
    }
    
}

/// Base request type for MCP protocol
public struct Request: Codable, Sendable, SupportsProgressToken {
    /// The method identifier for the request
    public let method: String
    
    /// The parameters for the request
    public let params: Parameters?
    
    public init(method: String, params: Parameters?) {
        self.method = method
        self.params = params
    }
}
