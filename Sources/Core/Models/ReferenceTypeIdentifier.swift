//
//  ReferenceTypeIdentifier.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Identifies the type of object that is being referenced.
public enum ReferenceTypeIdentifier: String, RawRepresentable, Codable, Sendable, CaseIterable, Equatable {
    case prompt = "ref/prompt"
    case resource = "ref/resource"
}
