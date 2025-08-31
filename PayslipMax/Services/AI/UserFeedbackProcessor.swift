import Foundation
import SwiftData
import Combine

/// Protocol for user feedback processing
public protocol UserFeedbackProcessorProtocol {
    func captureUserCorrection(_ correction: UserCorrection) async throws
    func processFieldValidation(_ validation: FieldValidation) async throws
    func generateSmartSuggestions(for field: String, currentValue: String, documentType: LiteRTDocumentFormatType) async throws -> [SmartSuggestion]
    func batchProcessCorrections(_ corrections: [UserCorrection]) async throws
    func getCorrectionHistory(for field: String) async throws -> [UserCorrection]
    func exportLearningData() async throws -> LearningDataExport
}

/// Service for capturing and processing user feedback and corrections
@MainActor
public class UserFeedbackProcessor: UserFeedbackProcessorProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let correctionStore: CorrectionStore
    private let validationProcessor: ValidationProcessor
    private let suggestionGenerator: SmartSuggestionGenerator
    private let batchProcessor: BatchCorrectionProcessor
    private let learningEngine: AdaptiveLearningEngineProtocol
    
    @Published public var processingStats: FeedbackProcessingStats = FeedbackProcessingStats()
    @Published public var recentCorrections: [UserCorrection] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        correctionStore: CorrectionStore? = nil,
        validationProcessor: ValidationProcessor? = nil,
        suggestionGenerator: SmartSuggestionGenerator? = nil,
        batchProcessor: BatchCorrectionProcessor? = nil,
        learningEngine: AdaptiveLearningEngineProtocol? = nil
    ) {
        self.correctionStore = correctionStore ?? CorrectionStore()
        self.validationProcessor = validationProcessor ?? ValidationProcessor()
        self.suggestionGenerator = suggestionGenerator ?? SmartSuggestionGenerator()
        self.batchProcessor = batchProcessor ?? BatchCorrectionProcessor()
        self.learningEngine = learningEngine ?? AdaptiveLearningEngine()
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Capture and process a user correction
    public func captureUserCorrection(_ correction: UserCorrection) async throws {
        print("[UserFeedbackProcessor] Capturing correction for field: \(correction.fieldName)")
        
        // Validate the correction
        try await validateCorrection(correction)
        
        // Store the correction
        try await correctionStore.store(correction)
        
        // Process the correction for learning
        try await learningEngine.processUserCorrection(correction)
        
        // Update UI state
        await updateUIState(with: correction)
        
        // Generate suggestions based on the correction
        let suggestions = try await generateRelatedSuggestions(correction)
        await presentSuggestions(suggestions)
        
        print("[UserFeedbackProcessor] Correction captured and processed successfully")
    }
    
    /// Process field validation from user
    public func processFieldValidation(_ validation: FieldValidation) async throws {
        print("[UserFeedbackProcessor] Processing field validation: \(validation.fieldName)")
        
        // Convert validation to correction if needed
        if let correction = await convertValidationToCorrection(validation) {
            try await captureUserCorrection(correction)
        }
        
        // Update confidence scores
        try await updateConfidenceScores(validation)
        
        // Track validation patterns
        try await trackValidationPattern(validation)
    }
    
    /// Generate smart suggestions for a field
    public func generateSmartSuggestions(for field: String, currentValue: String, documentType: LiteRTDocumentFormatType) async throws -> [SmartSuggestion] {
        print("[UserFeedbackProcessor] Generating suggestions for field: \(field)")
        
        // Get historical corrections for this field
        let corrections = try await getCorrectionHistory(for: field)
        
        // Generate suggestions based on patterns
        let suggestions = try await suggestionGenerator.generateSuggestions(
            field: field,
            currentValue: currentValue,
            documentType: documentType,
            corrections: corrections
        )
        
        return suggestions
    }
    
    /// Process multiple corrections in batch
    public func batchProcessCorrections(_ corrections: [UserCorrection]) async throws {
        print("[UserFeedbackProcessor] Processing batch of \(corrections.count) corrections")
        
        try await batchProcessor.processBatch(corrections) { [weak self] correction in
            // Process through learning engine
            try await self?.learningEngine.processUserCorrection(correction)
            // Store in correction store for history tracking
            try await self?.correctionStore.store(correction)
        }
        
        // Update statistics
        await updateBatchStatistics(corrections)
        
        print("[UserFeedbackProcessor] Batch processing completed")
    }
    
    /// Get correction history for a specific field
    public func getCorrectionHistory(for field: String) async throws -> [UserCorrection] {
        return try await correctionStore.getCorrections(for: field)
    }
    
    /// Export learning data for backup/analysis
    public func exportLearningData() async throws -> LearningDataExport {
        let allCorrections = try await correctionStore.getAllCorrections()
        let patterns = try await correctionStore.getAllPatterns()
        let validations = try await correctionStore.getAllValidations()
        
        return LearningDataExport(
            corrections: allCorrections,
            patterns: patterns,
            validations: validations,
            exportDate: Date(),
            version: "1.0"
        )
    }
    
    // MARK: - Private Methods
    
    /// Set up reactive bindings
    private func setupBindings() {
        // Bind recent corrections
        correctionStore.recentCorrectionsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.recentCorrections, on: self)
            .store(in: &cancellables)
    }
    
    /// Validate correction before processing
    private func validateCorrection(_ correction: UserCorrection) async throws {
        // Basic validation
        guard !correction.fieldName.isEmpty else {
            throw FeedbackProcessorError.invalidFieldName
        }
        
        guard !correction.correctedValue.isEmpty else {
            throw FeedbackProcessorError.invalidCorrectedValue
        }
        
        // Validate using validation processor
        try await validationProcessor.validateCorrection(correction)
    }
    
    /// Update UI state with new correction
    private func updateUIState(with correction: UserCorrection) async {
        processingStats.totalCorrections += 1
        processingStats.lastCorrectionDate = correction.timestamp
        
        // Update field-specific statistics
        processingStats.fieldCorrectionCounts[correction.fieldName, default: 0] += 1
        
        // Update document type statistics
        let documentTypeKey = correction.documentType.rawValue
        processingStats.documentTypeCorrectionCounts[documentTypeKey, default: 0] += 1
    }
    
    /// Generate related suggestions based on correction
    private func generateRelatedSuggestions(_ correction: UserCorrection) async throws -> [SmartSuggestion] {
        return try await suggestionGenerator.generateRelatedSuggestions(correction)
    }
    
    /// Present suggestions to user
    private func presentSuggestions(_ suggestions: [SmartSuggestion]) async {
        // This would integrate with UI to show suggestions
        print("[UserFeedbackProcessor] Generated \(suggestions.count) suggestions")
    }
    
    /// Convert field validation to correction if applicable
    private func convertValidationToCorrection(_ validation: FieldValidation) async -> UserCorrection? {
        guard validation.needsCorrection else { return nil }
        
        return UserCorrection(
            fieldName: validation.fieldName,
            originalValue: validation.extractedValue,
            correctedValue: validation.correctedValue ?? validation.extractedValue,
            documentType: validation.documentType,
            parserUsed: validation.parserUsed,
            confidenceImpact: calculateConfidenceImpact(validation)
        )
    }
    
    /// Calculate confidence impact from validation
    private func calculateConfidenceImpact(_ validation: FieldValidation) -> Double {
        if validation.wasCorrect {
            return 0.05 // Positive feedback
        } else {
            return -0.15 // Negative feedback
        }
    }
    
    /// Update confidence scores based on validation
    private func updateConfidenceScores(_ validation: FieldValidation) async throws {
        try await correctionStore.updateConfidenceScore(
            field: validation.fieldName,
            documentType: validation.documentType,
            impact: calculateConfidenceImpact(validation)
        )
    }
    
    /// Track validation patterns
    private func trackValidationPattern(_ validation: FieldValidation) async throws {
        let pattern = ValidationPattern(
            fieldName: validation.fieldName,
            documentType: validation.documentType,
            wasCorrect: validation.wasCorrect,
            confidence: validation.confidence,
            timestamp: Date()
        )
        
        try await correctionStore.storeValidationPattern(pattern)
    }
    
    /// Update batch processing statistics
    private func updateBatchStatistics(_ corrections: [UserCorrection]) async {
        processingStats.totalBatchCorrections += corrections.count
        processingStats.lastBatchDate = Date()
        
        // Calculate accuracy improvement estimate
        let estimatedImprovement = await calculateBatchImprovementEstimate(corrections)
        processingStats.estimatedAccuracyImprovement = estimatedImprovement
    }
    
    /// Calculate estimated accuracy improvement from batch
    private func calculateBatchImprovementEstimate(_ corrections: [UserCorrection]) async -> Double {
        let uniqueFields = Set(corrections.map { $0.fieldName })
        let fieldImprovements = uniqueFields.map { fieldName in
            let fieldCorrections = corrections.filter { $0.fieldName == fieldName }
            return Double(fieldCorrections.count) * 0.02 // 2% improvement per correction
        }
        
        return fieldImprovements.reduce(0, +)
    }
}

