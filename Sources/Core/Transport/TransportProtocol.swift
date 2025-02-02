//
//  TransportProtocol.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

/// A protocol defining a transport mechanism for sending and receiving messages.
///
/// Implementations of this protocol should handle message transmission
/// over different transport layers, such as standard input/output (stdio)
/// for local communication and network-based transports for remote communication.
//public protocol TransportProtocol {
//    
//    /// Sends a message using the transport mechanism.
//    ///
//    /// - Parameter message: The message to be sent as a `String`.
//    /// - Note: This function is asynchronous and should be awaited to ensure delivery.
//    func send(_ message: String) async throws
//    
//    /// Returns an asynchronous stream of received messages.
//    ///
//    /// - Returns: An `AsyncStream<String>` that emits incoming messages.
//    /// - Note: Consumers should iterate over the stream asynchronously to receive messages.
//    func receive() async -> AsyncStream<String>
//}


/// Default `send(_ data:timeout:)` with an optional parameter.
//extension MCPTransport {
//    public func send(_ data: Data, timeout: Duration? = nil) async throws {
//        if data.count > configuration.maxMessageSize {
//            throw TransportError.messageTooLarge(data.count)
//        }
//        let finalTimeout = timeout ?? configuration.sendTimeout
//        try await  with(timeout: .microseconds(Int64(finalTimeout * 1_000_000))) { [weak self] in
//            guard let self else { return }
//            try await send(data, timeout: nil)
//        }
//    }
//}

/// A protocol describing the core transport interface for MCP.
/// It is an `Actor` so that transport operations are serialized.
public protocol TransportProtocol: Actor {
    /// The current state of the transport
    var state: TransportState { get }
    /// Transport-level configuration
    var configuration: TransportConfiguration { get }
    
    /// Provides a stream of raw `Data` messages.
    /// This is used by `MCPClient` to receive inbound messages.
    func messages() -> AsyncThrowingStream<Data, Error>
    
    /// Start the transport, transitioning it from `.disconnected` to `.connecting` and eventually `.connected`.
    func start() async throws
    
    /// Stop the transport, closing any connections and cleaning up resources.
    func stop()
    
    /// Send data across the transport, optionally with a custom timeout.
    func send(_ data: Data, timeout: Duration?) async throws
}

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

/// Represents the high-level connection state of a transport.
public enum TransportState {
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

/// A protocol for transports to optionally provide a `withRetry` API.
public protocol RetryableTransport: TransportProtocol {
    func withRetry<T: Sendable>(
        operation: String,
        block: @escaping @Sendable () async throws -> T
    ) async throws -> T
}

/// Default implementation of `withRetry`.
extension RetryableTransport {
    public func withRetry<T: Sendable>(
        operation _: String,
        block: @escaping @Sendable () async throws -> T)
    async throws -> T
    {
        var attempt = 1
        var lastError: Error?
        
        while attempt <= configuration.retryPolicy.maxAttempts {
            do {
                return try await block()
            } catch {
                lastError = error
                // If we've used all attempts, stop
                guard attempt < configuration.retryPolicy.maxAttempts else { break }
                
                let delay = configuration.retryPolicy.delay(forAttempt: attempt)
                try await Task.sleep(for: delay)
                attempt += 1
            }
        }
        throw TransportError.operationFailed(detail: "\(String(describing: lastError))")
    }
}
