//
//  JSONRPCMessageSerializationTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

import Testing
import Foundation
@testable import MCPCore

struct JSONRPCMessageSerializationTests {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func verifyJSONRPCCodaable() throws {
        
    }
    
    @Test func encodeDecodeRequest() throws {
        let request = JSONRPCRequest(
            id: 1,
            method: "testMethod",
            params: ["key": .string("value")]
        )
        let message = JSONRPCMessage.request(request)
        
        let data = try encoder.encode(message)
        let decodedMessage = try decoder.decode(JSONRPCMessage.self, from: data)
        
        if case .request(let decodedRequest) = decodedMessage {
            #expect(decodedRequest.id == request.id)
            #expect(decodedRequest.method == request.method)
            #expect(decodedRequest.params?["key"]?.stringValue == "value")
        } else {
            Issue.record("Decoded message is not a request")
        }
    }
    
    @Test func encodeDecodeNotification() throws {
        
        let notification = JSONRPCNotification(
            method: "notifyMethod",
            params: ["flag": .bool(true)]
        )
        let message = JSONRPCMessage.notification(notification)
        
        let data = try encoder.encode(message)
        let decodedMessage = try decoder.decode(JSONRPCMessage.self, from: data)
        
        if case .notification(let decodedNotification) = decodedMessage {
            #expect(decodedNotification.method == notification.method)
            #expect(decodedNotification.params?["flag"]?.boolValue == true)
        } else {
            Issue.record("Decoded message is not a notification")
        }
    }
    
    @Test func encodeDecodeResponse() throws {
        let response = JSONRPCResponse(id: 1, result: .int(42))
        let message = JSONRPCMessage.response(response)
        
        let data = try encoder.encode(message)
        let decodedMessage = try decoder.decode(JSONRPCMessage.self, from: data)
        
        if case .response(let decodedResponse) = decodedMessage {
            #expect(decodedResponse.id == response.id)
            #expect(decodedResponse.result.intValue == 42)
        } else {
            Issue.record("Decoded message is not a response")
        }
    }
    
    @Test func encodeDecodeError() throws {
        let errorDetail = JSONRPCError.ErrorDetails(
            code: -32600,
            message: "Invalid Request",
            data: nil
        )
        let error = JSONRPCError(id: 1, error: errorDetail)
        let message = JSONRPCMessage.error(error)
        
        let data = try encoder.encode(message)
        let decodedMessage = try decoder.decode(JSONRPCMessage.self, from: data)
        
        if case .error(let decodedError) = decodedMessage {
            #expect(decodedError.id == error.id)
            #expect(decodedError.error.code == errorDetail.code)
            #expect(decodedError.error.message == errorDetail.message)
        } else {
            Issue.record("Decoded message is not an error")
        }
    }
    
    @Test func invalidJSONRPCVersion() throws {
        let invalidJSON = """
        {
            "jsonrpc": "2.1", 
            "id": 1, 
            "method": "testMethod"
        }
        """.data(using: .utf8)!
        
        
        #expect(performing: {
            try decoder.decode(JSONRPCMessage.self, from: invalidJSON)
        }, throws: { error in
            if let rpcError = error as? JSONRPCError {
                #expect(rpcError.error.code == -32600)
                #expect(rpcError.error.message == "Invalid JSON-RPC version")
                return true
            } else {
                return false
            }
        })
    }
    
    @Test func invalidMessageStructure() throws {
        let invalidJSON = """
        {
            "randomField": "someValue"
        }
        """.data(using: .utf8)!
        
        #expect(performing: {
            try decoder.decode(JSONRPCMessage.self, from: invalidJSON)
        }, throws: { error in
            if let rpcError = error as? JSONRPCError {
                #expect(rpcError.error.code == -32600)
                #expect(rpcError.error.message == "Missing JSON-RPC version")
                return true
            } else {
                return false
            }
        })
    }
}
