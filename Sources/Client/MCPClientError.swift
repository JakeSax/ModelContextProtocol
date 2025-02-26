//
//  MCPClientError.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/26/25.
//

import Foundation
import MCPCore

extension MCPClient {
    /// Defines errors that can occur during communication with the MCP server.
    public enum MCPClientError: Error {
        /// Thrown when the response's request ID does not match the ID of any
        /// requests sent.
        case mismatchedRequestID
        
        /// The JSON-RPC version received from the server is not supported by
        /// the client.
        case unsupportedJSONRPCVersion
        
        /// The client's transport is not connected.
        case transportNotConnected
        
        /// The client is not connected and cannot perform an action
        case notConnected
        
        case unknownRequestMethod(String)
        
        case unknownNotificationMethod(String)
        
        /// A client request was attempted to be sent that was already pending a
        /// response.
        case duplicateRequestID(RequestID)
        
        case noResponse(forRequestID: RequestID)
        
        case unsupportedCapability(method: ServerRequest.Method)
    }
}
