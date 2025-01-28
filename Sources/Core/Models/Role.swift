//
//  Role.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Defines role types (e.g., user, assistant).
public enum Role: String, Codable, Sendable, Equatable {
    case user
    case assistant
}
