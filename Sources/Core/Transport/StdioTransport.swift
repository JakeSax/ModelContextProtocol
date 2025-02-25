//
//  StdioTransport.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import OSLog

#if os(macOS) || os(Linux)
/// Transport implementation using stdio for process-based communication.
/// This transport is designed for long-running MCP servers launched via command line.
public actor StdioTransport: Transport {
    
    // MARK: Public Properties
    public private(set) var state = TransportState.disconnected
    public let configuration: TransportConfiguration
    private let logger: Logger
    public var isRunning: Bool { process?.isRunning ?? false }
    
    // MARK: Private Properties
    // Stored options for constructing the process each time
    private let command: String
    private let arguments: [String]
    private let environment: [String: String]?
    
    // Process & pipes are recreated on each start()
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    private var messagesContinuation: AsyncThrowingStream<Data, Error>.Continuation?
    private var processTask: Task<Void, Never>?
    
    
    // MARK: Initialization
    /// Initialize a stdio transport for a command-line MCP server
    /// - Parameters:
    ///   - options: Transport options
    ///   - configuration: Transport configuration
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
    
    /// Convenience initializer
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
    
    // MARK: Methods
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
        // We'll store these tasks in processTask, so they can be canceled on stop()
        processTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.readMessages(newOutputPipe) }
                group.addTask { await self.monitorStdErr(newErrorPipe) }
            }
        }
        
        try newProcess.run()
        state = .connected
    }
    
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
    
    public func send(_ data: Data, timeout _: Duration? = nil) async throws {
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
    
    
    // MARK: Private Methods
    /// Validates that the command exists in the system PATH.
    ///
    /// This method attempts to locate the command by using the system's `which` utility,
    /// which searches the directories in the PATH environment variable for the specified command.
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
    
    private func monitorStdErr(_ errorPipe: Pipe) async {
        for await line in errorPipe.bytes.lines {
            // Some MCP servers use stderr for logging
            logger.info("[SERVER STDERR] \(line)")
        }
    }
    
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
    
    public func stop() {
        // No-op
    }
    
    public func send(_: Data, timeout _: TimeInterval? = nil) async throws {
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
