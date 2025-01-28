//
//  PromptMessage.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Describes a message returned as part of a prompt.
///
/// This is similar to `SamplingMessage`, but also supports the embedding of
/// resources from the MCP server.
public struct PromptMessage: Codable, Sendable {
    
    /// The role associated with this message
    public let role: Role
    
    /// The content of the message, which can be text, image, or an embedded resource
    public let content: MessageContent
    
    public init(role: Role, content: MessageContent) {
        self.role = role
        self.content = content
    }
}
