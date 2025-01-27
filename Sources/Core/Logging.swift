//
//  Logging.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

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

/// The severity level of a log message, mapping to syslog severities (RFC-5424)
public enum LoggingLevel: String, Codable, Sendable {
    case emergency
    case alert
    case critical
    case error
    case warning
    case notice
    case info
    case debug
}

/// A notification containing a log message from server to client
public struct LoggingMessageNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .loggingMessage
    
    /// The method identifier for logging notifications
    public let method: ServerNotification.Method
    
    public let params: Params
    
    /// Parameters containing the log message details
    public struct Params: Codable, Sendable {
        /// The log message content
        public let data: DynamicValue
        
        /// The severity level of the message
        public let level: LoggingLevel
        
        /// Optional name of the logger
        public let logger: String?
        
        public init(data: DynamicValue, level: LoggingLevel, logger: String? = nil) {
            self.data = data
            self.level = level
            self.logger = logger
        }
    }
    
    
    public init(params: Params) {
        self.params = params
        self.method = Self.method
    }
}
