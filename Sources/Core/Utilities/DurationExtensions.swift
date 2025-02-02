//
//  DurationExtensions.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/2/25.
//

import Foundation

extension Duration {
    
    /// The number of attoseconds in one second.
    private static let attosecondsPerSecond: Double = 1e18
    private static let attosecondsPerSecondInt: Int64 = 1_000_000_000_000_000_000
    
    /// Constructs a `Duration` given a number of minutes represented as a `BinaryInteger`.
    public static func minutes<T: BinaryInteger>(_ minutes: T) -> Duration {
        // 60 seconds per minute.
        .seconds(60 * minutes)
    }
    
    /// Constructs a `Duration` given a number of hours represented as a `BinaryInteger`.
    public static func hours<T: BinaryInteger>(_ hours: T) -> Duration {
        // 60 minutes per hour.
        .minutes(60 * hours)
    }
    
    /// Constructs a `Duration` given a number of days represented as a `BinaryInteger`.
    public static func days<T: BinaryInteger>(_ days: T) -> Duration {
        // 24 hours per day.
        .hours(24 * days)
    }
    
    /// Initializes a `Duration` from a `TimeInterval`.
    ///
    /// This initializer converts a `TimeInterval` (which represents seconds) into a `Duration`.
    /// The conversion is lossy beyond 13 decimal places.
    ///
    /// - Parameter timeInterval: The `TimeInterval` to convert.
    /// - Returns: The corresponding `Duration` for the `TimeInterval`, or nil if the
    ///   `timeInterval` is NaN or infinite.
    public init?(timeInterval: TimeInterval) {
        // Return nil for invalid values.
        guard !timeInterval.isNaN && !timeInterval.isInfinite else {
            return nil
        }
        
        let seconds: Int64
        let attoseconds: Int64
        
        if timeInterval >= 0 {
            // Split into whole seconds and fractional part.
            seconds = Int64(timeInterval)
            let fractionalPart = timeInterval - TimeInterval(seconds)
            attoseconds = Int64((fractionalPart * Duration.attosecondsPerSecond).rounded())
            
            // If the rounding pushes the attoseconds to exactly one second,
            // bump the seconds by one.
            if attoseconds == Duration.attosecondsPerSecondInt {
                self.init(secondsComponent: seconds + 1, attosecondsComponent: 0)
                return
            }
        } else {
            // For negative values, use floor to ensure correct rounding.
            seconds = Int64(floor(timeInterval))
            let fractionalPart = timeInterval - TimeInterval(seconds)
            // Make sure the attoseconds value is positive.
            attoseconds = Int64((-fractionalPart * Duration.attosecondsPerSecond).rounded())
            
            if attoseconds == Duration.attosecondsPerSecondInt {
                self.init(secondsComponent: seconds - 1, attosecondsComponent: 0)
                return
            }
        }
        
        self.init(secondsComponent: seconds, attosecondsComponent: attoseconds)
    }
    
    /// Converts the `Duration` instance into a `TimeInterval`.
    ///
    /// This conversion is lossy beyond 13 decimal places.
    public var timeInterval: TimeInterval {
        let seconds = TimeInterval(self.components.seconds)
        let fractionalSeconds = TimeInterval(self.components.attoseconds) / Duration.attosecondsPerSecond
        
        // For negative durations, the fractional part should be subtracted.
        if self.components.seconds >= 0 {
            return seconds + fractionalSeconds
        } else {
            return seconds - fractionalSeconds
        }
    }
    
    /// A convenience alias for `timeInterval` that returns the duration in seconds.
    public var seconds: TimeInterval {
        timeInterval
    }
}

