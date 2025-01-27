//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation

/// An enumeration of the different method identifiers available for a given context.
/// These must be strings and will be stored at the `method` key.
public protocol AnyMethodIdentifier: RawRepresentable, Codable, Sendable, CaseIterable where RawValue == String {}

public typealias ProgressToken = StringOrIntValue
