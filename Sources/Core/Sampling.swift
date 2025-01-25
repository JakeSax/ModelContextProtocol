//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Controls AI sampling behavior within MCP workflows.
public struct SamplingControl: Codable {
    public let enabled: Bool
    public let maxDepth: Int?
}

/// Request to generate an LLM response.
public struct CreateMessageRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "sampling/createMessage"
    public let params: CreateMessageParams
}

/// Parameters for an LLM sampling request.
public struct CreateMessageParams: Codable {
    public let messages: [SamplingMessage]
    public let modelPreferences: ModelPreferences?
    public let systemPrompt: String?
    public let includeContext: String?
    public let temperature: Double?
    public let maxTokens: Int
    public let stopSequences: [String]?
    public let metadata: [String: DynamicValue]?
}

/// Response with the generated LLM message.
public struct CreateMessageResult: Codable {
    public let model: String
    public let stopReason: String?
    public let role: Role
    public let content: DynamicValue
}

/// Represents a message in an AI conversation.
public struct SamplingMessage: Codable {
    public let role: Role
    public let content: DynamicValue
}

/// Defines role types (e.g., user, assistant).
public enum Role: String, Codable {
    case user
    case assistant
}

/// Model selection preferences.
public struct ModelPreferences: Codable {
    public let hints: [ModelHint]?
    public let costPriority: Double?
    public let speedPriority: Double?
    public let intelligencePriority: Double?
}

/// Hints for selecting an LLM model.
public struct ModelHint: Codable {
    public let name: String?
}
