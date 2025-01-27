//
//  ListRoots.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/**
 * Sent from the server to request a list of root URIs from the client. Roots allow
 * servers to ask for specific directories or files to operate on. A common example
 * for roots is providing a set of repositories or directories a server should operate
 * on.
 *
 * This request is typically used when the server needs to understand the file system
 * structure or access specific locations that the client has permission to read from.
 */
public struct ListRootsRequest: Request {
    public static let method: ServerRequest.Method = .listRoots
    
    /// The method identifier for the roots/list request
    public let method: ServerRequest.Method
    
    /// Optional parameters for the request
    public let params: DefaultRequestParameters
    
    public init(params: DefaultRequestParameters = .init()) {
        self.method = Self.method
        self.params = params
    }
}

/**
 * The client's response to a roots/list request from the server.
 * This result contains an array of Root objects, each representing a root directory
 * or file that the server can operate on.
 */
public struct ListRootsResult: Codable, Sendable {
    /// Additional metadata attached to the response
    public let meta: OldParameters?
    
    /// Array of root objects representing accessible directories/files
    public let roots: [Root]
    
    public init(roots: [Root], meta: OldParameters? = nil) {
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
    public let params: OldParameters?
    
    public init(params: OldParameters? = nil) {
        self.method = Self.method
        self.params = params
    }
}
