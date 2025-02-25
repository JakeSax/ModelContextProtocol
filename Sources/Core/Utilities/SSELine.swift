//
//  SSELine.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/25/25.
//

import Foundation

/// Represents the different types of lines that can appear in a Server-Sent Events (SSE) stream.
///
/// According to the SSE specification (https://html.spec.whatwg.org/multipage/server-sent-events.html),
/// each event consists of one or more lines terminated by a blank line, with each line having
/// a specific format depending on the field type.
public enum SSELine: Equatable, Sendable {
    /// An empty line, which signals the end of an SSE event.
    case empty
    
    /// An event type line (e.g., "event: message").
    /// - Parameter String: The event type name.
    case event(_ event: String)
    
    /// A data line containing the event payload.
    /// - Parameter Data: The UTF-8 encoded data content.
    case data(_ data: Data)
    
    /// An event ID line.
    /// - Parameter String: The event identifier.
    case id(_ id: String)
    
    /// A retry line specifying the reconnection time.
    /// - Parameter Int: The retry interval in milliseconds.
    case retry(milliseconds: Int)
    
    /// A comment line (starting with ':').
    /// - Parameter String: The comment content.
    case comment(_ comment: String)
    
    /// An unknown or malformed line.
    /// - Parameter String: The original line content.
    case unknown(String)
    
    /// Parses a line from an SSE stream into its corresponding `SSELine` case.
    ///
    /// This method handles the following SSE field types:
    /// - Empty lines (event delimiters)
    /// - event: Field specifying the event type
    /// - data: Field containing the event data
    /// - id: Field providing the event ID
    /// - retry: Field indicating retry timeout
    /// - : Comment line (starting with colon)
    ///
    /// - Parameter line: A single line from the SSE stream.
    /// - Returns: The parsed `SSELine` representing the content and type of the line.
    ///  Returns `.unknown` if the line doesn't match any known SSE field format.
    public static func parse(_ line: String) -> SSELine {
        if line.isEmpty {
            return .empty
        } else if line.hasPrefix(":") {
            return .comment(String(line.dropFirst(":".count))
                .trimmingCharacters(in: .whitespaces))
        } else if line.hasPrefix("event:") {
            return .event(String(line.dropFirst("event:".count))
                .trimmingCharacters(in: .whitespaces))
        } else if line.hasPrefix("data:") {
            guard let chunk = String(line.dropFirst("data:".count))
                .trimmingCharacters(in: .whitespaces)
                .data(using: .utf8)
            else {
                return .unknown(line)
            }
            return .data(chunk)
        } else if line.hasPrefix("id:") {
            return .id(String(line.dropFirst("id:".count))
                .trimmingCharacters(in: .whitespaces))
        } else if line.hasPrefix("retry:") {
            guard let ms = Int(line.dropFirst("retry:".count)
                .trimmingCharacters(in: .whitespaces))
            else {
                return .unknown(line)
            }
            return .retry(milliseconds: ms)
        } else {
            return .unknown(line)
        }
    }
    
    /// Converts the SSELine back to its string representation according to the SSE specification.
    ///
    /// - Returns: A string representation of the SSE line.
    public func toString() -> String {
        switch self {
        case .empty:
            ""
        case .event(let eventName):
            "event: \(eventName)"
        case .data(let data):
            if let string = String(data: data, encoding: .utf8) {
                "data: \(string)"
            } else {
                "data:"
            }
        case .id(let id):
            "id: \(id)"
        case .retry(let ms):
            "retry: \(ms)"
        case .comment(let comment):
            ": \(comment)"
        case .unknown(let content):
            content
        }
    }
}

// MARK: - Equatable Implementation
extension SSELine {
    /// Implements Equatable for SSELine, with special handling for the data case
    public static func == (lhs: SSELine, rhs: SSELine) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.event(let lhsEvent), .event(let rhsEvent)):
            return lhsEvent == rhsEvent
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.id(let lhsId), .id(let rhsId)):
            return lhsId == rhsId
        case (.retry(let lhsMs), .retry(let rhsMs)):
            return lhsMs == rhsMs
        case (.comment(let lhsComment), .comment(let rhsComment)):
            return lhsComment == rhsComment
        case (.unknown(let lhsContent), .unknown(let rhsContent)):
            return lhsContent == rhsContent
        default:
            return false
        }
    }
}
