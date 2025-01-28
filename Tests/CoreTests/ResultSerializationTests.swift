//
//  ResultSerializationTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

import Testing
import Foundation
@testable import MCPCore

struct ResultSerializationTests {
    
    /// Tests whether the provided result encodes to and decodes from the expected
    /// JSON representation as well as encoding to and from a `JSONRPCResult`
    /// and tests for equality.
    /// - Parameters:
    ///   - result: The result to test encoding and decoding.
    ///   - expectedJSON: The JSON string that the object should encode to.
    private func validateResultCoding<T: Result>(
        of result: T,
        matchesJSON expectedJSON: String
    ) throws {
        try validateCoding(of: result, matchesJSON: expectedJSON)
        let jsonRPCResponse = try JSONRPCResponse(id: 1, result: result)
        let encodedJSONRPCResponse = try JSONEncoder().encode(jsonRPCResponse)
        let decodedJSONRPCResponse = try JSONDecoder().decode(
            JSONRPCResponse.self,
            from: encodedJSONRPCResponse
        )
        #expect(jsonRPCResponse == decodedJSONRPCResponse)
        
        let decodedResult = try jsonRPCResponse.asResult(T.self)
        #expect(result == decodedResult)
        
        let jsonRPCMessage = JSONRPCMessage.response(jsonRPCResponse)
        let encodedJSONRPCMessage = try JSONEncoder().encode(jsonRPCMessage)
        let decodedRPCMessage = try JSONDecoder().decode(JSONRPCMessage.self, from: encodedJSONRPCMessage)
        #expect(decodedRPCMessage == jsonRPCMessage)
        
        let responseFromMessage = decodedRPCMessage.value as? JSONRPCResponse
        #expect(responseFromMessage == jsonRPCResponse)
    }
    
    @Test func encodeCallToolResult() throws {
        let result = CallToolResult(
            content: [
                .text(.init(text: "Example response"))
            ],
            isError: false
        )
        let expectedJSON = """
    {
        "content": [
            {
                "type": "text",
                "text": "Example response"
            }
        ],
        "isError": false
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }
    
    @Test func encodeCompleteResult() throws {
        let result = CompleteResult(
            completion: .init(
                values: ["completion1", "completion2"],
                hasMore: false,
                total: 2
            )
        )
        let expectedJSON = """
    {
        "completion": {
            "values": ["completion1", "completion2"],
            "total": 2,
            "hasMore": false
        }
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeCreateMessageResult() throws {
        let result = CreateMessageResult(
            content: .text(.init(text: "Generated message")),
            model: "test-model",
            role: .assistant,
            stopReason: "length"
        )
        let expectedJSON = """
    {
        "content": {
            "type": "text",
            "text": "Generated message"
        },
        "model": "test-model",
        "role": "assistant",
        "stopReason": "length"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeGetPromptResult() throws {
        let result = GetPromptResult(
            messages: [
                .init(role: .assistant, content: .text(.init(text: "Prompt content")))
            ],
            description: "Example prompt"
        )
        let expectedJSON = """
    {
        "messages": [
            {
                "role": "assistant",
                "content": {
                    "type": "text",
                    "text": "Prompt content"
                }
            }
        ],
        "description": "Example prompt"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }
    
    @Test func encodeListPromptsResult() throws {
        let result = ListPromptsResult(
            nextCursor: "nextPageToken",
            prompts: [
                .init(name: "prompt1", description: "First prompt"),
                .init(name: "prompt2", description: "Second prompt")
            ]
        )
        let expectedJSON = """
    {
        "prompts": [
            {
                "name": "prompt1",
                "description": "First prompt"
            },
            {
                "name": "prompt2",
                "description": "Second prompt"
            }
        ],
        "nextCursor": "nextPageToken"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeListResourcesResult() throws {
        let result = ListResourcesResult(
            nextCursor: "resourceCursor",
            resources: [
                .init(name: "Resource A", uri: "https://example.com/resourceA"),
                .init(name: "Resource B", uri: "https://example.com/resourceB")
            ]
        )
        let expectedJSON = """
    {
        "resources": [
            {
                "name": "Resource A",
                "uri": "https://example.com/resourceA"
            },
            {
                "name": "Resource B",
                "uri": "https://example.com/resourceB"
            }
        ],
        "nextCursor": "resourceCursor"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeListResourceTemplatesResult() throws {
        let result = ListResourceTemplatesResult(
            nextCursor: "templateCursor",
            resourceTemplates: [
                .init(name: "Template A", uriTemplate: "https://example.com/templateA"),
                .init(name: "Template B", uriTemplate: "https://example.com/templateB")
            ]
        )
        let expectedJSON = """
    {
        "resourceTemplates": [
            {
                "name": "Template A",
                "uriTemplate": "https://example.com/templateA"
            },
            {
                "name": "Template B",
                "uriTemplate": "https://example.com/templateB"
            }
        ],
        "nextCursor": "templateCursor"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    
    @Test func encodeListToolsResult() throws {
        let result = ListToolsResult(
            nextCursor: "toolsCursor",
            tools: [
                .init(name: "Tool A", inputSchema: .init(properties: [:], required: [])),
                .init(name: "Tool B", inputSchema: .init(properties: [:], required: []))
            ]
        )
        let expectedJSON = """
    {
        "tools": [
            {
                "name": "Tool A",
                "inputSchema": {
                    "properties": {},
                    "required": [],
                    "type": "object"
                }
            },
            {
                "name": "Tool B",
                "inputSchema": {
                    "properties": {},
                    "required": [],
                    "type": "object"
                }
            }
        ],
        "nextCursor": "toolsCursor"
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeReadResourceResult() throws {
        let result = ReadResourceResult(
            contents: [
                .text(.init(text: "Resource content", uri: "https://example.com/resource"))
            ]
        )
        let expectedJSON = """
    {
        "contents": [
            {
                "text": "Resource content",
                "uri": "https://example.com/resource"
            }
        ]
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeListRootsResult() throws {
        let result = ListRootsResult(
            roots: [
                .init(uri: "file:///Users/example/"),
                .init(uri: "file:///Users/another/")
            ]
        )
        let expectedJSON = """
    {
        "roots": [
            {
                "uri": "file:///Users/example/"
            },
            {
                "uri": "file:///Users/another/"
            }
        ]
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

    @Test func encodeInitializeResult() throws {
        let result = InitializeResult(
            capabilities: .init(),
            protocolVersion: "1.0",
            serverInfo: .init(name: "TestServer", version: "1.0.0"),
            instructions: "Welcome to the server."
        )
        let expectedJSON = """
    {
        "capabilities": {},
        "protocolVersion": "1.0",
        "serverInfo": {
            "name": "TestServer",
            "version": "1.0.0"
        },
        "instructions": "Welcome to the server."
    }
    """
        try validateResultCoding(of: result, matchesJSON: expectedJSON)
    }

}
