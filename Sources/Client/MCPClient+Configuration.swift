//
//  MCPClient+Configuration.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/26/25.
//

import Foundation
import MCPCore
import HTTPTypes

extension MCPClient {
    public struct Configuration: Sendable {
        nonisolated public let initialization: InitializeRequest.Parameters
        let transport: any Transport
        nonisolated let encoder: JSONEncoder
        nonisolated let decoder: JSONDecoder
        
        init(
            initialization: InitializeRequest.Parameters,
            transport: any Transport,
            encoder: JSONEncoder = JSONEncoder(),
            decoder: JSONDecoder = JSONDecoder()
        ) {
            self.initialization = initialization
            self.transport = transport
            self.encoder = encoder
            self.decoder = decoder
        }
    }
    
    /// The network configuration for the MCPClient.
    public struct NetworkConfiguration: Sendable {
        /// The URL at which the MCP server is located.
        public let serverURL: URL
        /// The URLSession used to perform HTTP requests.
        public let session: URLSession
        /// Any headers to send along with requests, potentially authentication headers.
        public let additionalHeaders: HTTPFields?
        
        /// The network configuration for the MCPClient.
        /// - Parameters:
        ///   - serverURL: The URL where the MCP server is located.
        ///   - session: The URLSession instance to use for network requests. Defaults
        ///    to `.shared`.
        ///   - additionalHeaders: Optional HTTP header fields to include in the request.
        ///   These headers will be merged with the default headers.
        public init(
            serverURL: URL,
            session: URLSession = .shared,
            additionalHeaders: HTTPFields? = nil
        ) {
            self.serverURL = serverURL
            self.session = session
            self.additionalHeaders = additionalHeaders
        }
    }
}
