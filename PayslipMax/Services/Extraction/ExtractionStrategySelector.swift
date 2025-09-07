import Foundation
import PDFKit

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
final class ExtractionStrategySelector: ExtractionStrategySelectorProtocol {
    
    // MARK: - Dependencies
    
    /// Strategy implementations
    private let strategies: ExtractionStrategies
    
    /// Strategy evaluation rules
    private let evaluationRules: [StrategyEvaluationRule]
    
    // MARK: - Initialization
    
    /// Initializes the strategy selector with dependencies
    /// - Parameters:
    ///   - strategies: Strategy implementations
    ///   - evaluationRules: Custom evaluation rules (optional)
    init(
        strategies: ExtractionStrategies = ExtractionStrategies(),
        evaluationRules: [StrategyEvaluationRule]? = nil
    ) {
        self.strategies = strategies
        self.evaluationRules = evaluationRules ?? ExtractionStrategies.defaultEvaluationRules()
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
        let resourceAssessment = assessSystemResources()
        
        // Create evaluation context
        let context = StrategyEvaluationContext(
            documentAnalysis: documentAnalysis,
            resourceAssessment: resourceAssessment,
            userPreferences: userPreferences ?? ExtractionPreferences()
        )
        
        // Evaluate all strategies
        let strategyScores = evaluateStrategies(context: context)
        
        // Select best strategy
        let bestStrategy = selectBestStrategy(from: strategyScores)
        
        // Validate strategy selection
        guard StrategyValidation.isValidStrategy(bestStrategy, for: context) else {
            let fallback = ExtractionStrategies.fallbackStrategy(for: bestStrategy)
            return createRecommendation(strategy: fallback, context: context, confidence: 0.5)
        }
        
        // Calculate confidence
        let confidence = calculateConfidence(from: strategyScores)
        
        return createRecommendation(strategy: bestStrategy, context: context, confidence: confidence)
    }
    
    /// Analyzes document characteristics for strategy selection
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document analysis results
    func analyzeDocument(_ document: PDFDocument) async -> StrategyDocumentAnalysis {
        let pageCount = document.pageCount
        let estimatedSize = Int64(pageCount * 50000) // Rough estimate: 50KB per page
        
        // Assess content complexity
        let contentComplexity = assessContentComplexity(document)
        
        // Check for images and tables (simplified detection)
        let hasImages = pageCount > 0 // Simplified - assume images exist
        let hasTables = pageCount > 5 // Simplified heuristic
        
        // Assess text quality
        let textQuality = assessTextQuality(document)
        
        return StrategyDocumentAnalysis(
            pageCount: pageCount,
            estimatedSize: estimatedSize,
            contentComplexity: contentComplexity,
            hasImages: hasImages,
            hasTables: hasTables,
            textQuality: textQuality
        )
    }
    
    // MARK: - Private Implementation
    
    /// Assesses current system resources
    /// - Returns: Resource assessment results
    private func assessSystemResources() -> ResourceAssessment {
        let processInfo = ProcessInfo.processInfo
        let availableMemory = Int64(processInfo.physicalMemory / 4) // Conservative estimate
        let systemLoad = 0.5 // Simplified - would use actual system metrics
        let memoryPressure: MemoryPressureLevel = availableMemory > 1_000_000_000 ? .normal : .moderate
        
        return ResourceAssessment(
            availableMemory: availableMemory,
            systemLoad: systemLoad,
            memoryPressure: memoryPressure
        )
    }
    
    /// Evaluates all available strategies
    /// - Parameter context: Evaluation context
    /// - Returns: Dictionary of strategy scores
    private func evaluateStrategies(context: StrategyEvaluationContext) -> [TextExtractionStrategy: Double] {
        var scores: [TextExtractionStrategy: Double] = [:]
        
        for strategy in ExtractionStrategies.allStrategies() {
            var totalScore: Double = 0
            var totalWeight: Double = 0
            
            for rule in evaluationRules {
                let score = rule.evaluate(strategy: strategy, context: context)
                totalScore += score * rule.weight
                totalWeight += rule.weight
            }
            
            scores[strategy] = totalWeight > 0 ? totalScore / totalWeight : 0
        }
        
        return scores
    }
    
