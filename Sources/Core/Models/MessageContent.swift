//
//  MessageContent.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Just a helper protocol to create a standardized interface across
/// `MessageContent` types.
private protocol AnyMessageContent: Codable, Sendable {
    /// The content type identifier
    var type: String { get }
}

/// Represents the content type of a message.
public enum MessageContent: Codable, Sendable {
    case text(TextContent)
    case image(ImageContent)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let textContent = try? container.decode(TextContent.self) {
            self = .text(textContent)
        } else if let imageContent = try? container.decode(ImageContent.self) {
            self = .image(imageContent)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Content must be either text or image"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let content):
            try container.encode(content)
        case .image(let content):
            try container.encode(content)
        }
    }
}

/// Text provided to or from an LLM.
public struct TextContent: AnyMessageContent, Annotated {
    /// The text content of the message.
    public let text: String
    
    /// The content type identifier, which will always be `text`.
    public let type: String
    
    /// Optional annotations for the content.
    public let annotations: Annotations?
    
    public init(text: String, annotations: Annotations? = nil) {
        self.type = "text"
        self.text = text
        self.annotations = annotations
    }
}

/// An image provided to or from an LLM.
public struct ImageContent: AnyMessageContent, Annotated {
    /// The base64-encoded image data.
    public let data: String
    
    /// The MIME type of the image.  Different providers may support different image types.
    public let mimeType: String
    
    /// The content type identifier, which will always be `image`.
    public let type: String
    
    /// Optional annotations for the content.
    public let annotations: Annotations?
    
    public init(data: String, mimeType: String, annotations: Annotations? = nil) {
        self.type = "image"
        self.data = data
        self.mimeType = mimeType
        self.annotations = annotations
    }
}
