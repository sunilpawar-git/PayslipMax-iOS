import Foundation

/// Engine responsible for generating and applying corrections
public class CorrectionEngine {

    // MARK: - Public Methods

    /// Generate automatic corrections for discrepancies
    func generateAutomaticCorrections(
        discrepancies: [ReconciliationDiscrepancy],
        context: ReconciliationContext
    ) async throws -> [ReconciliationCorrection] {

        var corrections: [ReconciliationCorrection] = []

        for discrepancy in discrepancies {
            switch discrepancy.discrepancyType {
            case .roundingIssue:
                if let roundedValue = applyRoundingCorrection(discrepancy.extractedValue) {
                    corrections.append(ReconciliationCorrection(
                        component: discrepancy.component,
                        originalValue: discrepancy.extractedValue,
                        correctedValue: roundedValue,
                        reason: "Applied standard rounding",
                        confidence: 0.8
                    ))
                }
            case .amountMismatch:
                if let expectedValue = discrepancy.expectedValue,
                   shouldAutoCorrect(discrepancy, context: context) {
                    corrections.append(ReconciliationCorrection(
                        component: discrepancy.component,
                        originalValue: discrepancy.extractedValue,
                        correctedValue: expectedValue,
                        reason: "Aligned with expected total",
                        confidence: 0.7
                    ))
                }
            default:
                break
            }
        }

        return corrections
    }

    /// Apply corrections to financial totals
    func applyCorrections(
        credits: [String: Double],
        debits: [String: Double],
        corrections: [ReconciliationCorrection]
    ) async throws -> CorrectedTotals {

        var correctedCredits = credits
        var correctedDebits = debits

        for correction in corrections {
            if credits.keys.contains(correction.component) {
                correctedCredits[correction.component] = correction.correctedValue
            } else if debits.keys.contains(correction.component) {
                correctedDebits[correction.component] = correction.correctedValue
            }
        }

        let creditTotal = correctedCredits.values.reduce(0, +)
        let debitTotal = correctedDebits.values.reduce(0, +)
        let netAmount = creditTotal - debitTotal

        let confidence = calculateCorrectionConfidence(corrections)

        return CorrectedTotals(
            credits: correctedCredits,
            debits: correctedDebits,
            netAmount: netAmount,
            confidence: confidence
        )
    }

    // MARK: - Private Methods

    /// Apply rounding correction to amount
    private func applyRoundingCorrection(_ value: Double) -> Double? {
        let rounded = round(value)
        return abs(value - rounded) < 0.50 ? nil : rounded
    }

    /// Determine if discrepancy should be auto-corrected
    private func shouldAutoCorrect(_ discrepancy: ReconciliationDiscrepancy, context: ReconciliationContext) -> Bool {
        // Auto-correct low severity rounding issues
        if discrepancy.severity == .low && discrepancy.discrepancyType == .roundingIssue {
            return true
        }

        // Auto-correct medium severity amount mismatches if they are reasonable
        if discrepancy.discrepancyType == .amountMismatch && discrepancy.severity == .medium {
            if let expectedValue = discrepancy.expectedValue {
                let difference = abs(discrepancy.extractedValue - expectedValue)
                let differenceRatio = difference / expectedValue
                // Auto-correct if difference is less than 10%
                return differenceRatio < 0.1
            }
        }

        // Don't auto-correct high severity discrepancies automatically
        return false
    }

    /// Calculate correction confidence
    private func calculateCorrectionConfidence(_ corrections: [ReconciliationCorrection]) -> Double {
        let averageConfidence = corrections.isEmpty ? 0.0 :
            corrections.map { $0.confidence }.reduce(0, +) / Double(corrections.count)

        return corrections.isEmpty ? 1.0 : averageConfidence
    }
}
