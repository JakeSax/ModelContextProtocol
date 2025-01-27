//
//  RequestID.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/25/25.
//

import Foundation

/// Represents a request ID, which can be either a string or an integer.
public typealias RequestID = StringOrIntValue

/// A Codable value that may be a String or an Int.
public enum StringOrIntValue: Codable, Equatable, Sendable {
    
    // MARK: Cases
    case int(Int)
    case string(String)
    
    // MARK: Convenience Initializers
    public init(_ int: Int) {
        self = .int(int)
    }
    
    public init(_ string: String) {
        self = .string(string)
    }
    
    public init(_ uuid: UUID) {
        self = .string(uuid.uuidString)
    }
    
    public init?(_ dynamicValue: DynamicValue) {
        switch dynamicValue {
        case .string(let string): self = .string(string)
        case .int(let int): self = .int(int)
        default: return nil
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                RequestID.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid RequestID ID type"
                )
            )
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

extension StringOrIntValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension StringOrIntValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension StringOrIntValue {
    var dynamicValue: DynamicValue {
        switch self {
        case .int(let int): .int(int)
        case .string(let string): .string(string)
        }
    }
}
