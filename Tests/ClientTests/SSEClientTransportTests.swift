//
//  SSEClientTransportTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/25/25.
//

import Foundation
import Testing
@testable import MCPCore
@testable import MCPClient

@Suite("SSEClientTransportTests")
struct SSEClientTransportTests {
    
    @Test("Initialization sets correct properties")
    func testInitialization() async {
        let sseURL = URL(string: "https://example.com/events")!
        let config = TransportConfiguration(
            connectTimeout: .seconds(10),
            sendTimeout: .seconds(5)
        )
        
        let transport = SSEClientTransport(
            networkConfiguration: SSEClientTransport.NetworkConfiguration(
                serverURL: sseURL
            ),
            transportConfiguration: config
        )
        
        #expect(await transport.state == .disconnected)
        #expect(await transport.configuration.connectTimeout == .seconds(10))
        #expect(await transport.configuration.sendTimeout == .seconds(5))
    }
    
    @Test("Parses SSE lines correctly")
    func testSSELineParsing() {
        // Test the static parse method
        let eventLine = SSELine.parse("event: message")
        if case .event(let type) = eventLine {
            #expect(type == "message")
        } else {
            Issue.record("Should have parsed as event")
        }
        
        let dataLine = SSELine.parse("data: {\"key\":\"value\"}")
        if case .data(let data) = dataLine,
            let str = String(data: data, encoding: .utf8) {
            #expect(str == "{\"key\":\"value\"}")
        } else {
            Issue.record("Should have parsed as data")
        }
        
        let emptyLine = SSELine.parse("")
        if case .empty = emptyLine {
            #expect(true)
        } else {
            Issue.record("Should have parsed as empty")
        }
    }
    
//    @Test("Discovers POST URL from endpoint event")
//    func testPostURLDiscovery() async throws {
//        // Setup mock session with SSE stream that sends an endpoint event
//        let endpointData = "api/v1/post".data(using: .utf8)!
//        let mockLines = [
//            "event: endpoint",
//            "data: api/v1/post",
//            "" // Empty line to end event
//        ]
//        
//        let bytesStream = URLSession.AsyncBytes.mock(with: mockLines)
//        let response = HTTPURLResponse(
//            url: URL(string: "https://example.com/events")!,
//            statusCode: 200,
//            httpVersion: nil,
//            headerFields: nil
//        )!
//        
//        let mockSession = MockURLSession(
//            bytesTaskResult: (bytesStream, response)
//        )
//        
//        // Create transport with mock session
//        let transport = SSEClientTransport(
//            sseURL: URL(string: "https://example.com/events")!,
//            session: mockSession
//        )
//        
//        // Start the transport and wait for it to process the event
//        try await transport.start()
//        
//        // Give time for the actor to process the event
//        try await Task.sleep(for: .milliseconds(100))
//        
//        // Verify the POST URL was discovered
//        let discoveredURL = await transport.postURL
//        #expect(discoveredURL?.absoluteString == "https://example.com/api/v1/post")
//    }
//    
//    @Test("Handles connection errors appropriately")
//    func testConnectionError() async {
//        // Create a mock session that returns an error
//        let mockError = NSError(domain: "com.test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
//        let mockSession = MockURLSession(error: mockError)
//        
//        let transport = SSEClientTransport(
//            sseURL: URL(string: "https://example.com/events")!,
//            session: mockSession
//        )
//        
//        do {
//            try await transport.start()
//            Issue.record("Expected error was not thrown")
//        } catch {
//            // Check if the error is propagated
//            #expect(error.localizedDescription.contains("Connection failed"))
//            
//            // Verify the transport is in failed state
//            let state = transport.state
//            if case .failed(let stateError) = state {
//                #expect(stateError.localizedDescription.contains("Connection failed"))
//            } else {
//                Issue.record("Transport should be in failed state")
//            }
//        }
//    }
//    
//    @Test("Sends data successfully")
//    func testSendData() async throws {
//        // Create mock session that returns success for POST
//        let mockSession = MockURLSession(
//            dataTaskResult: (Data(), HTTPURLResponse(url: URL(string: "https://example.com/post")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
//        )
//        
//        let transport = SSEClientTransport(
//            sseURL: URL(string: "https://example.com/events")!,
//            postURL: URL(string: "https://example.com/post")!,
//            session: mockSession
//        )
//        
//        // Test sending data
//        let testData = "{\"message\":\"test\"}".data(using: .utf8)!
//        try await transport.send(testData)
//        
//        // If we get here without error, the test passes
//        #expect(true, "Data sent successfully")
//    }
//    
//    @Test("Processes SSE message events correctly")
//    func testSSEMessageProcessing() async throws {
//        // Setup mock SSE stream with message events
//        let messageData = "{\"type\":\"message\",\"content\":\"Hello\"}".data(using: .utf8)!
//        let mockLines = [
//            "event: message",
//            "data: {\"type\":\"message\",\"content\":\"Hello\"}",
//            "", // Empty line to end event
//            "event: message",
//            "data: {\"type\":\"message\",\"content\":\"World\"}",
//            "" // Empty line to end event
//        ]
//        
//        let bytesStream = URLSession.AsyncBytes.mock(with: mockLines)
//        let response = HTTPURLResponse(
//            url: URL(string: "https://example.com/events")!,
//            statusCode: 200,
//            httpVersion: nil,
//            headerFields: nil
//        )!
//        
//        let mockSession = MockURLSession(
//            bytesTaskResult: (bytesStream, response)
//        )
//        
//        // Create transport with mock session
//        let transport = SSEClientTransport(
//            sseURL: URL(string: "https://example.com/events")!,
//            session: mockSession
//        )
//        
//        // Start transport and collect messages
//        try await transport.start()
//        
//        var receivedMessages: [Data] = []
//        
//        // Create a task to collect messages
//        let collectTask = Task {
//            do {
//                for try await message in transport.messages() {
//                    receivedMessages.append(message)
//                    if receivedMessages.count >= 2 {
//                        break
//                    }
//                }
//            } catch {
//                Issue.record("Message stream failed: \(error)")
//            }
//        }
//        
//        // Wait for messages to be processed
//        try await Task.sleep(for: .milliseconds(300))
//        collectTask.cancel()
//        
//        // Verify received messages
//        #expect(receivedMessages.count == 2)
//        if let firstMessage = String(data: receivedMessages[0], encoding: .utf8) {
//            #expect(firstMessage.contains("Hello"))
//        }
//        if let secondMessage = String(data: receivedMessages[1], encoding: .utf8) {
//            #expect(secondMessage.contains("World"))
//        }
//    }
//    
//    @Test("Respects timeout settings")
//    func testTimeout() async {
//        // Create a transport with a very short timeout
//        let config = TransportConfiguration(
//            sendTimeout: .milliseconds(10)
//        )
//        
//        // Create a mock session with a "hanging" request that never completes
//        let mockSession = MockURLSession()
//        mockSession.dataTaskResult = {
//            // Simulate a request that never completes
//            await withCheckedContinuation { continuation in
//                // This continuation is purposely never resumed
//            }
//        }()
//        
//        let transport = SSEClientTransport(
//            sseURL: URL(string: "https://example.com/events")!,
//            postURL: URL(string: "https://example.com/post")!,
//            configuration: config,
//            session: mockSession
//        )
//        
//        // Attempt to send data which should time out
//        #expect(performing: {
//            try await transport.send("test".data(using: .utf8)!)
//        }, throws: { error in
//            guard let timeoutError = error as? TransportError, case .timeout(_) = timeoutError else {
//                return false
//            }
//            return true
//        })
//    }
//    
    @Test("Maintains actor isolation")
    func testActorIsolation() async {
        let transport = SSEClientTransport(
            url: URL(string: "https://example.com/events")!
        )
        
        // Create multiple tasks that concurrently interact with the transport
        let task1 = Task {
            try? await transport.start()
        }
        
        let task2 = Task {
            await transport.stop()
        }
        
        let task3 = Task {
            _ = await transport.state
        }
        
        // Wait for all tasks to complete
        await task1.value
        await task2.value
        await task3.value
        
        // If we get here without crashes, isolation is working
        #expect(true, "Actor isolation is maintained")
    }
}

