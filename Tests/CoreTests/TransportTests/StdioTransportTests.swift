//
//  StdioTransportTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/24/25.
//

import Foundation
import Testing
@testable import MCPCore

@Suite(.serialized)
struct StdioTransportTests {
    
    // Helper to create a simple echo server script
    private func createEchoScript() -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let scriptPath = tempDir.appendingPathComponent("echo_server.sh")
        
        // Simple bash script that echoes input back to stdout
        let scriptContent = """
        #!/bin/bash
        while IFS= read -r line; do
            echo "$line"
            # Also write something to stderr for testing
            echo "Received: $line" >&2
        done
        """
        
        try? FileManager.default.removeItem(at: scriptPath)
        try! scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        return scriptPath
    }
    
    @Test("Initialization")
    func initialization() async {
        // Test various initialization methods
        let transport1 = StdioTransport(
            options: .init(command: "echo", arguments: ["Hello"]),
            configuration: .init(maxMessageSize: 2048)
        )
        
        let transport2 = StdioTransport(
            command: "echo",
            arguments: ["Hello"],
            environment: ["TEST_VAR": "value"]
        )
        
        #expect(await transport1.configuration.maxMessageSize == 2048)
        #expect(await transport2.configuration.maxMessageSize == TransportConfiguration.default.maxMessageSize)
    }
    
    @Test("Start/Stop")
    func startStop() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        // Test initial state
        #expect(await transport.state == .disconnected)
        #expect(await !transport.isRunning)
        
        // Test start
        try await transport.start()
        #expect(await transport.state == .connected)
        #expect(await transport.isRunning)
        
        // Test idempotent start
        try await transport.start() // Should not throw or change state
        #expect(await transport.state == .connected)
        
        // Test stop
        await transport.stop()
        #expect(await transport.state == .disconnected)
        #expect(await !transport.isRunning)
        
        // Test idempotent stop
        await transport.stop() // Should not change state
        #expect(await transport.state == .disconnected)
    }
    
    @Test("Message Send/Receive")
    func messageSendReceive() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        try await transport.start()
        
        // Collect messages in the background
        let messagesTask = Task {
            var receivedMessages = [String]()
            for try await data in await transport.messages() {
                if let message = String(data: data, encoding: .utf8) {
                    receivedMessages.append(message)
                    // Break after receiving a few messages
                    if receivedMessages.count >= 3 {
                        break
                    }
                }
            }
            return receivedMessages
        }
        
        // Send test messages
        let testMessages = ["Hello", "World", "Testing 123"]
        for message in testMessages {
            try await transport.send(message.data(using: .utf8)!)
            try await Task.sleep(for: .milliseconds(100)) // Give time for echo
        }
        
        // Wait for messages and verify
        let receivedMessages = try await messagesTask.value
        #expect(receivedMessages == testMessages)
        
        await transport.stop()
    }
    
    @Test("Invalid Message Sending")
    func invalidMessageSending() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(
            command: scriptPath.path,
            configuration: .init(maxMessageSize: 10) // Small limit for testing
        )
        
        try await transport.start()
        
        // Test sending before connected
        await transport.stop()
        do {
            try await transport.send("test".data(using: .utf8)!)
            Issue.record("Should have thrown when sending to stopped transport")
        } catch {
            // Expected error
            #expect(error is TransportError)
        }
        
        // Test message too large
        try await transport.start()
        do {
            let largeMessage = String(repeating: "X", count: 20).data(using: .utf8)!
            try await transport.send(largeMessage)
            Issue.record("Should have thrown on message too large")
        } catch {
            // Expected error
            #expect(error is TransportError)
        }
        
        // Test message with embedded newline
        do {
            let invalidMessage = "line1\nline2".data(using: .utf8)!
            try await transport.send(invalidMessage)
            Issue.record("Should have thrown on message with newline")
        } catch {
            // Expected error
            #expect(error is TransportError)
        }
        
        await transport.stop()
    }
    
    @Test("Process Failure")
    func processFailure() async throws {
        // Test with a command that will fail
        let transport = StdioTransport(
            command: "this_command_definitely_does_not_exist_12345",
            arguments: ["arg"]
        )
        
        do {
            try await transport.start()
            Issue.record("Should have thrown on process launch failure")
        } catch {
            // Expected error
            #expect(await transport.state != .connected)
        }
    }
    
    @Test("Early Process Termination")
    func earlyProcessTermination() async throws {
        // Create a script that exits immediately
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let scriptPath = tempDir.appendingPathComponent("exit_script.sh")
        
        let scriptContent = """
    #!/bin/bash
    echo "Starting up"
    echo "Shutting down" >&2
    exit 1
    """
        
        try? FileManager.default.removeItem(at: scriptPath)
        try! scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        let transport = StdioTransport(command: scriptPath.path)
        
        // Start the transport
        try await transport.start()
        
        // Create a task to monitor when process stops running
        let monitorTask = Task {
            // Wait until the process is no longer running or a timeout occurs
            let maxWait = 2_000 // 2 seconds
            let checkInterval = 100 // 100ms
            var totalWait = 0
            
            while await transport.isRunning && totalWait < maxWait {
                try await Task.sleep(for: .milliseconds(checkInterval))
                totalWait += checkInterval
            }
            
            return await transport.state
        }
        
        // Wait for the monitoring task to complete
        let finalState = try await monitorTask.value
        
        // Log the final state for debugging
        print("Final transport state: \(finalState)")
        
        // The process should no longer be running
        #expect(await !transport.isRunning)
        
        // Check more specific state information
        switch finalState {
        case .disconnected:
            // This is acceptable if stop() was called during termination
            break
        case .failed(let error):
            // This is the expected outcome - verify error details
            if let transportError = error as? TransportError {
                print("Transport failed with error: \(transportError)")
            }
            break
        default:
            Issue.record("Expected transport to be disconnected or failed, but was \(finalState)")
        }
    }
    
    @Test("Stream Cancellation")
    func streamCancellation() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        // Start and get the messages stream
        try await transport.start()
        
        let messagesTask = Task {
            var count = 0
            for try await _ in await transport.messages() {
                count += 1
                if count >= 2 {
                    break // Exit early to test cancellation
                }
            }
        }
        
        // Send a couple messages
        try await transport.send("test1".data(using: .utf8)!)
        try await transport.send("test2".data(using: .utf8)!)
        
        // Wait for the task to complete (which should trigger cancellation)
        try await messagesTask.value
        
        // Wait a bit for cancellation to propagate
        try await Task.sleep(for: .milliseconds(300))
        
        // Transport should now be stopped due to stream cancellation
        #expect(await transport.state == .disconnected)
    }
    
    @Test("Message Stream Auto Start")
    func messageStreamAutoStart() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        // Don't explicitly start the transport, let messages() do it
        let messagesTask = Task {
            var receivedAny = false
            for try await _ in await transport.messages() {
                receivedAny = true
                break
            }
            return receivedAny
        }
        
        // Give some time for auto-start
        try await Task.sleep(for: .milliseconds(300))
        
        // Transport should be started
        #expect(await transport.state == .connected)
        
        // Send a test message
        try await transport.send("auto-start test".data(using: .utf8)!)
        
        // Verify we received a message
        let receivedAny = try await messagesTask.value
        #expect(receivedAny)
        
        await transport.stop()
    }
    
    @Test("Concurrent Message Sending")
    func concurrentMessageSending() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        try await transport.start()
        
        // Collect messages in the background
        let messagesTask = Task {
            var receivedMessages = [String]()
            for try await data in await transport.messages() {
                if let message = String(data: data, encoding: .utf8) {
                    receivedMessages.append(message)
                    // Break after receiving enough messages
                    if receivedMessages.count >= 10 {
                        break
                    }
                } else {
                    Issue.record("Could not decode message as UTF-8")
                }
            }
            return receivedMessages
        }
        
        // Send multiple messages concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    do {
                        let message = "Concurrent message \(i)"
                        try await transport.send(message.data(using: .utf8)!)
                    } catch {
                        Issue.record("Failed to send concurrent message: \(error)")
                    }
                }
            }
        }
        
        // Wait for messages and verify we got 10
        let receivedMessages = try await messagesTask.value
        #expect(receivedMessages.count == 10)
        
        await transport.stop()
    }
    
    @Test("Reconnection After Failure")
    func reconnectionAfterFailure() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        // First connection
        try await transport.start()
        #expect(await transport.state == .connected)
        
        // Send and receive a message
        let testMessage = "Initial connection"
        try await transport.send(testMessage.data(using: .utf8)!)
        
        // Force stop (simulating failure)
        await transport.stop()
        #expect(await transport.state == .disconnected)
        
        // Reconnect
        try await transport.start()
        #expect(await transport.state == .connected)
        
        // Add a short delay to ensure the process is fully started
        try await Task.sleep(for: .milliseconds(500))
        
        // Verify we can still send/receive
        let messagesTask = Task {
            for try await data in await transport.messages() {
                if let message = String(data: data, encoding: .utf8) {
                    return message
                }
            }
            return ""
        }
        
        let secondMessage = "Reconnected successfully"
        try await transport.send(secondMessage.data(using: .utf8)!)
        
        let received = try await messagesTask.value
        #expect(received == secondMessage)
        
        await transport.stop()
    }
    
    @Test("Reconnection Diagnostics")
    func reconnectionDiagnostics() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(command: scriptPath.path)
        
        print("1. Initial state: \(await transport.state)")
        
        // First connection
        try await transport.start()
        print("2. After first start: \(await transport.state)")
        #expect(await transport.state == .connected)
        
        // Set up a monitoring task to watch state changes
        let monitorTask = Task {
            for i in 1...10 {
                print("Monitor \(i): State = \(await transport.state), isRunning = \(await transport.isRunning)")
                try await Task.sleep(for: .milliseconds(300))
            }
        }
        
        // Send and receive a message
        let testMessage = "Initial connection"
        try await transport.send(testMessage.data(using: .utf8)!)
        print("3. After first message send")
        
        // Force stop
        await transport.stop()
        print("4. After stop: \(await transport.state)")
        #expect(await transport.state == .disconnected)
        
        // Wait to ensure full shutdown
        try await Task.sleep(for: .milliseconds(1000))
        print("5. After delay: \(await transport.state)")
        
        // Reconnect
        try await transport.start()
        print("6. After second start: \(await transport.state)")
        #expect(await transport.state == .connected)
        
        // More extensive wait to ensure startup
        for i in 1...5 {
            print("7.\(i) Waiting: state=\(await transport.state), isRunning=\(await transport.isRunning)")
            try await Task.sleep(for: .milliseconds(300))
        }
        
        // Stream setup
        let messagesStream = await transport.messages()
        print("8. Created message stream")
        Task {
            for try await message in messagesStream {
                print(message)
            }
        }
        
        // Try sending another message
        do {
            let secondMessage = "Reconnected successfully"
            print("9. Attempting to send message: \(secondMessage)")
            try await transport.send(secondMessage.data(using: .utf8)!)
            print("10. Message sent successfully")
        } catch {
            print("10. Failed to send message: \(error)")
            throw error
        }
        
        // Cancel the monitor task
        monitorTask.cancel()
        
        // Clean up
        await transport.stop()
    }
    
    @Test("Large Message Handling")
    func largeMessageHandling() async throws {
        let scriptPath = createEchoScript()
        let transport = StdioTransport(
            command: scriptPath.path,
            configuration: .init(maxMessageSize: 100_000) // Large enough for test
        )
        
        try await transport.start()
        
        // Generate a large but valid message
        let largeMessage = String(repeating: "X", count: 50_000).data(using: .utf8)!
        
        // Collect the response
        let messagesTask = Task {
            for try await data in await transport.messages() {
                return data.count
            }
            return 0
        }
        
        // Send the large message
        try await transport.send(largeMessage)
        
        // Verify we got back a message of the same size
        let receivedSize = try await messagesTask.value
        #expect(receivedSize == largeMessage.count)
        
        await transport.stop()
    }
    
    @Test("Environment Variables")
    func environmentVariables() async throws {
        // Create a script that prints an environment variable
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let scriptPath = tempDir.appendingPathComponent("env_script.sh")
        
        let scriptContent = """
    #!/bin/bash
    echo "TEST_ENV_VAR=$TEST_ENV_VAR"
    """
        
        try? FileManager.default.removeItem(at: scriptPath)
        try! scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        // Create transport with specific environment variables
        let transport = StdioTransport(
            command: scriptPath.path,
            environment: ["TEST_ENV_VAR": "custom_value"]
        )
        
        try await transport.start()
        
        // Collect the response
        let messagesTask = Task {
            for try await data in await transport.messages() {
                if let message = String(data: data, encoding: .utf8) {
                    return message
                }
            }
            return ""
        }
        
        // Verify environment variable was passed correctly
        let received = try await messagesTask.value
        #expect(received == "TEST_ENV_VAR=custom_value")
        
        await transport.stop()
    }
    
    @Test("Error Propagation")
    func errorPropagation() async throws {
        // Create a script that exits with an error after sending a message
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let scriptPath = tempDir.appendingPathComponent("error_script.sh")
        
        let scriptContent = """
    #!/bin/bash
    echo "About to fail"
    sleep 0.2
    exit 1
    """
        
        try? FileManager.default.removeItem(at: scriptPath)
        try! scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        let transport = StdioTransport(command: scriptPath.path)
        
        // Start the messages stream first
        let messagesTask = Task {
            do {
                for try await _ in await transport.messages() {
                    // Just consume messages
                }
                return "Stream completed normally"
            } catch let error as TransportError {
                return "Caught expected error: \(error)"
            } catch {
                return "Caught unexpected error: \(error)"
            }
        }
        
        // Wait for the message stream to complete or error
        let result = await messagesTask.value
        
        // Should contain an error message
        #expect(result.starts(with: "Caught"))
    }
}
