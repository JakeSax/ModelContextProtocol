//
//  Resource.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/24/25.
//

/// A known resource that the server is capable of reading.
public struct Resource: Codable, Sendable, Annotated {
    
    /// A description of what this resource represents.
    ///
    /// This can be used by clients to improve the LLM's understanding of available resources.
    /// It can be thought of like a "hint" to the model.
    public var description: String?
    
    /// The MIME type of this resource, if known.
    public var mimeType: String?
    
    /// A human-readable name for this resource.
    ///
    /// This can be used by clients to populate UI elements.
    public var name: String
    
    /// The size of the raw resource content, in bytes (i.e., before base64 encoding or any tokenization), if known.
    ///
    /// This can be used by Hosts to display file sizes and estimate context window usage.
    public var size: Int?
    
    /// The URI of this resource.
    public var uri: String
    
    /// Additional metadata about the resource.
    public var annotations: Annotations?
    
    public init(
        description: String? = nil,
        mimeType: String? = nil,
        name: String,
        size: Int? = nil,
        uri: String,
        annotations: Annotations? = nil
    ) {
        self.description = description
        self.mimeType = mimeType
        self.name = name
        self.size = size
        self.uri = uri
        self.annotations = annotations
    }
}


/// The contents of a specific resource or sub-resource.
public struct ResourceContents: Codable, Sendable {
    /// The MIME type of this resource, if known.
    public var mimeType: String?
    
    /// The URI of this resource.
    public var uri: String
    
    public init(mimeType: String? = nil, uri: String) {
        self.mimeType = mimeType
        self.uri = uri
    }
}

/// A reference to a resource or resource template definition.
public struct ResourceReference: Codable, Sendable {
    /// The type identifier for resource references.
    public let type: ReferenceTypeIdentifier
    
    /// The URI or URI template of the resource.
    public var uri: String
    
    public init(uri: String) {
        self.uri = uri
        self.type = .resource
    }
}

/// A template description for resources available on the server.
public struct ResourceTemplate: Codable, Sendable, Annotated {
    
    /// A description of what this template is for.
    ///
    /// This can be used by clients to improve the LLM's understanding of available resources.
    /// It can be thought of like a "hint" to the model.
    public var description: String?
    
    /// The MIME type for all resources that match this template.
    ///
    /// This should only be included if all resources matching this template have the same type.
    public var mimeType: String?
    
    /// A human-readable name for the type of resource this template refers to.
    ///
    /// This can be used by clients to populate UI elements.
    public var name: String
    
    /// A URI template (according to RFC 6570) that can be used to construct resource URIs.
    public var uriTemplate: String
    
    /// Additional metadata about the resource template.
    public var annotations: Annotations?
    
    public init(
        description: String? = nil,
        mimeType: String? = nil,
        name: String,
        uriTemplate: String,
        annotations: Annotations? = nil
    ) {
        self.description = description
        self.mimeType = mimeType
        self.name = name
        self.uriTemplate = uriTemplate
        self.annotations = annotations
    }
}
