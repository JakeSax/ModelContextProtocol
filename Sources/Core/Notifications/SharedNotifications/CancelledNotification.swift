//
//  CancelledNotification.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//


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
    
    // MARK: Codable Conformance
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(MethodIdentifier.self, forKey: .method)
        self.method = try Self.verify(method, decodedUsing: decoder)
        self.params = try container.decode(Parameters.self, forKey: .params)
    }

}
