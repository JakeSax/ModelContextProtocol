//
//  ListRoots.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to list root URIs from the client, allowing servers to access specific directories or files.
public struct ListRootsRequest: AnyServerRequest {
    public static let method: ServerRequest.Method = .listRoots
    
    /// The method identifier for the roots/list request
    public let method: ServerRequest.Method
    
    /// Optional parameters for the request
    public let params: Parameters
    
    public init(params: Parameters = [:]) {
        self.method = Self.method
        self.params = params
    }
}

/// The response containing available root directories or files
public struct ListRootsResult: Codable, Sendable {
    /// Additional metadata attached to the response
    public let meta: Parameters?
    
    /// Array of root objects representing accessible directories/files
    public let roots: [Root]
    
    public init(roots: [Root], meta: Parameters? = nil) {
        self.roots = roots
        self.meta = meta
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
