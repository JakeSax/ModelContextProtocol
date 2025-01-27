//
//  ServerCapabilities.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Capabilities that a server may support.
public struct ServerCapabilities: Codable, Sendable {
    /// Experimental, non-standard capabilities that the server supports.
    public var experimental: [String: Parameters]?
    
    /// Present if the server supports sending log messages to the client.
    public var logging: Parameters?
    
    /// Present if the server offers any prompt templates.
    public var prompts: PromptCapabilities?
    
    /// Present if the server offers any resources to read.
    public var resources: ResourceCapabilities?
    
    /// Present if the server offers any tools to call.
    public var tools: ToolCapabilities?
    
    
    /// Capabilities related to prompts
    public struct PromptCapabilities: Codable, Sendable {
        /// Whether this server supports notifications for changes to the prompt list.
        public var listChanged: Bool?
    }
    
    /// Capabilities related to resources
    public struct ResourceCapabilities: Codable, Sendable {
        /// Whether this server supports notifications for changes to the resource list.
        public var listChanged: Bool?
        
        /// Whether this server supports subscribing to resource updates.
        public var subscribe: Bool?
    }
    
    /// Capabilities related to tools
    public struct ToolCapabilities: Codable, Sendable {
        /// Whether this server supports notifications for changes to the tool list.
        public var listChanged: Bool?
    }
    
}
