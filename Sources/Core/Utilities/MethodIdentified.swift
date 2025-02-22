//
//  MethodIdentified.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Indicates that this request or notification is identified by a specific identifier in
/// at the `method` key/property.
public protocol MethodIdentified<MethodIdentifier>: Codable, Sendable {
    /// The identifier for the method that `self.method` should only and
    /// always contain.
    static var method: MethodIdentifier { get }
    /// The identifier for the method, which should always match `Self.method`.
    var method: MethodIdentifier { get }
    /// The type of method identifier being used, which much be an enum with
    /// a String for a RawValue.
    associatedtype MethodIdentifier: AnyMethodIdentifier
}

extension MethodIdentified {
    /// Verifies that that the method decoded using the provided decoder matches
    /// the method associated with Self.
    /// - Parameters:
    ///   - method: The decoded ``MethodIdentifier``.
    ///   - decoder: The ``Decoder`` used to decode the method.
    /// - Returns: The verified method, if successful. Throws a `DecodingError`
    /// otherwise.
    static func verify(
        _ method: MethodIdentifier,
        decodedUsing decoder: any Decoder
    ) throws -> MethodIdentifier {
        guard method == Self.method else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Provided method: \(method) does not match expected method: \(Self.method)"
                )
            )
        }
        return method
    }
}


/// An enumeration of the different method identifiers available for a given context.
/// These must be strings and will be stored at the `method` key.
public protocol AnyMethodIdentifier: RawRepresentable, Codable, Sendable, CaseIterable where RawValue == String {}


