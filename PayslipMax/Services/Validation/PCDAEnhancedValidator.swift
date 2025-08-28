import Foundation

/// Protocol for enhanced PCDA validation with AI integration
public protocol PCDAEnhancedValidatorProtocol {
    func validateWithAI(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> PCDAValidationResult
}

/// Service responsible for enhanced PCDA validation with AI integration
public final class PCDAEnhancedValidator: PCDAEnhancedValidatorProtocol {

    // MARK: - Properties

    private let financialIntelligenceService: FinancialIntelligenceServiceProtocol
    private let dynamicValidator: PCDADynamicValidatorProtocol

    // MARK: - Initialization

    public init() {
        self.financialIntelligenceService = FinancialIntelligenceService(liteRTService: nil)
        self.dynamicValidator = PCDADynamicValidator()
    }

    public init(
        financialIntelligenceService: FinancialIntelligenceServiceProtocol,
        dynamicValidator: PCDADynamicValidatorProtocol
    ) {
        self.financialIntelligenceService = financialIntelligenceService
        self.dynamicValidator = dynamicValidator
    }

    // MARK: - Public Methods

    /// Validates PCDA extraction using AI-powered analysis with dynamic thresholds
    ///
    /// This enhanced validation method uses machine learning to:
    /// - Apply dynamic thresholds based on document context
    /// - Detect outliers using statistical analysis
    /// - Cross-reference with printed totals when available
    /// - Generate reconciliation suggestions
    ///
    /// - Parameters:
    ///   - extractedData: Dictionary of all extracted financial components
    ///   - printedTotals: Optional printed totals for cross-reference validation
    ///   - documentFormat: Document format type for context-aware validation
    /// - Returns: Enhanced validation result with AI analysis
    public func validateWithAI(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> PCDAValidationResult {

        print("[PCDAEnhancedValidator] Starting AI-powered validation")

        // Use FinancialIntelligenceService for comprehensive AI validation
        let aiValidationResult = try await financialIntelligenceService.validateFinancialData(
            extractedData: extractedData,
            printedTotals: printedTotals,
            documentFormat: documentFormat
        )

        // Convert AI validation result to enhanced PCDA validation result
        let enhancedResult = EnhancedValidationResult(
            isValid: aiValidationResult.isValid,
            confidence: aiValidationResult.confidence,
            primaryIssue: aiValidationResult.issues.first?.message,
            secondaryIssues: Array(aiValidationResult.issues.dropFirst().map { $0.message }),
            suggestions: aiValidationResult.reconciliationSuggestions,
            outlierAnalysis: aiValidationResult.outlierAnalysis
        )

        // Apply dynamic thresholds based on AI analysis
        let dynamicValidation = try await dynamicValidator.applyDynamicThresholds(
            extractedData: extractedData,
            aiResult: aiValidationResult
        )

        // Combine AI and dynamic validation results
        let combinedConfidence = (aiValidationResult.confidence + dynamicValidation.confidence) / 2
        let combinedIsValid = aiValidationResult.isValid && dynamicValidation.isValid

        let finalResult = EnhancedValidationResult(
            isValid: combinedIsValid,
            confidence: combinedConfidence,
            primaryIssue: enhancedResult.primaryIssue ?? dynamicValidation.primaryIssue,
            secondaryIssues: enhancedResult.secondaryIssues + dynamicValidation.secondaryIssues,
            suggestions: enhancedResult.suggestions + dynamicValidation.suggestions,
            outlierAnalysis: aiValidationResult.outlierAnalysis
        )

        print("[PCDAEnhancedValidator] AI validation completed with confidence: \(finalResult.confidence)")

        return .enhanced(finalResult)
    }
}
