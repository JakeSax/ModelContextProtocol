//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Defines a structured prompt template for AI interactions.
public struct Prompt: Codable {
    public let name: String
    public let template: String
    public let variables: [String: String]?
}

/// Request to list available prompts.
public struct ListPromptsRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "prompts/list"
}

/// Response with available prompts.
public struct ListPromptsResult: Codable {
    public let prompts: [Prompt]
}

/// Request to retrieve a specific prompt.
public struct GetPromptRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "prompts/get"
    public let params: [String: String]
}

/// Response with the requested prompt.
public struct GetPromptResult: Codable {
    public let description: String?
    public let messages: [DynamicValue]
}

/// Notification that the prompt list has changed.
public struct PromptListChangedNotification: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/prompts/list_changed"
}

