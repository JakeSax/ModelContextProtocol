//
//  PromptReference.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Identifies a prompt.
public struct PromptReference: Codable, Sendable {
    /// The name of the prompt or prompt template
    public let name: String
    
    /// The type identifier for the prompt reference
    public let type: ReferenceTypeIdentifier
    
    public init(name: String) {
        self.name = name
        self.type = .prompt
    }
}
