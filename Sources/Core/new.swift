//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/25/25.
//

import Foundation


/// Represents possible client result types.
public enum ClientResult: Codable, Sendable {
    case result(Result)
    case createMessage(CreateMessageResult)
    case listRoots(ListRootsResult)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let createMessage = try? container.decode(CreateMessageResult.self) {
            self = .createMessage(createMessage)
        } else if let listRoots = try? container.decode(ListRootsResult.self) {
            self = .listRoots(listRoots)
        } else if let result = try? container.decode(Result.self) {
            self = .result(result)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid client result type"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .result(let result):
            try container.encode(result)
        case .createMessage(let createMessage):
            try container.encode(createMessage)
        case .listRoots(let listRoots):
            try container.encode(listRoots)
        }
    }
}

/// A request from the client to the server, to ask for completion options.
public struct CompleteRequest: Codable, Sendable {
    /// The method identifier for completion requests
    public let method: ClientRequest.Method
    
    /// The parameters for the completion request
    public let params: Params
    
    init(params: Params) {
        self.params = params
        self.method = .complete
    }
    
    /// Parameters for a completion request
    public struct Params: Codable, Sendable {
        /// The argument's information
        public let argument: Argument
        /// Reference to either a prompt or resource
        public let ref: Reference
        
        /// Information about an argument
        public struct Argument: Codable, Sendable {
            /// The name of the argument
            public let name: String
            /// The value of the argument to use for completion matching
            public let value: String
        }
    }
    
    public enum Reference: Codable, Sendable {
        case prompt(PromptReference)
        case resource(ResourceReference)
        
        private enum CodingKeys: String, CodingKey {
            case type
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ReferenceTypeIdentifier.self, forKey: .type)
            switch type {
            case .prompt: self =  .prompt(try PromptReference(from: decoder))
            case .resource: self = .resource(try ResourceReference(from: decoder))
            }
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .prompt(let promptReference):
                try container.encode(promptReference)
            case .resource(let resourceReference):
                try container.encode(resourceReference)
            }
        }
    }
}

public enum ReferenceTypeIdentifier: String, AnyMethodIdentifier {
    case prompt = "ref/prompt"
    case resource = "ref/resource"
}

/// The server's response to a completion/complete request
public struct CompleteResult: Codable, Sendable {
    /// Metadata attached to the response
    public let meta: DynamicValue?
    /// The completion results
    public let completion: Completion
    
    /// Completion results structure
    public struct Completion: Codable, Sendable {
        /// An array of completion values. Must not exceed 100 items.
        public let values: [String]
        /// Indicates whether there are additional completion options beyond those provided
        public let hasMore: Bool?
        /// The total number of completion options available
        public let total: Int?
    }
}


/// A request from the server to sample an LLM via the client. The client has full
/// discretion over which model to select. The client should also inform the user
/// before beginning sampling, to allow them to inspect the request (human in
/// the loop) and decide whether to approve it.
public struct CreateMessageRequest: Codable, Sendable {
    public let method: ServerRequestMethod
    public let params: MessageParameters
    
    init(params: MessageParameters) {
        self.method = .createMessage
        self.params = params
    }
    
    public struct MessageParameters: Codable, Sendable {
        /// Maximum tokens to sample. Client may sample fewer.
        public let maxTokens: Int
        
        /// Messages to include in the sampling request
        public let messages: [SamplingMessage]
        
        /// Request to include context from MCP servers
        public var includeContext: ContextInclusion?
        
        /// Provider-specific metadata to pass through
        public var metadata: Parameters?
        
        /// Server's model preferences (client may ignore)
        public var modelPreferences: ModelPreferences?
        
        /// Sequences that will stop sampling when encountered
        public var stopSequences: [String]?
        
        /// Optional system prompt (client may modify/omit)
        public var systemPrompt: String?
        
        /// Temperature for sampling
        public var temperature: Double?
    }
    
    /// Available context inclusion options for message creation
    public enum ContextInclusion: String, Codable, Sendable {
        case allServers
        case none
        case thisServer
    }
}

