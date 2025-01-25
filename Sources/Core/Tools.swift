//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Represents an executable tool available to the AI.
public struct Tool: Codable {
    public let name: String
    public let description: String
    public let parameters: [String: String]?
}

/// Request to list available tools.
public struct ListToolsRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "tools/list"
    public let params: [String: DynamicValue]?
}

/// Response with available tools.
public struct ListToolsResult: Codable {
    public let tools: [Tool]
}

/// Request to invoke a tool.
public struct CallToolRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "tools/call"
    public let params: [String: DynamicValue]
}

/// Response from a tool execution.
public struct CallToolResult: Codable {
    public let content: [DynamicValue]
    public let isError: Bool?
}

/// Notification that the tool list has changed.
public struct ToolListChangedNotification: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/tools/list_changed"
}
