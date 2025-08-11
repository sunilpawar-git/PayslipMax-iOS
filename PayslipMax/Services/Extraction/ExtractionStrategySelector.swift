import Foundation
import PDFKit

/// Protocol for extraction strategy selection
protocol ExtractionStrategySelectorProtocol {
    /// Selects the optimal extraction strategy for a given document
    /// - Parameters:
    ///   - document: The PDF document to analyze
    ///   - userPreferences: User-specified preferences for extraction
    /// - Returns: The recommended extraction strategy and options
    func selectOptimalStrategy(
        for document: PDFDocument,
        userPreferences: ExtractionPreferences?
    ) async -> StrategyRecommendation
    
    /// Analyzes document characteristics for strategy selection
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document analysis results
    func analyzeDocument(_ document: PDFDocument) async -> StrategyDocumentAnalysis
}

/// Service responsible for selecting the optimal extraction strategy
///
/// This service analyzes PDF documents to determine the most appropriate
/// extraction strategy based on document characteristics, system resources,
/// and user preferences. It serves as the decision-making layer between
/// document analysis and strategy execution.
///
/// ## Strategy Selection Factors:
/// - Document size and page count
/// - Content complexity (text vs images vs tables)
/// - Available system memory
/// - User preferences (speed vs quality vs memory efficiency)
/// - Document format characteristics (scanned vs native)
///
/// ## Architecture:
/// The selector uses a rule-based system with configurable weights to
/// evaluate multiple factors and recommend the most suitable strategy.
class ExtractionStrategySelector: ExtractionStrategySelectorProtocol {
    
    // MARK: - Dependencies
    
    /// Document analyzer for detailed analysis
    private let documentAnalyzer: ExtractionDocumentAnalyzer
    
    /// Memory manager for resource assessment
    private let memoryManager: TextExtractionMemoryManager
    
    /// Strategy evaluation rules
    private let evaluationRules: [StrategyEvaluationRule]
    
    // MARK: - Configuration
    
    /// Default strategy selection weights
    private struct SelectionWeights {
        static let memoryPressure: Double = 0.4
        static let documentComplexity: Double = 0.3
        static let userPreference: Double = 0.2
        static let systemPerformance: Double = 0.1
    }
    
    // MARK: - Initialization
    
    /// Initializes the strategy selector with dependencies
    /// - Parameters:
    ///   - documentAnalyzer: Analyzer for document characteristics
    ///   - memoryManager: Manager for memory resource assessment
    ///   - evaluationRules: Custom evaluation rules (optional)
    init(
        documentAnalyzer: ExtractionDocumentAnalyzer,
        memoryManager: TextExtractionMemoryManager,
        evaluationRules: [StrategyEvaluationRule]? = nil
    ) {
        self.documentAnalyzer = documentAnalyzer
        self.memoryManager = memoryManager
        self.evaluationRules = evaluationRules ?? Self.defaultEvaluationRules()
    }
    
    // MARK: - Strategy Selection
    
    /// Selects the optimal extraction strategy for a given document
    /// - Parameters:
    ///   - document: The PDF document to analyze
    ///   - userPreferences: User-specified preferences for extraction
    /// - Returns: The recommended extraction strategy and options
    func selectOptimalStrategy(
        for document: PDFDocument,
        userPreferences: ExtractionPreferences? = nil
    ) async -> StrategyRecommendation {
        
        // Analyze document characteristics
        let documentAnalysis = await analyzeDocument(document)
        
        // Assess system resources
        let resourceAssessment = assessSystemResources(for: document)
        
        // Evaluate strategies using rules
        let evaluationContext = StrategyEvaluationContext(
            documentAnalysis: documentAnalysis,
            resourceAssessment: resourceAssessment,
            userPreferences: userPreferences ?? .default
        )
        
        let strategyScores = evaluateStrategies(using: evaluationContext)
        
        // Select best strategy
        let bestStrategy = selectBestStrategy(from: strategyScores)
        
        // Generate optimized options
        let optimizedOptions = generateOptimizedOptions(
            for: bestStrategy,
            context: evaluationContext
        )
        
        let recommendation = StrategyRecommendation(
            strategy: bestStrategy,
            options: optimizedOptions,
            confidence: calculateConfidence(from: strategyScores),
            reasoning: generateReasoning(for: bestStrategy, context: evaluationContext)
        )
        // Record PII-safe diagnostics
        recordDiagnosticsDecision(
            documentAnalysis: documentAnalysis,
            resources: resourceAssessment,
            recommendation: recommendation
        )
        return recommendation
    }
    
