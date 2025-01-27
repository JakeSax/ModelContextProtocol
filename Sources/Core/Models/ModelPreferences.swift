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
public struct ModelPreferences: Codable, Sendable {
    /// How much to prioritize cost (0 = not important, 1 = most important)
    public let costPriority: Double
    
    /// How much to prioritize intelligence and capabilities (0 = not important, 1 = most important)
    public let intelligencePriority: Double
    
    /// How much to prioritize sampling speed/latency (0 = not important, 1 = most important)
    public let speedPriority: Double
    
    /// Optional ordered hints for model selection
    public let hints: [ModelHint]?
    
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
    public struct ModelHint: Codable, Sendable {
        /// A hint for a model name.
        ///
        /// The client should treat this as a substring of a model name. For example:
        /// - `claude-3-5-sonnet` should match `claude-3-5-sonnet-20241022`
        /// - `sonnet` should match `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, etc.
        /// - `claude` should match any Claude model
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
    }

}
