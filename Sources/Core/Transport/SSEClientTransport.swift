//
//  SSETransport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation
import OSLog

/// A transport implementation using Server-Sent Events (SSE) for remote communication.
///
/// This transport is useful for streaming messages over HTTP to a client,
/// maintaining a persistent connection for real-time updates.
//actor SSETransport: TransportProtocol {
//
//    /// The URL of the SSE server endpoint.
//    private let url: URL
//
//    /// The active task handling message reception.
//    private var receiveTask: Task<Void, Never>?
//
//    /// Initializes an SSE transport with the given server URL.
//    ///
//    /// - Parameter url: The URL of the SSE server to connect to.
//    init(url: URL) {
//        self.url = url
//    }
//
//    /// Sends a message using SSE (not typically supported in a standard SSE setup).
//    ///
//    /// - Parameter message: The message to be sent as a `String`.
//    /// - Note: SSE is primarily a **server-to-client** streaming protocol.
//    ///   Sending messages may require an alternative mechanism, such as WebSockets or HTTP POST.
//    func send(_ message: String) async {
//        print("SSETransport does not support direct message sending.")
//    }
//
//    /// Returns an asynchronous stream of messages received from the SSE server.
//    ///
//    /// - Returns: An `AsyncStream<String>` that emits incoming SSE events.
//    /// - Important: The stream starts an HTTP connection that remains open
//    ///   until canceled or the server closes the connection.
//    func receive() -> AsyncStream<String> {
//        AsyncStream { continuation in
//            receiveTask = Task {
//                await startSSEListening(continuation: continuation)
//            }
//        }
//    }
//
//    /// Establishes an SSE connection and listens for incoming events.
//    ///
//    /// - Parameter continuation: The `AsyncStream.Continuation` to emit received messages.
//    private func startSSEListening(continuation: AsyncStream<String>.Continuation) async {
//        var request = URLRequest(url: url)
//        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
//
//        do {
//            let (stream, _) = try await URLSession.shared.bytes(for: request)
//            for try await line in stream.lines {
//                if !line.isEmpty {
//                    continuation.yield(line)
//                }
//            }
//            continuation.finish()
//        } catch {
//            print("SSE connection failed: \(error)")
//            continuation.finish()
//        }
//    }
//
//    /// Cleans up the background task when the transport is deallocated.
//    ///
//    /// - Important: Ensures that the SSE listening task does not persist
//    ///   after the transport instance is released.
//    deinit {
//        receiveTask?.cancel()
//    }
//}



