//
//  Initialize.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request sent from client to server when first connecting to begin initialization.
public struct InitializeRequest: Request {
    
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .initialize
    
    // MARK: Properties
    /// Initialize method identifier
    public let method: ClientRequest.Method
    
    /// Parameters for initialization
    public let params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    /// Parameters for the initialize request
    public struct Parameters: RequestParameters {
        /// Client's supported capabilities
        public let capabilities: ClientCapabilities
        
        /// Information about the client implementation
        public let clientInfo: Implementation
        
        /// Latest supported MCP version. Client may support older versions.
        public let protocolVersion: String
        
        public let _meta: RequestMetadata?
        
        public init(
            capabilities: ClientCapabilities,
            clientInfo: Implementation,
            protocolVersion: String,
            meta: RequestMetadata? = nil
        ) {
            self.capabilities = capabilities
            self.clientInfo = clientInfo
            self.protocolVersion = protocolVersion
            self._meta = meta
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
    
}

/// Server's response to client's initialize request
public struct InitializeResult: Result {
    /// Server's supported capabilities
    public let capabilities: ServerCapabilities
    
    /// Server's chosen protocol version. Client must disconnect if unsupported.
    public let protocolVersion: String
    
    /// Information about the server implementation
    public let serverInfo: Implementation
    
    /// Usage instructions for server features. May be used to enhance LLM understanding.
    public let instructions: String?
    
    public let _meta: ResultMetadata?
    
    public init(
        capabilities: ServerCapabilities,
        protocolVersion: String,
        serverInfo: Implementation,
        instructions: String? = nil,
        meta: ResultMetadata? = nil
    ) {
        self.capabilities = capabilities
        self.protocolVersion = protocolVersion
        self.serverInfo = serverInfo
        self.instructions = instructions
        self._meta = meta
    }
}
