//
//  SetLevelRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to enable or adjust logging
public struct SetLevelRequest: Codable, Sendable {
    public let method: ClientRequest.Method
    public let params: LoggingParameters
    
    public struct LoggingParameters: Codable, Sendable {
        /// Level of logging client wants to receive. Server sends logs at this level and higher.
        public let level: LoggingLevel
    }
    
    init(params: LoggingParameters) {
        self.method = .setLevel
        self.params = params
    }
}
