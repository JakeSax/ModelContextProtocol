//
//  Notification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Base Notification requirements for MCP protocol.
public protocol Notification<MethodIdentifier>: MethodIdentified, Equatable {
    
    /// The parameters that may be included with a notification.
    associatedtype Parameters: NotificationParameters
    
    /// The parameters for the notification.
    var params: Parameters { get }
    
    /// Creates a Notification with the given parameters.
    init(params: Parameters)
}

public protocol NotificationParameters: Codable, Sendable, Equatable {
    /// This property is reserved by MCP to allow clients and servers to attach
    /// additional metadata to their messages.
    var _meta: NotificationMetadata? { get }
}

public typealias NotificationMetadata = [String: DynamicValue]

public typealias DefaultNotificationParameters = [String: DynamicValue]

extension DefaultNotificationParameters: NotificationParameters {
    public var _meta: NotificationMetadata? {
        self["_meta"]?.dictionaryValue
    }
}
