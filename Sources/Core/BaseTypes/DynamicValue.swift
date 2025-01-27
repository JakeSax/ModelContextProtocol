//
//  DynamicValue.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/25/25.
//

import Foundation

/// A flexible data structure for handling various JSON-compatible values within MCP.
public enum DynamicValue: Codable, Sendable {
    
    // MARK: Cases
    case string(String)
    case int(Int)
    case double(Double)
    case dictionary([String: DynamicValue])
    case array([DynamicValue])
    case bool(Bool)
    case null
    
    // MARK: Convenience Initializers
    init(_ string: String) {
        self = .string(string)
    }
    
    init(_ int: Int) {
        self = .int(int)
    }
    
    init(_ double: Double) {
        self = .double(double)
    }
    
    init(_ dictionary: [String: DynamicValue]) {
        self = .dictionary(dictionary)
    }
    
    init(_ array: [DynamicValue]) {
        self = .array(array)
    }
    
    init(_ bool: Bool) {
        self = .bool(bool)
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
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
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Content cannot be decoded"
            )
        }
    }
}

extension DynamicValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension DynamicValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension DynamicValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension DynamicValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension DynamicValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, DynamicValue)...) {
        let dict = Dictionary(uniqueKeysWithValues: elements)
        self = .dictionary(dict)
    }
}

extension DynamicValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: DynamicValue...) {
        self = .array(elements)
    }
}

extension DynamicValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}
