//
//  RetryableTransport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/3/25.
//

/// A protocol that extends `Transport` to provide retry functionality for transport operations.
///
/// Conforming types can implement retry logic for operations that may fail transiently.
/// The protocol provides a default implementation through an extension that handles
/// retry attempts based on the transport's configuration.
public protocol RetryableTransport: Transport {
    /// Executes an operation with automatic retry capability.
    ///
    /// This method attempts to execute the provided operation block, and if it fails,
    /// retries the operation according to the transport's retry policy configuration.
    ///
    /// - Parameters:
    ///   - operation: A string identifying the operation being performed. This can be
    ///     used for logging or debugging purposes.
    ///   - block: An asynchronous closure that performs the actual operation. This closure
    ///     must be sendable (thread-safe) and can throw errors.
    ///
    /// - Returns: The value produced by the successful execution of the operation block.
    ///
    /// - Throws: `TransportError.operationFailed` if all retry attempts are exhausted
    ///   without success. The error detail will contain information about the last
    ///   error encountered.
    func withRetry<T: Sendable>(
        operation: String,
        block: @escaping @Sendable () async throws -> T
    ) async throws -> T
}

/// Default implementation of `withRetry`.
extension RetryableTransport {
    /// Default implementation of `withRetry` that provides retry logic based on
    /// the transport's configuration.
    ///
    /// This implementation will:
    /// 1. Attempt to execute the provided operation
    /// 2. If the operation fails, wait for a configured delay period
    /// 3. Retry the operation up to the configured maximum number of attempts
    ///
    /// - Parameters:
    ///   - operation: The operation identifier (unused in the default implementation
    ///     but available for custom implementations)
    ///   - block: The operation to execute with retry capability
    ///
    /// - Returns: The value produced by a successful execution of the operation block
    ///
    /// - Throws: `TransportError.operationFailed` if all retry attempts are exhausted.
    ///   The error detail will contain the description of the last error encountered.
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