    /// Analyzes document characteristics for strategy selection
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document analysis results
    func analyzeDocument(_ document: PDFDocument) async -> StrategyDocumentAnalysis {
        // Get basic document characteristics
        let pageCount = document.pageCount
        let estimatedSize = estimateDocumentSize(document)
        
        // Analyze document content using the document analyzer
        let documentCharacteristics = documentAnalyzer.analyzeDocumentCharacteristics(document)
        
        // Determine content complexity
        let contentComplexity = assessContentComplexity(document)
        
        // Check for scanned content
        let hasScannedContent = documentAnalyzer.hasScannedContent(document)
        
        // Estimate processing requirements
        let processingRequirements = estimateProcessingRequirements(
            pageCount: pageCount,
            complexity: contentComplexity,
            hasScannedContent: hasScannedContent
        )
        
        return StrategyDocumentAnalysis(
            pageCount: pageCount,
            estimatedSizeBytes: estimatedSize,
            contentComplexity: contentComplexity,
            hasScannedContent: hasScannedContent,
            processingRequirements: processingRequirements,
            documentCharacteristics: documentCharacteristics
        )
    }
    
    // MARK: - Private Methods
    
    /// Assesses current system resources
    /// - Parameter document: The document being processed
    /// - Returns: System resource assessment
    private func assessSystemResources(for document: PDFDocument) -> ResourceAssessment {
        let availableMemory = memoryManager.getAvailableMemory()
        let estimatedMemoryNeed = memoryManager.estimateMemoryRequirement(for: document)
        let memoryPressure = Double(estimatedMemoryNeed) / Double(availableMemory)
        
        return ResourceAssessment(
            availableMemoryMB: availableMemory / (1024 * 1024),
            estimatedMemoryNeedMB: estimatedMemoryNeed / (1024 * 1024),
            memoryPressureRatio: memoryPressure,
            processorCoreCount: ProcessInfo.processInfo.processorCount
        )
    }
    
    /// Evaluates all strategies against the current context
    /// - Parameter context: The evaluation context
    /// - Returns: Dictionary of strategies and their scores
    private func evaluateStrategies(using context: StrategyEvaluationContext) -> [TextExtractionStrategy: Double] {
        var scores: [TextExtractionStrategy: Double] = [:]
        
        let strategies: [TextExtractionStrategy] = [.parallel, .sequential, .streaming, .adaptive]
        
        for strategy in strategies {
            var totalScore = 0.0
            
            for rule in evaluationRules {
                let ruleScore = rule.evaluate(strategy: strategy, context: context)
                totalScore += ruleScore * rule.weight
            }
            
            scores[strategy] = totalScore
        }
        
        return scores
    }
    
    /// Selects the best strategy from the evaluation scores
    /// - Parameter scores: Strategy evaluation scores
    /// - Returns: The best scoring strategy
    private func selectBestStrategy(from scores: [TextExtractionStrategy: Double]) -> TextExtractionStrategy {
        return scores.max(by: { $0.value < $1.value })?.key ?? .adaptive
    }
    