/// The client's response to a sampling/create_message request from the server.
public struct CreateMessageResult: Codable, Sendable {
    /// Additional metadata attached to the response.
    public let meta: Parameters?
    
    /// The content of the generated message.
    public let content: MessageContent
    
    /// The name of the model that generated the message.
    public let model: String
    
    /// The role of the message sender.
    public let role: Role
    
    /// The reason why sampling stopped, if known.
    public let stopReason: String?
    
    public init(
        content: MessageContent,
        model: String,
        role: Role,
        stopReason: String? = nil,
        meta: [String: DynamicValue]? = nil
    ) {
        self.content = content
        self.model = model
        self.role = role
        self.stopReason = stopReason
        self.meta = meta
    }
}


/// Cursor type for pagination
public typealias Cursor = String

/// Empty result type
public typealias EmptyResult = Result

/// Request to get a prompt from the server
public struct GetPromptRequest: Codable, Sendable {
    public let method: ClientRequest.Method
    public let params: Parameters
    
    public struct Parameters: Codable, Sendable {
        public let name: String
        public let arguments: [String: String]?
        
        public init(name: String, arguments: [String: String]? = nil) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(params: Parameters) {
        self.params = params
        self.method = .getPrompt
    }
}

/// The server's response to a `prompts/get` request from the client.
public struct GetPromptResult: Codable, Sendable {
    /// An optional description for the prompt.
    public let messages: [PromptMessage]
    public let description: String?
    public let meta: Parameters?
    
    public init(
        meta: [String: DynamicValue]? = nil,
        messages: [PromptMessage],
        description: String? = nil
    ) {
        self.meta = meta
        self.messages = messages
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "_meta"
        case messages
        case description
    }
}

/// Describes the name and version of an MCP implementation.
public struct Implementation: Codable, Sendable {
    public let name: String
    public let version: String
    
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

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
    
    public init(capabilities: ServerCapabilities,
                protocolVersion: String,
                serverInfo: Implementation,
                instructions: String? = nil,
                metadata: DynamicValue? = nil) {
        self.capabilities = capabilities
        self.protocolVersion = protocolVersion
        self.serverInfo = serverInfo
        self.instructions = instructions
        self.metadata = metadata
    }
}



public protocol JSONRPCMessage: Codable, Sendable {
    /// The version of JSON-RPC being used, defaults to "2.0"
    var jsonrpc: String { get }
}

extension JSONRPCMessage {
    public var jsonrpc: String { JSONRPC.jsonrpcVersion }
}

/// JSONRPC message types
///

//public enum JSONRPCMessage: Codable {
//    case request(JSONRPCRequest)
//    case notification(JSONRPCNotification)
//    case response(JSONRPCResponse)
//    case error(JSONRPCError)
//}

/// Indicates that this object may have a ``ProgressToken`` specified amongst its parameters.
public protocol SupportsProgressToken {
    var params: Parameters? { get }
}

extension SupportsProgressToken {
    /// If specified, the caller is requesting out-of-band progress notifications for this
    /// request (as represented by `notifications/progress`). The value of this
    /// parameter is an opaque token that will be attached to any subsequent notifications.
    /// The receiver is not obligated to provide these notifications.
    public var progressToken: ProgressToken? {
        params?["progressToken"] as? ProgressToken
    }
}

/// A request that expects a response.
public struct JSONRPCRequest: JSONRPCMessage, SupportsProgressToken {
    public let id: String
    public let method: String
    public let params: Parameters?
}

public typealias Parameters = [String: DynamicValue]

extension Parameters {
    /// This parameter name is reserved by MCP to allow clients and servers to attach
    /// additional metadata to their notifications.
    public var metadata: DynamicValue? { self["_meta"] }
}


/// A notification which does not expect a response.
public struct JSONRPCNotification: JSONRPCMessage {
    public let method: String
    public let params: Parameters
}

/// JSONRPC 2.0 response
//public struct JSONRPCResponse: JSONRPCMessage {
//    public let id: String
//    public let result: Result
//}

/// A response to a request that indicates an error occurred.
public struct JSONRPCError: JSONRPCMessage {
    public let id: RequestID
    public let error: ErrorDetails
    
