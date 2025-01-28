//
//  SharedNotifications.swift
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

}

/// This notification can be sent by either side (Client or Server) to indicate that it
/// is cancelling a previously-issued request.
///
/// The request SHOULD still be in-flight, but due to communication latency, it
/// is always possible that this notification MAY arrive after the request has
/// already finished.
///
/// This notification indicates that the result will be unused, so any associated
/// processing SHOULD cease.
///
/// A client MUST NOT attempt to cancel its `initialize` request.
public struct CancelledNotification: AnyClientNotification {
    
    // MARK: Static Properties
    public static let method = ClientNotification.Method.cancelled
    
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
        /// The ID of the request to cancel.
        ///
        /// This MUST correspond to the ID of a request previously issued
        /// in the same direction.
        public let requestId: RequestID
        /// An optional string describing the reason for the cancellation. This
        /// MAY be logged or presented to the user.
        public let reason: String?
        
        public let _meta: NotificationMetadata?
        
        public init(
            requestID: RequestID,
            reason: String? = nil,
            meta: NotificationMetadata? = nil
        ) {
            self.requestId = requestID
            self.reason = reason
            self._meta = meta
        }
    }

}
