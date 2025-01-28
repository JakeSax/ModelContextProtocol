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
        /// Properties/parameters specific to this tool.
        public let properties: [String: DynamicValue]?
        /// The String key values from `.properties` that are required to use this tool
        public let required: [String]?
        
        public init(properties: [String: DynamicValue]?, required: [String]? = nil) {
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
    public let params: DefaultNotificationParameters
    
    public init(params: DefaultNotificationParameters = .init()) {
        self.method = Self.method
        self.params = params
    }
}
