//
//  Transport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

/// A protocol describing the core transport interface for MCP.
/// It is an `Actor` so that transport operations are serialized.
public protocol Transport: Actor {
    
    /// The current state of the transport
    var state: TransportState { get }
    
    /// Transport-level configuration
    var configuration: TransportConfiguration { get }
    
    /// Provides a stream of raw `Data` messages.
    /// This is used by `MCPClient` to receive inbound messages.
    func messages() -> AsyncThrowingStream<Data, Error>
    
    /// Start the transport, transitioning it from `.disconnected` to
    /// `.connecting` and eventually `.connected`.
    func start() async throws
    
    /// Stop the transport, closing any connections and cleaning up resources.
    func stop()
    
    /// Send data across the transport, optionally with a custom timeout.
    func send(_ data: Data, timeout: Duration?) async throws
}
