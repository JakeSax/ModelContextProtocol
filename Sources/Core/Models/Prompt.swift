//
//  Prompt.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A prompt or prompt template that the server offers.
public struct Prompt: Codable, Sendable {
    
    // MARK: Properties
    /// The name of the prompt or prompt template.
    public let name: String
    
    /// An optional description of what this prompt provides
    public let description: String?
    
    /// A list of arguments to use for templating the prompt.
    public let arguments: [Argument]?
    
    // MARK: Initialization
    public init(name: String, description: String? = nil, arguments: [Argument]? = nil) {
        self.name = name
        self.description = description
        self.arguments = arguments
    }
    
    // MARK: Data Structures
    /// Describes an argument that a prompt can accept.
    public struct Argument: Codable, Sendable {
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
    
}
