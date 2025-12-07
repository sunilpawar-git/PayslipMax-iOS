import Foundation

// Collection of extraction strategies with their specific implementations
// swiftlint:disable no_hardcoded_strings
struct ExtractionStrategies {
    /// Creates default evaluation rules for strategy selection
    /// - Returns: Array of default evaluation rules
    static func defaultEvaluationRules() -> [StrategyEvaluationRule] {
        return [
            MemoryPressureRule(),
            PerformanceRule(),
            DocumentComplexityRule(),
            UserPreferenceRule()
        ]
    }

    /// Gets all available strategies
    /// - Returns: Array of all extraction strategies
    static func allStrategies() -> [TextExtractionStrategy] {
        return TextExtractionStrategy.allCases
    }

    /// Gets strategies suitable for large documents
    /// - Returns: Array of strategies optimized for large documents
    static func strategiesForLargeDocuments() -> [TextExtractionStrategy] {
        return [.streaming, .adaptive]
    }

    /// Gets strategies suitable for high-quality extraction
    /// - Returns: Array of strategies optimized for quality
    static func strategiesForHighQuality() -> [TextExtractionStrategy] {
        return [.sequential, .adaptive]
    }

    /// Gets strategies suitable for memory-constrained environments
    /// - Returns: Array of memory-efficient strategies
    static func strategiesForMemoryConstraints() -> [TextExtractionStrategy] {
        return [.streaming, .sequential]
    }

    /// Gets strategies suitable for speed-critical scenarios
    /// - Returns: Array of fast strategies
    static func strategiesForSpeed() -> [TextExtractionStrategy] {
        return [.parallel, .adaptive]
    }

    /// Determines the fallback strategy for a given primary strategy
    /// - Parameter primaryStrategy: The primary strategy that failed
    /// - Returns: Recommended fallback strategy
    static func fallbackStrategy(for primaryStrategy: TextExtractionStrategy) -> TextExtractionStrategy {
        switch primaryStrategy {
        case .parallel:
            return .sequential
        case .streaming:
            return .sequential
        case .sequential:
            return .adaptive
        case .adaptive:
            return .sequential
        }
    }

    /// Gets strategy-specific configuration parameters
    /// - Parameter strategy: The extraction strategy
    /// - Returns: Configuration parameters for the strategy
    static func configurationParameters(for strategy: TextExtractionStrategy) -> [String: Any] {
        switch strategy {
        case .parallel:
            return [
                "maxConcurrentOperations": 4,
                "batchSize": 1_024,
                "memoryThreshold": 50_000_000
            ]
        case .sequential:
            return [
                "batchSize": 2_048,
                "qualityLevel": "high",
                "enableValidation": true
            ]
        case .streaming:
            return [
                "chunkSize": 512,
                "bufferSize": 4_096,
                "memoryLimit": 25_000_000
            ]
        case .adaptive:
            return [
                "adaptiveThreshold": 0.7,
                "fallbackEnabled": true,
                "monitoringInterval": 1.0
            ]
        }
    }

    /// Estimates processing time for a strategy given document characteristics
    /// - Parameters:
    ///   - strategy: The extraction strategy
    ///   - analysis: Document analysis results
    /// - Returns: Estimated processing time in seconds
    static func estimatedProcessingTime(
        for strategy: TextExtractionStrategy,
        given analysis: StrategyDocumentAnalysis
    ) -> Double {
        let baseTime = Double(analysis.pageCount) * 0.5 // Base: 0.5 seconds per page

        let complexityMultiplier: Double
        switch analysis.contentComplexity {
        case .low:
            complexityMultiplier = 1.0
        case .medium:
            complexityMultiplier = 1.5
        case .high:
            complexityMultiplier = 2.5
        }

        let strategyMultiplier: Double
        switch strategy {
        case .parallel:
            strategyMultiplier = 0.4 // Fastest
        case .streaming:
            strategyMultiplier = 0.6
        case .adaptive:
            strategyMultiplier = 0.7
        case .sequential:
            strategyMultiplier = 1.0 // Slowest but most reliable
        }

        return baseTime * complexityMultiplier * strategyMultiplier
    }

    /// Calculates memory requirements for a strategy
    /// - Parameters:
    ///   - strategy: The extraction strategy
    ///   - analysis: Document analysis results
    /// - Returns: Estimated memory requirement in bytes
    static func estimatedMemoryRequirement(
        for strategy: TextExtractionStrategy,
        given analysis: StrategyDocumentAnalysis
    ) -> Int64 {
        let baseMemory = analysis.estimatedSize / 10 // Base: 10% of document size

        let strategyMultiplier: Double
        switch strategy {
        case .parallel:
            strategyMultiplier = 3.0 // Highest memory usage
        case .sequential:
            strategyMultiplier = 1.2
        case .adaptive:
            strategyMultiplier = 1.5
        case .streaming:
            strategyMultiplier = 0.5 // Lowest memory usage
        }

        return Int64(Double(baseMemory) * strategyMultiplier)
    }
}
// swiftlint:enable no_hardcoded_strings
