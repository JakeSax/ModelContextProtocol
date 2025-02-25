//
//  TransportError.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/3/25.
//

import Foundation

/// Common errors at the transport layer (outside the scope of `MCPError`).
public enum TransportError: Error, LocalizedError {
    /// Timed out waiting for an operation
    case timeout(operation: String)
    /// Invalid message format
    case invalidMessage(message: String)
    /// Unable to connect or connection lost
    case connectionFailed(detail: String)
    /// A general operation failure
    case operationFailed(detail: String)
    /// Transport not in a valid state
    case invalidState(reason: String)
    /// Message size exceeded
    case messageTooLarge(sizeLimit: Int)
    /// Transport type not supported on this platform
    case notSupported(detail: String)
    
    // MARK: Public
    
    public var errorDescription: String? {
        switch self {
        case .timeout(let operation): "Timeout waiting for operation: \(operation)"
        case .invalidMessage(let message): "Invalid message format: \(message)"
        case .connectionFailed(let detail): "Connection failed: \(detail)"
        case .operationFailed(let detail): "Operation failed: \(detail)"
        case .invalidState(let reason): "Invalid state: \(reason)"
        case .messageTooLarge(let sizeLimit): "Message exceeds size limit: \(sizeLimit)"
        case .notSupported(let detail): "Transport type not supported: \(detail)"
        }
    }
}
