import Foundation
import SwiftData
import Combine

/// Protocol for adaptive learning functionality
public protocol AdaptiveLearningEngineProtocol {
    func processUserCorrection(_ correction: UserCorrection) async throws
    func getPersonalizedSuggestions(for documentType: LiteRTDocumentFormatType) async throws -> [PersonalizedSuggestion]
    func adaptParserParameters(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> ParserAdaptation
    func trackParserPerformance(_ metrics: ParserPerformanceMetrics) async throws
    func getConfidenceAdjustment(for field: String, documentType: LiteRTDocumentFormatType) async -> Double
}

/// Adaptive learning engine that improves extraction accuracy through user feedback
@MainActor
public class AdaptiveLearningEngine: AdaptiveLearningEngineProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let userLearningStore: any UserLearningStoreProtocol
    private let patternAnalyzer: PatternAnalyzer
    private let performanceTracker: any PerformanceTrackerProtocol
    private let privacyManager: any PrivacyPreservingLearningManagerProtocol
    
    @Published public var learningStats: LearningStatistics = LearningStatistics()
    
    // MARK: - Initialization
    
    public init(
        userLearningStore: (any UserLearningStoreProtocol)? = nil,
        patternAnalyzer: PatternAnalyzer? = nil,
        performanceTracker: (any PerformanceTrackerProtocol)? = nil,
        privacyManager: (any PrivacyPreservingLearningManagerProtocol)? = nil
    ) {
        self.userLearningStore = userLearningStore ?? UserLearningStore()
        self.patternAnalyzer = patternAnalyzer ?? PatternAnalyzer()
        self.performanceTracker = performanceTracker ?? PerformanceTracker()
        self.privacyManager = privacyManager ?? PrivacyPreservingLearningManager()
    }
    
    // MARK: - Public Methods
    
    /// Process user correction and update learning models
    public func processUserCorrection(_ correction: UserCorrection) async throws {
        print("[AdaptiveLearningEngine] Processing user correction for field: \(correction.fieldName)")
        
        // Store the correction securely
        try await userLearningStore.storeCorrection(correction)
        
        // Analyze patterns in the correction
        let pattern = try await patternAnalyzer.analyzeCorrection(correction)
        
        // Update learning models based on the pattern
        try await updateLearningModels(with: pattern)
        
        // Update statistics
        await updateLearningStatistics(correction)
        
        print("[AdaptiveLearningEngine] Correction processed successfully")
    }
    
    /// Get personalized suggestions based on user's correction history
    public func getPersonalizedSuggestions(for documentType: LiteRTDocumentFormatType) async throws -> [PersonalizedSuggestion] {
        print("[AdaptiveLearningEngine] Generating personalized suggestions for: \(documentType)")
        
        // Get user's historical patterns
        let userPatterns = try await userLearningStore.getUserPatterns(for: documentType)
        
        // Generate suggestions based on patterns
        let suggestions = try await generateSuggestions(from: userPatterns, documentType: documentType)
        
        return suggestions
    }
    