    /// Generates optimized extraction options for the selected strategy
    /// - Parameters:
    ///   - strategy: The selected extraction strategy
    ///   - context: The evaluation context
    /// - Returns: Optimized extraction options
    private func generateOptimizedOptions(
        for strategy: TextExtractionStrategy,
        context: StrategyEvaluationContext
    ) -> ExtractionOptions {
        var options = ExtractionOptions.default
        
        // Apply strategy-specific optimizations
        switch strategy {
        case .parallel:
            options.useParallelProcessing = true
            options.maxConcurrentOperations = min(8, context.resourceAssessment.processorCoreCount)
            
        case .sequential:
            options.useParallelProcessing = false
            options.useAdaptiveBatching = true
            
        case .streaming:
            options.useParallelProcessing = false
            options.memoryThresholdMB = 100
            
        case .adaptive:
            // Use context to determine best settings
            if context.resourceAssessment.memoryPressureRatio > 0.8 {
                options.useParallelProcessing = false
                options.memoryThresholdMB = 100
            } else {
                options.useParallelProcessing = true
                options.maxConcurrentOperations = context.resourceAssessment.processorCoreCount
            }
        }
        
        // Apply user preferences
        switch context.userPreferences.priority {
        case .speed:
            options.preprocessText = false
            options.maxConcurrentOperations = min(options.maxConcurrentOperations * 2, 16)
            
        case .quality:
            options.preprocessText = true
            options.useParallelProcessing = false
            
        case .memoryEfficient:
            options.memoryThresholdMB = 50
            options.useAdaptiveBatching = true
        }
        
        return options
    }
    
    /// Calculates confidence in the strategy selection
    /// - Parameter scores: Strategy evaluation scores
    /// - Returns: Confidence value between 0.0 and 1.0
    private func calculateConfidence(from scores: [TextExtractionStrategy: Double]) -> Double {
        let sortedScores = scores.values.sorted(by: >)
        guard sortedScores.count >= 2 else { return 1.0 }
        
        let topScore = sortedScores[0]
        let secondScore = sortedScores[1]
        
        // Confidence is higher when there's a clear winner
        let scoreDifference = topScore - secondScore
        return min(1.0, scoreDifference / topScore)
    }
    
    /// Generates human-readable reasoning for the strategy selection
    /// - Parameters:
    ///   - strategy: The selected strategy
    ///   - context: The evaluation context
    /// - Returns: Reasoning explanation
    private func generateReasoning(
        for strategy: TextExtractionStrategy,
        context: StrategyEvaluationContext
    ) -> String {
        var reasons: [String] = []
        
        // Memory-based reasoning
        if context.resourceAssessment.memoryPressureRatio > 0.8 {
            reasons.append("High memory pressure detected")
        }
        
        // Document-based reasoning
        if context.documentAnalysis.pageCount > 50 {
            reasons.append("Large document with \(context.documentAnalysis.pageCount) pages")
        }
        
        if context.documentAnalysis.contentComplexity == .high {
            reasons.append("Complex document layout detected")
        }
        
        if context.documentAnalysis.hasScannedContent {
            reasons.append("Scanned content requires special processing")
        }
        
        // User preference reasoning
        switch context.userPreferences.priority {
        case .speed:
            reasons.append("Speed optimization requested")
        case .quality:
            reasons.append("Quality optimization requested")
        case .memoryEfficient:
            reasons.append("Memory efficiency requested")
        }
        
        let baseReason = "Selected \(strategy) strategy"
        return reasons.isEmpty ? baseReason : "\(baseReason): \(reasons.joined(separator: ", "))"
    }
    
    /// Estimates document size in bytes
    /// - Parameter document: The PDF document
    /// - Returns: Estimated size in bytes
    private func estimateDocumentSize(_ document: PDFDocument) -> UInt64 {
        // This is a simplified estimation
        // In practice, you might use document.dataRepresentation()?.count
        return UInt64(document.pageCount * 50000) // Rough estimate: 50KB per page
    }
    