//@Suite("SSEClientTransport Tests", .serialized)
//struct SSEClientTransportTests {
//    
//    /// ../../../
//    private var repoRootPath: URL {
//        URL(fileURLWithPath: #filePath)
//            .deletingLastPathComponent()
//            .deletingLastPathComponent()
//            .deletingLastPathComponent()
//    }
//    
//    /// <REPO>/JS/sse.js
//    private var sseScriptPath: String {
//        repoRootPath.appendingPathComponent("JS/sse.js").path
//    }
//    
//    /// Must match the setup from JS
//    private let sseServerEndpoint = URL(string: "http://127.0.0.1:3000/sse")!
//    
//    private func spawnSSEServer() -> StdioTransport {
//        StdioTransport(
//            options: .init(
//                command: "node",
//                arguments: [sseScriptPath],
//                environment: ProcessInfo.processInfo.environment
//            )
//        )
//    }
//    
//    @Test("Connects to dummy SSE server, receives endpoint event, sets postEndpoint")
//    func testConnectionAndEndpoint() async throws {
//        let server = spawnSSEServer()
//        
//        let serverLogsTask = Task {
//            for try await line in await server.messages() {
//                print("Server Log:", String(data: line, encoding: .utf8) ?? "<nil>")
//            }
//        }
//        
//        try await server.start()
//        // wait a sec
//        try await Task.sleep(for: .milliseconds(500))
//        
//        let sseTransport = SSEClientTransport(
//            sseURL: sseServerEndpoint,
//            configuration: .default
//        )
//        
//        var receivedMessages = [Data]()
//        let messagesTask = Task {
//            for try await msg in await sseTransport.messages() {
//                receivedMessages.append(msg)
//            }
//        }
//        
//        try await Task.sleep(for: .seconds(1))
//        
//        // We expect the SSE server to send an "endpoint" event with data: <postURL>.
//        // SSEClientTransport should set `postEndpoint` from that event.
//        let postEndpoint = await sseTransport.postURL
//        #expect(postEndpoint != nil)  // We should have discovered the endpoint
//        #expect(await sseTransport.state == .connected)
//        
//        // 🧹💨💨
//        await sseTransport.stop()
//        await server.stop()
//        try await messagesTask.value
//        serverLogsTask.cancel()
//    }
//    
//    @Test("Sends data to SSE server; receives no immediate errors")
//    func testDataTransfer() async throws {
//        let server = spawnSSEServer()
//        let serverLogsTask = Task {
//            for try await line in await server.messages() {
//                print("Server Log:", String(data: line, encoding: .utf8) ?? "<nil>")
//            }
//        }
//        
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(500))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        
//        let messagesTask = Task {
//            for try await _ in await sseTransport.messages() { }
//        }
//        
//        // Wait for the "endpoint" event to set postEndpoint
//        try await Task.sleep(for: .seconds(1))
//        let postURL = await sseTransport.postURL
//        #expect(postURL != nil)
//        
//        let testMessage = Data(#"{"hello":"world"}"#.utf8)
//        do {
//            try await sseTransport.send(testMessage)
//            // we dont care what was returned just that the fact that it succeeded
//        } catch {
//            Issue.record("Sending data threw an error: \(error)")
//        }
//        
//        await sseTransport.stop()
//        await server.stop()
//        try await messagesTask.value
//        serverLogsTask.cancel()
//    }
//    
//    @Test("Handles server close/disconnect gracefully")
//    func testServerDisconnection() async throws {
//        let server = spawnSSEServer()
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(300))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        let messagesTask = Task {
//            for try await _ in await sseTransport.messages() { }
//        }
//        
//        try await Task.sleep(for: .milliseconds(500))
//        #expect(await sseTransport.state == .connected)
//        
//        // STOP 🛑
//        await server.stop()
//        
//        // hold-up
//        try await Task.sleep(for: .seconds(1))
//        
//        #expect(true, "No crash or exception means success.")
//        
//        await sseTransport.stop()
//        try await messagesTask.value
//    }
//    
//    @Test("Can reconnect after stopping SSEClientTransport")
//    func testReconnection() async throws {
//        let server = spawnSSEServer()
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(300))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        
//        let firstSessionTask = Task {
//            for try await _ in await sseTransport.messages() {}
//        }
//        
//        try await Task.sleep(for: .milliseconds(500))
//        #expect(await sseTransport.state == .connected)
//        
//        await sseTransport.stop()
//        #expect(await sseTransport.state == .disconnected)
//        
//        let secondSessionTask = Task {
//            for try await _ in await sseTransport.messages() {}
//        }
//        
//        try await Task.sleep(for: .milliseconds(500))
//        #expect(await sseTransport.state == .connected)
//        
//        // Cleanup
//        await sseTransport.stop()
//        await server.stop()
//        try await firstSessionTask.value
//        try await secondSessionTask.value
//    }
//    
//    @Test("Handles server changing the post endpoint mid-connection")
//    func testEndpointChangeEvent() async throws {
//        let server = spawnSSEServer()
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(300))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        let messagesTask = Task {
//            for try await _ in await sseTransport.messages() {}
//        }
//        
//        try await Task.sleep(for: .seconds(1))
//        let firstEndpoint = await sseTransport.postURL
//        #expect(firstEndpoint != nil, "First endpoint is set")
//        
//        do {
//            // trigger endpoint change
//            try await sseTransport.send(Data(#"client::changeEndpoint"#.utf8))
//        } catch { }
//        
//        try await Task.sleep(for: .seconds(3))
//        let secondEndpoint = await sseTransport.postURL
//        #expect(secondEndpoint != nil, "Second endpoint is set or remains unchanged")
//        #expect(firstEndpoint != secondEndpoint, "Endpoints are the same. they should have updated.")
//        
//        // Cleanup
//        await sseTransport.stop()
//        await server.stop()
//        try await messagesTask.value
//    }
//    
//    @Test("Handles error response from the server for data send")
//    func testDataSendError() async throws {
//        let server = spawnSSEServer()
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(300))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        let messagesTask = Task {
//            for try await _ in await sseTransport.messages() {}
//        }
//        
//        try await Task.sleep(for: .seconds(1))
//        let postURL = await sseTransport.postURL
//        #expect(postURL != nil)
//        
//        // trigger 5XX on post
//        let badData = Data(#"client::badMessage"#.utf8)
//        do {
//            try await sseTransport.send(badData)
//            Issue.record("Expected an error but got none")
//        } catch {
//            #expect(true)
//        }
//        
//        await sseTransport.stop()
//        await server.stop()
//        try await messagesTask.value
//    }
//    
//    @Test("Handles forced server close/disconnect gracefully")
//    func testServerDisconnect() async throws {
//        let server = spawnSSEServer()
//        let serverLogsTask = Task {
//            for try await line in await server.messages() {
//                print("Server Log:", String(data: line, encoding: .utf8) ?? "<nil>")
//            }
//        }
//        
//        try await server.start()
//        try await Task.sleep(for: .milliseconds(300))
//        
//        let sseTransport = SSEClientTransport(sseURL: sseServerEndpoint)
//        let messagesTask = Task {
//            for try await line in await sseTransport.messages() {
//                print("Server Log:", String(data: line, encoding: .utf8) ?? "<nil>")
//            }
//        }
//        
//        try await Task.sleep(for: .seconds(1))
//        let postURL = await sseTransport.postURL
//        #expect(postURL != nil)
//        
//        let disconnectMsg = Data(#"client::disconnect"#.utf8)
//        try? await sseTransport.send(disconnectMsg)
//        
//        do {
//            try await messagesTask.value
//            #expect(true, "server disconnect should not throw")
//            #expect(await sseTransport.state == .disconnected)
//        } catch {
//            Issue.record("server side initiated disconnect should not throw, it should be handled the same as client initiated disconnect")
//        }
//        
//        await sseTransport.stop()
//        await server.stop()
//        serverLogsTask.cancel()
//    }
//}
