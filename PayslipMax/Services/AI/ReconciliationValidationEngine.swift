import Foundation

/// Engine responsible for validating reconciliation results
public class ReconciliationValidationEngine {

    // MARK: - Properties

    private let amountTolerance: Double = 1.0

    // MARK: - Public Methods

    /// Validate the reconciliation process
    func validateReconciliation(
        originalTotals: OriginalTotals,
        reconciledTotals: CorrectedTotals
    ) async throws -> ReconciliationValidation {

        var issues: [String] = []
        var confidence = 0.9
        var qualityScore = 0.0

        // Check net amount consistency
        let netDifference = abs(originalTotals.netAmount - reconciledTotals.netAmount)
        if netDifference > amountTolerance {
            issues.append("Net amount changed significantly during reconciliation")
            confidence -= 0.2
        }

        // Check for negative values
        if reconciledTotals.netAmount < 0 && originalTotals.netAmount >= 0 {
            issues.append("Reconciliation introduced negative net amount")
            confidence -= 0.3
        }

        // Validate component totals
        let creditTotal = reconciledTotals.credits.values.reduce(0, +)
        let debitTotal = reconciledTotals.debits.values.reduce(0, +)
        let calculatedNet = creditTotal - debitTotal

        if abs(calculatedNet - reconciledTotals.netAmount) > amountTolerance {
            issues.append("Inconsistent credit/debit totals after reconciliation")
            confidence -= 0.4
        }

        // Calculate quality score based on reconciliation success
        qualityScore = confidence * (1.0 - Double(issues.count) * 0.1)

        return ReconciliationValidation(
            isValid: issues.isEmpty,
            confidence: max(0.0, confidence),
            validationIssues: issues,
            qualityScore: max(0.0, qualityScore)
        )
    }
}
