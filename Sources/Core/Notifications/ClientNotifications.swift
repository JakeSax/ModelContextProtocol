//
//  ClientNotifications.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

/// A Notification identified by a ``ClientNotification.Method`` in its `method` property.
public protocol AnyClientNotification: Notification where MethodIdentifier == ClientNotification.Method {}

/// Represents all possible client notifications
public enum ClientNotification: Codable, Sendable {
    
    case cancelled(CancelledNotification)
    case initialized(InitializedNotification)
    case progress(ProgressNotification)
    case rootsListChanged(RootsListChangedNotification)
    
    // MARK: Data Structures
    public enum Method: String, AnyMethodIdentifier {
        case cancelled = "notifications/cancelled"
        case progress = "notifications/progress"
        case initialized = "notifications/initialized"
        case rootsListChanged = "notifications/roots/list_changed"
    }
    
    // MARK: Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case method
    }
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .cancelled(let cancelledNotification):
            try cancelledNotification.encode(to: encoder)
        case .initialized(let initializedNotification):
            try initializedNotification.encode(to: encoder)
        case .progress(let progressNotification):
            try progressNotification.encode(to: encoder)
        case .rootsListChanged(let rootsListChangedNotification):
            try rootsListChangedNotification.encode(to: encoder)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(ClientNotification.Method.self, forKey: .method)
        
        switch method {
        case .cancelled: self = .cancelled(try CancelledNotification(from: decoder))
        case .initialized: self = .initialized(try InitializedNotification(from: decoder))
        case .progress: self = .progress(try ProgressNotification(from: decoder))
        case .rootsListChanged: self = .rootsListChanged(try RootsListChangedNotification(from: decoder))
        }
    }
    
}

/// Notification sent after initialization is complete
public struct InitializedNotification: AnyClientNotification {
    public static let method: ClientNotification.Method = .initialized
    public let method: ClientNotification.Method
    public let params: DefaultNotificationParameters
    
    public init(params: DefaultNotificationParameters = .init()) {
        self.method = Self.method
        self.params = params
    }
}
