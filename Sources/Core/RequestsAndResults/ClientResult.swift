//
//  ClientResult.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// An enumeration of all the possible client results.
///
/// For optimal performance, avoid decoding values directly as `ClientResult`. Since results
/// lack type identifiers, decoding requires attempting each possible case until a match is found.
/// Instead, when the expected result type is known, decode directly to that specific type
/// (e.g., `CreateMessageResult`, `ListRootsResult`).
///
/// Example:
/// ```swift
/// // Less efficient:
/// let clientResult = try decoder.decode(ClientResult.self, from: data)
///
/// // More efficient, when type is known:
/// let createMessageResult = try decoder.decode(CreateMessageResult.self, from: data)
/// ```
public enum ClientResult: Codable, Sendable {
    
    case result(AnyResult)
    case createMessage(CreateMessageResult)
    case listRoots(ListRootsResult)
    
    public var result: any MCPCore.Result {
        switch self {
        case .result(let anyResult): anyResult
        case .createMessage(let createMessageResult): createMessageResult
        case .listRoots(let listRootsResult): listRootsResult
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let createMessage = try? container.decode(CreateMessageResult.self) {
            self = .createMessage(createMessage)
        } else if let listRoots = try? container.decode(ListRootsResult.self) {
            self = .listRoots(listRoots)
        } else if let result = try? container.decode(AnyResult.self) {
            self = .result(result)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid client result type"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .result(let result):
            try container.encode(result)
        case .createMessage(let createMessage):
            try container.encode(createMessage)
        case .listRoots(let listRoots):
            try container.encode(listRoots)
        }
    }
}
