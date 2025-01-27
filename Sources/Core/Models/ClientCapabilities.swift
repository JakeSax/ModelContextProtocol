//
//  ClientCapabilities.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
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
