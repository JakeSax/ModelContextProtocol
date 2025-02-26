//
//  Initialize.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request sent from client to server when first connecting to begin initialization.
///
/// The initialization request is the first message sent by the client after establishing
/// a transport connection. It informs the server about the client's capabilities,
/// identity, and supported protocol version. The server responds with its own
/// capabilities and confirms protocol compatibility.
///
/// This handshake establishes the shared understanding between client and server
/// about which features are supported by both sides.
public struct InitializeRequest: AnyClientRequest {
    
    // MARK: Static Properties
    /// The method identifier for initialization requests.
    public static let method: ClientRequest.Method = .initialize
    
    /// The expected response type for this request.
    public typealias Response = InitializeResult
    
    // MARK: Properties
    /// The method identifier for this request.
    ///
    /// Always set to `.initialize` to identify this as an initialization request.
    public let method: ClientRequest.Method
    
    /// The parameters for this initialization request.
    ///
    /// Contains information about the client's capabilities, implementation details,
    /// and supported protocol version.
    public let params: Parameters
    
    // MARK: Initialization
    /// Creates a new initialization request with the specified parameters.
    ///
    /// - Parameter params: The parameters describing the client's capabilities and identity.
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    /// Parameters for the initialize request.
    ///
    /// These parameters provide the server with all the information it needs to establish
    /// a compatible connection with the client, including the client's capabilities,
    /// identity, and supported protocol version.
    public struct Parameters: RequestParameters {
        /// The client's supported capabilities.
        ///
        /// Describes the features and extensions that this client implementation supports,
        /// allowing the server to adjust its behavior accordingly.
        public let capabilities: ClientCapabilities
        
        /// Information about the client implementation.
        ///
        /// Provides details about the client software, including its name, version,
        /// and potentially other identifying information.
        public let clientInfo: Implementation
        
        /// Latest MCP protocol version supported by the client.
        ///
        /// The client may also support older versions, but this field indicates the
        /// most recent version it can handle.
        public let protocolVersion: String
        
        /// Optional metadata associated with this request.
        ///
        /// Can be used to provide additional context or tracking information.
        public let _meta: RequestMetadata?
        
        /// Creates new initialization parameters with the specified values.
        ///
        /// - Parameters:
        ///   - capabilities: The client's supported capabilities.
        ///   - clientInfo: Information about the client implementation.
        ///   - protocolVersion: The latest MCP protocol version supported by the client.
        ///   - meta: Optional metadata for this request. Defaults to `nil`.
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
