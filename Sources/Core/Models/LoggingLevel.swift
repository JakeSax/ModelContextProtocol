//
//  LoggingLevel.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

import OSLog

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

extension LoggingLevel {
    /// Converts a LoggingLevel to the corresponding OSLogType
    ///
    /// OSLogType has fewer severity levels than RFC-5424, so multiple
    /// LoggingLevel values map to the same OSLogType value.
    public var osLogType: OSLogType {
        switch self {
        case .emergency, .alert, .critical: .fault
        case .error, .warning: .error
        case .notice, .info: .info
        case .debug: .debug
        }
    }
}
