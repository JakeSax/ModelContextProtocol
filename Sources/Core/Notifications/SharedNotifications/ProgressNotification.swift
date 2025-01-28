//
//  ProgressNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

public typealias ProgressToken = StringOrIntValue

/// An out-of-band notification used to inform the receiver of a progress update for a
/// long-running request. This notification may be sent or received by either server or
/// client.
public struct ProgressNotification: AnyClientNotification {
    
    // MARK: Static Properties
    public static let method = ClientNotification.Method.progress
    
    // MARK: Properties
    public let method: ClientNotification.Method
    public let params: Parameters
    
    // MARK: Initialization
    public init(params: Parameters) {
        self.method = Self.method
        self.params = params
    }
    
    // MARK: Data Structures
    public struct Parameters: NotificationParameters {
        /// The progress thus far. This should increase every time progress is made,
        /// even if the total is unknown.
        public let progress: Double
        /// The progress token which was given in the initial request, used to associate
        /// this notification with the request that is proceeding.
        public let progressToken: ProgressToken
        /// Total number of items to process (or total progress required), if known.
        public let total: Double?
        
        public let _meta: NotificationMetadata?
        
        init(
            progress: Double,
            progressToken: ProgressToken,
            total: Double?,
            meta: NotificationMetadata? = nil
        ) {
            self.progress = progress
            self.progressToken = progressToken
            self.total = total
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
