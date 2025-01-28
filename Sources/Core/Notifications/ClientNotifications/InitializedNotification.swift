//
//  InitializedNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Notification sent after initialization is complete
public struct InitializedNotification: AnyClientNotification {
    public static let method: ClientNotification.Method = .initialized
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