// MARK: - Supporting Classes

/// Store for corrections and learning data
@MainActor
public class CorrectionStore: ObservableObject {
    private var corrections: [UserCorrection] = []
    private var patterns: [CorrectionPattern] = []
    private var validationPatterns: [ValidationPattern] = []
    
    @Published public var recentCorrections: [UserCorrection] = []
    
    public var recentCorrectionsPublisher: Published<[UserCorrection]>.Publisher {
        $recentCorrections
    }
    
    public func store(_ correction: UserCorrection) async throws {
        corrections.append(correction)
        recentCorrections.insert(correction, at: 0)
        if recentCorrections.count > 10 {
            recentCorrections.removeLast()
        }
    }
    
    public func getCorrections(for field: String) async throws -> [UserCorrection] {
        return corrections.filter { $0.fieldName == field }
    }
    
    public func getAllCorrections() async throws -> [UserCorrection] {
        return corrections
    }
    
    public func getAllPatterns() async throws -> [CorrectionPattern] {
        return patterns
    }
    
    public func getAllValidations() async throws -> [ValidationPattern] {
        return validationPatterns
    }
    
    public func updateConfidenceScore(field: String, documentType: LiteRTDocumentFormatType, impact: Double) async throws {
        // Implementation for confidence score updates
    }
    
