//
//  SamplingMessage.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

/// Describes a message issued to or received from an LLM API.
public struct SamplingMessage: Codable, Sendable, Equatable {
    /// The content of the message, which can be either text or image.
    public let content: MessageContent
    
    /// The role of the message sender/recipient.
    public let role: Role
    
    public init(content: MessageContent, role: Role) {
        self.content = content
        self.role = role
    }
    
}
