//
//  RootsListChangedNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A notification from the client to the server, informing it that the list of roots has changed.
/// This notification should be sent whenever the client adds, removes, or modifies any root.
/// The server should then request an updated list of roots using the ``ListRootsRequest``.
public struct RootsListChangedNotification: AnyClientNotification {
    public static let method: ClientNotification.Method = .rootsListChanged
    /// The method identifier for this notification.
    public let method: ClientNotification.Method
    public let params: DefaultNotificationParameters
    
    public init(params: DefaultNotificationParameters = .init()) {
        self.method = Self.method
        self.params = params
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
}
