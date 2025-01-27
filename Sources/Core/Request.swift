//
//  Request.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// Base request type for MCP protocol.
public protocol Request<MethodIdentifier>: Codable, Sendable {
    
    /// The type of identifier for the method.
    associatedtype MethodIdentifier: AnyMethodIdentifier
    
    associatedtype Parameters: RequestParameters
    
    /// The method identifier for the request.
    var method: MethodIdentifier { get }
    
    /// The parameters for the request.
    var params: Parameters { get }
}

public protocol RequestParameters: Codable, Sendable {
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
public struct RequestMetadata: Codable, Sendable {
    /// If specified, the caller is requesting out-of-band progress notifications for this
    /// request (as represented by `notifications/progress`). The value of this
    /// parameter is an opaque token that will be attached to any subsequent notifications.
    /// The receiver is not obligated to provide these notifications.
    public let progressToken: ProgressToken?
}


/// The default request paramters if no additional properties are explicitly expected. It only
/// includes ``RequestMetadata`` with the ability to hold more, unspecified values.
public struct DefaultRequestParameters: RequestParameters {
    
    // MARK: Properties
    public let _meta: RequestMetadata?
    public var additionalProperties: [String: DynamicValue]?
    
    // MARK: Initialization
    public init(meta: RequestMetadata? = nil, additionalProperties: [String : DynamicValue]? = nil) {
        self._meta = meta
        self.additionalProperties = additionalProperties
    }
    
    // MARK: Codable Conformance
    public init(from decoder: Decoder) throws {
        do {
            // Use a dictionary container to capture all fields
            let container = try decoder.singleValueContainer()
            let allProperties = try container.decode([String: DynamicValue].self)
            
            // Store all non-meta properties
            self.additionalProperties = allProperties.filter { $0.key != Self.metadataKey }
            
            // Extract _meta if it exists
            guard let metaValue = allProperties[Self.metadataKey],
                  case .dictionary(let metaDict) = metaValue else {
                self._meta = nil
                return
            }
            guard let progressTokenValue = metaDict[Self.progressTokenKey] else {
                self._meta = .init(progressToken: nil)
                return
            }
            
            self._meta = .init(progressToken: ProgressToken(progressTokenValue) )
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


extension OldParameters: RequestParameters {
    
    public var _meta: RequestMetadata? {
        guard let metadata = self["_meta"] else {
            return nil
        }
        switch metadata {
        case .dictionary(let dictionary):
            return switch dictionary["progressToken"] {
            case .string(let string): RequestMetadata(progressToken: .string(string))
            case .int(let int): RequestMetadata(progressToken: .int(int))
            default: nil
            }
        default: return nil
        }
    }
//    public var progressToken: ProgressToken? {
//        guard let metadata = self["_meta"] else {
//            return nil
//        }
//        switch metadata {
//        case .dictionary(let dictionary):
//            return switch dictionary["progressToken"] {
//            case .int(let int): .int(int)
//            case .string(let string): .string(string)
//            default: nil
//            }
//        default: return nil
//        }
//    }
}