    public func storeValidationPattern(_ pattern: ValidationPattern) async throws {
        validationPatterns.append(pattern)
    }
}

/// Processor for field validations
public class ValidationProcessor {
    public func validateCorrection(_ correction: UserCorrection) async throws {
        // Validate that the correction makes sense
        guard correction.originalValue != correction.correctedValue else {
            throw FeedbackProcessorError.noChangeInCorrection
        }
    }
}

/// Generator for smart suggestions
public class SmartSuggestionGenerator {
    public func generateSuggestions(
        field: String,
        currentValue: String,
        documentType: LiteRTDocumentFormatType,
        corrections: [UserCorrection]
    ) async throws -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Analyze correction patterns
        let commonCorrections = findCommonCorrections(corrections)
        
        for (pattern, frequency) in commonCorrections {
            if frequency >= 1 && (pattern.contains(currentValue.prefix(min(3, currentValue.count))) || corrections.count > 0) {
                suggestions.append(SmartSuggestion(
                    id: UUID(),
                    type: .autocomplete,
                    text: pattern,
                    confidence: Double(frequency) / Double(max(1, corrections.count)),
                    reason: "Based on your previous corrections"
                ))
            }
        }
        
        // If no pattern-based suggestions, create a basic suggestion from recent corrections
        if suggestions.isEmpty && !corrections.isEmpty {
            let recentCorrection = corrections.last!
            suggestions.append(SmartSuggestion(
                id: UUID(),
                type: .pattern,
                text: recentCorrection.correctedValue,
                confidence: 0.5,
                reason: "Based on recent correction pattern"
            ))
        }
        
        return suggestions
    }
    
    public func generateRelatedSuggestions(_ correction: UserCorrection) async throws -> [SmartSuggestion] {
        // Generate suggestions related to the correction
        return []
    }
    
    private func findCommonCorrections(_ corrections: [UserCorrection]) -> [String: Int] {
        let correctionCounts = corrections.reduce(into: [:]) { counts, correction in
            counts[correction.correctedValue, default: 0] += 1
        }
        return correctionCounts
    }
}

/// Processor for batch corrections
public class BatchCorrectionProcessor {
    public func processBatch<T>(_ items: [T], processor: (T) async throws -> Void) async throws {
        for item in items {
            try await processor(item)
        }
    }
}

// MARK: - Supporting Types

/// Field validation from user
public struct FieldValidation {
    public let fieldName: String
    public let extractedValue: String
    public let correctedValue: String?
    public let wasCorrect: Bool
    public let confidence: Double
    public let documentType: LiteRTDocumentFormatType
    public let parserUsed: String
    public let needsCorrection: Bool
    
    public init(
        fieldName: String,
        extractedValue: String,
        correctedValue: String? = nil,
        wasCorrect: Bool,
        confidence: Double,
        documentType: LiteRTDocumentFormatType,
        parserUsed: String,
        needsCorrection: Bool = false
    ) {
        self.fieldName = fieldName
        self.extractedValue = extractedValue
        self.correctedValue = correctedValue
        self.wasCorrect = wasCorrect
        self.confidence = confidence
        self.documentType = documentType
        self.parserUsed = parserUsed
        self.needsCorrection = needsCorrection
    }
}

/// Smart suggestion for user
public struct SmartSuggestion: Identifiable {
    public let id: UUID
    public let type: SuggestionType
    public let text: String
    public let confidence: Double
    public let reason: String
    
    public enum SuggestionType {
        case autocomplete
        case validation
        case pattern
        case format
    }
}

/// Validation pattern for tracking
public struct ValidationPattern: Codable, Sendable {
    public let fieldName: String
    public let documentType: LiteRTDocumentFormatType
    public let wasCorrect: Bool
    public let confidence: Double
    public let timestamp: Date
}

/// Learning data export
public struct LearningDataExport: Codable {
    public let corrections: [UserCorrection]
    public let patterns: [CorrectionPattern]
    public let validations: [ValidationPattern]
    public let exportDate: Date
    public let version: String
}

/// Statistics for feedback processing
public struct FeedbackProcessingStats {
    public var totalCorrections: Int = 0
    public var totalBatchCorrections: Int = 0
    public var lastCorrectionDate: Date?
    public var lastBatchDate: Date?
    public var fieldCorrectionCounts: [String: Int] = [:]
    public var documentTypeCorrectionCounts: [String: Int] = [:]
    public var estimatedAccuracyImprovement: Double = 0.0
}

/// Errors for feedback processing
public enum FeedbackProcessorError: Error, LocalizedError {
    case invalidFieldName
    case invalidCorrectedValue
    case noChangeInCorrection
    case validationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFieldName:
            return "Field name cannot be empty"
        case .invalidCorrectedValue:
            return "Corrected value cannot be empty"
        case .noChangeInCorrection:
            return "Correction must change the original value"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        }
    }
}
