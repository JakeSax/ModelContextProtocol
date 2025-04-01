//
//  MCPClient+Configuration.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/26/25.
//

import Foundation
import MCPCore
import HTTPTypes

public extension MCPClient {
    
    /// Configuration for an MCPClient instance.
    ///
    /// This structure encapsulates all the settings needed to establish and maintain
    /// a connection to an MCP server, including protocol parameters, transport mechanism,
    /// and JSON coding options.
    struct Configuration: Sendable {
        
        // MARK: Properties
        /// Parameters used for initializing the connection with the server.
        ///
        /// These parameters describe the client's capabilities, identity, and supported
        /// protocol version, which are sent to the server during the initialization handshake.
        public let initialization: InitializeRequest.Parameters
        
        /// The transport mechanism used for network communication.
        ///
        /// This transport handles the low-level data transfer between client and server,
        /// abstracting the specific network protocol (e.g., WebSockets, HTTP) from the client.
        let transport: any Transport
        
        /// The encoder used to convert Swift objects to JSON data for transmission.
        ///
        /// Used when sending requests, notifications, and responses to the server.
        let encoder: JSONEncoder
        
        /// The decoder used to convert received JSON data to Swift objects.
        ///
        /// Used when processing messages received from the server.
        let decoder: JSONDecoder
        
        // MARK: Initialization
        /// Creates a new configuration with the specified parameters.
        ///
        /// - Parameters:
        ///   - initialization: The parameters to use when initializing the connection to the server.
        ///   - transport: The transport mechanism to use for communication.
        ///   - encoder: The JSON encoder to use for outgoing messages. Defaults to a new instance.
        ///   - decoder: The JSON decoder to use for incoming messages. Defaults to a new instance.
        public init(
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
}
