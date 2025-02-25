//
//  TransportConfiguration.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

/// Defines overall transport behavior and retry policies.
public struct TransportConfiguration: Sendable {
    
    // MARK: Static Properties
    /// Default transport configuration with standard timeouts, message size limits,
    /// and retry policies.
    public static let `default` = TransportConfiguration()
    
    // MARK: Properties
    /// Maximum time allowed to establish a connection, in seconds.
    public let connectTimeout: Duration
    
    /// Maximum time allowed to send a message, in seconds.
    public let sendTimeout: Duration
    
    /// Maximum allowed message size, in bytes.
    public let maxMessageSize: Int
    
    /// Defines the retry policy for short-lived operations.
    public var retryPolicy: RetryPolicy
    
    /// Configuration for periodic health checks.
    /// If `nil`, health checks will be disabled.
    public let healthCheckConfiguration: HealthCheckConfiguration?
    
    // MARK: Initialization
    /// Initializes a transport configuration with customizable timeouts, message size
    /// limits, and retry policies.
    /// - Parameters:
    ///   - connectTimeout: Maximum duration allowed for connection
    ///   establishment. Defaults to 2 minutes.
    ///   - sendTimeout: Maximum duration allowed for sending data. Defaults
    ///   to 2 minutes.
    ///   - maxMessageSize: Limit in bytes for message size. Defaults to
    ///   4MB (4,194,304 bytes).
    ///   - retryPolicy: Retry policy for handling short-lived operation failures.
    ///   - healthCheckConfiguration: Configuration for periodic health
    ///   checks. If `nil`, health checks are disabled.
    public init(
        connectTimeout: Duration = .minutes(2),
        sendTimeout: Duration = .minutes(2),
        maxMessageSize: Int = 4_194_304, // 4 MB
        retryPolicy: RetryPolicy = .default,
        healthCheckConfiguration: HealthCheckConfiguration? = .init(
            healthCheckInterval: .seconds(30),
            maxReconnectAttempts: 3
        )
    ) {
        self.connectTimeout = connectTimeout
        self.sendTimeout = sendTimeout
        self.maxMessageSize = maxMessageSize
        self.retryPolicy = retryPolicy
        self.healthCheckConfiguration = healthCheckConfiguration
    }
    
    // MARK: Supporting Types
    /// Configuration options for health checks that monitor connection stability.
    public struct HealthCheckConfiguration: Sendable {
        
        /// Interval between health checks, in seconds.
        public let healthCheckInterval: Duration
        
        /// Maximum number of reconnection attempts when a health check fails.
        public let maxReconnectAttempts: Int
        
        /// Initializes a health check configuration.
        /// - Parameters:
        ///   - healthCheckInterval: Interval in seconds between successive
        ///   health checks.
        ///   - maxReconnectAttempts: Maximum number of reconnection
        ///   attempts allowed on health check failures.
        public init(healthCheckInterval: Duration, maxReconnectAttempts: Int) {
            self.healthCheckInterval = healthCheckInterval
            self.maxReconnectAttempts = maxReconnectAttempts
        }
    }
}
