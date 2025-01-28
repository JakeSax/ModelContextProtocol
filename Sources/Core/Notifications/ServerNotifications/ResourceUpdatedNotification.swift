//
//  ResourceUpdatedNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A notification from the server to the client, informing it that a resource has changed
/// and may need to be read again. This should only be sent if the client previously sent
/// a resources/subscribe request.
public struct ResourceUpdatedNotification: AnyServerNotification {
    
    // MARK: Static Properties
    public static let method: ServerNotification.Method = .resourceUpdated
    
    // MARK: Properties
    /// The method identifier for this notification.
    public let method: ServerNotification.Method
    
    public var params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    /// Parameters for the resource update notification.
    public struct Parameters: NotificationParameters {
        /// The URI of the resource that has been updated.
        /// This might be a sub-resource of the one that the client actually subscribed to.
        public var uri: String
        
        public let _meta: NotificationMetadata?
        
        public init(uri: String, meta: NotificationMetadata? = nil) {
            self.uri = uri
            self._meta = meta
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
    
}
