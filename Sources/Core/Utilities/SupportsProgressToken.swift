//
//  SupportsProgressToken.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Indicates that this object may have a ``ProgressToken`` specified amongst its parameters.
public protocol SupportsProgressToken {
    var params: Parameters? { get }
}

/// A progress token, used to associate progress notifications with the original request.
public typealias ProgressToken = StringOrIntValue

extension SupportsProgressToken {
    /// If specified, the caller is requesting out-of-band progress notifications for this
    /// request (as represented by `notifications/progress`). The value of this
    /// parameter is an opaque token that will be attached to any subsequent notifications.
    /// The receiver is not obligated to provide these notifications.
    public var progressToken: ProgressToken? {
        params?["progressToken"] as? ProgressToken
    }
}
