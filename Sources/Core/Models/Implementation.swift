//
//  Implementation.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Describes the name and version of an MCP Ccient implementation.
public struct Implementation: Codable, Sendable, Equatable {
    /// The name of the client.
    public let name: String
    /// The version of the client
    public let version: String
    
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}
