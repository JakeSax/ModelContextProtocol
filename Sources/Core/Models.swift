//
//  Core.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

import Foundation

public typealias ProgressToken = DynamicValue
public typealias Cursor = String

// MARK: Feature Specific Types

/// Represents a request ID, which can be either a string or an integer.
public enum RequestIDValue: Codable, Equatable {
    case int(value: Int)
    case string(value: String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(value: intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(value: stringValue)
        } else {
            throw DecodingError.typeMismatch(RequestIDValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid Request ID type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

/// A flexible data structure for handling various JSON-compatible values within MCP.
public enum DynamicValue: Codable {
    case string(String)
    case integer(Int)
    case double(Double)
    case dictionary([String: DynamicValue])
    case array([DynamicValue])
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if container.decodeNil() {
            self = .null
        } else if let arrayValue = try? container.decode([DynamicValue].self) {
            self = .array(arrayValue)
        } else if let dictionaryValue = try? container.decode([String: DynamicValue].self) {
            self = .dictionary(dictionaryValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Content cannot be decoded")
        }
    }
}

/// Represents the capabilities a client or server can declare.
public struct CapabilityNegotiation: Codable {
    /// The list of features the server or client supports.
    public let supportedFeatures: [String]
    /// The optional name of the server.
    public let serverName: String?
    /// The optional name of the client.
    public let clientName: String?
}

/// Represents an out-of-band progress notification.
public struct ProgressNotification: Codable {
    public var jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/progress"
    public let params: ProgressUpdate
}

/// Represents an initialization request.
public struct InitializeRequest: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let id: RequestIDValue
    public let method: String = "initialize"
    public let params: [String: DynamicValue]
}

/// Represents an initialization result.
public struct InitializeResult: Codable {
    public let protocolVersion: String
    public let capabilities: [String: DynamicValue]
    public let serverInfo: [String: String]
    public let instructions: String?
}

/// Represents an initialization notification.
public struct InitializedNotification: Codable {
    public let jsonrpc: String = JSONRPC.jsonrpcVersion
    public let method: String = "notifications/initialized"
}

/// Represents configuration settings shared between components.
public struct Configuration: Codable {
    public let settings: [String: DynamicValue]
}

/// Provides updates on long-running tasks.
public struct ProgressUpdate: Codable {
    public let progressToken: ProgressToken
    public let progress: Double
}

/// A request to cancel a pending operation.
public struct Cancellation: Codable {
    public let requestId: RequestIDValue
}

