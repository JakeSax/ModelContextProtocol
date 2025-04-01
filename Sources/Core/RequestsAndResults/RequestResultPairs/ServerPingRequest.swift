//
//  PingRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A ping issued by the server, to check that the client is still alive.
/// The receiver must promptly respond, or else may be disconnected.
/// This is identical to ``ClientPingRequest`` but just satisfies different protocol
/// requirements.
public struct ServerPingRequest: AnyServerRequest {
    
    // MARK: Static Properties
    public static let method: ServerRequest.Method = .ping
    public typealias Result = EmptyResult
    
    // MARK: Properties
    public let method: ServerRequest.Method
    public let params: DefaultRequestParameters
    
    // MARK: Initialization
    public init(params: DefaultRequestParameters = .init()) {
        self.params = params
        self.method = Self.method
    }
    
    // MARK: Codable Conformance
    enum CodingKeys: CodingKey {
        case method
        case params
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decodeIfPresent(
            DefaultRequestParameters.self,
            forKey: .params
        ) ?? .init()
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.method, forKey: .method)
        if !self.params.isEmpty {
            try container.encode(self.params, forKey: .params)
        }
    }
    
}

/// A ping issued by the client, to check that the server is still alive.
/// The receiver must promptly respond, or else may be disconnected.
/// This is identical to ``ServerPingRequest`` but just satisfies different protocol
/// requirements.
public struct ClientPingRequest: AnyClientRequest {
    
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .ping
    public typealias Result = EmptyResult
    
    // MARK: Properties
    public let method: ClientRequest.Method
    public let params: DefaultRequestParameters
    
    public var clientRequest: ClientRequest { .ping(self) }
    
    // MARK: Initialization
    public init(params: DefaultRequestParameters = .init()) {
        self.params = params
        self.method = Self.method
    }
    
    // MARK: Codable Conformance
    enum CodingKeys: CodingKey {
        case method
        case params
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decodeIfPresent(
            DefaultRequestParameters.self,
            forKey: .params
        ) ?? .init()
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.method, forKey: .method)
        if !self.params.isEmpty {
            try container.encode(self.params, forKey: .params)
        }
    }
    
}


