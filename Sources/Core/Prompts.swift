//
//  Prompts.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// A prompt or prompt template that the server offers.
public struct Prompt: Codable, Sendable {
    /// The name of the prompt or prompt template.
    public let name: String
    
    /// An optional description of what this prompt provides
    public let description: String?
    
    /// A list of arguments to use for templating the prompt.
    public let arguments: [PromptArgument]?
    
    public init(name: String, description: String? = nil, arguments: [PromptArgument]? = nil) {
        self.name = name
        self.description = description
        self.arguments = arguments
    }
}

/// Describes a message returned as part of a prompt.
///
/// This is similar to `SamplingMessage`, but also supports the embedding of
/// resources from the MCP server.
public struct PromptMessage: Codable, Sendable {
    /// The content of the message, which can be text, image, or an embedded resource
    public let content: MessageContent
    
    /// The role associated with this message
    public let role: Role
    
    public init(content: MessageContent, role: Role) {
        self.content = content
        self.role = role
    }
}

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

/// Describes an argument that a prompt can accept.
public struct PromptArgument: Codable, Sendable {
    /// The name of the argument.
    public let name: String
    
    /// A human-readable description of the argument.
    public let description: String?
    
    /// Whether this argument must be provided.
    public let required: Bool?
    
    public init(name: String, description: String? = nil, required: Bool? = nil) {
        self.name = name
        self.description = description
        self.required = required
    }
}

/// An optional notification from the server to the client, informing it that the list of prompts
/// it offers has changed. This may be issued by servers without any previous subscription from the client.
public struct PromptListChangedNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .promptListChanged
    /// The method identifier for the notification
    public let method: ServerNotification.Method
    
    /// Additional parameters for the notification
    public let params: Parameters
    
    public init(params: Parameters = [:]) {
        self.method = Self.method
        self.params = params
    }
}
