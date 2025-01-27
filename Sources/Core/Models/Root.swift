//
//  Root.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

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
