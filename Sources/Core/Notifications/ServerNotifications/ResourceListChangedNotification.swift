//
//  ResourceListChangedNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// An optional notification from the server to the client, informing it that the list of resources
/// it can read from has changed. This may be issued by servers without any previous subscription
/// from the client.
public struct ResourceListChangedNotification: AnyServerNotification {
    
    public static let method: ServerNotification.Method = .resourceListChanged
    
    /// The method identifier for this notification.
    public let method: ServerNotification.Method
    
    public var params: DefaultNotificationParameters
    
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
