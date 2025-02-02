//
//  RetryPolicy.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

/// A policy defining how operations (e.g., network requests) should be retried upon failure.
/// This includes settings for maximum retry attempts, delays, jitter, and backoff strategies.
public struct RetryPolicy: Sendable {
    
    // MARK: Static Properties
    /// The default retry policy with reasonable defaults.
    public static let `default` = RetryPolicy()
    
    // MARK: Properties
    /// The maximum number of retry attempts before giving up.
    public let maxAttempts: Int
    
    /// The base delay applied before each retry attempt.
    public var baseDelay: Duration
    
    /// The maximum delay allowed between retry attempts.
    public let maxDelay: Duration
    
    /// The jitter factor (0.0 - 1.0) applied to introduce randomness in retry delays.
    public let jitter: Double
    
    /// The type of backoff strategy used to calculate retry delays.
    public let backoffPolicy: BackoffPolicy
    
    // MARK: Initialization
    /// Creates a new retry policy with the specified parameters.
    ///
    /// - Parameters:
    ///   - maxAttempts: The maximum number of retry attempts. Defaults to `3`.
    ///   - baseDelay: The base delay between retry attempts. Defaults to `1` second.
    ///   - maxDelay: The maximum delay allowed between retry attempts. Defaults to `30` seconds.
    ///   - jitter: The jitter factor applied to introduce randomness. Defaults to `0.1` (10% variability).
    ///   - backoffPolicy: The backoff strategy to use. Defaults to `.exponential`.
    public init(
        maxAttempts: Int = 3,
        baseDelay: Duration = .seconds(1),
        maxDelay: Duration = .seconds(30),
        jitter: Double = 0.1,
        backoffPolicy: BackoffPolicy = .exponential
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitter = jitter
        self.backoffPolicy = backoffPolicy
    }
    
    // MARK: Methods
    /// Computes the appropriate delay for a given retry attempt.
    ///
    /// - Parameter attempt: The current retry attempt (1-based index).
    /// - Returns: The computed delay duration for the given attempt, capped at `maxDelay`.
    public func delay(forAttempt attempt: Int) -> Duration {
        let raw = backoffPolicy.delay(forAttempt: attempt, baseDelay: baseDelay, jitter: jitter)
        return min(raw, maxDelay)
    }
    
    // MARK: Supporting Types
    /// Defines different backoff strategies for retrying failed operations.
    public enum BackoffPolicy: Sendable {
        /// Uses a constant delay for all retry attempts.
        case constant
        
        /// Uses an exponential backoff strategy, increasing the delay exponentially
        /// based on powers of 2.
        case exponential
        
        /// Uses a linear backoff strategy, increasing the delay incrementally.
        case linear
        
        /// Allows a custom delay calculation for each retry attempt.
        case custom(calculateDelay: @Sendable (_ attempt: Int) -> Duration)
        
        // MARK: - Internal
        
        /// Computes the delay for a given retry attempt based on the backoff policy.
        ///
        /// - Parameters:
        ///   - attempt: The current retry attempt (1-based index).
        ///   - baseDelay: The base delay to start with.
        ///   - jitter: The jitter factor to apply.
        /// - Returns: The computed retry delay duration.
        func delay(forAttempt attempt: Int, baseDelay: Duration, jitter: Double) -> Duration {
            let rawDelay: Duration = switch self {
            case .constant: baseDelay
            case .exponential: baseDelay * pow(2.0, Double(attempt - 1))
            case .linear: baseDelay * Double(attempt)
            case .custom(let calculateDelay): calculateDelay(attempt)
            }
            
            if jitter > 0 {
                let jitterRange: TimeInterval = rawDelay.timeInterval * jitter
                let randomJitter: Duration = .seconds(Double.random(in: -jitterRange...jitterRange))
                return max(.zero, rawDelay + randomJitter)
            }
            
            return rawDelay
        }
    }
}
