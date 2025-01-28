//
//  ModelPreferences.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// The server's preferences for model selection during sampling.
///
/// Because LLMs can vary along multiple dimensions, choosing the "best" model is
/// rarely straightforward. Different models excel in different areas—some are
/// faster but less capable, others are more capable but more expensive.
public struct ModelPreferences: Codable, Sendable, Equatable {
    /// How much to prioritize cost (0 = not important, 1 = most important)
    public let costPriority: Double
    
    /// How much to prioritize intelligence and capabilities (0 = not important, 1 = most important)
    public let intelligencePriority: Double
    
    /// How much to prioritize sampling speed/latency (0 = not important, 1 = most important)
    public let speedPriority: Double
    
    /// Optional ordered hints for model selection
    public let hints: [ModelHint]?
    
    /// Creates model selection preferences with specified priorities and optional hints.
    ///
    /// - Parameters:
    ///   - costPriority: A value between 0 and 1 indicating how much to prioritize cost optimization.
    ///    A value of 0 means cost is not important, while 1 means cost is most important.
    ///   - intelligencePriority: A value between 0 and 1 indicating how much to prioritize model intelligence
    ///    and capabilities. A value of 0 means intelligence is not important, while 1 means it is most important.
    ///   - speedPriority: A value between 0 and 1 indicating how much to prioritize sampling speed and latency.
    ///    A value of 0 means speed is not important, while 1 means it is most important.
    ///   - hints: Optional array of model selection hints to guide model choice. Defaults to nil.
    ///
    ///  - Precondition: All priority values must be between 0 and 1, inclusive.
    public init(
        costPriority: Double,
        intelligencePriority: Double,
        speedPriority: Double,
        hints: [ModelHint]? = nil
    ) {
        precondition((0...1).contains(costPriority), "costPriority must be between 0 and 1")
        precondition((0...1).contains(intelligencePriority), "intelligencePriority must be between 0 and 1")
        precondition((0...1).contains(speedPriority), "speedPriority must be between 0 and 1")
        
        self.costPriority = costPriority
        self.intelligencePriority = intelligencePriority
        self.speedPriority = speedPriority
        self.hints = hints
    }

    /// Hints to use for model selection.
    public struct ModelHint: Codable, Sendable, Equatable {
        /// A hint for a model name.
        ///
        /// The client should treat this as a substring of a model name. For example:
        /// - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
        /// - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
        /// - `claude` should match any Claude model
        public let name: String
        
        /// Creates a model selection hint with the specified model name pattern.
        ///
        /// The name parameter is treated as a substring match pattern for model names.
        /// For example:
        /// - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
        /// - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
        /// - `claude` should match any Claude model
        /// - Parameter name: A string pattern to match against model names.
        public init(name: String) {
            self.name = name
        }
    }

}