/// A concrete implementation of `MCPTransport` providing Server-Sent Events (SSE) support.
///
/// This transport uses:
/// - An indefinite GET request to the SSE endpoint for receiving events.
/// - A short-lived POST for sending data, using an endpoint typically announced by the server via an SSE `endpoint` event.
/// It also supports retries via `RetryableTransport`.
public actor SSEClientTransport: TransportProtocol, RetryableTransport {
    
    // MARK: Public Properties
    public private(set) var state = TransportState.disconnected
    public private(set) var configuration: TransportConfiguration
    
    // MARK: Internal Properties
    
    /// Optional post URL, typically discovered from an SSE `endpoint` event
    private(set) var postURL: URL?
    
    // MARK: Private Properties
    
    /// SSE endpoint URL
    private let sseURL: URL
    
    /// Session used for SSE streaming and short-lived POST
    private let session: URLSession
    
    /// Task that runs the indefinite SSE read loop
    private var sseReadTask: Task<Void, Never>?
    
    /// Continuation used by `messages()` for inbound SSE messages
    private var messagesContinuation: AsyncThrowingStream<Data, Error>.Continuation?

    /// A single continuation used to await `postURL` if we haven't discovered it yet
    private var postURLWaitContinuation: CheckedContinuation<URL, Error>?
    
    private let logger: Logger
    
    // MARK: Lifecycle
    
    /// Initialize an SSEClientTransport.
    ///
    /// - Parameters:
    ///   - sseURL: The SSE endpoint URL for receiving events.
    ///   - postURL: Optional known URL for POSTing data. If not provided, we discover it via SSE events.
    ///   - configuration: The `TransportConfiguration` to use.
    public init(
        sseURL: URL,
        postURL: URL? = nil,
        configuration: TransportConfiguration = .default,
        logger: Logger = .init(subsystem: "MCP", category: "SSEClientTransport")
    ) {
        self.sseURL = sseURL
        self.postURL = postURL
        self.configuration = configuration
        session = URLSession(configuration: .ephemeral)
        self.logger = logger
        logger.debug("Initialized SSEClientTransport with sseURL=\(sseURL.absoluteString)")
    }
    
    // MARK: Public
 
    /// Provides a stream of inbound SSE messages as `Data`.
    /// This call does not start the transport if it's not already started. The caller must `start()` first if needed.
    public func messages() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                await self?.storeMessagesContinuation(continuation)
            }
        }
    }
    
    /// Starts the SSE connection by launching the read loop.
    public func start() async throws {
        guard state != .connected else {
            logger.info("SSEClientTransport start called but already connected.")
            return
        }
        
        logger.debug("SSEClientTransport is transitioning to .connecting")
        state = .connecting
        
        sseReadTask = Task {
            await runSSEReadLoop()
        }
    }
    
    /// Stops the SSE connection, finishing the message stream and canceling tasks.
    public func stop() {
        logger.debug("Stopping SSEClientTransport.")
        sseReadTask?.cancel()
        sseReadTask = nil
        
        messagesContinuation?.finish()
        messagesContinuation = nil
        
        // If we are waiting for postURL, fail it
        postURLWaitContinuation?.resume(throwing: CancellationError())
        postURLWaitContinuation = nil
        
        state = .disconnected
        logger.info("SSEClientTransport is now disconnected.")
    }
    
    /// Sends data via a short-lived POST request.
    /// - Parameter data: The data to send (e.g. JSON-encoded).
    /// - Parameter timeout: Optional override for send timeout.
    public func send(_ data: Data, timeout: Duration? = nil) async throws {
        logger.debug("Sending data via SSEClientTransport POST...")
        let targetURL = try await resolvePostURL(timeout: timeout)
        
        try await withRetry(operation: "SSE POST send") {
            try await self.performPOSTSend(data, to: targetURL, timeout: timeout)
        }
    }
    
    // MARK: - RetryableTransport
    
    /// Retry a block of code with the configured `TransportRetryPolicy`.
    public func withRetry<T: Sendable>(
        operation: String,
        block: @escaping @Sendable () async throws -> T)
    async throws -> T
    {
        var attempt = 1
        let maxAttempts = configuration.retryPolicy.maxAttempts
        var lastError: Error?
        
        while attempt <= maxAttempts {
            do {
                return try await block()
            } catch {
                lastError = error
                guard attempt < maxAttempts else { break }
                
                let delay = configuration.retryPolicy.delay(forAttempt: attempt)
                logger.warning("\(operation) failed (attempt \(attempt)). Retrying in \(delay).")
                try await Task.sleep(for: delay)
                attempt += 1
            }
        }
        throw TransportError.operationFailed(
            detail: "\(operation) failed after \(maxAttempts) attempts: \(String(describing: lastError))")
    }
    
    
    
    /// Internally store the messages continuation inside the actor.
    private func storeMessagesContinuation(_ cont: AsyncThrowingStream<Data, Error>.Continuation) {
        messagesContinuation = cont
        cont.onTermination = { _ in
            Task { [weak self] in
                await self?.handleMessagesStreamTerminated()
            }
        }
    }
    
    /// Called when the consumer of `messages()` cancels their stream.
    private func handleMessagesStreamTerminated() {
        // Must remain on actor
        logger.debug("Messages stream terminated by consumer. Stopping SSE transport.")
        stop()
    }
    
    // MARK: - SSE Read Loop
    
    /// Main SSE read loop, reading lines from the SSE endpoint and yielding them as needed.
    private func runSSEReadLoop() async {
        do {
            let byteStream = try await establishSSEConnection()
            try await processSSEStream(byteStream)
        } catch {
            handleSSEError(error)
        }
    }
    
    private func establishSSEConnection() async throws -> URLSession.AsyncBytes {
        var request = URLRequest(url: sseURL)
        request.timeoutInterval = configuration.connectTimeout.timeInterval
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        let (byteStream, response) = try await session.bytes(for: request)
        try validateHTTPResponse(response)
        
        state = .connected
        logger.info("SSEClientTransport connected to \(self.sseURL.absoluteString, privacy: .private).")
        
        return byteStream
    }
    
    private func processSSEStream(_ byteStream: URLSession.AsyncBytes) async throws {
        // Accumulate lines into SSE events
        var dataBuffer = Data()
        var eventType = "message"
        var eventID: String?
        
        for try await line in byteStream.allLines {
            guard !Task.isCancelled else { break }
            
            switch SSELine.parse(line) {
            case .empty:
                try await handleSSEEvent(type: eventType, id: eventID, data: dataBuffer)
                dataBuffer.removeAll()
                eventType = "message"
                eventID = nil
                
            case .event(let value):
                eventType = value
                
            case .data(let chunk):
                dataBuffer.append(chunk)
                
            case .id(let value):
                eventID = value
                
            case .retry(let ms):
                configuration.retryPolicy.baseDelay = .milliseconds(ms)
                
            case .unknown(let line):
                logger.debug("SSEClientTransport ignoring unknown line: \(line)")
            }
        }
        
        
        // If there's leftover data in the buffer, handle it
        if !dataBuffer.isEmpty {
            try await handleSSEEvent(type: eventType, id: eventID, data: dataBuffer)
        }
        
        // SSE stream ended gracefully
        messagesContinuation?.finish()
        state = .disconnected
        logger.debug("SSE stream ended gracefully.")
    }
    
    private func handleRetryLine(_ line: String) {
        if let ms = parseRetry(line) {
            configuration.retryPolicy.baseDelay = .milliseconds(ms)
        } else {
            logger.warning("Failed to apply retry delay from SSE server: \(line)")
        }
    }
    
    private func handleSSEError(_ error: Error) {
        if error is CancellationError {
            logger.debug("SSE read loop cancelled.")
            state = .disconnected
            messagesContinuation?.finish()
        } else {
            logger.error("SSE read loop failed with error: \(error.localizedDescription)")
            state = .failed(error: error)
            messagesContinuation?.finish(throwing: error)
        }
    }
    
