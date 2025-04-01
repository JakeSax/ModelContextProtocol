//
//  MCPClient+Progress.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 3/24/25.
//

import Foundation
import MCPCore

/// A representation of a request that the receiver would like to receive progress updates for.
///
/// Progress tokens can be chosen by the sender using any means, but MUST be unique
/// across all active requests.
public struct ProgressRequest: Sendable, Codable, Hashable, Identifiable {
    /// The token provided for a Request that the receiver would like to receive
    /// ``ProgressNotification``s for.
    public let token: ProgressToken
    /// The ID of the Request.
    public let requestID: RequestID
    
    public var id: ProgressToken { token }
}
