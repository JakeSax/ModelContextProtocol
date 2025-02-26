//
//  SSEClientTransport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation
import OSLog
import MCPCore
import HTTPTypes
import HTTPTypesFoundation

/// A concrete implementation of `Transport` providing Server-Sent Events (SSE) support.
///
/// This transport establishes a bidirectional communication channel using:
/// - A persistent GET request to receive server events via the SSE protocol
/// - Individual POST requests to send data to the server endpoint
///
/// The transport automatically handles:
/// - Connection establishment and maintenance
/// - Parsing of SSE event streams
/// - Discovery of the POST endpoint via SSE events (if not provided at initialization)
/// - Automatic retries with configurable policies
///
/// - Note: As an actor, this class ensures all operations are thread-safe and properly sequenced.
///
/// - SeeAlso: ``Transport``, ``RetryableTransport``
///
/// Usage example:
/// ```swift
/// let transport = SSEClientTransport(
///     sseURL: URL(string: "https://api.example.com/events")!,
///     configuration: .default
/// )
///
/// // Start the transport
/// try await transport.start()
///
/// // Listen for messages
/// Task {
///     for try await message in transport.messages() {
///         // Process message data
///     }
/// }
///
/// // Send a message
/// let payload = ["message": "Hello server"].data(using: .utf8)!
/// try await transport.send(payload)
/// ```
public actor SSEClientTransport: Transport, RetryableTransport {
    
    // MARK: Public Properties
    public private(set) var state = TransportState.disconnected
    public private(set) var configuration: TransportConfiguration
    
    // MARK: Internal Properties
    /// The URL to which POST requests should be sent, typically discovered
    /// from an SSE `endpoint` event.
    private(set) var postURL: URL?
    
    // MARK: Private Properties
    /// The configuration for how to find and communicate with the server.
    private let networkConfig: NetworkConfiguration
    
    /// Task that manages the indefinite SSE read loop
    private var sseReadTask: Task<Void, Never>?
    
    /// Continuation used by `messages()` for inbound SSE messages
    private var messagesContinuation: AsyncThrowingStream<Data, Error>.Continuation?

    /// A single continuation used to await `postURL` if we haven't discovered it yet
    private var postURLWaitContinuation: CheckedContinuation<URL, Error>?
    
    private let logger: Logger
    
    // MARK: Initialization
    /// Initialize an SSEClientTransport.
    ///
    /// - Parameters:
    ///   - url: The URL to communicate with via SSE.
    ///   - transportConfiguration: The `TransportConfiguration` to use.
    ///   - logger: The Logger instance to use, with a default value.
    public init(
        url: URL,
        transportConfiguration: TransportConfiguration = .default,
        logger: Logger = .init(subsystem: "MCP", category: "SSEClientTransport")
    ) {
        self.networkConfig = NetworkConfiguration(serverURL: url)
        self.configuration = transportConfiguration
        self.logger = logger
        logger.debug("Initialized SSEClientTransport with server URL: \(self.networkConfig.url.absoluteString)")
    }
    
    /// Initialize an SSEClientTransport.
    /// 
    /// - Parameters:
    ///   - networkConfiguration: The configuration for how to find and communicate with the server.
    ///   - transportConfiguration: The `TransportConfiguration` to use.
    ///   - logger: The Logger instance to use, with a default value.
    public init(
        networkConfiguration: NetworkConfiguration,
        transportConfiguration: TransportConfiguration = .default,
        logger: Logger = .init(subsystem: "MCP", category: "SSEClientTransport")
    ) {
        self.networkConfig = networkConfiguration
        self.configuration = transportConfiguration
        self.logger = logger
        logger.debug("Initialized SSEClientTransport with server URL: \(networkConfiguration.url.absoluteString)")
    }
    
    // MARK: Methods
    /// Provides a stream of inbound SSE messages as `Data`.
    ///
    /// - Note: This method doesn't automatically start the transport. You must call `start()`
    ///   before messages will begin flowing through this stream.
    ///
    /// - Returns: An `AsyncThrowingStream` that emits decoded data from SSE events.
    ///   The stream will complete when the transport is stopped or encounters an error.
    public func messages() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                await self?.storeMessagesContinuation(continuation)
            }
        }
    }
    
    /// Starts the SSE connection by initiating the connection to the SSE endpoint.
    ///
    /// This method transitions the transport from `.disconnected` to `.connecting`,
    /// and then to `.connected` upon successful connection establishment.
    ///
    /// - Throws: A `TransportError` if the connection cannot be established.
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
    
    /// Stops the SSE connection, closing the event stream and releasing resources.
    ///
    /// This method:
    /// - Cancels any ongoing SSE read tasks
    /// - Completes the message stream
    /// - Releases any pending continuation waiting for a POST URL
    /// - Sets the transport state to `.disconnected`
    public func stop() async {
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
    
    /// Sends data to the server via a HTTP POST request.
    ///
    /// If the POST URL wasn't provided during initialization, this method will wait for
    /// the URL to be announced by the server via an SSE `endpoint` event, or until the
    /// specified timeout elapses.
    ///
    /// - Parameters:
    ///   - data: The data to send (typically JSON-encoded).
    ///   - timeout: Optional timeout duration that overrides the default from configuration.
    ///   If not specified, uses `configuration.sendTimeout`.
    ///
    /// - Throws:
    ///   - `TransportError.timeout` if waiting for POST URL or sending exceeds the timeout.
    ///   - `TransportError.operationFailed` if the HTTP request fails or returns a non-2xx status.
    ///   - `CancellationError` if the operation is cancelled.
    public func send(_ data: Data, timeout: Duration? = nil) async throws {
        logger.debug("Sending data via SSEClientTransport POST...")
        let targetURL = try await resolvePostURL(timeout: timeout)
        
        try await withRetry(operation: "SSE POST send") {
            try await self.performPOSTSend(data, to: targetURL, timeout: timeout)
        }
    }
    
    // MARK: RetryableTransport
    /// Executes an operation with automatic retries based on the configured retry policy.
    ///
    /// This method will repeatedly attempt the operation until it succeeds or
    /// the maximum number of retries is reached.
    ///
    /// - Parameters:
    ///   - operation: A descriptive name for the operation being retried (for logging).
    ///   - block: The asynchronous operation to execute and potentially retry.
    ///
    /// - Returns: The result of the successful operation execution.
    ///
    /// - Throws: `TransportError.operationFailed` if all retry attempts fail, containing
    ///   details about the last error encountered.
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
    private func storeMessagesContinuation(
        _ continuation: AsyncThrowingStream<Data, Error>.Continuation
    ) {
        messagesContinuation = continuation
        continuation.onTermination = { _ in
            Task { [weak self] in
                await self?.handleMessagesStreamTerminated()
            }
        }
    }
    
    /// Called when the consumer of `messages()` cancels their stream.
    private func handleMessagesStreamTerminated() async {
        // Must remain on actor
        logger.debug("Messages stream terminated by consumer. Stopping SSE transport.")
        await stop()
    }
    
    // MARK: SSE Read Loop
    /// Main SSE read loop that maintains the persistent SSE connection.
    ///
    /// This method:
    /// 1. Establishes the initial SSE connection
    /// 2. Processes the byte stream to parse SSE events
    /// 3. Handles any errors that occur during reading
    /// 4. Updates the transport state appropriately
    ///
    /// The loop continues until explicitly cancelled via `stop()` or an unrecoverable
    /// error occurs.
    private func runSSEReadLoop() async {
        do {
            let byteStream = try await establishSSEConnection()
            try await processSSEStream(byteStream)
        } catch {
            handleSSEError(error)
        }
    }
    
    /// Establishes a connection to the SSE endpoint and returns a stream of bytes.
    ///
    /// This method:
    /// 1. Creates and configures a URLRequest with appropriate headers for SSE
    /// 2. Initiates the connection using URLSession.bytes(for:)
    /// 3. Validates the HTTP response is successful (200 OK)
    /// 4. Updates the transport state to `.connected` on success
    ///
    /// - Returns: An `AsyncBytes` stream that provides access to the raw byte stream from the server
    ///
    /// - Throws:
    ///   - `TransportError.operationFailed` if the HTTP response is not a 200 OK
    ///   - Any network errors that might occur during connection establishment
    ///
    /// - Note: This method applies the `connectTimeout` from the transport configuration
    private func establishSSEConnection() async throws -> URLSession.AsyncBytes {
        var request = HTTPRequest(url: networkConfig.url)
        if let additionalHeaders = networkConfig.additionalHeaders {
            request.headerFields = additionalHeaders
        }
        request.headerFields[.accept] = "text/event-stream"
        guard var urlRequest = URLRequest(httpRequest: request) else {
            throw URLError(.badURL)
        }
        urlRequest.timeoutInterval = configuration.connectTimeout.timeInterval
        
        let (byteStream, response) = try await networkConfig.session.bytes(for: urlRequest)
        try validateHTTPResponse(response)
        
        state = .connected
        logger.info("SSEClientTransport connected to \(self.networkConfig.url.absoluteString, privacy: .private).")
        
        return byteStream
    }
    
    /// Processes the SSE byte stream according to the SSE protocol specification.
    ///
    /// This method implements the core of the SSE protocol parsing logic:
    /// - Reads the stream line by line
    /// - Parses each line according to SSE line format rules
    /// - Accumulates data across multiple data lines
    /// - Dispatches complete events when an empty line is encountered
    /// - Handles special events like 'retry' that affect transport behavior
    /// - Supports cancellation and graceful completion
    ///
    /// The method maintains the following state while processing:
    /// - `dataBuffer`: Accumulates data across multiple data: lines
    /// - `eventType`: Current event type (defaults to "message")
    /// - `eventID`: Optional event ID
    ///
    /// - Parameter byteStream: The `AsyncBytes` stream from the SSE connection
    ///
    /// - Throws:
    ///   - Errors propagated from event handling
    ///   - Any network errors that occur while reading the stream
    ///
    /// - Note: The method will complete normally if the stream ends or is cancelled,
    ///   updating state and completing the message continuation appropriately.
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
                
            case .comment(let comment):
                logger.info("Received comment: \(comment)")
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
    
    /// Handles errors that occur during the SSE connection.
    ///
    /// This method properly updates the transport state and propagates errors
    /// to consumers of the message stream when appropriate.
    ///
    /// - Parameter error: The error that occurred during SSE operations
    ///
    /// Error handling strategy:
    /// - `CancellationError`: Treated as a normal disconnection (e.g., from `stop()`)
    /// - Other errors: Transitions transport to `.failed` state and propagates to the consumer
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
        
        guard let baseURL = URL(string: "/", relativeTo: networkConfig.url)?.baseURL,
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
    
    // MARK: POST Send
    /// Perform a short-lived POST request to send data.
    private func performPOSTSend(
        _ data: Data,
        to url: URL,
        timeout: Duration?
    ) async throws {
        var request = HTTPRequest(method: .post, url: url)
        if let additionalHeaders = networkConfig.additionalHeaders {
            request.headerFields = additionalHeaders
        }
        request.headerFields[.contentType] = "application/json"
        
        guard var urlRequest = URLRequest(httpRequest: request) else {
            throw URLError(.badURL)
        }
        urlRequest.timeoutInterval = (timeout ?? configuration.sendTimeout).timeInterval
        urlRequest.httpBody = data
        
        let (_, response) = try await networkConfig.session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw TransportError.operationFailed(detail: "POST request to \(url) failed with non-2xx response.")
        }
        logger.debug("SSEClientTransport POST send succeeded.")
    }
    
    /// If `postURL` is not yet known, await it until SSE server provides it or we time out.
    ///
    /// This method handles the case where the POST URL hasn't been provided at initialization
    /// and needs to be discovered via an SSE `endpoint` event from the server.
    ///
    /// - Parameter timeout: Custom timeout that overrides the default configuration
    /// - Returns: A valid URL to use for POST requests
    /// - Throws:
    ///   - `TransportError.timeout` if we don't receive the endpoint event within the timeout
    ///   - `CancellationError` if the transport is stopped while waiting
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
    
    // MARK: Timeout Helper
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

}

extension SSEClientTransport {
    
    /// The network configuration for the MCPClient.
    public struct NetworkConfiguration: Sendable {
        /// SSE endpoint URL used to establish the persistent connection
        public let url: URL
        /// URLSession used for both SSE streaming and short-lived POST requests
        public let session: URLSession
        /// Any headers to send along with requests, potentially authentication headers.
        public let additionalHeaders: HTTPFields?
        
        /// The network configuration for the MCPClient.
        /// - Parameters:
        ///   - serverURL: The URL where the MCP server is located.
        ///   - session: The URLSession instance to use for network requests. Defaults
        ///    to `.shared`.
        ///   - additionalHeaders: Optional HTTP header fields to include in the request.
        ///   These headers will be merged with the default headers.
        public init(serverURL: URL, session: URLSession = .shared, additionalHeaders: HTTPFields? = nil) {
            self.url = serverURL
            self.session = session
            self.additionalHeaders = additionalHeaders
        }
    }
}
