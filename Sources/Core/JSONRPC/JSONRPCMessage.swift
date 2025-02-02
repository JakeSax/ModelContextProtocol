//
//  JSONRPCMessage.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//

public enum JSONRPCMessage: Codable, Sendable, Equatable, CustomDebugStringConvertible {
    case request(JSONRPCRequest)
    case notification(JSONRPCNotification)
    case response(JSONRPCResponse)
    case error(JSONRPCError)
    
    /// The associated value with the case.
    public var value: any AnyJSONRPCMessage {
        switch self {
        case .request(let request): request
        case .notification(let notification): notification
        case .response(let response): response
        case .error(let error): error
        }
    }
    
    private var caseDescription: String {
        switch self {
        case .request(_): "Request"
        case .notification(_): "Notification"
        case .response(_): "Response"
        case .error(_): "Error"
        }
    }
    
    public var debugDescription: String {
        "\(caseDescription): \(value.debugDescription)"
    }
    
    // MARK: Codable Conformance
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .request(let request): try container.encode(request)
        case .notification(let notification): try container.encode(notification)
        case .response(let response): try container.encode(response)
        case .error(let error): try container.encode(error)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let jsonObject = try container.decode([String: DynamicValue].self)
        
        // Ensure this is a valid JSON-RPC message
        guard let jsonrpc = jsonObject["jsonrpc"]?.stringValue else {
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Missing JSON-RPC version",
                    data: nil
                )
            )
        }
        guard jsonrpc == JSONRPC.jsonrpcVersion else {
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Invalid JSON-RPC version",
                    data: nil
                )
            )
        }
        
        let hasID = jsonObject["id"] != nil
        let hasMethod = jsonObject["method"] != nil
        if hasID, hasMethod {
            // This is a **request** (has an `id` and `method`)
            self = .request(try container.decode(JSONRPCRequest.self))
        } else if hasMethod {
            // This is a **notification** (has a `method` but no `id`)
            self = .notification(try container.decode(JSONRPCNotification.self))
        } else if hasID, jsonObject["result"] != nil {
            // This is a **response** (has an `id` and a `result`)
            self = .response(try container.decode(JSONRPCResponse.self))
        } else if hasID, jsonObject["error"] != nil {
            // This is an **error** response (has an `id` and an `error` object)
            self = .error(try container.decode(JSONRPCError.self))
        } else {
            // The JSON structure doesn’t match any valid JSON-RPC message type
            throw JSONRPCError(
                id: -1,
                error: .init(
                    code: -32600,
                    message: "Invalid JSON-RPC message",
                    data: nil
                )
            )
        }
    }
}
