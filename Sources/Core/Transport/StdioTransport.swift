//
//  StdioTransport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import OSLog

#if os(macOS) || os(Linux)
/// A transport implementation that communicates with a subprocess via standard input/output.
///
/// `StdioTransport` launches and manages an external process, communicating with it by:
/// - Writing to the process's standard input
/// - Reading from the process's standard output
/// - Monitoring the process's standard error
///
/// This transport is designed for long-running MCP servers launched via command line.
/// Each message sent must be a single line (no embedded newlines), and messages are
/// delimited by newline characters.
///
/// - Note: The transport automatically adds PATH entries for common Node.js installations
///   to improve compatibility with JavaScript-based MCP servers.
public actor StdioTransport: Transport {
    
    // MARK: Public Properties
    
    /// The current state of the transport.
    /// Starts as `.disconnected` and transitions through states as the transport operates.
    public private(set) var state = TransportState.disconnected
    
    /// Configuration options that control transport behavior.
    public let configuration: TransportConfiguration
    
    /// Returns whether the underlying process is currently running.
    /// - Returns: `true` if the process is running, `false` otherwise.
    public var isRunning: Bool { process?.isRunning ?? false }
    
    // MARK: Private Properties
    
    /// Logger used for diagnostic information.
    private let logger: Logger
    
    /// The executable command to run.
    private let command: String
    
    /// Arguments to pass to the command.
    private let arguments: [String]
    
    /// Environment variables to set for the process.
    private let environment: [String: String]?
    
    /// The managed subprocess.
    private var process: Process?
    
    /// Pipe for writing to the process's standard input.
    private var inputPipe: Pipe?
    
    /// Pipe for reading from the process's standard output.
    private var outputPipe: Pipe?
    
    /// Pipe for reading from the process's standard error.
    private var errorPipe: Pipe?
    
    /// Continuation for the messages stream.
    private var messagesContinuation: AsyncThrowingStream<Data, Error>.Continuation?
    
    /// Task that manages reading from pipes.
    private var processTask: Task<Void, Never>?
    
    // MARK: Initialization
    
    /// Initializes a stdio transport for a command-line MCP server using options.
    ///
    /// - Parameters:
    ///   - options: Configuration options for the subprocess.
    ///   - configuration: Transport-level configuration for handling messages.
    ///   - logger: Logger for diagnostic information.
    public init(
        options: Options,
        configuration: TransportConfiguration = .default,
        logger: Logger = .init(subsystem: "MCP", category: "StdioTransport")
    ) {
        command = options.command
        arguments = options.arguments
        environment = options.environment
        self.configuration = configuration
        self.logger = logger
    }
    
    /// Initializes a stdio transport for a command-line MCP server.
    ///
    /// - Parameters:
    ///   - command: The executable to run (must be in PATH).
    ///   - arguments: Command-line arguments to pass to the executable.
    ///   - environment: Additional environment variables to set for the process.
    ///     These are merged with the current process environment.
    ///   - configuration: Transport-level configuration for handling messages.
    ///   - logger: Logger for diagnostic information.
    public init(
        command: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        configuration: TransportConfiguration = .default,
        logger: Logger = .init(subsystem: "MCP", category: "StdioTransport")
    ) {
        self.command = command
        self.arguments = arguments
        self.environment = environment
        self.configuration = configuration
        self.logger = logger
    }
    
    // MARK: Transport Protocol Methods
    
    /// Provides a stream of messages received from the subprocess's standard output.
    ///
    /// Each message is delivered as `Data` with the trailing newline removed.
    /// If the transport is not already running, calling this method will
    /// automatically start it.
    ///
    /// - Returns: An asynchronous stream of data messages received from the subprocess.
    /// - Note: When the caller stops consuming the stream, the transport will be stopped.
    public func messages() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            self.messagesContinuation = continuation
            
            // Auto-start if needed
            if self.state == .disconnected {
                Task {
                    do {
                        try await self.start()
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
            }
            
            // When the caller stops consuming the stream, we'll stop the transport.
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.stop()
                }
            }
        }
    }
    
    /// Starts the transport by launching the subprocess.
    ///
    /// This method:
    /// 1. Validates that the command exists in PATH
    /// 2. Creates pipes for stdin, stdout, and stderr
    /// 3. Launches the subprocess with the configured arguments and environment
    /// 4. Sets up message monitoring
    ///
    /// - Throws: `TransportError.invalidState` if the command is not found or
    ///   the process cannot be started.
    /// - Note: If the transport is already connected or connecting, this method
    ///   will log a warning and return without doing anything.
    public func start() async throws {
        guard state == .disconnected else {
            logger.warning("Transport already connected or connecting: \(self.state)")
            return
        }
        
        state = .connecting
        
        // Validate that the command exists in PATH
        try validateCommand()
        
        let newInputPipe = Pipe()
        let newOutputPipe = Pipe()
        let newErrorPipe = Pipe()
        
        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env") // locate command in PATH
        newProcess.arguments = [command] + arguments
        
        // Merge environment
        var processEnv = ProcessInfo.processInfo.environment
        environment?.forEach { processEnv[$0] = $1 }
        
        // Ensure PATH includes typical node/npm locations
        if var path = processEnv["PATH"] {
            let additionalPaths = [
                "/usr/local/bin",
                "/usr/local/npm/bin",
                "\(processEnv["HOME"] ?? "")/node_modules/.bin",
                "\(processEnv["HOME"] ?? "")/.npm-global/bin",
                "/opt/homebrew/bin",
                "/usr/local/opt/node/bin",
            ]
            path = (additionalPaths + [path]).joined(separator: ":")
            processEnv["PATH"] = path
        }
        newProcess.environment = processEnv
        
        // Assign pipes
        newProcess.standardInput = newInputPipe
        newProcess.standardOutput = newOutputPipe
        newProcess.standardError = newErrorPipe
        
        newProcess.terminationHandler = { [weak self] process in
            guard let self else { return }
            Task {
                await self.handleProcessTermination(process)
            }
        }
        
        // Keep references so we can use them later
        process = newProcess
        inputPipe = newInputPipe
        outputPipe = newOutputPipe
        errorPipe = newErrorPipe
        
        // Monitor stdout and stderr
        processTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.readMessages(newOutputPipe) }
                group.addTask { await self.monitorStdErr(newErrorPipe) }
            }
        }
        
        try newProcess.run()
        state = .connected
    }
    
    /// Stops the transport and cleans up all resources.
    ///
    /// This method:
    /// 1. Terminates the subprocess if it's running
    /// 2. Closes all pipes
    /// 3. Finishes the message stream
    /// 4. Resets the transport state to `.disconnected`
    ///
    /// If the transport is already disconnected or disconnecting, this method
    /// returns immediately without doing anything.
    public func stop() async {
        guard state != .disconnected, state != .disconnecting else {
            return
        }
        let error = state.error
        state = .disconnecting
        
        processTask?.cancel()
        processTask = nil
        
        if let process, process.isRunning {
            process.terminate()
            // Wait for the process to exit before proceeding
            await withCheckedContinuation { continuation in
                Task.detached {
                    process.waitUntilExit()
                    continuation.resume()
                }
            }
        }
        
        do {
            try inputPipe?.fileHandleForWriting.close()
        } catch {
            logger.error("Error closing input pipe: \(error)")
        }
        
        do {
            try outputPipe?.fileHandleForWriting.close()
        } catch {
            logger.error("Error closing output pipe: \(error)")
        }
        
        do {
            try errorPipe?.fileHandleForWriting.close()
        } catch {
            logger.error("Error closing errror pipe: \(error)")
        }
        
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        
        // Finish the message stream
        if let error {
            messagesContinuation?.finish(throwing: error)
        } else {
            messagesContinuation?.finish()
        }
        
        messagesContinuation = nil
        state = .disconnected
    }
    
    /// Sends data to the subprocess via standard input.
    ///
    /// This method validates the message, appends a newline character, and writes
    /// the data to the subprocess's standard input.
    ///
    /// - Parameters:
    ///   - data: The data to send. Must not contain embedded newlines.
    ///   - timeout: Optional timeout for the send operation. Currently unused.
    ///
    /// - Throws:
    ///   - `TransportError.invalidState` if the transport is not connected or the pipe is unavailable
    ///   - `TransportError.messageTooLarge` if the message exceeds the configured size limit
    ///   - `TransportError.invalidMessage` if the message contains embedded newlines
    public func send(_ data: Data, timeout: Duration? = nil) async throws {
        guard state == .connected else {
            throw TransportError.invalidState(
                reason: "Transport not connected, transport state: \(state.debugDescription)"
            )
        }
        guard let inputPipe else {
            throw TransportError.invalidState(reason: "Pipe not available")
        }
        
        // Check message size
        guard data.count <= configuration.maxMessageSize else {
            throw TransportError.messageTooLarge(sizeLimit: data.count)
        }
        
        // Validate no embedded newlines
        guard !data.contains(0x0A) else {
            throw TransportError.invalidMessage(message: "Message contains embedded newlines")
        }
        
        var messageData = data
        messageData.append(0x0A)
        inputPipe.fileHandleForWriting.write(messageData)
    }
    
    // MARK: - Private Methods
    
    /// Validates that the command exists in the system PATH.
    ///
    /// Uses the system's `which` utility to search the PATH environment variable
    /// for the specified command.
    ///
    /// - Throws: `TransportError.invalidState` if the command cannot be found or
    ///   if there's an error in the validation process.
    private func validateCommand() throws {
        // Create a process to run the "which" command to search for our command in PATH
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = [command]
        
        do {
            // Run the "which" command
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            // Check exit status - nonzero means the command wasn't found
            if whichProcess.terminationStatus != 0 {
                throw TransportError.invalidState(
                    reason: "Command '\(command)' not found in PATH. Please ensure it is installed and accessible."
                )
            }
        } catch {
            // Handle errors from the "which" process itself
            if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain {
                throw TransportError.invalidState(
                    reason: "Error validating command: \(error.localizedDescription)"
                )
            } else {
                // Propagate other unexpected errors
                throw error
            }
        }
    }
    
    /// Monitors the stderr output from the subprocess and logs it.
    ///
    /// - Parameter errorPipe: The pipe connected to the subprocess's stderr.
    private func monitorStdErr(_ errorPipe: Pipe) async {
        for await line in errorPipe.bytes.lines {
            // Some MCP servers use stderr for logging
            logger.info("[SERVER STDERR] \(line)")
        }
    }
    
    /// Reads and processes messages from the subprocess's stdout.
    ///
    /// Each line read from stdout is converted to Data and yielded to the messages stream.
    ///
    /// - Parameter outputPipe: The pipe connected to the subprocess's stdout.
    private func readMessages(_ outputPipe: Pipe) async {
        do {
            for try await line in outputPipe.bytes.lines {
                try Task.checkCancellation()
                guard let data = line.data(using: .utf8) else {
                    continue
                }
                messagesContinuation?.yield(data)
            }
        } catch is CancellationError {
            logger.warning("STDOUT message reading cancelled")
        } catch {
            logger.error("Caught error reading stdout messages: \(error)")
        }
        await stop()
    }
    
    /// Handles subprocess termination.
    ///
    /// Called when the subprocess exits. Updates the transport state based on
    /// the exit code and triggers transport shutdown.
    ///
    /// - Parameter process: The terminated process.
    private func handleProcessTermination(_ process: Process) async {
        let status = process.terminationStatus
        if status != 0 {
            logger.error("Process terminated with non-zero exit code: \(status)")
            state = .failed(
                error: TransportError.operationFailed(detail: "Process exited with status \(status)")
            )
        }
        await stop()
    }
}

