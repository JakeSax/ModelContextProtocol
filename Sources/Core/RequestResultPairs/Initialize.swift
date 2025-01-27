//
//  Initialize.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request sent from client to server when first connecting to begin initialization.
public struct InitializeRequest: Codable, Sendable {
    /// Initialize method identifier
    public let method: ClientRequest.Method
    
    /// Parameters for initialization
    public let params: Parameters
    
    /// Parameters for the initialize request
    public struct Parameters: Codable, Sendable {
        /// Client's supported capabilities
        public let capabilities: ClientCapabilities
        
        /// Information about the client implementation
        public let clientInfo: Implementation
        
        /// Latest supported MCP version. Client may support older versions.
        public let protocolVersion: String
        
        public init(
            capabilities: ClientCapabilities,
            clientInfo: Implementation,
            protocolVersion: String
        ) {
            self.capabilities = capabilities
            self.clientInfo = clientInfo
            self.protocolVersion = protocolVersion
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .initialize
    }
}

/// Server's response to client's initialize request
public struct InitializeResult: Codable, Sendable {
    /// Server's supported capabilities
    public let capabilities: ServerCapabilities
    
    /// Server's chosen protocol version. Client must disconnect if unsupported.
    public let protocolVersion: String
    
    /// Information about the server implementation
    public let serverInfo: Implementation
    
    /// Usage instructions for server features. May be used to enhance LLM understanding.
    public let instructions: String?
    
    /// Additional metadata attached to the response
    public let metadata: DynamicValue?
    
    public init(
        capabilities: ServerCapabilities,
        protocolVersion: String,
        serverInfo: Implementation,
        instructions: String? = nil,
        metadata: DynamicValue? = nil
    ) {
        self.capabilities = capabilities
        self.protocolVersion = protocolVersion
        self.serverInfo = serverInfo
        self.instructions = instructions
        self.metadata = metadata
    }
}
