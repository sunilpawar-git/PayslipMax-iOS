import Foundation

/// Engine responsible for core reconciliation logic
public class ReconciliationEngine {

    // MARK: - Properties

    private let amountTolerance: Double = 1.0

    // MARK: - Public Methods

    /// Perform reconciliation of extracted totals with expected values
    func reconcileTotals(
        extractedCredits: [String: Double],
        extractedDebits: [String: Double],
        expectedCredits: Double?,
        expectedDebits: Double?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> ReconciliationResult {

        print("[ReconciliationEngine] Starting reconciliation process")

        // Calculate current totals
        let currentCreditTotal = extractedCredits.values.reduce(0, +)
        let currentDebitTotal = extractedDebits.values.reduce(0, +)
        let currentNet = currentCreditTotal - currentDebitTotal

        // Identify discrepancies
        let discrepancies = try await identifyDiscrepancies(
            extractedCredits: extractedCredits,
            extractedDebits: extractedDebits,
            expectedCredits: expectedCredits,
            expectedDebits: expectedDebits,
            documentFormat: documentFormat
        )

        // Create reconciliation context
        let context = ReconciliationContext(
            documentFormat: documentFormat,
            hasPrintedTotals: expectedCredits != nil || expectedDebits != nil,
            componentCount: extractedCredits.count + extractedDebits.count,
            totalAmount: currentCreditTotal + currentDebitTotal
        )

        // Generate suggestions
        let suggestionEngine = SuggestionEngine()
        let suggestions = try await suggestionEngine.suggestCorrections(
            discrepancies: discrepancies,
            context: context
        )

        // Generate automatic corrections
        let correctionEngine = CorrectionEngine()
        let corrections = try await correctionEngine.generateAutomaticCorrections(
            discrepancies: discrepancies,
            context: context
        )

        // Apply corrections
        let correctedTotals = try await correctionEngine.applyCorrections(
            credits: extractedCredits,
            debits: extractedDebits,
            corrections: corrections
        )

        // Calculate confidence
        let confidence = calculateReconciliationConfidence(
            originalNet: currentNet,
            reconciledNet: correctedTotals.netAmount,
            expectedCredits: expectedCredits,
            expectedDebits: expectedDebits,
            corrections: corrections,
            unresolvedDiscrepancies: discrepancies.filter { discrepancy in
                !corrections.contains(where: { correction in
                    correction.component == discrepancy.component
                })
            }
        )

        print("[ReconciliationEngine] Reconciliation completed with confidence: \(confidence)")

        return ReconciliationResult(
            reconciledCredits: correctedTotals.credits,
            reconciledDebits: correctedTotals.debits,
            netAmount: correctedTotals.netAmount,
            confidence: confidence,
            appliedCorrections: corrections,
            unresolvedDiscrepancies: discrepancies.filter { discrepancy in
                !corrections.contains(where: { correction in
                    correction.component == discrepancy.component
                })
            },
            suggestions: suggestions
        )
    }

    // MARK: - Private Methods

    /// Identify discrepancies between extracted and expected values
    private func identifyDiscrepancies(
        extractedCredits: [String: Double],
        extractedDebits: [String: Double],
        expectedCredits: Double?,
        expectedDebits: Double?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> [ReconciliationDiscrepancy] {

        var discrepancies: [ReconciliationDiscrepancy] = []

        let actualCredits = extractedCredits.values.reduce(0, +)
        let actualDebits = extractedDebits.values.reduce(0, +)

        // Check total discrepancies
        if let expectedCredits = expectedCredits {
            let difference = abs(actualCredits - expectedCredits)
            if difference > amountTolerance {
                discrepancies.append(ReconciliationDiscrepancy(
                    component: "TOTAL_CREDITS",
                    extractedValue: actualCredits,
                    expectedValue: expectedCredits,
                    discrepancyType: .amountMismatch,
                    severity: difference > expectedCredits * 0.1 ? .high : .medium,
                    explanation: "Total credits differ from expected value by \(difference)"
                ))
            }
        }

        if let expectedDebits = expectedDebits {
            let difference = abs(actualDebits - expectedDebits)
            if difference > amountTolerance {
                discrepancies.append(ReconciliationDiscrepancy(
                    component: "TOTAL_DEBITS",
                    extractedValue: actualDebits,
                    expectedValue: expectedDebits,
                    discrepancyType: .amountMismatch,
                    severity: difference > expectedDebits * 0.1 ? .high : .medium,
                    explanation: "Total debits differ from expected value by \(difference)"
                ))
            }
        }

        // Check for rounding issues
        discrepancies.append(contentsOf: identifyRoundingIssues(
            credits: extractedCredits,
            debits: extractedDebits
        ))

        return discrepancies
    }

    /// Identify rounding-related discrepancies
    private func identifyRoundingIssues(credits: [String: Double], debits: [String: Double]) -> [ReconciliationDiscrepancy] {
        var discrepancies: [ReconciliationDiscrepancy] = []

        for (component, amount) in credits {
            if let roundedAmount = applyRoundingCorrection(amount) {
                discrepancies.append(ReconciliationDiscrepancy(
                    component: component,
                    extractedValue: amount,
                    expectedValue: roundedAmount,
                    discrepancyType: .roundingIssue,
                    severity: .low,
                    explanation: "Amount appears to need rounding correction"
                ))
            }
        }

        for (component, amount) in debits {
            if let roundedAmount = applyRoundingCorrection(amount) {
                discrepancies.append(ReconciliationDiscrepancy(
                    component: component,
                    extractedValue: amount,
                    expectedValue: roundedAmount,
                    discrepancyType: .roundingIssue,
                    severity: .low,
                    explanation: "Amount appears to need rounding correction"
                ))
            }
        }

        return discrepancies
    }

    /// Apply rounding correction to amount
    private func applyRoundingCorrection(_ value: Double) -> Double? {
        let rounded = round(value)
        return abs(value - rounded) < 0.50 ? nil : rounded
    }

    /// Calculate reconciliation confidence
    private func calculateReconciliationConfidence(
        originalNet: Double,
        reconciledNet: Double,
        expectedCredits: Double?,
        expectedDebits: Double?,
        corrections: [ReconciliationCorrection],
        unresolvedDiscrepancies: [ReconciliationDiscrepancy]
    ) -> Double {

        var confidence = 0.8

        // Reduce confidence for large net changes
        let netChangeRatio = abs(reconciledNet - originalNet) / max(abs(originalNet), 1.0)
        confidence -= netChangeRatio * 0.3

        // Reduce confidence for unresolved discrepancies
        confidence -= Double(unresolvedDiscrepancies.count) * 0.1

        // Increase confidence for applied corrections
        confidence += Double(corrections.count) * 0.05

        return max(0.0, min(1.0, confidence))
    }
}
