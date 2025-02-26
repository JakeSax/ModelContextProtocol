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
    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, result, error
    }
    
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Ensure this is a valid JSON-RPC message
        guard let jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc) else {
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
        
        let hasID = container.contains(.id)
        let hasMethod = container.contains(.method)
        
        if hasID, hasMethod {
            // This is a request (has an `id` and `method`)
            self = .request(try JSONRPCRequest(from: decoder))
        } else if hasMethod {
            // This is a notification (has a `method` but no `id`)
            self = .notification(try JSONRPCNotification(from: decoder))
        } else if hasID, container.contains(.result) {
            // This is a response (has an `id` and a `result`)
            self = .response(try JSONRPCResponse(from: decoder))
        } else if hasID, container.contains(.error) {
            // This is an error (has an `id` and an `error` object)
            self = .error(try JSONRPCError(from: decoder))
        } else {
            // Invalid JSON-RPC message
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
