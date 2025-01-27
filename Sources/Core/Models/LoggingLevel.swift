//
//  LoggingLevel.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

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