//    private func runSSEReadLoopOld() async {
//        let endpoint = sseURL
//        do {
//            var request = URLRequest(url: endpoint)
//            request.timeoutInterval = configuration.connectTimeout.timeInterval
//            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
//            
//            let (byteStream, response) = try await session.bytes(for: request)
//            try validateHTTPResponse(response)
//            
//            state = .connected
//            logger.info(
//                "SSEClientTransport connected to \(endpoint.absoluteString, privacy: .private).")
//            
//            // Accumulate lines into SSE events
//            var dataBuffer = Data()
//            var eventType = "message"
//            var eventID: String?
//            
//            for try await line in byteStream.allLines {
//                guard !Task.isCancelled else { break }
//                
//                if line.isEmpty {
//                    // End of an SSE event
//                    try await handleSSEEvent(type: eventType, id: eventID, data: dataBuffer)
//                    dataBuffer.removeAll()
//                    eventType = "message"
//                    eventID = nil
//                } else if line.hasPrefix("event:") {
//                    eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
//                } else if line.hasPrefix("data:") {
//                    let text = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
//                    if let chunk = text.data(using: .utf8) {
//                        dataBuffer.append(chunk)
//                    }
//                } else if line.hasPrefix("id:") {
//                    eventID = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
//                } else if line.hasPrefix("retry:") {
//                    if let ms = parseRetry(line) {
//                        configuration.retryPolicy.baseDelay = .milliseconds(ms)
//                    } else {
//                        logger.warning("Failed to apply retry delay from SSE server: \(line)")
//                    }
//                } else {
//                    logger.debug("SSEClientTransport ignoring unknown line: \(line)")
//                }
//            }
//            
//            // If there's leftover data in the buffer, handle it
//            if !dataBuffer.isEmpty {
//                try await handleSSEEvent(type: eventType, id: eventID, data: dataBuffer)
//            }
//            
//            // SSE stream ended gracefully
//            messagesContinuation?.finish()
//            state = .disconnected
//            logger.debug("SSE stream ended gracefully.")
//        } catch is CancellationError {
//            logger.debug("SSE read loop cancelled.")
//            state = .disconnected
//            messagesContinuation?.finish()
//        } catch {
//            logger.error("SSE read loop failed with error: \(error.localizedDescription)")
//            state = .failed(error: error)
//            messagesContinuation?.finish(throwing: error)
//        }
//    }
    
    /// Parse and handle a single SSE event upon encountering a blank line.
    private func handleSSEEvent(type: String, id _: String?, data: Data) async throws {
        logger.debug("SSE event type=\(type), size=\(data.count) bytes.")
        switch type {
        case "message": messagesContinuation?.yield(data)
        case "endpoint": try handleEndpointEvent(data)
        default: messagesContinuation?.yield(data)
        }
    }
    
    /// Validate that the SSE endpoint returned a successful 200 OK response.
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TransportError.operationFailed(detail: "SSE request did not return HTTP 200.")
        }
    }
    
    /// If SSE `endpoint` event is received, parse it as a new POST URL.
    private func handleEndpointEvent(_ data: Data) throws {
        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            throw TransportError.invalidMessage(message: "Empty or invalid 'endpoint' SSE event.")
        }
        
        guard let baseURL = URL(string: "/", relativeTo: sseURL)?.baseURL,
              let newURL = URL(string: text, relativeTo: baseURL)
        else {
            throw TransportError.invalidMessage(message: "Could not form absolute endpoint from: \(text)")
        }
        
        logger.debug("SSEClientTransport discovered POST endpoint: \(newURL.absoluteString)")
        postURL = newURL
        
        
        // If someone was awaiting postURL, resume them
        postURLWaitContinuation?.resume(returning: newURL)
        postURLWaitContinuation = nil
    }
    
    /// Parse "retry: xyz" line, returning xyz as Int (milliseconds).
    nonisolated private func parseRetry(_ line: String) -> Int? {
        Int(line.dropFirst("retry:".count).trimmingCharacters(in: .whitespaces))
    }
    
    // MARK: - POST Send
    
    /// Perform a short-lived POST request to send data.
    private func performPOSTSend(
        _ data: Data,
        to url: URL,
        timeout: Duration?
    ) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = (timeout ?? configuration.sendTimeout).timeInterval
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await session.data(for: request)
        guard let httpResp = response as? HTTPURLResponse,
            (200...299).contains(httpResp.statusCode)
        else {
            throw TransportError.operationFailed(detail: "POST request to \(url) failed with non-2xx response.")
        }
        logger.debug("SSEClientTransport POST send succeeded.")
    }
    
    /// If `postURL` is not yet known, await it until SSE server provides it or we time out.
    private func resolvePostURL(timeout: Duration?) async throws -> URL {
        if let existingPostURL = postURL {
            logger.debug("Using existing postURL: \(existingPostURL.absoluteString)")
            return existingPostURL
        }
        
        let effectiveTimeout = timeout ?? configuration.sendTimeout
        
        return try await withThrowingTimeout(duration: effectiveTimeout) {
            try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self else { return }
                // Run the mutation on the actor
                Task {
                    await self.setPostURLWaitContinuation(continuation)
                }
            }
        }
    }
    
    private func setPostURLWaitContinuation(_ continuation: CheckedContinuation<URL, Error>) {
        self.postURLWaitContinuation = continuation
    }
    
    // MARK: - Timeout Helper
    
    /// Executes an asynchronous throwing operation with a timeout.
    ///
    /// This method runs the provided operation with a specified timeout duration. If the operation
    /// completes before the timeout, its result is returned. If the timeout occurs first, the operation
    /// is cancelled and a timeout error is thrown.
    ///
    /// Example usage:
    /// ```swift
    /// do {
    ///     let result = try await withThrowingTimeout(duration: .seconds(5)) {
    ///         try await someAsyncOperation()
    ///     }
    /// } catch {
    ///     print("Operation timed out or failed: \(error)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - duration: The maximum time to wait for the operation to complete.
    ///   - operation: The asynchronous throwing operation to execute.
    ///
    /// - Returns: The result of the operation if it completes before the timeout.
    ///
    /// - Throws:
    ///   - `TransportError.timeout` if the operation doesn't complete within the specified duration.
    ///   - Any error thrown by the operation itself.
    ///
    /// - Note: When a timeout occurs, the original operation is cancelled but might continue executing
    ///         in the background until it reaches its next suspension point.
    private func withThrowingTimeout<T: Sendable>(
        duration: Duration,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: duration)
                throw TransportError.timeout(operation: "\(duration.description) elapsed")
            }
            
            // Wait for either the operation to complete or the timeout to occur
            guard let result = try await group.next() else {
                throw TransportError.timeout(operation: "Operation completed with no result")
            }
            
            // Cancel any remaining tasks (either the timeout task or the operation)
            group.cancelAll()
            return result
        }
    }
    
    // MARK: Data Structures
//    private enum SSEEventType: String {
//        case message
//        case endpoint
//        case unknown
//        
//        init(rawValue: String) {
//            switch rawValue {
//            case "message": self = .message
//            case "endpoint": self = .endpoint
//            default: self = .unknown
//            }
//        }
//    }
    
    private enum SSELine {
        case empty
        case event(String)
        case data(Data)
        case id(String)
        case retry(Int)
        case unknown(String)
        
        static func parse(_ line: String) -> SSELine {
            if line.isEmpty {
                return .empty
            } else if line.hasPrefix("event:") {
                let value = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                return .event(value)
            } else if line.hasPrefix("data:") {
                let text = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if let chunk = text.data(using: .utf8) {
                    return .data(chunk)
                }
                return .unknown(line)
            } else if line.hasPrefix("id:") {
                let value = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                return .id(value)
            } else if line.hasPrefix("retry:") {
                if let ms = Int(line.dropFirst("retry:".count).trimmingCharacters(in: .whitespaces)) {
                    return .retry(ms)
                }
                return .unknown(line)
            }
            return .unknown(line)
        }
    }

    
}
