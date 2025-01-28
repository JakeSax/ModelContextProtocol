//
//  Implementation.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Describes the name and version of an MCP implementation.
public struct Implementation: Codable, Sendable {
    public let name: String
    public let version: String
    
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

