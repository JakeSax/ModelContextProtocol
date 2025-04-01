//
//  ClientCapabilities.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Represents the set of capabilities supported by an MCP client implementation.
///
/// Client capabilities communicate to the server what optional features the client
/// can understand and support. These capabilities influence how the server interacts
/// with the client and what features it may expose.
public struct ClientCapabilities: Codable, Sendable, Equatable {
  
    // MARK: Properties
    /// Configuration for filesystem "root" listing capabilities.
    ///
    /// When non-nil, indicates that the client supports listing filesystem "roots" and
    /// whether the client will emit notifications when that list changes.
    public let roots: RootsSupport?
    
    /// Whether the client supports filesystem "root" listing .
    public var supportsRootListing: Bool { roots != nil }
    
    /// Sampling capabilities configuration.
    ///
    /// When non-nil, indicates that the client supports sampling operations.
    /// The specific value contains any sampling-related configuration details.
    public let sampling: DynamicValue?
    
    /// Whether the client supports sampling operations.
    public var supportsSampling: Bool { sampling != nil }
    
    /// Experimental or non-standard capabilities.
    ///
    /// A dictionary of capability identifiers to their configuration values.
    /// These represent capabilities that may not be part of the standard MCP
    /// specification or are in an experimental state.
    public let experimental: [String: DynamicValue]?
    
    /// Whether the client supports experimental capabilities.
    public var supportsExperimentalCapabilities: Bool { experimental?.isEmpty == false }
    
    // MARK: Initialization
    /// Creates a new set of client capabilities.
    ///
    /// - Parameters:
    ///   - roots: Configuration for filesystem "root" listing support. When nil, the client
    ///     does not support root listing operations.
    ///   - supportsSampling: Whether the client supports sampling operations.
    ///     When true, the `sampling` property will be set to an empty dictionary value.
    ///   - experimental: A dictionary of experimental or non-standard capabilities
    ///     supported by the client.
    public init(
        roots: RootsSupport? = nil,
        supportsSampling: Bool = false,
        experimental: [String: DynamicValue]? = nil
    ) {
        self.roots = roots
        self.sampling = supportsSampling ? [:] : nil
        self.experimental = experimental
    }
    
    // MARK: Data Structures
    /// Configuration for the client's filesystem “root” listing support.
    ///
    /// > The Model Context Protocol (MCP) provides a standardized way for clients to expose
    /// filesystem “roots” to servers. Roots define the boundaries of where servers can operate
    /// within the filesystem, allowing them to understand which directories and files they have
    /// access to. Servers can request the list of roots from supporting clients and receive
    /// notifications when that list changes.
    public struct RootsSupport: Codable, Sendable, Equatable {
        /// Indicates whether the client will emit notifications when the list of roots changes.
        public let listChanged: Bool
        
        /// Creates a new filesystem "roots" support configuration.
        ///
        /// - Parameter listChanged: Indicates whether the client will emit notifications
        /// when the list of roots changes.
        public init(listChanged: Bool) {
            self.listChanged = listChanged
        }
    }
    
}
