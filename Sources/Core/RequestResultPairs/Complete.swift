//
//  Completion.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request from the client to the server, to ask for completion options.
public struct CompleteRequest: Request {
    /// The method identifier for completion requests
    public let method: ClientRequest.Method
    
    /// The parameters for the completion request
    public let params: Parameters
    
    init(params: Parameters) {
        self.params = params
        self.method = .complete
    }
    
    /// Parameters for a completion request
    public struct Parameters: RequestParameters {
        /// The argument's information
        public let argument: Argument
        /// Reference to either a prompt or resource
        public let ref: Reference
        
        public let _meta: RequestMetadata?
        
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
