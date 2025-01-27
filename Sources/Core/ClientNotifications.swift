//
//  ClientNotifications.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation

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

/// This notification can be sent by either side to indicate that it is cancelling a
/// previously-issued request.
///
/// The request SHOULD still be in-flight, but due to communication latency, it
/// is always possible that this notification MAY arrive after the request has
/// already finished.
///
/// This notification indicates that the result will be unused, so any associated
/// processing SHOULD cease.
///
/// A client MUST NOT attempt to cancel its `initialize` request.
public struct CancelledNotification: MethodIdentified {
    public static let method = ClientNotification.Method.cancelled
    public let method: ClientNotification.Method
    public let params: Parameters
    
    public struct Parameters: Codable, Sendable {
        /// The ID of the request to cancel.
        ///
        /// This MUST correspond to the ID of a request previously issued
        /// in the same direction.
        public let requestId: RequestID
        /// An optional string describing the reason for the cancellation. This
        /// MAY be logged or presented to the user.
        public let reason: String?
        
        public init(requestID: RequestID, reason: String? = nil) {
            self.requestId = requestID
            self.reason = reason
        }
    }
    
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
}

/// Notification sent after initialization is complete
public struct InitializedNotification: MethodIdentified {
    public static let method: ClientNotification.Method = .initialized
    public let method: ClientNotification.Method
    public let params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.method = Self.method
        self.params = params
    }
}

/// An out-of-band notification used to inform the receiver of a progress update for a long-running request.
public struct ProgressNotification: MethodIdentified {
    public static let method = ClientNotification.Method.progress
    public let method: ClientNotification.Method
    public let params: Params
    
    public struct Params: Codable, Sendable {
        /// The progress thus far. This should increase every time progress is made, even if the total is unknown.
        public let progress: Double
        /// The progress token which was given in the initial request, used to associate this notification
        /// with the request that is proceeding.
        public let progressToken: ProgressToken
        /// Total number of items to process (or total progress required), if known.
        public let total: Double?
        
        private enum CodingKeys: String, CodingKey {
            case progress, progressToken, total
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case method, params
    }
    
    public init(params: Params) {
        self.method = Self.method
        self.params = params
    }
}

/// A notification from the client to the server, informing it that the list of roots has changed.
/// This notification should be sent whenever the client adds, removes, or modifies any root.
/// The server should then request an updated list of roots using the ``ListRootsRequest``.
public struct RootsListChangedNotification: MethodIdentified {
    public static let method: ClientNotification.Method = .rootsListChanged
    /// The method identifier for this notification.
    public let method: ClientNotification.Method
    public let params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.method = Self.method
        self.params = params
    }
}
