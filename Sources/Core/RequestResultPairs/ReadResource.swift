//
//  ReadResource.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to read a specific resource URI.
public struct ReadResourceRequest: Request {
    /// The method identifier for the request
    public let method: ClientRequest.Method
    
    /// The parameters for the request
    public let params: ReadResourceParams
    
    public init(params: ReadResourceParams) {
        self.method = .readResource
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
}


/// The server's response to a resources/read request from the client.
public struct ReadResourceResult: Codable, Sendable {
    /// The contents of the resource
    public let contents: [ResourceContents]
    
    /// Additional metadata attached to the response
    public let meta: OldParameters?
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case contents
    }
    
    public init(contents: [ResourceContents], meta: OldParameters? = nil) {
        self.meta = meta
        self.contents = contents
    }
}

