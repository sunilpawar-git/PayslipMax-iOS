import Foundation
import Vision
import CoreML

/// AI-powered financial intelligence service
public class FinancialIntelligenceService: FinancialIntelligenceServiceProtocol {

    // MARK: - Properties

    private let liteRTService: LiteRTServiceProtocol
    private let validationEngine: FinancialValidationEngine
    private let reconciliationEngine: AmountReconciliationEngine
    private let outlierEngine: OutlierDetectionEngine

    // MARK: - Initialization

    public init(liteRTService: LiteRTServiceProtocol? = nil) {
        if let service = liteRTService {
            self.liteRTService = service
        } else {
            // Create a new instance to avoid MainActor isolation issues
            self.liteRTService = LiteRTService()
        }
        self.validationEngine = FinancialValidationEngine()
        self.reconciliationEngine = AmountReconciliationEngine()
        self.outlierEngine = OutlierDetectionEngine()
    }

    // MARK: - Public Methods

    /// Validate financial data using AI-powered analysis
    public func validateFinancialData(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> FinancialValidationResult {

        var issues: [FinancialValidationIssue] = []
        var reconciliationSuggestions: [ReconciliationSuggestion] = []

        // Perform constraint-based validation
        let constraintIssues = try await validationEngine.validateConstraints(
            extractedData: extractedData,
            format: documentFormat
        )
        issues.append(contentsOf: constraintIssues)

        // Cross-reference with printed totals
        if let printedTotals = printedTotals {
            let crossReferenceIssues = try await validationEngine.validateCrossReferences(
                extractedData: extractedData,
                printedTotals: printedTotals
            )
            issues.append(contentsOf: crossReferenceIssues)

            // Generate reconciliation suggestions
            reconciliationSuggestions = try await validationEngine.generateReconciliationSuggestions(
                extractedData: extractedData,
                printedTotals: printedTotals
            )
        }

        // Detect outliers
        let outlierAnalysis = try await outlierEngine.detectOutliers(
            amounts: extractedData,
            format: documentFormat
        )

        // Calculate overall confidence
        let confidence = await calculateConfidenceScore(
            extractedData: extractedData,
            validationResults: issues
        )

        let isValid = issues.filter { $0.severity == .critical }.isEmpty

        return FinancialValidationResult(
            isValid: isValid,
            confidence: confidence,
            issues: issues,
            outlierAnalysis: outlierAnalysis,
            reconciliationSuggestions: reconciliationSuggestions.map { $0.type.rawValue }
        )
    }

    /// Reconcile amounts using intelligent algorithms
    public func reconcileAmounts(
        credits: [String: Double],
        debits: [String: Double],
        expectedNet: Double?
    ) async throws -> AmountReconciliationResult {

        return try await reconciliationEngine.reconcileAmounts(
            credits: credits,
            debits: debits,
            expectedNet: expectedNet
        )
    }

    /// Detect outlier values in financial data
    public func detectOutliers(
        amounts: [String: Double],
        format: LiteRTDocumentFormatType
    ) async throws -> OutlierDetectionResult {

        return try await outlierEngine.detectOutliers(
            amounts: amounts,
            format: format
        )
    }

    /// Calculate confidence score for extracted financial data
    public func calculateConfidenceScore(
        extractedData: [String: Double],
        validationResults: [FinancialValidationIssue]
    ) async -> Double {

        let criticalIssues = validationResults.filter { $0.severity == .critical }.count
        let warningIssues = validationResults.filter { $0.severity == .warning }.count

        let baseConfidence = 1.0
        let criticalPenalty = Double(criticalIssues) * 0.3
        let warningPenalty = Double(warningIssues) * 0.1

        let dataCompleteness = validationEngine.calculateDataCompleteness(extractedData)
        let amountReasonableness = validationEngine.calculateAmountReasonableness(extractedData)

        let finalConfidence = baseConfidence - criticalPenalty - warningPenalty +
                             (dataCompleteness * 0.1) + (amountReasonableness * 0.1)

        return max(0.0, min(1.0, finalConfidence))
    }
}
