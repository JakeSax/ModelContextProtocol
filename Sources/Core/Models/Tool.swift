//
//  Tool.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

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