    /// Assesses content complexity of the document
    /// - Parameter document: The PDF document
    /// - Returns: Content complexity level
    private func assessContentComplexity(_ document: PDFDocument) -> ContentComplexity {
        // Simplified complexity assessment
        // In practice, this would analyze layout, tables, images, etc.
        let pageCount = document.pageCount
        
        if pageCount > 100 {
            return .high
        } else if pageCount > 20 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Estimates processing requirements for the document
    /// - Parameters:
    ///   - pageCount: Number of pages in the document
    ///   - complexity: Content complexity level
    ///   - hasScannedContent: Whether document contains scanned content
    /// - Returns: Processing requirements assessment
    private func estimateProcessingRequirements(
        pageCount: Int,
        complexity: ContentComplexity,
        hasScannedContent: Bool
    ) -> ProcessingRequirements {
        let baseTimePerPage: TimeInterval = hasScannedContent ? 2.0 : 0.5
        let complexityMultiplier = complexity.processingMultiplier
        
        return ProcessingRequirements(
            estimatedTimeSeconds: TimeInterval(pageCount) * baseTimePerPage * complexityMultiplier,
            estimatedMemoryMB: UInt64(pageCount * (hasScannedContent ? 10 : 2)),
            requiresOCR: hasScannedContent
        )
    }
    
    /// Creates default evaluation rules
    /// - Returns: Array of default strategy evaluation rules
    private static func defaultEvaluationRules() -> [StrategyEvaluationRule] {
        return [
            MemoryPressureRule(),
            DocumentSizeRule(),
            ContentComplexityRule(),
            UserPreferenceRule()
        ]
    }
}

// MARK: - Supporting Models and Enums

/// User preferences for extraction
struct ExtractionPreferences {
    enum Priority {
        case speed
        case quality
        case memoryEfficient
    }
    
    let priority: Priority
    let allowParallelProcessing: Bool
    let maxMemoryUsageMB: Int?
    
    static let `default` = ExtractionPreferences(
        priority: .quality,
        allowParallelProcessing: true,
        maxMemoryUsageMB: nil
    )
}

/// Strategy recommendation result
struct StrategyRecommendation {
    let strategy: TextExtractionStrategy
    let options: ExtractionOptions
    let confidence: Double
    let reasoning: String
}

/// Strategy document analysis results
struct StrategyDocumentAnalysis {
    let pageCount: Int
    let estimatedSizeBytes: UInt64
    let contentComplexity: ContentComplexity
    let hasScannedContent: Bool
    let processingRequirements: ProcessingRequirements
    let documentCharacteristics: Any // Placeholder for actual DocumentCharacteristics
}

/// Content complexity levels
enum ContentComplexity {
    case low
    case medium
    case high
    
    var processingMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 1.5
        case .high: return 2.0
        }
    }
}

/// System resource assessment
struct ResourceAssessment {
    let availableMemoryMB: UInt64
    let estimatedMemoryNeedMB: UInt64
    let memoryPressureRatio: Double
    let processorCoreCount: Int
}

/// Processing requirements for a document
struct ProcessingRequirements {
    let estimatedTimeSeconds: TimeInterval
    let estimatedMemoryMB: UInt64
    let requiresOCR: Bool
}

/// Context for strategy evaluation
struct StrategyEvaluationContext {
    let documentAnalysis: StrategyDocumentAnalysis
    let resourceAssessment: ResourceAssessment
    let userPreferences: ExtractionPreferences
}

/// Protocol for strategy evaluation rules
protocol StrategyEvaluationRule {
    var weight: Double { get }
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double
}

// MARK: - Default Evaluation Rules

struct MemoryPressureRule: StrategyEvaluationRule {
    let weight: Double = 0.4
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let memoryPressure = context.resourceAssessment.memoryPressureRatio
        
        switch strategy {
        case .streaming:
            return memoryPressure > 0.8 ? 1.0 : 0.3
        case .sequential:
            return memoryPressure > 0.6 ? 0.8 : 0.6
        case .parallel:
            return memoryPressure < 0.4 ? 1.0 : 0.2
        case .adaptive:
            return 0.7 // Always decent choice
        }
    }
}

struct DocumentSizeRule: StrategyEvaluationRule {
    let weight: Double = 0.3
    
    func evaluate(strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> Double {
        let pageCount = context.documentAnalysis.pageCount
        
        switch strategy {
        case .streaming:
            return pageCount > 100 ? 1.0 : 0.4
        case .parallel:
            return pageCount > 10 && pageCount < 100 ? 1.0 : 0.6
        case .sequential:
            return pageCount < 20 ? 0.8 : 0.4
        case .adaptive:
            return 0.8 // Good for most sizes
        }
    }
}

struct ContentComplexityRule: StrategyEvaluationRule {
    let weight: Double = 0.2
    
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