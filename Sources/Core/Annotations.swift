//
//  Annotations.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation

/// Base protocol for objects that include optional annotations for client use.
/// Clients can use annotations to inform how objects are used or displayed.
public protocol Annotated {
    /// Optional annotations providing metadata about the object
    var annotations: Annotations? { get }
}

/// Describes metadata annotations that can be attached to objects
public struct Annotations: Codable, Sendable {
    /// Describes who the intended customer of this object or data is.
    ///
    /// It can include multiple entries to indicate content useful for multiple audiences
    /// (e.g., ["user", "assistant"]).
    public let audience: [Role]?
    
    /// Describes how important this data is for operating the server.
    /// Value of 1 means "most important" (effectively required),
    /// while 0 means "least important" (entirely optional).
    public let priority: Double?
    
    public init(audience: [Role]? = nil, priority: Double? = nil) {
        self.audience = audience
        self.priority = priority
    }
}
