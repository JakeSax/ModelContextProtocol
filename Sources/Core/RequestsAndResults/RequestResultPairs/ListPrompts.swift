//
//  ListPrompts.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A request to retrieve available prompts and prompt templates from the server.
public struct ListPromptsRequest: PaginatedRequest {
    
    public static let method: ClientRequest.Method = .listPrompts
    public typealias Response = ListPromptsResult
    
    /// The API method identifier.
    public let method: ClientRequest.Method
    
    /// Optional parameters for the request.
    public let params: PaginationParameters
    
    public init(params: PaginationParameters = PaginationParameters()) {
        self.method = Self.method
        self.params = params
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
}

/// The server's response to a prompts/list request.
public struct ListPromptsResult: PaginatedResult {
    
    /// The list of returned prompts.
    public let prompts: [Prompt]
    
    /// Token representing the pagination position after the last result.
    /// If present, more results may be available.
    public let nextCursor: Cursor?
    
    public let _meta: ResultMetadata?
    
    public init(
        nextCursor: Cursor? = nil,
        prompts: [Prompt],
        meta: ResultMetadata? = nil
    ) {
        self.nextCursor = nextCursor
        self.prompts = prompts
        self._meta = meta
    }
}
