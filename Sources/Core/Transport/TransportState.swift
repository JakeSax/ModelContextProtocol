//
//  TransportState.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/3/25.
//

/// Represents the high-level connection state of a transport.
public enum TransportState: Sendable {
    /// Transport is in the process of disconnecting
    case disconnecting
    /// Transport is not connected
    case disconnected
    /// Transport is in the process of connecting
    case connecting
    /// Transport is connected
    case connected
    /// Transport has failed
    case failed(error: Error)
}

extension TransportState: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .disconnecting: "disconnecting"
        case .disconnected: "disconnected"
        case .connecting: "connecting"
        case .connected: "connected"
        case .failed(let error): "failed: \(error)"
        }
    }
    
    public var debugDescription: String { description }
}

extension TransportState: Equatable {
    public static func ==(lhs: TransportState, rhs: TransportState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnecting, .disconnecting),
            (.disconnected, .disconnected),
            (.connecting, .connecting),
            (.connected, .connected),
            (.failed, .failed):
            true
        default:
            false
        }
    }
}