    /// Selects the best strategy from evaluation scores
    /// - Parameter scores: Strategy evaluation scores
    /// - Returns: Best performing strategy
    private func selectBestStrategy(from scores: [TextExtractionStrategy: Double]) -> TextExtractionStrategy {
        return scores.max(by: { $0.value < $1.value })?.key ?? .adaptive
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
        return min(1.0, max(0.0, scoreDifference / max(topScore, 0.001)))
    }
    
    /// Creates a strategy recommendation
    /// - Parameters:
    ///   - strategy: Selected strategy
    ///   - context: Evaluation context
    ///   - confidence: Confidence score
    /// - Returns: Strategy recommendation
    private func createRecommendation(
        strategy: TextExtractionStrategy,
        context: StrategyEvaluationContext,
        confidence: Double
    ) -> StrategyRecommendation {
        let alternatives = ExtractionStrategies.allStrategies().filter { $0 != strategy }
        let reasoning = generateReasoning(for: strategy, context: context)
        
        return StrategyRecommendation(
            strategy: strategy,
            confidence: confidence,
            alternatives: alternatives,
            reasoning: reasoning
        )
    }
    
    /// Generates reasoning for strategy selection
    /// - Parameters:
    ///   - strategy: Selected strategy
    ///   - context: Evaluation context
    /// - Returns: Human-readable reasoning
    private func generateReasoning(for strategy: TextExtractionStrategy, context: StrategyEvaluationContext) -> String {
        var reasons: [String] = []
        
        // Memory-based reasoning
        if context.resourceAssessment.memoryPressure == .high {
            reasons.append("high memory pressure")
        }
        
        // Document-based reasoning
        if context.documentAnalysis.pageCount > 50 {
            reasons.append("large document (\(context.documentAnalysis.pageCount) pages)")
        }
        
        if context.documentAnalysis.contentComplexity == .high {
            reasons.append("complex document layout")
        }
        
        // User preference reasoning
        switch context.userPreferences.priority {
        case .speed:
            reasons.append("speed optimization requested")
        case .quality:
            reasons.append("quality optimization requested")
        case .memoryEfficient:
            reasons.append("memory efficiency requested")
        case .balanced:
            reasons.append("balanced approach requested")
        }
        
        let baseReason = "Selected \(strategy) strategy"
        return reasons.isEmpty ? baseReason : "\(baseReason) due to: \(reasons.joined(separator: ", "))"
    }
    
    /// Assesses content complexity of the document
    /// - Parameter document: The PDF document
    /// - Returns: Content complexity level
    private func assessContentComplexity(_ document: PDFDocument) -> ContentComplexity {
        let pageCount = document.pageCount
        
        if pageCount > 100 {
            return .high
        } else if pageCount > 20 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Assesses text quality of the document
    /// - Parameter document: The PDF document
    /// - Returns: Text quality assessment
    private func assessTextQuality(_ document: PDFDocument) -> TextQuality {
        // Simplified assessment - would analyze actual text in practice
        guard document.pageCount > 0 else { return .poor }
        
        // Sample first page for quality assessment
        guard let firstPage = document.page(at: 0),
              let text = firstPage.string else {
            return .scanned
        }
        
        // Basic heuristics for text quality
        let hasLongWords = text.contains { $0.isLetter && text.components(separatedBy: .whitespaces).contains { $0.count > 10 } }
        let hasSpecialChars = text.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
        
        if hasLongWords && hasSpecialChars {
            return .excellent
        } else if !text.isEmpty {
            return .good
        } else {
            return .scanned
        }
    }
}