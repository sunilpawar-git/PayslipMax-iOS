import Foundation

/// Protocol for AI-powered smart totals reconciliation
public protocol SmartTotalsReconcilerProtocol {
    func reconcileTotals(
        extractedCredits: [String: Double],
        extractedDebits: [String: Double],
        expectedCredits: Double?,
        expectedDebits: Double?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> ReconciliationResult

    func suggestCorrections(
        discrepancies: [ReconciliationDiscrepancy],
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion]

    func applyCorrections(
        credits: [String: Double],
        debits: [String: Double],
        corrections: [ReconciliationCorrection]
    ) async throws -> CorrectedTotals

    func validateReconciliation(
        originalTotals: OriginalTotals,
        reconciledTotals: CorrectedTotals
    ) async throws -> ReconciliationValidation
}

/// Result of totals reconciliation process
public struct ReconciliationResult {
    let reconciledCredits: [String: Double]
    let reconciledDebits: [String: Double]
    let netAmount: Double
    let confidence: Double
    let appliedCorrections: [ReconciliationCorrection]
    let unresolvedDiscrepancies: [ReconciliationDiscrepancy]
    let suggestions: [ReconciliationSuggestion]
}

/// Individual reconciliation discrepancy
public struct ReconciliationDiscrepancy {
    let component: String
    let extractedValue: Double
    let expectedValue: Double?
    let discrepancyType: DiscrepancyType
    let severity: ReconciliationSeverity
    let explanation: String
}

/// Types of reconciliation discrepancies
public enum DiscrepancyType {
    case amountMismatch
    case missingComponent
    case extraComponent
    case calculationError
    case roundingIssue
}

/// Severity levels for reconciliation discrepancies
public enum ReconciliationSeverity {
    case low
    case medium
    case high
    case critical
}

/// Context information for reconciliation
public struct ReconciliationContext {
    let documentFormat: LiteRTDocumentFormatType
    let hasPrintedTotals: Bool
    let componentCount: Int
    let totalAmount: Double
}

/// Corrected totals after applying reconciliation
public struct CorrectedTotals {
    let credits: [String: Double]
    let debits: [String: Double]
    let netAmount: Double
    let confidence: Double
}

/// Original totals before reconciliation
public struct OriginalTotals {
    let credits: [String: Double]
    let debits: [String: Double]
    let netAmount: Double
}

/// Validation result of reconciliation process
public struct ReconciliationValidation {
    let isValid: Bool
    let confidence: Double
    let validationIssues: [String]
    let qualityScore: Double
}

/// Correction to apply to financial data
public struct ReconciliationCorrection {
    let component: String
    let originalValue: Double
    let correctedValue: Double
    let reason: String
    let confidence: Double
}

/// Suggestion for reconciliation improvement
public struct ReconciliationSuggestion {
    let type: SuggestionType
    let component: String
    let suggestedValue: Double
    let confidence: Double
    let explanation: String
}

/// Types of reconciliation suggestions
public enum SuggestionType: String {
    case correction
    case addition
    case removal
    case consolidation
}
