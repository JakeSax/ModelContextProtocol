//
//  Roots.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

/// Client capabilities supported by the implementation
public struct ClientCapabilities: Codable, Sendable {
    /// Root listing support configuration
    public struct RootsSupport: Codable, Sendable {
        /// Whether client supports root list change notifications
        public let listChanged: Bool
        
        public init(listChanged: Bool) {
            self.listChanged = listChanged
        }
    }
    
    /// Root listing capabilities
    public let roots: RootsSupport?
    /// Sampling capabilities
    public let sampling: DynamicValue?
    /// Experimental capabilities
    public let experimental: [String: DynamicValue]?
    
    public init(
        roots: RootsSupport? = nil,
        sampling: DynamicValue? = nil,
        experimental: [String: DynamicValue]? = nil
    ) {
        self.roots = roots
        self.sampling = sampling
        self.experimental = experimental
    }
}

/// A request to list root URIs from the client, allowing servers to access specific directories or files.
public struct ListRootsRequest: AnyServerRequest {
    /// The method identifier for the roots/list request
    public let method: ServerRequestMethod
    
    /// Optional parameters for the request
    public let params: Parameters
    
    public init(params: Parameters = [:]) {
        self.method = .listRoots
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

/// Represents a root directory or file that the server can operate on.
public struct Root: Codable, Sendable {
    /// An optional name for the root. This can be used to provide a human-readable
    /// identifier for the root, which may be useful for display purposes or for
    /// referencing the root in other parts of the application.
    public var name: String?
    
    /// The URI identifying the root. This must start with file:// for now.
    /// This restriction may be relaxed in future versions of the protocol to allow
    /// other URI schemes.
    public var uri: String
    
    public init(name: String? = nil, uri: String) {
        self.name = name
        self.uri = uri
    }
}
