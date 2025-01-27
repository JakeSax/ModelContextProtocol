//
//  ServerRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A Request identified by a ``ServerRequest.Method`` in its `method` property.
protocol AnyServerRequest: Request, MethodIdentified where MethodIdentifier == ServerRequest.Method {}

/// An enumeration of all the possible server requests.
public enum ServerRequest: Codable, Sendable {
    
    case ping(PingRequest)
    case createMessage(CreateMessageRequest)
    case listRoots(ListRootsRequest)
    
    // MARK: Data Structures
    public enum Method: String, AnyMethodIdentifier {
        case ping = "ping"
        case createMessage = "sampling/createMessage"
        case listRoots = "roots/list"
    }
    
    // MARK: Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case method
    }
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .ping(let pingRequest):
            try pingRequest.encode(to: encoder)
        case .createMessage(let createMessageRequest):
            try createMessageRequest.encode(to: encoder)
        case .listRoots(let listRootsRequest):
            try listRootsRequest.encode(to: encoder)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(ServerRequest.Method.self, forKey: .method)
        
        switch method {
        case .ping:
            self = .ping(try PingRequest(from: decoder))
        case .createMessage:
            self = .createMessage(try CreateMessageRequest(from: decoder))
        case .listRoots:
            self = .listRoots(try ListRootsRequest(from: decoder))
        }
    }
    
}
