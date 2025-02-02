//
//  AsyncHelpers.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

extension AsyncSequence where Element == UInt8, Self: Sendable {
    /// Splits an async byte stream into lines delimited by `\n`.
    public var allLines: AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var buffer: [UInt8] = []
                var iterator = self.makeAsyncIterator()
                
                do {
                    while let byte = try await iterator.next() {
                        if byte == UInt8(ascii: "\n") {
                            // End of line
                            if buffer.isEmpty {
                                continuation.yield("") // blank line
                            } else {
                                if let line = String(data: Data(buffer), encoding: .utf8) {
                                    continuation.yield(line)
                                } else {
                                    throw TransportError.invalidMessage(message: "Could not decode SSE line as UTF-8.")
                                }
                                buffer.removeAll()
                            }
                        } else {
                            buffer.append(byte)
                        }
                    }
                    // End of stream, flush partial
                    if !buffer.isEmpty {
                        if let line = String(data: Data(buffer), encoding: .utf8) {
                            continuation.yield(line)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}


extension Pipe {
    /// A sequence that provides asynchronous access to bytes from a pipe
    ///
    /// This sequence reads bytes from the pipe's file handle as they become
    /// available, providing them one at a time through its iterator.
    ///
    /// Example usage:
    /// ```swift
    /// for await byte in pipe.bytes {
    ///     // Process each byte
    /// }
    /// ```
    public struct AsyncBytes: AsyncSequence {
        /// The type of element produced by this sequence
        public typealias Element = UInt8
        
        /// The underlying pipe instance
        private let pipe: Pipe
        
        /// Creates an asynchronous byte sequence from the given pipe
        /// - Parameter pipe: The pipe to read bytes from
        public init(pipe: Pipe) {
            self.pipe = pipe
        }
        
        /// Creates an iterator that asynchronously produces bytes from the pipe
        /// - Returns: An async iterator that yields bytes from the pipe's reading handle
        public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
            AsyncStream { continuation in
                pipe.fileHandleForReading.readabilityHandler = { @Sendable handle in
                    let data = handle.availableData
                    guard !data.isEmpty else {
                        continuation.finish()
                        return
                    }
                    for byte in data {
                        continuation.yield(byte)
                    }
                }
                
                continuation.onTermination = { [weak pipe] _ in
                    pipe?.fileHandleForReading.readabilityHandler = nil
                }
            }.makeAsyncIterator()
        }
    }
    
    /// An asynchronous sequence of bytes read from this pipe
    var bytes: AsyncBytes {
        AsyncBytes(pipe: self)
    }
}
