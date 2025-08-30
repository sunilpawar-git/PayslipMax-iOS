import Foundation

/// Engine responsible for intelligent amount reconciliation
public class AmountReconciliationEngine {

    // MARK: - Properties

    private let amountTolerance: Double = 1.0

    // MARK: - Public Methods

    /// Reconcile amounts using intelligent algorithms
    func reconcileAmounts(
        credits: [String: Double],
        debits: [String: Double],
        expectedNet: Double?
    ) async throws -> AmountReconciliationResult {

        var reconciledCredits = credits
        var reconciledDebits = debits
        var corrections: [ReconciliationCorrection] = []

        // Calculate current totals
        let currentCreditTotal = credits.values.reduce(0, +)
        let currentDebitTotal = debits.values.reduce(0, +)
        let currentNet = currentCreditTotal - currentDebitTotal

        // Apply intelligent corrections
        let creditCorrections = try await reconcileComponentAmounts(
            amounts: credits,
            componentType: .credits
        )
        corrections.append(contentsOf: creditCorrections)

        let debitCorrections = try await reconcileComponentAmounts(
            amounts: debits,
            componentType: .debits
        )
        corrections.append(contentsOf: debitCorrections)

        // Apply corrections
        for correction in corrections {
            if credits.keys.contains(correction.component) {
                reconciledCredits[correction.component] = correction.correctedValue
            } else if debits.keys.contains(correction.component) {
                reconciledDebits[correction.component] = correction.correctedValue
            }
        }

        let finalCreditTotal = reconciledCredits.values.reduce(0, +)
        let finalDebitTotal = reconciledDebits.values.reduce(0, +)
        let finalNet = finalCreditTotal - finalDebitTotal

        let confidence = calculateReconciliationConfidence(
            originalNet: currentNet,
            reconciledNet: finalNet,
            expectedNet: expectedNet,
            corrections: corrections
        )

        return AmountReconciliationResult(
            reconciledCredits: reconciledCredits,
            reconciledDebits: reconciledDebits,
            netAmount: finalNet,
            confidence: confidence
        )
    }

    // MARK: - Private Methods

    /// Reconcile individual component amounts
    private func reconcileComponentAmounts(
        amounts: [String: Double],
        componentType: ComponentType
    ) async throws -> [ReconciliationCorrection] {

        var corrections: [ReconciliationCorrection] = []

        for (component, value) in amounts {
            if let correctedValue = applyRoundingCorrection(value: value) {
                let correction = ReconciliationCorrection(
                    component: component,
                    originalValue: value,
                    correctedValue: correctedValue,
                    reason: "Applied standard rounding",
                    confidence: 0.7
                )
                corrections.append(correction)
            }
        }

        return corrections
    }

    /// Apply rounding corrections to amounts
    private func applyRoundingCorrection(value: Double) -> Double? {
        let rounded = round(value)
        return abs(value - rounded) < 0.01 ? nil : rounded
    }

    /// Calculate reconciliation confidence
    private func calculateReconciliationConfidence(
        originalNet: Double,
        reconciledNet: Double,
        expectedNet: Double?,
        corrections: [ReconciliationCorrection]
    ) -> Double {
        let netImprovement = abs(originalNet - (expectedNet ?? originalNet))
        let correctionCount = corrections.count

        var confidence = 0.8
        confidence -= Double(correctionCount) * 0.05
        confidence += netImprovement > 0 ? 0.1 : 0

        return max(0.0, min(1.0, confidence))
    }
}

// MARK: - Supporting Types

private enum ComponentType {
    case credits
    case debits
}
