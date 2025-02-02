//
//  TransportProtocol.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

/// Protocol defining transport behavior using async functions
public protocol TransportProtocol {
    func send(_ message: String) async
    func receive() -> AsyncStream<String>
}

/// Stdio Transport for local communication
final class StdioTransport: TransportProtocol {
    private var receiveTask: Task<Void, Never>?
    
    func send(_ message: String) async {
        print(message)
    }
    
    func receive() -> AsyncStream<String> {
        AsyncStream { continuation in
            receiveTask = Task {
                while let line = readLine() {
                    continuation.yield(line)
                }
                continuation.finish()
            }
        }
    }
    
    deinit {
        receiveTask?.cancel() // Ensure cleanup when transport is deallocated
    }
}
