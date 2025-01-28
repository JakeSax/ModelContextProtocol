//
//  ServerNotifications.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/26/25.
//

/// A Notification identified by a ``ServerNotification.Method`` in its `method` property.
public protocol AnyServerNotification: Notification where MethodIdentifier == ServerNotification.Method {
}

/// An enumeration of all the possible server notifications.
public enum ServerNotification: Codable, Sendable {
    
    case cancelled(CancelledNotification)
    case progress(ProgressNotification)
    case resourceListChanged(ResourceListChangedNotification)
    case resourceUpdated(ResourceUpdatedNotification)
    case promptListChanged(PromptListChangedNotification)
    case toolListChanged(ToolListChangedNotification)
    case loggingMessage(LoggingMessageNotification)
    
    // MARK: Data Structures
    public enum Method: String, AnyMethodIdentifier {
        case cancelled = "notifications/cancelled"
        case progress = "notifications/progress"
        case resourceListChanged = "notifications/resources/list_changed"
        case resourceUpdated = "notifications/resources/updated"
        case promptListChanged = "notifications/prompts/list_changed"
        case toolListChanged = "notifications/tools/list_changed"
        case loggingMessage = "notifications/message"
    }
    
    // MARK: Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case method
    }
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .cancelled(let cancelledNotification):
            try cancelledNotification.encode(to: encoder)
        case .progress(let progressNotification):
            try progressNotification.encode(to: encoder)
        case .resourceListChanged(let resourceListChangedNotification):
            try resourceListChangedNotification.encode(to: encoder)
        case .resourceUpdated(let resourceUpdatedNotification):
            try resourceUpdatedNotification.encode(to: encoder)
        case .promptListChanged(let promptListChangedNotification):
            try promptListChangedNotification.encode(to: encoder)
        case .toolListChanged(let toolListChangedNotification):
            try toolListChangedNotification.encode(to: encoder)
        case .loggingMessage(let loggingMessageNotification):
            try loggingMessageNotification.encode(to: encoder)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(ServerNotification.Method.self, forKey: .method)
        
        switch method {
        case .cancelled:
            self = .cancelled(try CancelledNotification(from: decoder))
        case .progress:
            self = .progress(try ProgressNotification(from: decoder))
        case .resourceListChanged:
            self = .resourceListChanged(try ResourceListChangedNotification(from: decoder))
        case .resourceUpdated:
            self = .resourceUpdated(try ResourceUpdatedNotification(from: decoder))
        case .promptListChanged:
            self = .promptListChanged(try PromptListChangedNotification(from: decoder))
        case .toolListChanged:
            self = .toolListChanged(try ToolListChangedNotification(from: decoder))
        case .loggingMessage:
            self = .loggingMessage(try LoggingMessageNotification(from: decoder))
        }
    }

}


/// A notification containing a log message from server to client
public struct LoggingMessageNotification: AnyServerNotification {
    public static let method: ServerNotification.Method = .loggingMessage
    
    /// The method identifier for logging notifications
    public let method: ServerNotification.Method
    
    public let params: Parameters
    
    /// Parameters containing the log message details
    public struct Parameters: NotificationParameters {
        /// The log message content
        public let data: DynamicValue
        
        /// The severity level of the message
        public let level: LoggingLevel
        
        /// Optional name of the logger
        public let logger: String?
        
        public let _meta: [String: DynamicValue]?
        
        public init(
            data: DynamicValue,
            level: LoggingLevel,
            logger: String? = nil,
            meta: [String: DynamicValue]? = nil
        ) {
            self.data = data
            self.level = level
            self.logger = logger
            self._meta = meta
        }
    }
    
    
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
}
