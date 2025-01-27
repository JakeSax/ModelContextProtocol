//
//  Notification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Base Notification type for MCP protocol.
public protocol Notification<MethodIdentifier>: Codable, Sendable {
    
    /// The type of identifier for the method.
    associatedtype MethodIdentifier: AnyMethodIdentifier
    
    /// The method identifier for the request.
    var method: MethodIdentifier { get }
    
    /// The parameters for the request.
    var params: OldParameters? { get }
}
