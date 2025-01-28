//
//  EmbeddedResource.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation

/// The contents of a resource, embedded into a prompt or tool call result.
///
/// It is up to the client how best to render embedded resources for the benefit
/// of the LLM and/or the user.
public struct EmbeddedResource: Codable, Sendable, Annotated {
    /// The resource content, which can be either text or blob data.
    public let resource: ResourceContent
    
    /// The content type identifier.
    public let type: String
    
    /// Optional annotations for the content.
    public let annotations: Annotations?
    
    public init(resource: ResourceContent, annotations: Annotations? = nil) {
        self.resource = resource
        self.type = "resource"
        self.annotations = annotations
    }
}

/// Represents the content type of an embedded resource.
public enum ResourceContent: Codable, Sendable {
    case text(TextResourceContents)
    case blob(BlobResourceContents)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let textContent = try? container.decode(TextResourceContents.self) {
            self = .text(textContent)
        } else if let blobContent = try? container.decode(BlobResourceContents.self) {
            self = .blob(blobContent)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Resource content must be either text or blob"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let content): try container.encode(content)
        case .blob(let content): try container.encode(content)
        }
    }
}

/// The contents of a specific resource or sub-resource.
protocol ResourceContents: Codable, Sendable {
    /// The MIME type of this resource, if known.
    var mimeType: String? { get }
    
    /// The URI of this resource.
    var uri: String { get }
}

/// Represents the contents of a text resource with its location and format
public struct TextResourceContents: ResourceContents {
    /// The text content. Must only be set if item can be represented as text.
    public let text: String
    
    /// The URI location of this resource
    public let uri: String
    
    /// The MIME type of this resource, if known
    public let mimeType: String?
    
    public init(text: String, uri: String, mimeType: String? = nil) {
        self.text = text
        self.uri = uri
        self.mimeType = mimeType
    }
}

/// Represents a binary resource with its metadata
public struct BlobResourceContents: ResourceContents {
    /// Base64-encoded string representing the binary data
    public let blob: Data
    
    /// The URI of this resource
    public let uri: String
    
    /// The MIME type of this resource, if known
    public let mimeType: String?
    
    public init(blob: Data, mimeType: String? = nil, uri: String) {
        self.blob = blob
        self.mimeType = mimeType
        self.uri = uri
    }
}

