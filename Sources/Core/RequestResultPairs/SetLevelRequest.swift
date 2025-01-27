//
//  SetLevelRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Request to enable or adjust logging
public struct SetLevelRequest: Request {
    public let method: ClientRequest.Method
    public let params: LoggingParameters
    
    public struct LoggingParameters: RequestParameters {
        /// Level of logging client wants to receive. Server sends logs at this level and higher.
        public let level: LoggingLevel
        
        public let _meta: RequestMetadata?
        
        init(level: LoggingLevel, meta: RequestMetadata? = nil) {
            self.level = level
            self._meta = meta
        }
    }
    
    init(params: LoggingParameters) {
        self.method = .setLevel
        self.params = params
    }
}