    public struct ErrorDetails: Codable ,Sendable {
        /// The error type that occurred.
        public let code: Int
        
        /// A short description of the error. The message SHOULD be limited to a concise
        /// single sentence.
        public let message: String
        
        /// Additional information about the error. The value of this member is defined
        /// by the sender (e.g. detailed error information, nested errors etc.).
        public let data: DynamicValue?
    }
}


/// A request to retrieve available prompts and prompt templates from the server.
public struct ListPromptsRequest: Codable, Sendable {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: Params?
    
    /// Parameters for configuring the prompts list request.
    public struct Params: Codable, Sendable {
        /// An opaque token representing the current pagination position.
        /// If provided, the server will return results starting after this cursor.
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
    
    public init(params: Params? = nil) {
        self.params = params
        self.method = .listPrompts
    }
}

/// The server's response to a prompts/list request.
public struct ListPromptsResult: Codable, Sendable {
    /// Reserved metadata field for additional response information.
    public let _meta: [String: DynamicValue]?
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: String?
    
    /// The list of returned prompts.
    public let prompts: [Prompt]
    
    public init(_meta: [String: DynamicValue]? = nil, nextCursor: String? = nil, prompts: [Prompt]) {
        self._meta = _meta
        self.nextCursor = nextCursor
        self.prompts = prompts
    }
}



// MARK: - List Roots

/// A request to list available tools from the server
public struct ListToolsRequest: Codable, Sendable {
    /// The method identifier for the tools/list request
    public let method: ClientRequest.Method
    
    public let params: Params
    
    /// Parameters for pagination and filtering
    public struct Params: Codable, Sendable {
        /// Opaque token for pagination position
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
    
    public init(params: Params = Params()) {
        self.params = params
        self.method = .listTools
    }
}

/// The response containing available tools from the server
public struct ListToolsResult: Codable, Sendable {
    /// Additional metadata attached to the response
    public let _meta: DynamicValue?
    
    /// Token for accessing the next page of results
    public let nextCursor: String?
    
    /// Array of available tools
    public let tools: [Tool]
    
    public init(tools: [Tool], nextCursor: String? = nil, _meta: DynamicValue? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
        self._meta = _meta
    }
}


/// Hints to use for model selection.
public struct ModelHint: Codable, Sendable {
    /// A hint for a model name.
    ///
    /// The client should treat this as a substring of a model name. For example:
    /// - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
    /// - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
    /// - `claude` should match any Claude model
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

/// The server's preferences for model selection during sampling.
///
/// Because LLMs can vary along multiple dimensions, choosing the "best" model is
/// rarely straightforward. Different models excel in different areas—some are
/// faster but less capable, others are more capable but more expensive.
public struct ModelPreferences: Codable, Sendable {
    /// How much to prioritize cost (0 = not important, 1 = most important)
    public let costPriority: Double
    
    /// How much to prioritize intelligence and capabilities (0 = not important, 1 = most important)
    public let intelligencePriority: Double
    
    /// How much to prioritize sampling speed/latency (0 = not important, 1 = most important)
    public let speedPriority: Double
    
    /// Optional ordered hints for model selection
    public let hints: [ModelHint]?
    
    public init(
        costPriority: Double,
        intelligencePriority: Double,
        speedPriority: Double,
        hints: [ModelHint]? = nil
    ) {
        precondition((0...1).contains(costPriority), "costPriority must be between 0 and 1")
        precondition((0...1).contains(intelligencePriority), "intelligencePriority must be between 0 and 1")
        precondition((0...1).contains(speedPriority), "speedPriority must be between 0 and 1")
        
        self.costPriority = costPriority
        self.intelligencePriority = intelligencePriority
        self.speedPriority = speedPriority
        self.hints = hints
    }
}

/// Represents a notification message in the MCP protocol
public struct Notification: Codable, Sendable {
    /// The notification method name
    public let method: String
    
    /// Optional parameters for the notification
    public let params: Parameters?
    