#else

/// Stub implementation for platforms that don't support Process
public actor StdioTransport: Transport {
    
    // MARK: Properties
    public private(set) var state = TransportState.disconnected
    public let configuration: TransportConfiguration
    
    public var isRunning: Bool { false }
    
    // MARK: Initialization
    public init(
        configuration: TransportConfiguration = .default
    ) {
        self.configuration = configuration
    }
    
    public init(
        command _: String,
        arguments _: [String] = [],
        environment _: [String: String]? = nil,
        configuration: TransportConfiguration = .default
    ) {
        self.configuration = configuration
    }
    
    // MARK: Public
    
    public func messages() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: TransportError.unsupportedPlatform)
        }
    }
    
    public func start() async throws {
        throw TransportError.unsupportedPlatform
    }
    
    public func stop() async {
        // No-op
    }
    
    public func send(_ data: Data, timeout: Duration?) async throws {
        throw TransportError.unsupportedPlatform
    }
}

#endif

extension TransportError {
    static let unsupportedPlatform = TransportError.notSupported(
        detail: "StdioTransport is not supported on this platform. It requires macOS or Linux."
    )
}

extension StdioTransport {
    /// Configuration options for StdioTransport
    public struct Options {
        /// The command to execute
        public let command: String
        
        /// Arguments to pass to the command
        public let arguments: [String]
        
        /// Optional environment variables to set
        public let environment: [String: String]?
        
        public init(command: String, arguments: [String] = [], environment: [String: String]? = nil) {
            self.command = command
            self.arguments = arguments
            self.environment = environment
        }
    }
}
