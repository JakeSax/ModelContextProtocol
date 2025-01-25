//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

/// A structured log entry for debugging and monitoring purposes.
public struct LogEntry: Codable {
    public let level: String
    public let message: String
    public let timestamp: Date
}

/// Request to set the logging level.
public struct SetLevelRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "logging/setLevel"
    public let params: [String: DynamicValue]
}

/// Notification of a log message.
public struct LoggingMessageNotification: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/message"
    public let params: [String: DynamicValue]
}