    public init(method: String, params: Parameters? = nil) {
        self.method = method
        self.params = params
    }
}


/// A paginated request implementation
public struct PaginatedRequest: Codable, Sendable {
    /// The request method name
    public let method: String
    /// Optional pagination parameters
    public let params: PaginationParams?
    
    public init(method: String, params: PaginationParams? = nil) {
        self.method = method
        self.params = params
    }
    
    /// Parameters for paginated requests
    public struct PaginationParams: Codable, Sendable {
        /// An opaque token representing the current pagination position
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
}


/// A paginated result implementation
public struct PaginatedResult: Codable, Sendable {
    /// Next page cursor token, if more results exist
    public let nextCursor: String?
    
    /// Optional metadata for the result
    public var _meta: DynamicValue?
    
    public init(nextCursor: String? = nil, meta: DynamicValue? = nil) {
        self.nextCursor = nextCursor
        self._meta = meta
    }
}

/// A ping, issued by either the server or the client, to check that the other party is still alive.
/// The receiver must promptly respond, or else may be disconnected.
public struct PingRequest: AnyServerRequest, SupportsProgressToken {
    public let method: ServerRequestMethod
    public let params: Parameters?
    
    public init(params: Parameters? = nil) {
        self.params = params
        self.method = .ping
    }
    
}

/// A request to read a specific resource URI.
public struct ReadResourceRequest: Codable, Sendable {
    /// The method identifier for the request
    public let method: ClientRequest.Method
    
    /// The parameters for the request
    public let params: ReadResourceParams
    
    public init(params: ReadResourceParams) {
        self.method = .readResource
        self.params = params
    }
    
    /// Parameters for a resource read request
    public struct ReadResourceParams: Codable, Sendable {
        /// The URI of the resource to read. The URI can use any protocol; it is up to the server how to interpret it.
        public let uri: String
        
        public init(uri: String) {
            self.uri = uri
        }
    }
}


/// The server's response to a resources/read request from the client.
public struct ReadResourceResult: Codable, Sendable {
    /// The contents of the resource
    public let contents: [ResourceContents]
    
    /// Additional metadata attached to the response
    public let meta: Parameters?
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case contents
    }
    
    public init(contents: [ResourceContents], meta: Parameters? = nil) {
        self.meta = meta
        self.contents = contents
    }
}


/// Base request type for MCP protocol
public struct Request: Codable, Sendable, SupportsProgressToken {
    /// The method identifier for the request
    public let method: String
    
    /// The parameters for the request
    public let params: Parameters?
    
    public init(method: String, params: Parameters?) {
        self.method = method
        self.params = params
    }
}


/// Metadata for a request
public struct RequestMetadata: Codable, Sendable {
    /// Token for tracking request progress
    public let progressToken: ProgressToken?
    
    public init(progressToken: ProgressToken? = nil) {
        self.progressToken = progressToken
    }
}

/// A result type that allows for additional metadata in responses.
public typealias Result = Parameters

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


// MARK: - Server Requests
protocol AnyServerRequest: Codable, Sendable {
    var method: ServerRequestMethod { get }
}

public enum ServerRequestMethod: String, AnyMethodIdentifier {
    /// A ping, issued by either the server or the client, to check that the other party is still alive.
    /// The receiver must promptly respond, or else may be disconnected.
    case ping = "ping"
    case createMessage = "sampling/createMessage"
    case listRoots = "roots/list"
}

/// Union type representing all possible server requests
public enum ServerRequest: Codable, Sendable {
    case ping(PingRequest)
    case createMessage(CreateMessageRequest)
    case listRoots(ListRootsRequest)
}

/// Union type representing all possible server results
//public enum ServerResult: Codable, Sendable {
//    case standard(Result)
//    case initialize(InitializeResult)
//    case listResources(ListResourcesResult)
//    case listResourceTemplates(ListResourceTemplatesResult)
//    case readResource(ReadResourceResult)
//    case listPrompts(ListPromptsResult)
//    case getPrompt(GetPromptResult)
//    case listTools(ListToolsResult)
//    case callTool(CallToolResult)
//    case complete(CompleteResult)
//}



