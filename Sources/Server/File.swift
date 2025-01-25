//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

///// Handles communication with an MCP server using JSON-RPC over HTTP.
//public class MCPClient {
//    private let serverURL: URL
//    private let session: URLSession
//    
//    public init(serverURL: URL, session: URLSession = .shared) {
//        self.serverURL = serverURL
//        self.session = session
//    }
//    
//    /// Sends a JSON-RPC request to the server and returns a decoded response.
//    public func sendRequest<T: Codable, U: Codable>(
//        _ request: T
//    ) async throws -> U {
//        var urlRequest = URLRequest(url: serverURL)
//        urlRequest.httpMethod = "POST"
//        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestData = try JSONRPCMessageHandler.encode(request)
//        urlRequest.httpBody = requestData
//        
//        let (data, response) = try await session.data(for: urlRequest)
//        
//        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//            throw MCPClientError.invalidResponse
//        }
//        
//        return try JSONRPCMessageHandler.decode(U.self, from: data)
//    }
//}
//
///// Defines errors that can occur in MCPClient.
//public enum MCPClientError: Error {
//    case invalidResponse
//    case encodingFailed
//    case decodingFailed
//}
