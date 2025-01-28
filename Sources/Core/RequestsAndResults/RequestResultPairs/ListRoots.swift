//
//  ListRoots.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/**
 * Sent from the server to request a list of root URIs from the client. Roots allow
 * servers to ask for specific directories or files to operate on. A common example
 * for roots is providing a set of repositories or directories a server should operate
 * on.
 *
 * This request is typically used when the server needs to understand the file system
 * structure or access specific locations that the client has permission to read from.
 */
public struct ListRootsRequest: Request {
    
    // MARK: Static Properties
    public static let method: ServerRequest.Method = .listRoots
    
    // MARK: Properties
    /// The method identifier for the roots/list request
    public let method: ServerRequest.Method
    
    /// Optional parameters for the request
    public let params: DefaultRequestParameters
    
    // MARK: Initialization
    public init(params: DefaultRequestParameters = .init()) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Codable Conformance
    private enum CodingKeys: CodingKey {
        case method
        case params
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decodeIfPresent(Parameters.self, forKey: .params) ?? .init()
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.method, forKey: .method)
        if !self.params.isEmpty {
            try container.encode(self.params, forKey: .params)
        }
    }
}

/**
 * The client's response to a roots/list request from the server.
 * This result contains an array of Root objects, each representing a root directory
 * or file that the server can operate on.
 */
public struct ListRootsResult: Result {
    
    /// Array of root objects representing accessible directories/files
    public let roots: [Root]
    
    public let _meta: ResultMetadata?
    
    public init(roots: [Root], meta: ResultMetadata? = nil) {
        self.roots = roots
        self._meta = meta
    }
}
