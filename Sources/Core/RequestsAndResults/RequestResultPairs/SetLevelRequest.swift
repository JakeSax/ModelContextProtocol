//
//  SetLevelRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to enable or adjust logging
public struct SetLevelRequest: AnyClientRequest {
    
    // MARK: Static Properties
    public static let method: ClientRequest.Method = .setLevel
    public typealias Result = EmptyResult
    
    // MARK: Properties
    public let method: ClientRequest.Method
    public let params: LoggingParameters
    
    public var clientRequest: ClientRequest { .setLevel(self) }
    
    // MARK: Initialization
    public init(params: LoggingParameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    public struct LoggingParameters: RequestParameters {
        /// Level of logging client wants to receive. Server sends logs at this level and higher.
        public let level: LoggingLevel
        
        public let _meta: RequestMetadata?
        
        init(level: LoggingLevel, meta: RequestMetadata? = nil) {
            self.level = level
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
