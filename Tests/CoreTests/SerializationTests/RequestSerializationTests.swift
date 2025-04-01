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
    
    /// Tests whether the provided request encodes to and decodes from the expected
    /// JSON representation as well as encoding to and from a `JSONRPCRequest`
    /// and tests for equality.
    /// - Parameters:
    ///   - request: The request to test encoding and decoding.
    ///   - expectedJSON: The JSON string that the object should encode to.
    private func validateRequestCoding<T: Request>(
        of request: T,
        matchesJSON expectedJSON: String
    ) throws {
        try validateCoding(of: request, matchesJSON: expectedJSON)
        let jsonRPCRequest = try JSONRPCRequest(id: 1, request: request)
        let encodedJSONRPCRequest = try JSONEncoder().encode(jsonRPCRequest)
        let decodedJSONRPCRequest = try JSONDecoder().decode(
            JSONRPCRequest.self,
            from: encodedJSONRPCRequest
        )
        #expect(jsonRPCRequest == decodedJSONRPCRequest)
        
        let decodedRequest = try jsonRPCRequest.asRequest(T.self)
        #expect(request == decodedRequest)
        
        let jsonRPCMessage = JSONRPCMessage.request(jsonRPCRequest)
        let encodedJSONRPCMessage = try JSONEncoder().encode(jsonRPCMessage)
        let decodedRPCMessage = try JSONDecoder().decode(JSONRPCMessage.self, from: encodedJSONRPCMessage)
        #expect(decodedRPCMessage == jsonRPCMessage)
        
        let requestFromMessage = decodedRPCMessage.value as? JSONRPCRequest
        #expect(requestFromMessage == jsonRPCRequest)
    }
    
    @Test func encodeDefaultRequestParameters() throws {
        let parameters = DefaultRequestParameters()
        let encoded = try JSONEncoder().encode(parameters)
        let decodedParameters = try JSONDecoder().decode(DefaultRequestParameters.self, from: encoded)
        #expect(parameters == decodedParameters)
    }

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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
    }
    
    @Test func encodeInitializeRequest() throws {
        let request = InitializeRequest(
            params: .init(
                capabilities: ClientCapabilities(
                    roots: .init(listChanged: true),
                    supportsSampling: true,
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodePingRequest() throws {
        let request = ServerPingRequest()
        let expectedJSON = """
    {
        "method": "ping"
    }
    """
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
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
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
    }

    @Test func encodeListRootsRequest() throws {
        let request = ListRootsRequest()
        let expectedJSON = """
    {
        "method": "roots/list"
    }
    """
        try validateRequestCoding(of: request, matchesJSON: expectedJSON)
    }

}