    /// Adapt parser parameters based on user's correction patterns
    public func adaptParserParameters(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> ParserAdaptation {
        print("[AdaptiveLearningEngine] Adapting parameters for parser: \(parser)")
        
        // Get parser-specific corrections
        let corrections = try await userLearningStore.getCorrections(forParser: parser, documentType: documentType)
        
        // Analyze patterns and generate adaptations
        let adaptation = try await analyzeAndAdapt(corrections: corrections, parser: parser)
        
        return adaptation
    }
    
    /// Track parser performance for continuous improvement
    public func trackParserPerformance(_ metrics: ParserPerformanceMetrics) async throws {
        try await performanceTracker.recordPerformance(metrics)
        
        // Update learning statistics
        await updatePerformanceStatistics(metrics)
    }
    
    /// Get confidence adjustment based on user feedback patterns
    public func getConfidenceAdjustment(for field: String, documentType: LiteRTDocumentFormatType) async -> Double {
        do {
            let corrections = try await userLearningStore.getCorrections(forField: field, documentType: documentType)
            
            // Calculate confidence adjustment based on correction frequency
            let totalExtractions = corrections.reduce(0) { $0 + $1.totalExtractions }
            let totalCorrections = corrections.count
            
            // If no corrections exist, return a small positive adjustment to indicate learning readiness
            guard totalExtractions > 0 else { 
                // Return a small positive adjustment for new fields to indicate learning capability
                return 0.1 
            }
            
            let errorRate = Double(totalCorrections) / Double(totalExtractions)
            
            // Reduce confidence for fields with high error rates
            return max(-0.3, -errorRate * 0.5)
            
        } catch {
            print("[AdaptiveLearningEngine] Error calculating confidence adjustment: \(error)")
            return 0.1 // Return positive value for error cases too
        }
    }
    
    // MARK: - Private Methods
    
    /// Update learning models with new pattern
    private func updateLearningModels(with pattern: CorrectionPattern) async throws {
        // Apply privacy-preserving learning techniques
        let anonymizedPattern = try await privacyManager.anonymizePattern(pattern)
        
        // Update pattern weights
        try await patternAnalyzer.updatePatternWeights(anonymizedPattern)
        
        // Update confidence adjustments
        try await updateConfidenceAdjustments(pattern)
    }
    
    /// Generate personalized suggestions from user patterns
    private func generateSuggestions(from patterns: [UserPattern], documentType: LiteRTDocumentFormatType) async throws -> [PersonalizedSuggestion] {
        var suggestions: [PersonalizedSuggestion] = []
        
        for pattern in patterns {
            switch pattern.type {
            case .fieldExtraction:
                if pattern.confidence > 0.7 {
                    suggestions.append(PersonalizedSuggestion(
                        type: .fieldValidation,
                        field: pattern.fieldName,
                        suggestion: "Based on your corrections, this field often contains: \(pattern.commonValue)",
                        confidence: pattern.confidence
                    ))
                }
                
            case .formatPreference:
                suggestions.append(PersonalizedSuggestion(
                    type: .formatOptimization,
                    field: pattern.fieldName,
                    suggestion: "Consider using \(pattern.preferredParser) parser for better accuracy",
                    confidence: pattern.confidence
                ))
                
            case .validationRule:
                suggestions.append(PersonalizedSuggestion(
                    type: .validationRule,
                    field: pattern.fieldName,
                    suggestion: "Custom validation: \(pattern.validationRule)",
                    confidence: pattern.confidence
                ))
                
            case .parserPreference:
                suggestions.append(PersonalizedSuggestion(
                    type: .parserSelection,
                    field: pattern.fieldName,
                    suggestion: "Consider using \(pattern.preferredParser) parser for better results",
                    confidence: pattern.confidence
                ))
            }
        }
        
        return suggestions
    }
    
    /// Analyze corrections and generate parser adaptations
    private func analyzeAndAdapt(corrections: [UserCorrection], parser: String) async throws -> ParserAdaptation {
        var adaptations: [String: Any] = [:]
        
        // Analyze field-specific patterns
        let fieldGroups = Dictionary(grouping: corrections) { $0.fieldName }
        
        for (fieldName, fieldCorrections) in fieldGroups {
            let adaptation = try await analyzeFieldCorrections(fieldCorrections, fieldName: fieldName)
            adaptations[fieldName] = adaptation
        }
        
        // If no corrections exist, create default adaptations to indicate readiness
        if adaptations.isEmpty {
            adaptations["performance_optimization"] = "Parser ready for performance-based adaptations"
            adaptations["learning_readiness"] = 1.0
        }
        
        return ParserAdaptation(
            parserName: parser,
            adaptations: adaptations,
            confidenceMultiplier: calculateConfidenceMultiplier(corrections),
            priority: calculateAdaptationPriority(corrections)
        )
    }
    
    /// Analyze corrections for a specific field
    private func analyzeFieldCorrections(_ corrections: [UserCorrection], fieldName: String) async throws -> FieldAdaptation {
        let patterns = corrections.compactMap { $0.extractedPattern }
        let commonPatterns = findCommonPatterns(patterns)
        
        return FieldAdaptation(
            fieldName: fieldName,
            preferredPatterns: commonPatterns,
            confidenceAdjustment: calculateFieldConfidenceAdjustment(corrections),
            validationRules: extractValidationRules(corrections)
        )
    }
    
    /// Find common patterns in user corrections
    private func findCommonPatterns(_ patterns: [String]) -> [String] {
        let patternCounts = patterns.reduce(into: [:]) { counts, pattern in
            counts[pattern, default: 0] += 1
        }
        
        return patternCounts
            .filter { $0.value >= 2 } // Pattern must appear at least twice
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    /// Calculate confidence multiplier based on correction history
    private func calculateConfidenceMultiplier(_ corrections: [UserCorrection]) -> Double {
        let totalCorrections = corrections.count
        guard totalCorrections > 0 else { return 1.0 }
        
        // Reduce confidence for parsers with many corrections
        let penalty = min(0.3, Double(totalCorrections) * 0.02)
        return max(0.7, 1.0 - penalty)
    }
    
    /// Calculate adaptation priority
    private func calculateAdaptationPriority(_ corrections: [UserCorrection]) -> AdaptationPriority {
        let recentCorrections = corrections.filter { 
            Date().timeIntervalSince($0.timestamp) < 7 * 24 * 3600 // Last 7 days
        }
        
        if recentCorrections.count >= 5 {
            return .high
        } else if recentCorrections.count >= 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Calculate field-specific confidence adjustment
    private func calculateFieldConfidenceAdjustment(_ corrections: [UserCorrection]) -> Double {
        let avgCorrections = corrections.reduce(0.0) { $0 + $1.confidenceImpact } / Double(corrections.count)
        return max(-0.5, min(0.2, avgCorrections))
    }
    
    /// Extract validation rules from corrections
    private func extractValidationRules(_ corrections: [UserCorrection]) -> [ValidationRule] {
        var rules: [ValidationRule] = []
        
        for correction in corrections {
            if let rule = correction.suggestedValidationRule {
                rules.append(rule)
            }
        }
        
        return Array(Set(rules)) // Remove duplicates
    }
    
    /// Update confidence adjustments based on correction patterns
    private func updateConfidenceAdjustments(_ pattern: CorrectionPattern) async throws {
        try await userLearningStore.updateConfidenceAdjustment(
            field: pattern.fieldName,
            documentType: pattern.documentType,
            adjustment: pattern.confidenceAdjustment
        )
    }
    
    /// Update learning statistics
    private func updateLearningStatistics(_ correction: UserCorrection) async {
        learningStats.totalCorrections += 1
        learningStats.lastCorrectionDate = correction.timestamp
        
        // Update field-specific statistics
        learningStats.fieldStatistics[correction.fieldName, default: 0] += 1
        
        // Update accuracy improvement estimate
        let improvementEstimate = await calculateAccuracyImprovement()
        learningStats.estimatedAccuracyImprovement = improvementEstimate
    }
    
    /// Update performance statistics
    private func updatePerformanceStatistics(_ metrics: ParserPerformanceMetrics) async {
        learningStats.totalDocumentsProcessed += 1
        learningStats.averageProcessingTime = (learningStats.averageProcessingTime + metrics.processingTime) / 2.0
        learningStats.averageAccuracy = (learningStats.averageAccuracy + metrics.accuracy) / 2.0
    }
    
    /// Calculate estimated accuracy improvement
    private func calculateAccuracyImprovement() async -> Double {
        do {
            let allCorrections = try await userLearningStore.getAllCorrections()
            guard allCorrections.count >= 10 else { return 0.0 }
            
            // Calculate improvement based on correction patterns
            let recentCorrections = allCorrections.filter { 
                Date().timeIntervalSince($0.timestamp) < 30 * 24 * 3600 // Last 30 days
            }
            
            let improvementRate = Double(recentCorrections.count) / Double(allCorrections.count)
            return min(0.25, improvementRate * 0.1) // Max 25% improvement estimate
            
        } catch {
            print("[AdaptiveLearningEngine] Error calculating accuracy improvement: \(error)")
            return 0.0
        }
    }
}

// MARK: - Supporting Types

/// Statistics about the learning system
public struct LearningStatistics {
    public var totalCorrections: Int = 0
    public var totalDocumentsProcessed: Int = 0
    public var lastCorrectionDate: Date?
    public var averageProcessingTime: TimeInterval = 0.0
    public var averageAccuracy: Double = 0.0
    public var estimatedAccuracyImprovement: Double = 0.0
    public var fieldStatistics: [String: Int] = [:]
}

/// Priority levels for adaptations
public enum AdaptationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}
