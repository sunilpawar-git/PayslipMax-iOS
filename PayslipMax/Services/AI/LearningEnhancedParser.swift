import Foundation
import PDFKit

/// Protocol for learning-enhanced parser functionality
public protocol LearningEnhancedParserProtocol {
    func parseWithLearning(_ pdfDocument: PDFDocument, documentType: LiteRTDocumentFormatType) async throws -> LearningEnhancedParseResult
    func applyAdaptation(_ adaptation: ParserAdaptation) async throws
    func getConfidenceAdjustments() async -> [String: Double]
    func recordParseResult(_ result: ParseResult, metrics: ParserPerformanceMetrics) async throws
}

/// Wrapper that enhances existing parsers with adaptive learning capabilities
@MainActor
public class LearningEnhancedParser: LearningEnhancedParserProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let baseParser: PayslipParserProtocol
    private let learningEngine: AdaptiveLearningEngineProtocol
    private let userLearningStore: UserLearningStoreProtocol
    private let performanceTracker: PerformanceTrackerProtocol
    private let parserName: String
    
    private var confidenceAdjustments: [String: Double] = [:]
    private var currentAdaptation: ParserAdaptation?
    
    @Published public var learningStats: ParserLearningStats = ParserLearningStats()
    @Published public var adaptationStatus: AdaptationStatus = .none
    
    // MARK: - Initialization
    
    public init(
        baseParser: PayslipParserProtocol,
        parserName: String,
        learningEngine: AdaptiveLearningEngineProtocol? = nil,
        userLearningStore: UserLearningStoreProtocol? = nil,
        performanceTracker: PerformanceTrackerProtocol? = nil
    ) {
        self.baseParser = baseParser
        self.parserName = parserName
        self.learningEngine = learningEngine ?? AdaptiveLearningEngine()
        self.userLearningStore = userLearningStore ?? UserLearningStore()
        self.performanceTracker = performanceTracker ?? PerformanceTracker()
        
        Task {
            await loadLearningData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Parse document with learning enhancements
    public func parseWithLearning(_ pdfDocument: PDFDocument, documentType: LiteRTDocumentFormatType) async throws -> LearningEnhancedParseResult {
        print("[LearningEnhancedParser] Parsing with learning for \(parserName)")
        
        let startTime = Date()
        
        // Get personalized suggestions
        let suggestions = try await learningEngine.getPersonalizedSuggestions(for: documentType)
        
        // Apply current adaptations
        try await applyCurrentAdaptations(documentType: documentType)
        
        // Perform base parsing
        let baseResult = try await performBaseParsing(pdfDocument, documentType: documentType)
        
        // Apply learning enhancements
        let enhancedResult = try await applyLearningEnhancements(baseResult, documentType: documentType)
        
        // Calculate performance metrics
        let endTime = Date()
        let processingTime = endTime.timeIntervalSince(startTime)
        let accuracy = calculateAccuracy(enhancedResult.extractedData)
        
        let metrics = ParserPerformanceMetrics(
            parserName: parserName,
            documentType: documentType,
            processingTime: processingTime,
            accuracy: accuracy,
            fieldsExtracted: enhancedResult.extractedData.count,
            fieldsCorrect: Int(accuracy * Double(enhancedResult.extractedData.count))
        )
        
        // Record performance
        try await performanceTracker.recordPerformance(metrics)
        
        // Update learning statistics
        await updateLearningStatistics(metrics)
        
        return LearningEnhancedParseResult(
            baseResult: baseResult,
            enhancedData: enhancedResult.extractedData,
            confidence: enhancedResult.confidence,
            suggestions: suggestions,
            adaptationsApplied: currentAdaptation != nil,
            processingTime: processingTime,
            accuracy: accuracy,
            learningInsights: enhancedResult.learningInsights
        )
    }
    
    /// Apply parser adaptation
    public func applyAdaptation(_ adaptation: ParserAdaptation) async throws {
        print("[LearningEnhancedParser] Applying adaptation for \(adaptation.parserName)")
        
        guard adaptation.parserName == parserName else {
            throw LearningEnhancedParserError.adaptationMismatch
        }
        
        currentAdaptation = adaptation
        
        // Apply confidence adjustments
        for (field, adjustment) in adaptation.adaptations {
            if let confidenceValue = adjustment as? Double {
                confidenceAdjustments[field] = confidenceValue
            }
        }
        
        adaptationStatus = .applied(adaptation.priority)
        
        print("[LearningEnhancedParser] Adaptation applied successfully")
    }
    
    /// Get current confidence adjustments
    public func getConfidenceAdjustments() async -> [String: Double] {
        return confidenceAdjustments
    }
    
    /// Record parse result for learning
    public func recordParseResult(_ result: ParseResult, metrics: ParserPerformanceMetrics) async throws {
        try await performanceTracker.recordPerformance(metrics)
        await updateLearningStatistics(metrics)
    }
    
    /// Apply user corrections for learning
    public func applyUserCorrections(_ corrections: [UserCorrection]) async throws {
        for correction in corrections {
            try await learningEngine.processUserCorrection(correction)
            
            // Update confidence adjustments based on corrections
            let fieldAdjustment = await learningEngine.getConfidenceAdjustment(
                for: correction.fieldName,
                documentType: correction.documentType
            )
            confidenceAdjustments[correction.fieldName] = fieldAdjustment
        }
        
        await updateLearningStatistics()
    }
    
    /// Get learning recommendations
    public func getLearningRecommendations(for documentType: LiteRTDocumentFormatType) async throws -> [LearningRecommendation] {
        let suggestions = try await learningEngine.getPersonalizedSuggestions(for: documentType)
        
        return suggestions.map { suggestion in
            LearningRecommendation(
                type: .suggestion,
                title: suggestion.suggestion,
                description: "Based on your correction patterns",
                confidence: suggestion.confidence,
                field: suggestion.field
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Load learning data for this parser
    private func loadLearningData() async {
        do {
            // Load confidence adjustments from user learning store
            let allCorrections = try await userLearningStore.getAllCorrections()
            let parserCorrections = allCorrections.filter { $0.parserUsed == parserName }
            
            // Calculate confidence adjustments from corrections
            let fieldGroups = Dictionary(grouping: parserCorrections) { $0.fieldName }
            
            for (fieldName, corrections) in fieldGroups {
                let totalExtractions = corrections.reduce(0) { $0 + $1.totalExtractions }
                let totalCorrections = corrections.count
                
                guard totalExtractions > 0 else { continue }
                
                let errorRate = Double(totalCorrections) / Double(totalExtractions)
                confidenceAdjustments[fieldName] = max(-0.5, -errorRate * 0.3)
            }
            
            await updateLearningStatistics()
            
        } catch {
            print("[LearningEnhancedParser] Error loading learning data: \(error)")
        }
    }
    
    /// Apply current adaptations for document type
    private func applyCurrentAdaptations(documentType: LiteRTDocumentFormatType) async throws {
        // Get parser-specific adaptations
        let adaptation = try await learningEngine.adaptParserParameters(
            for: parserName,
            documentType: documentType
        )
        
        if adaptation.priority == .high {
            try await applyAdaptation(adaptation)
        }
    }
    
    /// Perform base parsing with original parser
    private func performBaseParsing(_ pdfDocument: PDFDocument, documentType: LiteRTDocumentFormatType) async throws -> ParseResult {
        // Use base parser to extract data
        // This would integrate with the existing parser interface
        
        // For now, simulate base parsing
        return ParseResult(
            extractedData: [:],
            confidence: 0.8,
            errors: [],
            processingTime: 1.0
        )
    }
    
    /// Apply learning enhancements to base result
    private func applyLearningEnhancements(_ baseResult: ParseResult, documentType: LiteRTDocumentFormatType) async throws -> EnhancedParseResult {
        var enhancedData = baseResult.extractedData
        var overallConfidence = baseResult.confidence
        var insights: [LearningInsight] = []
        
        // Apply confidence adjustments
        for (field, value) in enhancedData {
            if let adjustment = confidenceAdjustments[field] {
                // Adjust confidence for this field
                let _ = overallConfidence + adjustment // Confidence adjustment calculated but not used in this implementation
                enhancedData[field] = value // Keep value, adjust confidence separately
                
                insights.append(LearningInsight(
                    type: .confidenceAdjustment,
                    field: field,
                    description: "Confidence adjusted by \(Int(adjustment * 100))% based on learning",
                    impact: adjustment
                ))
            }
        }
        
        // Apply pattern-based corrections
        let patternCorrections = try await applyPatternBasedCorrections(enhancedData, documentType: documentType)
        enhancedData.merge(patternCorrections) { (_, new) in new }
        
        if !patternCorrections.isEmpty {
            insights.append(LearningInsight(
                type: .patternCorrection,
                field: "multiple",
                description: "Applied \(patternCorrections.count) pattern-based corrections",
                impact: 0.1
            ))
        }
        
        // Apply validation-based enhancements
        let validationEnhancements = try await applyValidationEnhancements(enhancedData, documentType: documentType)
        enhancedData.merge(validationEnhancements) { (_, new) in new }
        
        // Calculate enhanced confidence
        let enhancementBonus = insights.reduce(0.0) { $0 + max(0, $1.impact) }
        overallConfidence = min(1.0, overallConfidence + enhancementBonus)
        
        return EnhancedParseResult(
            extractedData: enhancedData,
            confidence: overallConfidence,
            learningInsights: insights
        )
    }
    
    /// Apply pattern-based corrections
    private func applyPatternBasedCorrections(_ data: [String: Any], documentType: LiteRTDocumentFormatType) async throws -> [String: Any] {
        var corrections: [String: Any] = [:]
        
        // Get user patterns for this document type
        let patterns = try await userLearningStore.getUserPatterns(for: documentType)
        
        for pattern in patterns where pattern.type == .fieldExtraction && pattern.confidence > 0.7 {
            if let currentValue = data[pattern.fieldName] as? String {
                // Check if current value doesn't match learned pattern
                if currentValue != pattern.commonValue && pattern.frequency >= 3 {
                    corrections[pattern.fieldName] = pattern.commonValue
                }
            }
        }
        
        return corrections
    }
    
    /// Apply validation-based enhancements
    private func applyValidationEnhancements(_ data: [String: Any], documentType: LiteRTDocumentFormatType) async throws -> [String: Any] {
        let enhancements: [String: Any] = [:]
        
        // Apply learned validation rules
        // This would integrate with validation rules from user corrections
        
        return enhancements
    }
    
    /// Calculate accuracy estimate
    private func calculateAccuracy(_ extractedData: [String: Any]) -> Double {
        // Simple accuracy calculation based on data completeness and confidence adjustments
        let expectedFields = getExpectedFieldCount()
        let extractedFields = extractedData.count
        
        let completeness = Double(extractedFields) / Double(expectedFields)
        
        // Apply confidence adjustments
        let avgConfidenceAdjustment = confidenceAdjustments.values.reduce(0.0, +) / Double(max(1, confidenceAdjustments.count))
        
        return min(1.0, max(0.0, completeness + avgConfidenceAdjustment))
    }
    
    /// Get expected field count for document type
    private func getExpectedFieldCount() -> Int {
        // This would be determined based on document type and parser capabilities
        return 10 // Default expectation
    }
    
    /// Update learning statistics
    private func updateLearningStatistics(_ metrics: ParserPerformanceMetrics? = nil) async {
        learningStats.totalDocumentsParsed += 1
        
        if let metrics = metrics {
            learningStats.averageAccuracy = (learningStats.averageAccuracy + metrics.accuracy) / 2.0
            learningStats.averageProcessingTime = (learningStats.averageProcessingTime + metrics.processingTime) / 2.0
        }
        
        learningStats.confidenceAdjustmentCount = confidenceAdjustments.count
        learningStats.hasActiveAdaptation = currentAdaptation != nil
        learningStats.lastUpdateDate = Date()
    }
}

// MARK: - Supporting Types

/// Result of learning-enhanced parsing
public struct LearningEnhancedParseResult {
    public let baseResult: ParseResult
    public let enhancedData: [String: Any]
    public let confidence: Double
    public let suggestions: [PersonalizedSuggestion]
    public let adaptationsApplied: Bool
    public let processingTime: TimeInterval
    public let accuracy: Double
    public let learningInsights: [LearningInsight]
}

/// Enhanced parse result with learning insights
public struct EnhancedParseResult {
    public let extractedData: [String: Any]
    public let confidence: Double
    public let learningInsights: [LearningInsight]
}

/// Base parse result
public struct ParseResult {
    public let extractedData: [String: Any]
    public let confidence: Double
    public let errors: [String]
    public let processingTime: TimeInterval
}

/// Learning insight from parsing
public struct LearningInsight {
    public let type: LearningInsightType
    public let field: String
    public let description: String
    public let impact: Double
    
    public enum LearningInsightType {
        case confidenceAdjustment
        case patternCorrection
        case validationEnhancement
        case suggestionApplied
    }
}

/// Learning recommendation
public struct LearningRecommendation {
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let confidence: Double
    public let field: String
    
    public enum RecommendationType {
        case suggestion
        case adaptation
        case validation
        case improvement
    }
}

/// Parser learning statistics
public struct ParserLearningStats {
    public var totalDocumentsParsed: Int = 0
    public var averageAccuracy: Double = 0.0
    public var averageProcessingTime: TimeInterval = 0.0
    public var confidenceAdjustmentCount: Int = 0
    public var hasActiveAdaptation: Bool = false
    public var lastUpdateDate: Date = Date()
}

/// Adaptation status
public enum AdaptationStatus {
    case none
    case pending
    case applied(AdaptationPriority)
    case failed(String)
}

/// Errors for learning-enhanced parser
public enum LearningEnhancedParserError: Error, LocalizedError {
    case adaptationMismatch
    case learningDataCorrupted
    case enhancementFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .adaptationMismatch:
            return "Parser adaptation mismatch"
        case .learningDataCorrupted:
            return "Learning data is corrupted"
        case .enhancementFailed(let reason):
            return "Enhancement failed: \(reason)"
        }
    }
}

/// Protocol for payslip parsers (placeholder)
public protocol PayslipParserProtocol {
    var name: String { get }
    // Additional parser methods would be defined here
}
