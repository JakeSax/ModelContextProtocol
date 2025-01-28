//
//  DynamicValue.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/25/25.
//

import Foundation

/// A flexible data structure for handling various JSON-compatible values within MCP.
public enum DynamicValue: Codable, Sendable, Equatable {
    
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
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string): try container.encode(string)
        case .int(let int): try container.encode(int)
        case .double(let double): try container.encode(double)
        case .dictionary(let (dictionary)): try container.encode(dictionary)
        case .array(let array): try container.encode(array)
        case .bool(let bool): try container.encode(bool)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: More Convenience Initializers
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

// MARK: Serialization Extensions
extension DynamicValue {
    /// Converts this DynamicValue to another Codable type through JSON encoding/decoding.
    ///
    /// Use this method to safely convert a DynamicValue instance to any type that conforms
    /// to Decodable:
    /// ```swift
    /// let params = try dynamicValue.to(ResourceParams.self)
    /// ```
    ///
    /// - Parameter type: The type to convert this value to.
    /// - Returns: The converted value of the specified type.
    /// - Throws: DecodingError if the conversion fails or the data is invalid for the target type.
    public func to<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Creates a DynamicValue from any Encodable type through JSON encoding/decoding.
    ///
    /// Use this method to convert any Encodable type into a DynamicValue:
    /// ```swift
    /// let dynamic = try DynamicValue.from(params)
    /// ```
    ///
    /// - Parameter value: The value to convert to DynamicValue.
    /// - Returns: A new DynamicValue representing the input.
    /// - Throws: EncodingError if the value cannot be encoded to JSON.
    public static func from<T: Encodable>(_ value: T) throws -> DynamicValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(DynamicValue.self, from: data)
    }
}

extension [String: DynamicValue] {
    /// Converts this dictionary to another Codable type through JSON encoding/decoding.
    ///
    /// Use this method to convert a dictionary of DynamicValues to any type that conforms
    /// to Decodable:
    /// ```swift
    /// let params = try dynamicDict.to(ResourceParams.self)
    /// ```
    ///
    /// - Parameter type: The type to convert this dictionary to.
    /// - Returns: The converted value of the specified type.
    /// - Throws: DecodingError if the conversion fails or the data is invalid for the target type.
    public func to<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Creates a dictionary of DynamicValues from any Encodable type through JSON encoding/decoding.
    ///
    /// Use this method to convert any Encodable type into a dictionary of DynamicValues:
    /// ```swift
    /// let dict = try [String: DynamicValue].from(params)
    /// ```
    ///
    /// - Parameter value: The value to convert to a dictionary.
    /// - Returns: A new dictionary containing DynamicValues representing the input.
    /// - Throws: EncodingError if the value cannot be encoded to JSON.
    public static func from<T: Encodable>(_ value: T) throws -> [String: DynamicValue] {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode([String: DynamicValue].self, from: data)
    }
}

public extension Encodable {
    /// Converts this value to a DynamicValue representation.
    ///
    /// Use this method to easily convert any Encodable type to a DynamicValue:
    /// ```swift
    /// let dynamicValue = try params.toDynamicValue()
    /// ```
    ///
    /// - Returns: A DynamicValue representing this value.
    /// - Throws: EncodingError if the conversion fails.
    func toDynamicValue() throws -> DynamicValue {
        try DynamicValue.from(self)
    }
    
    /// Converts this value to a dictionary of DynamicValues.
    ///
    /// Use this method to easily convert any Encodable type to a dictionary:
    /// ```swift
    /// let dict = try params.toDynamicDictionary()
    /// ```
    ///
    /// - Returns: A dictionary containing DynamicValues representing this value.
    /// - Throws: EncodingError if the conversion fails.
    func toDynamicDictionary() throws -> [String: DynamicValue] {
        try [String: DynamicValue].from(self)
    }
    
    /// Converts this value to an optional dictionary of DynamicValues.
    ///
    /// Use this method to easily convert any Encodable type to a dictionary:
    /// ```swift
    /// let dict = try params.toOptionalDynamicDictionary()
    /// ```
    ///
    /// - Returns: An optional dictionary containing DynamicValues representing this value.
    /// - Throws: EncodingError if the conversion fails.
    func toOptionalDynamicDictionary() throws -> [String: DynamicValue]? {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode([String: DynamicValue]?.self, from: data)
    }
}

// MARK: Value Accessors
extension DynamicValue {
    
    /// The string value if this is a `.string`, otherwise nil.
    public var stringValue: String? {
        guard case .string(let value) = self else {
            return nil
        }
        return value
    }
    
    /// The integer value if this is an `.int`, otherwise nil.
    public var intValue: Int? {
        guard case .int(let value) = self else {
            return nil
        }
        return value
    }
    
    /// The double value if this is a `.double`, otherwise nil.
    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        // Also try converting int to double for convenience
        if case .int(let value) = self {
            return Double(value)
        }
        return nil
    }
    
    /// The boolean value if this is a `.bool`, otherwise nil.
    public var boolValue: Bool? {
        guard case .bool(let value) = self else {
            return nil
        }
        return value
    }
    
    /// The array value if this is an `.array`, otherwise nil.
    public var arrayValue: [DynamicValue]? {
        guard case .array(let value) = self else {
            return nil
        }
        return value
    }
    
    /// The dictionary value if this is a `.dictionary`, otherwise nil.
    public var dictionaryValue: [String: DynamicValue]? {
        guard case .dictionary(let value) = self else {
            return nil
        }
        return value
    }
}
            
