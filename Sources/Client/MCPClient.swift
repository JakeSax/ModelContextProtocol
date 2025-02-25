//
//  MCPClient.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation
import MCPCore
import HTTPTypes
import HTTPTypesFoundation
import OSLog

/// A client for communicating with an MCP server using JSON-RPC over HTTP.
///
/// This client converts a generic request into a JSON-RPC formatted message, encodes it,
/// sends it to the specified MCP server URL, and decodes the server's JSON-RPC response.
/// It supports adding custom HTTP header fields and logs significant events and errors.
public class MCPClient {
    
    // MARK: Properties
    
    /// The URL at which the MCP server is located.
    private let serverURL: URL
    /// The URLSession used to perform HTTP requests.
    private let session: URLSession
    /// A JSONDecoder instance for decoding server responses.
    private let decoder: JSONDecoder
    /// A JSONEncoder instance for encoding requests.
    private let encoder: JSONEncoder
    /// A logger for recording events and errors.
    private let logger: Logger
    
    // MARK: Initialization
    
    /// Creates a new MCPClient instance configured to communicate with the MCP server.
    ///
    /// - Parameters:
    ///   - serverURL: The URL where the MCP server is located.
    ///   - session: The URLSession instance to use for network requests. Defaults
    ///    to `.shared`.
    ///   - decoder: The JSONDecoder to use for decoding responses. Defaults to a
    ///    new instance.
    ///   - encoder: The JSONEncoder to use for encoding requests. Defaults to a
    ///   new instance.
    ///   - logger: The OSLog Logger for logging errors and debug information.
    ///    Defaults to a Logger with subsystem `"MCPClient"` and category `serverURL`.
    public init(
        serverURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init(),
        logger: Logger? = nil
    ) {
        self.serverURL = serverURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.logger = logger ?? Logger(subsystem: "MCPClient", category: serverURL.absoluteString)
    }
    
    // MARK: Methods
//    public func beginConnection(additionalHeaders: HTTPFields? = nil) async throws {
//        let response = try await sendRequest(
//            InitializeRequest(
//                params: .init(
//                    capabilities: <#T##ClientCapabilities#>,
//                    clientInfo: <#T##Implementation#>,
//                    protocolVersion: <#T##String#>
//                )
//            ),
//            requestID: 1
//        )
//    }
    
    /// Sends a JSON-RPC request to the MCP server and returns the decoded response.
    ///
    /// This method encodes the provided generic request into a JSON-RPC format, uploads it
    /// to the server using HTTP POST, and attempts to decode the server's response into the
    /// expected response type.
    ///
    /// - Parameters:
    ///   - request: The generic request conforming to `Request` which holds the
    ///   details of the RPC call.
    ///   - requestID: A unique identifier for the request, used to correlate the response.
    ///   - additionalHeaders: Optional HTTP header fields to include in the request.
    ///   These headers will be merged with the default headers.
    /// - Returns: The decoded response of type `R.Response` associated with the
    /// sent request.
    /// - Throws:
    ///   - `URLError.badServerResponse` if the server response status code is not
    ///   in the 200–299 range.
    ///   - `MCPClientError.mismatchedRequestID` if the response contains an ID
    ///   that does not match the provided `requestID`.
    ///   - A `JSONRPCError` if the response indicates an error, or the underlying error
    ///   from decoding fails.
    public func sendRequest<R: Request>(
        _ request: R,
        requestID: RequestID,
        additionalHeaders: HTTPFields? = nil
    ) async throws -> R.Response {
        
        // Convert to JSONRPCRequest and encode it.
        let jsonRPCRequest = try JSONRPCRequest(id: requestID, request: request)
        let requestData = try encoder.encode(jsonRPCRequest)
        
        // Prepare the HTTP request.
        var httpRequest = HTTPRequest(method: .post, url: serverURL)
        if let additionalHeaders {
            httpRequest.headerFields = additionalHeaders
        }
        httpRequest.headerFields[.contentType] = "application/json"
        
        // Upload the request data and retrieve the response.
        let (data, response) = try await session.upload(for: httpRequest, from: requestData)
        
        // Validate the HTTP response status code.
        guard (200...299).contains(response.status.code) else {
            logger.error("MCP Request \(requestID) failed with status code \(response.status.code)")
            throw URLError(.badServerResponse)
        }
        
        do {
            // Attempt to decode the data as a JSONRPCResponse and convert it to the expected result.
            let responseMessage = try decoder.decode(JSONRPCResponse.self, from: data)
            guard responseMessage.id == requestID else {
                logger.error("MCP Request [\(requestID)] received response with mismatched ID: \(responseMessage.id)")
                throw MCPClientError.mismatchedRequestID
            }
            return try responseMessage.asResult(R.Response.self)
        } catch {
            // Attempt to decode a JSONRPCError from the response.
            guard let jsonRCPError = try? decoder.decode(JSONRPCError.self, from: data) else {
                logger.error("Could not decode JSONRPCError from response to Request [\(requestID)], throwing original error: \(error)")
                throw error
            }
            if let errorID = jsonRCPError.id, errorID != requestID {
                logger.error("MCP Request [\(requestID)] received error response with mismatched ID: \(errorID)")
                throw MCPClientError.mismatchedRequestID
            }
            logger.error("Received JSONRPCError in response to Request [\(requestID)]: \(jsonRCPError)")
            throw jsonRCPError
        }
    }
    
    
    // MARK: Data Structures
    
    /// Defines errors that can occur during communication with the MCP server.
    public enum MCPClientError: Error {
        /// Thrown when the response's request ID does not match the ID of the
        /// request sent.
        case mismatchedRequestID
    }
    
}
