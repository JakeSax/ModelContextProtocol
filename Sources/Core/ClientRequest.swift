//
//  File.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

import Foundation


// MARK: - Client Requests
public protocol AnyClientRequest: MethodIdentified where MethodIdentifier == ClientRequest.Method {}

public enum ClientRequest: Codable, Sendable {
    case initialize(InitializeRequest)
    case ping(PingRequest)
    case listResources(ListResourcesRequest)
    case listResourceTemplates(ListResourceTemplatesRequest)
    case readResource(ReadResourceRequest)
    case subscribe(SubscribeRequest)
    case unsubscribe(UnsubscribeRequest)
    case listPrompts(ListPromptsRequest)
    case getPrompt(GetPromptRequest)
    case listTools(ListToolsRequest)
    case callTool(CallToolRequest)
    case setLevel(SetLevelRequest)
    case complete(CompleteRequest)
    
    public enum Method: String, AnyMethodIdentifier {
        case initialize
        case ping
        case listResources = "resources/list"
        case listResourceTemplates = "resources/templates/list"
        case readResource = "resources/read"
        case subscribe = "resources/subscribe"
        case unsubscribe = "resources/unsubscribe"
        case listPrompts = "prompts/list"
        case getPrompt = "prompts/get"
        case listTools = "tools/list"
        case callTool = "tools/call"
        case setLevel = "logging/setLevel"
        case complete = "completion/complete"
    }
    
    private enum CodingKeys: String, CodingKey {
        case method
    }
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .initialize(let initializeRequest):
            try initializeRequest.encode(to: encoder)
        case .ping(let pingRequest):
            try pingRequest.encode(to: encoder)
        case .listResources(let listResourcesRequest):
            try listResourcesRequest.encode(to: encoder)
        case .listResourceTemplates(let listResourceTemplatesRequest):
            try listResourceTemplatesRequest.encode(to: encoder)
        case .readResource(let readResourceRequest):
            try readResourceRequest.encode(to: encoder)
        case .subscribe(let subscribeRequest):
            try subscribeRequest.encode(to: encoder)
        case .unsubscribe(let unsubscribeRequest):
            try unsubscribeRequest.encode(to: encoder)
        case .listPrompts(let listPromptsRequest):
            try listPromptsRequest.encode(to: encoder)
        case .getPrompt(let getPromptRequest):
            try getPromptRequest.encode(to: encoder)
        case .listTools(let listToolsRequest):
            try listToolsRequest.encode(to: encoder)
        case .callTool(let callToolRequest):
            try callToolRequest.encode(to: encoder)
        case .setLevel(let setLevelRequest):
            try setLevelRequest.encode(to: encoder)
        case .complete(let completeRequest):
            try completeRequest.encode(to: encoder)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(ClientRequest.Method.self, forKey: .method)
        
        switch method {
        case .initialize:
            self = .initialize(try InitializeRequest(from: decoder))
        case .ping:
            self = .ping(try PingRequest(from: decoder))
        case .listResources:
            self = .listResources(try ListResourcesRequest(from: decoder))
        case .listResourceTemplates:
            self = .listResourceTemplates(try ListResourceTemplatesRequest(from: decoder))
        case .readResource:
            self = .readResource(try ReadResourceRequest(from: decoder))
        case .subscribe:
            self = .subscribe(try SubscribeRequest(from: decoder))
        case .unsubscribe:
            self = .unsubscribe(try UnsubscribeRequest(from: decoder))
        case .listPrompts:
            self = .listPrompts(try ListPromptsRequest(from: decoder))
        case .getPrompt:
            self = .getPrompt(try GetPromptRequest(from: decoder))
        case .listTools:
            self = .listTools(try ListToolsRequest(from: decoder))
        case .callTool:
            self = .callTool(try CallToolRequest(from: decoder))
        case .setLevel:
            self = .setLevel(try SetLevelRequest(from: decoder))
        case .complete:
            self = .complete(try CompleteRequest(from: decoder))
        }
    }
}

/// Request to subscribe to resource updates
public struct SubscribeRequest: AnyClientRequest {
    static public let method: ClientRequest.Method = .subscribe
    public let method: ClientRequest.Method
    public let params: SubscribeParameters
    
    public struct SubscribeParameters: Codable, Sendable {
        /// URI of resource to subscribe to. Server determines interpretation.
        public let uri: String
    }
    
    init(params: SubscribeParameters) {
        self.params = params
        self.method = .subscribe
    }
}

/// Client request to unsubscribe from resource updates
public struct UnsubscribeRequest: AnyClientRequest {
    static public let method: ClientRequest.Method = .unsubscribe
    public let method: ClientRequest.Method
    
    public struct Params: Codable, Sendable {
        /// URI of the resource to unsubscribe from
        public let uri: String
        
        public init(uri: String) {
            self.uri = uri
        }
    }
    
    public let params: Params
    
    public init(params: Params) {
        self.method = .unsubscribe
        self.params = params
    }
}

