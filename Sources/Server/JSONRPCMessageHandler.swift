//
//  JSONRPCMessageHandler.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation
import MCPCore

/// Handles parsing and routing JSON-RPC messages
struct JSONRPCMessageHandler {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    /// Processes a raw JSON-RPC payload and determines the response
    func handleMessage(_ data: Data) async throws -> JSONRPCMessage {
        try decoder.decode(JSONRPCMessage.self, from: data)
    }
    
    /// Handles an RPC request and returns a response
//    private func handleRequest<T: Request>(_ request: JSONRPCRequest<T>) async throws -> JSONRPCResponse<T.Response> {
//        guard request.method == T.method else {
//            throw JSONRPCErrorResponse.ErrorDetail(code: -32601, message: "Method not found")
//        }
//        let result = try await execute(request)
//        return JSONRPCResponse(id: request.id, result: result)
//    }
//    
//    /// Processes notifications (fire-and-forget, no response)
//    private func handleNotification<T: Request>(_ notification: JSONRPCNotification<T>) async throws {
//        guard notification.method == T.method else {
//            return // Ignore unknown notifications
//        }
//        try await execute(notification)
//    }
//    
//    /// Placeholder for executing request logic
//    private func execute<T: Request>(_ request: JSONRPCRequest<T>) async throws -> T.Response {
//        fatalError("Implement request execution logic")
//    }
//    
//    private func execute<T: Request>(_ notification: JSONRPCNotification<T>) async throws {
//        fatalError("Implement notification handling logic")
//    }
}
