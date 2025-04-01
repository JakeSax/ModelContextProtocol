//
//  Request.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Base request type for MCP protocol.
public protocol Request<MethodIdentifier>: MethodIdentified, Equatable {
    
    /// The parameters that may be included in this request.
    associatedtype Parameters: RequestParameters
    
    /// The parameters for the request.
    var params: Parameters { get }
    
    /// Creates a Request with the given parameters.
    init(params: Parameters)
    
    /// The ``Result`` that is expected as a response to this request.
    associatedtype Result: MCPCore.Result
}

/// The parameters that may be inclued in a ``Request``.
public protocol RequestParameters: Codable, Sendable, Equatable {
    /// This parameter name is reserved by MCP to allow clients and servers to attach
    /// additional metadata to their messages.
    var _meta: RequestMetadata? { get }
}

extension RequestParameters {
    /// This key is reserved by MCP to allow clients and servers to attach
    /// additional metadata to their messages.
    static var metadataKey: String { "_meta" }
    
    /// This key is reserved by MCP within it's metadata at `_meta` to store
    /// a progress token.
    static var progressTokenKey: String { "progressToken" }
}

/// The metadata expected for a ``Request``, which only optionally includes
/// a ``ProgressToken``.
public struct RequestMetadata: Codable, Sendable, Equatable {
    /// If specified, the caller is requesting out-of-band progress notifications for this
    /// request (as represented by `notifications/progress`). The value of this
    /// parameter is an opaque token that will be attached to any subsequent notifications.
    /// The receiver is not obligated to provide these notifications.
    public let progressToken: ProgressToken?
    
    public init(progressToken: ProgressToken?) {
        self.progressToken = progressToken
    }
}

/// The default request paramters if no additional properties are explicitly expected. It only
/// includes ``RequestMetadata`` with the ability to hold more, unspecified values.
public struct DefaultRequestParameters: RequestParameters {
    
    // MARK: Properties
    public let _meta: RequestMetadata?
    public var additionalProperties: [String: DynamicValue]?
    
    /// Whether there is no metadata and no additional properties, or not.
    var isEmpty: Bool {
        _meta == nil && (additionalProperties == nil || additionalProperties?.isEmpty == true)
    }
    
    // MARK: Initialization
    public init(
        meta: RequestMetadata? = nil,
        additionalProperties: [String : DynamicValue]? = nil
    ) {
        self._meta = meta
        self.additionalProperties = additionalProperties
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        do {
            // Use a dictionary container to capture all fields
            let container = try decoder.singleValueContainer()
            let allProperties = try container.decode([String: DynamicValue].self)
            let nonMetadataProperties = allProperties.filter { $0.key != Self.metadataKey }
            
            // Store all non-meta properties
            if nonMetadataProperties.isEmpty {
                self.additionalProperties = nil
            } else {
                self.additionalProperties = nonMetadataProperties
            }
            
            // Extract _meta if it exists
            guard let metaDict = allProperties[Self.metadataKey]?.dictionaryValue else {
                self._meta = nil
                return
            }
            guard let progressTokenValue = metaDict[Self.progressTokenKey] else {
                self._meta = .init(progressToken: nil)
                return
            }
            
            self._meta = .init(progressToken: ProgressToken(progressTokenValue))
        } catch {
            self._meta = nil
            self.additionalProperties = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var allProperties = additionalProperties
        
        // Add _meta if present
        if let meta = _meta {
            var propertiesWithMetadata = allProperties ?? [:]
            if let progressToken = meta.progressToken {
                propertiesWithMetadata[Self.metadataKey] = .dictionary(
                    [Self.progressTokenKey : progressToken.dynamicValue]
                )
            } else {
                propertiesWithMetadata[Self.metadataKey] = .dictionary([Self.progressTokenKey : .null])
            }
            
            allProperties = propertiesWithMetadata
        }
        
        try container.encode(allProperties)
    }

}
