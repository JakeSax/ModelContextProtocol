//
//  Completion.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request from the client to the server, to ask for completion options.
public struct CompleteRequest: AnyClientRequest {
    
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .complete
    public typealias Result = CompleteResult
    
    // MARK: Properties
    /// The method identifier for completion requests
    public let method: ClientRequest.Method
    
    /// The parameters for the completion request
    public let params: Parameters
    
    public var clientRequest: ClientRequest { .complete(self) }
    
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    /// Parameters for a completion request
    public struct Parameters: RequestParameters {
        /// The argument's information
        public let argument: Argument
        /// Reference to either a prompt or resource
        public let ref: Reference
        
        public let _meta: RequestMetadata?
        
        /// Information about an argument
        public struct Argument: Codable, Sendable, Equatable {
            /// The name of the argument
            public let name: String
            /// The value of the argument to use for completion matching
            public let value: String
        }
        
        init(argument: Argument, ref: Reference, meta: RequestMetadata? = nil) {
            self.argument = argument
            self.ref = ref
            self._meta = meta
        }
    }
    
    public enum Reference: Codable, Sendable, Equatable {
        case prompt(PromptReference)
        case resource(ResourceReference)
        
        private enum CodingKeys: String, CodingKey {
            case type
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ReferenceTypeIdentifier.self, forKey: .type)
            switch type {
            case .prompt: self = .prompt(try PromptReference(from: decoder))
            case .resource: self = .resource(try ResourceReference(from: decoder))
            }
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .prompt(let promptReference): try container.encode(promptReference)
            case .resource(let resourceReference): try container.encode(resourceReference)
            }
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

/// The server's response to a completion/complete request
public struct CompleteResult: Result {
    /// The completion results
    public let completion: Completion
    
    public let _meta: ResultMetadata?
    
    /// Completion results structure
    public struct Completion: Codable, Sendable, Equatable {
        /// An array of completion values. Must not exceed 100 items.
        public let values: [String]
        /// Indicates whether there are additional completion options beyond those provided
        public let hasMore: Bool?
        /// The total number of completion options available
        public let total: Int?
    }
    
    init(completion: Completion, meta: ResultMetadata? = nil) {
        self.completion = completion
        self._meta = meta
    }
}
