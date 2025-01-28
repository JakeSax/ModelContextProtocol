//
//  RequestSerializationTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

import Testing
import Foundation
@testable import MCPCore

struct RequestSerializationTests {

    @Test func encodeCallToolRequest() throws {
        let request = CallToolRequest(
            params: .init(name: "exampleTool", arguments: ["key": "value"])
        )
        let expectedJSON = """
        {
            "method": "tools/call",
            "params": {
                "name": "exampleTool",
                "arguments": {
                    "key": "value"
                }
            }
        }
        """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeCallToolResult() throws {
        let result = CallToolResult(
            content: [],
            isError: false
        )
        let expectedJSON = """
    {
        "content": [],
        "isError": false
    }
    """
        try validateCoding(of: result, matchesJSON: expectedJSON)
    }
    
    @Test func encodeCancelledNotification() throws {
        let notification = CancelledNotification(
            params: .init(requestID: "1234", reason: "Timeout")
        )
        let expectedJSON = """
    {
        "method": "notifications/cancelled",
        "params": {
            "requestId": "1234",
            "reason": "Timeout"
        }
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }
    
    @Test func encodeClientCapabilities() throws {
        let capabilities = ClientCapabilities(
            roots: .init(listChanged: true),
            sampling: [:],
            experimental: [:]
        )
        let expectedJSON = """
    {
        "experimental": {},
        "roots": {
            "listChanged": true
        },
        "sampling": {}
    }
    """
        try validateCoding(of: capabilities, matchesJSON: expectedJSON)
    }
    
    @Test func encodeInitializeRequest() throws {
        let request = InitializeRequest(
            params: .init(
                capabilities: ClientCapabilities(
                    roots: .init(listChanged: true),
                    sampling: [:],
                    experimental: [:]
                ),
                clientInfo: Implementation(name: "TestClient", version: "1.0.0"),
                protocolVersion: "1.0"
            )
        )
        let expectedJSON = """
    {
        "method": "initialize",
        "params": {
            "capabilities": {
                "experimental": {},
                "roots": {
                    "listChanged": true
                },
                "sampling": {}
            },
            "clientInfo": {
                "name": "TestClient",
                "version": "1.0.0"
            },
            "protocolVersion": "1.0"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeCompleteRequest() throws {
        let request = CompleteRequest(
            params: .init(
                argument: .init(name: "query", value: "search term"),
                ref: .prompt(.init(name: "examplePrompt"))
            )
        )
        let expectedJSON = """
    {
        "method": "completion/complete",
        "params": {
            "argument": {
                "name": "query",
                "value": "search term"
            },
            "ref": {
                "type": "ref/prompt",
                "name": "examplePrompt"
            }
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeListToolsRequest() throws {
        let request = ListToolsRequest(
            params: .init(cursor: "nextPageCursor")
        )
        let expectedJSON = """
    {
        "method": "tools/list",
        "params": {
            "cursor": "nextPageCursor"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeGetPromptRequest() throws {
        let request = GetPromptRequest(
            params: .init(name: "examplePrompt", arguments: ["key": "value"])
        )
        let expectedJSON = """
    {
        "method": "prompts/get",
        "params": {
            "name": "examplePrompt",
            "arguments": {
                "key": "value"
            }
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeListPromptsRequest() throws {
        let request = ListPromptsRequest(
            params: .init(cursor: "cursorToken")
        )
        let expectedJSON = """
    {
        "method": "prompts/list",
        "params": {
            "cursor": "cursorToken"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    
    @Test func encodeListResourcesRequest() throws {
        let request = ListResourcesRequest(
            params: .init(cursor: "cursor123")
        )
        let expectedJSON = """
    {
        "method": "resources/list",
        "params": {
            "cursor": "cursor123"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeListResourceTemplatesRequest() throws {
        let request = ListResourceTemplatesRequest(
            params: .init(cursor: "cursor456")
        )
        let expectedJSON = """
    {
        "method": "resources/templates/list",
        "params": {
            "cursor": "cursor456"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeReadResourceRequest() throws {
        let request = ReadResourceRequest(
            params: .init(uri: "https://example.com/resource")
        )
        let expectedJSON = """
    {
        "method": "resources/read",
        "params": {
            "uri": "https://example.com/resource"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeSetLevelRequest() throws {
        let request = SetLevelRequest(
            params: .init(level: .warning)
        )
        let expectedJSON = """
    {
        "method": "logging/setLevel",
        "params": {
            "level": "warning"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodePingRequest() throws {
        let request = PingRequest()
        let expectedJSON = """
    {
        "method": "ping"
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeSubscribeRequest() throws {
        let request = SubscribeRequest(
            params: .init(uri: "https://example.com/data")
        )
        let expectedJSON = """
    {
        "method": "resources/subscribe",
        "params": {
            "uri": "https://example.com/data"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeUnsubscribeRequest() throws {
        let request = UnsubscribeRequest(
            params: .init(uri: "https://example.com/data")
        )
        let expectedJSON = """
    {
        "method": "resources/unsubscribe",
        "params": {
            "uri": "https://example.com/data"
        }
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeListRootsRequest() throws {
        let request = ListRootsRequest()
        let expectedJSON = """
    {
        "method": "roots/list"
    }
    """
        try validateCoding(of: request, matchesJSON: expectedJSON)
    }

}
