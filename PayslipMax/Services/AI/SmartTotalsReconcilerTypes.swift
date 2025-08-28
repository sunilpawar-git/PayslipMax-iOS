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
public struct ReconciliationResult: Codable, Sendable {
    let reconciledCredits: [String: Double]
    let reconciledDebits: [String: Double]
    let netAmount: Double
    let confidence: Double
    let appliedCorrections: [ReconciliationCorrection]
    let unresolvedDiscrepancies: [ReconciliationDiscrepancy]
    let suggestions: [ReconciliationSuggestion]
}

/// Individual reconciliation discrepancy
public struct ReconciliationDiscrepancy: Codable, Sendable {
    let component: String
    let extractedValue: Double
    let expectedValue: Double?
    let discrepancyType: DiscrepancyType
    let severity: ReconciliationSeverity
    let explanation: String
}

/// Types of reconciliation discrepancies
public enum DiscrepancyType: String, Codable, Sendable {
    case amountMismatch
    case missingComponent
    case extraComponent
    case calculationError
    case roundingIssue
}

/// Severity levels for reconciliation discrepancies
public enum ReconciliationSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Context information for reconciliation
public struct ReconciliationContext: Codable, Sendable {
    let documentFormat: LiteRTDocumentFormatType
    let hasPrintedTotals: Bool
    let componentCount: Int
    let totalAmount: Double
}

/// Corrected totals after applying reconciliation
public struct CorrectedTotals: Codable, Sendable {
    let credits: [String: Double]
    let debits: [String: Double]
    let netAmount: Double
    let confidence: Double
}

/// Original totals before reconciliation
public struct OriginalTotals: Codable, Sendable {
    let credits: [String: Double]
    let debits: [String: Double]
    let netAmount: Double
}

/// Validation result of reconciliation process
public struct ReconciliationValidation: Codable, Sendable {
    let isValid: Bool
    let confidence: Double
    let validationIssues: [String]
    let qualityScore: Double
}

/// Correction to apply to financial data
public struct ReconciliationCorrection: Codable, Sendable {
    let component: String
    let originalValue: Double
    let correctedValue: Double
    let reason: String
    let confidence: Double
}

/// Suggestion for reconciliation improvement
public struct ReconciliationSuggestion: Codable, Sendable {
    let type: ReconciliationSuggestionType
    let component: String
    let suggestedValue: Double
    let confidence: Double
    let explanation: String
}

/// Types of reconciliation suggestions
public enum ReconciliationSuggestionType: String, Codable, Sendable {
    case correction = "correction"
    case addition = "addition"
    case removal = "removal"
    case consolidation = "consolidation"
}
