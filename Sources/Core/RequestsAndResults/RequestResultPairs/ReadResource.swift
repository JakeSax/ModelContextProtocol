//
//  ReadResource.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to read a specific resource URI.
public struct ReadResourceRequest: Request {
    
    public static let method: ClientRequest.Method = .readResource
    
    /// The method identifier for the request
    public let method: MethodIdentifier
    
    /// The parameters for the request
    public let params: ReadResourceParams
    
    public init(params: ReadResourceParams) {
        self.method = Self.method
        self.params = params
    }
    
    /// Parameters for a resource read request
    public struct ReadResourceParams: RequestParameters {
        /// The URI of the resource to read. The URI can use any protocol; it is up to the server how to interpret it.
        public let uri: String
        
        public let _meta: RequestMetadata?
        
        public init(uri: String, meta: RequestMetadata? = nil) {
            self.uri = uri
            self._meta = meta
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
}


/// The server's response to a resources/read request from the client.
public struct ReadResourceResult: Result {
    /// The contents of the resource
    public let contents: [ResourceContent]
    
    public let _meta: ResultMetadata?
    
    public init(contents: [ResourceContent], meta: ResultMetadata? = nil) {
        self.contents = contents
        self._meta = meta
    }
}

