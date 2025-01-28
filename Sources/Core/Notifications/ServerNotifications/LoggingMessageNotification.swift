//
//  LoggingMessageNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A notification containing a log message from server to client
public struct LoggingMessageNotification: AnyServerNotification {
    
    // MARK: Static Properties
    public static let method: ServerNotification.Method = .loggingMessage
    
    // MARK: Properties
    /// The method identifier for logging notifications
    public let method: ServerNotification.Method
    
    public let params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    /// Parameters containing the log message details
    public struct Parameters: NotificationParameters {
        /// The severity level of the message
        public let level: LoggingLevel
        
        /// The log message content
        public let data: DynamicValue
        
        /// Optional name of the logger
        public let logger: String?
        
        public let _meta: NotificationMetadata?
        
        public init(
            level: LoggingLevel,
            data: DynamicValue,
            logger: String? = nil,
            meta: NotificationMetadata? = nil
        ) {
            self.level = level
            self.data = data
            self.logger = logger
            self._meta = meta
        }
    }
    
    // MARK: Codable Conformance
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }
    
}
