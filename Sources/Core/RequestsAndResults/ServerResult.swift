//
//  ServerResult.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// An enumeration of all the possible server results.
///
/// For optimal performance, avoid decoding values directly as `ServerResult`. Since results
/// lack type identifiers, decoding requires attempting each possible case until a match is found.
/// Instead, when the expected result type is known, decode directly to that specific type
/// (e.g., `InitializeResult`, `ListResourcesResult`).
///
/// Example:
/// ```swift
/// // Less efficient:
/// let serverResult = try decoder.decode(ServerResult.self, from: data)
///
/// // More efficient, when type is known:
/// let initResult = try decoder.decode(InitializeResult.self, from: data)
/// ```
public enum ServerResult: Codable, Sendable {
    
    case standard(AnyResult)
    case initialize(InitializeResult)
    case listResources(ListResourcesResult)
    case listResourceTemplates(ListResourceTemplatesResult)
    case readResource(ReadResourceResult)
    case listPrompts(ListPromptsResult)
    case getPrompt(GetPromptResult)
    case listTools(ListToolsResult)
    case callTool(CallToolResult)
    case complete(CompleteResult)
    
    /// The ``Result`` stored in the associated value of the enum case.
    public var result: any Result {
        switch self {
        case .standard(let anyResult): anyResult
        case .initialize(let initializeResult): initializeResult
        case .listResources(let listResourcesResult): listResourcesResult
        case .listResourceTemplates(let listResourceTemplatesResult): listResourceTemplatesResult
        case .readResource(let readResourceResult): readResourceResult
        case .listPrompts(let listPromptsResult): listPromptsResult
        case .getPrompt(let getPromptResult): getPromptResult
        case .listTools(let listToolsResult): listToolsResult
        case .callTool(let callToolResult): callToolResult
        case .complete(let completeResult): completeResult
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let initialize = try? container.decode(InitializeResult.self) {
            self = .initialize(initialize)
        } else if let listResources = try? container.decode(ListResourcesResult.self) {
            self = .listResources(listResources)
        } else if let listResourceTemplates = try? container.decode(ListResourceTemplatesResult.self) {
            self = .listResourceTemplates(listResourceTemplates)
        } else if let readResource = try? container.decode(ReadResourceResult.self) {
            self = .readResource(readResource)
        } else if let listPrompts = try? container.decode(ListPromptsResult.self) {
            self = .listPrompts(listPrompts)
        } else if let getPrompt = try? container.decode(GetPromptResult.self) {
            self = .getPrompt(getPrompt)
        } else if let listTools = try? container.decode(ListToolsResult.self) {
            self = .listTools(listTools)
        } else if let callTool = try? container.decode(CallToolResult.self) {
            self = .callTool(callTool)
        } else if let complete = try? container.decode(CompleteResult.self) {
            self = .complete(complete)
        } else if let standard = try? container.decode(AnyResult.self) {
            self = .standard(standard)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid server result type"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .standard(let result):
            try container.encode(result)
        case .initialize(let initialize):
            try container.encode(initialize)
        case .listResources(let listResources):
            try container.encode(listResources)
        case .listResourceTemplates(let listResourceTemplates):
            try container.encode(listResourceTemplates)
        case .readResource(let readResource):
            try container.encode(readResource)
        case .listPrompts(let listPrompts):
            try container.encode(listPrompts)
        case .getPrompt(let getPrompt):
            try container.encode(getPrompt)
        case .listTools(let listTools):
            try container.encode(listTools)
        case .callTool(let callTool):
            try container.encode(callTool)
        case .complete(let complete):
            try container.encode(complete)
        }
    }
}



