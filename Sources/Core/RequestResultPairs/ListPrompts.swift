//
//  ListPrompts.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available prompts and prompt templates from the server.
public struct ListPromptsRequest: Codable, Sendable {
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: Params?
    
    /// Parameters for configuring the prompts list request.
    public struct Params: Codable, Sendable {
        /// An opaque token representing the current pagination position.
        /// If provided, the server will return results starting after this cursor.
        public let cursor: String?
        
        public init(cursor: String? = nil) {
            self.cursor = cursor
        }
    }
    
    public init(params: Params? = nil) {
        self.params = params
        self.method = .listPrompts
    }
}

/// The server's response to a prompts/list request.
public struct ListPromptsResult: Codable, Sendable {
    /// Reserved metadata field for additional response information.
    public let meta: Parameters?
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: String?
    
    /// The list of returned prompts.
    public let prompts: [Prompt]
    
    public init(meta: Parameters? = nil, nextCursor: String? = nil, prompts: [Prompt]) {
        self.meta = meta
        self.nextCursor = nextCursor
        self.prompts = prompts
    }
}

/// An optional notification from the server to the client, informing it that the list of prompts
/// it offers has changed. This may be issued by servers without any previous subscription from the client.
public struct PromptListChangedNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .promptListChanged
    /// The method identifier for the notification
    public let method: ServerNotification.Method
    
    /// Additional parameters for the notification
    public let params: Parameters
    
    public init(params: Parameters = [:]) {
        self.method = Self.method
        self.params = params
    }
}
