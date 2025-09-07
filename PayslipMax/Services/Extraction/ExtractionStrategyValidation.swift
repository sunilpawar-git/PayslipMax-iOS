import Foundation

/// Protocol for strategy evaluation rules
protocol StrategyEvaluationRule {
    var weight: Double { get }
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double
}

/// Default strategy selection weights
struct SelectionWeights {
    static let memoryPressure: Double = 0.4
    static let documentComplexity: Double = 0.3
    static let userPreference: Double = 0.2
    static let systemPerformance: Double = 0.1
}

/// Memory-based evaluation rule
struct MemoryPressureRule: StrategyEvaluationRule {
    let weight: Double = 0.3
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let pressure = context.resourceAssessment.memoryPressure
        
        switch (strategy, pressure) {
        case (.streaming, .high), (.streaming, .critical):
            return 1.0
        case (.sequential, .normal):
            return 1.0
        case (.parallel, .normal), (.parallel, .moderate):
            return 0.8
        case (.adaptive, _):
            return 0.7
        default:
            return 0.3
        }
    }
}

/// Performance-based evaluation rule
struct PerformanceRule: StrategyEvaluationRule {
    let weight: Double = 0.2
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let systemLoad = context.resourceAssessment.systemLoad
        
        switch strategy {
        case .parallel:
            return systemLoad < 0.5 ? 1.0 : 0.3
        case .streaming:
            return systemLoad < 0.8 ? 0.9 : 0.6
        case .sequential:
            return 0.7
        case .adaptive:
            return 0.8
        }
    }
}

/// Document complexity evaluation rule
struct DocumentComplexityRule: StrategyEvaluationRule {
    let weight: Double = 0.25
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let complexity = context.documentAnalysis.contentComplexity
        
        switch strategy {
        case .sequential:
            return complexity == .high ? 1.0 : 0.6
        case .parallel:
            return complexity == .low ? 1.0 : 0.5
        case .streaming, .adaptive:
            return 0.7
        }
    }
}

/// User preference evaluation rule
struct UserPreferenceRule: StrategyEvaluationRule {
    let weight: Double = 0.1
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let priority = context.userPreferences.priority
        
        switch (strategy, priority) {
        case (.parallel, .speed):
            return 1.0
        case (.sequential, .quality):
            return 1.0
        case (.streaming, .memoryEfficient):
            return 1.0
        case (.adaptive, _):
            return 0.8
        default:
            return 0.5
        }
    }
}

/// Strategy validation utilities
struct StrategyValidation {
    /// Validates if a strategy is suitable for the given context
    /// - Parameters:
    ///   - strategy: The strategy to validate
    ///   - context: The evaluation context
    /// - Returns: True if the strategy is valid, false otherwise
    static func isValidStrategy(_ strategy: TextExtractionStrategy, for context: StrategyEvaluationContext) -> Bool {
        // Check memory constraints
        if context.resourceAssessment.memoryPressure == .critical && strategy == .parallel {
            return false
        }
        
        // Check document size constraints
        if context.documentAnalysis.estimatedSize > 100_000_000 && strategy == .sequential {
            return false
        }
        
        // Check quality requirements
        if context.userPreferences.qualityThreshold > 0.9 && strategy == .streaming {
            return false
        }
        
        return true
    }
    
    /// Gets the minimum confidence threshold for a strategy
    /// - Parameter strategy: The strategy
    /// - Returns: Minimum confidence threshold
    static func minimumConfidence(for strategy: TextExtractionStrategy) -> Double {
        switch strategy {
        case .sequential:
            return 0.7
        case .parallel:
            return 0.6
        case .streaming:
            return 0.5
        case .adaptive:
            return 0.4
        }
    }
}
