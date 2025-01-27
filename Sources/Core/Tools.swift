//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// Definition for a tool the client can call
public struct Tool: Codable, Sendable {
    /// The name of the tool
    public let name: String
    
    /// A human-readable description of the tool
    public let description: String?
    
    /// JSON Schema defining the expected parameters
    public let inputSchema: ToolInputSchema
    
    public init(name: String, description: String? = nil, inputSchema: ToolInputSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
    
    /// Defines expected parameters for a tool using JSON Schema
    public struct ToolInputSchema: Codable, Sendable {
        public let type: String
        public let properties: Parameters
        public let required: [String]?
        
        public init(properties: Parameters, required: [String]? = nil) {
            self.type = "object"
            self.properties = properties
            self.required = required
        }
    }

}

/// Server notification indicating the tool list has changed
public struct ToolListChangedNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .toolListChanged
    public let method: ServerNotification.Method
    public let params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.method = .toolListChanged
        self.params = params
    }
}

/// Request to invoke a tool provided by the server
public struct CallToolRequest: Codable, Sendable {
    /// The method identifier for tool calls
    public let method: ClientRequest.Method
    
    /// Parameters for the tool call
    public let params: Parameters
    
    public struct Parameters: Codable, Sendable {
        /// Name of the tool to call
        public let name: String
        
        /// Arguments to pass to the tool
        public let arguments: [String: DynamicValue]?
        
        public init(name: String, arguments: [String: DynamicValue]? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .callTool
    }
}

/// Response from a tool call
public struct CallToolResult: Codable {
    /// Additional metadata attached to the response
    public let meta: [String: DynamicValue]?
    
    /// Content returned by the tool
    public let content: [MessageContent]
    
    /// Whether the tool call ended in an error
    public let isError: Bool?
    
    public init(
        meta: [String: DynamicValue]? = nil,
        content: [MessageContent],
        isError: Bool? = nil
    ) {
        self.meta = meta
        self.content = content
        self.isError = isError
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "_meta"
        case content
        case isError
    }
}
