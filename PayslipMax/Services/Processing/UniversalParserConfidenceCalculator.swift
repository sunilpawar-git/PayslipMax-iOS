import Foundation

/// Calculates confidence scores for payslips parsed by the universal parser
/// Uses weighted field approach to evaluate parsing quality
/// Now uses shared validators to eliminate duplication
final class UniversalParserConfidenceCalculator {

    // MARK: - Constants

    private struct Weights {
        // Core date/period fields
        static let month: Double = 2.0
        static let year: Double = 2.0

        // Critical financial fields
        static let netRemittance: Double = 3.0  // Most important
        static let credits: Double = 2.5
        static let basicPay: Double = 2.0

        // Supporting data
        static let earnings: Double = 1.5
        static let deductions: Double = 1.5
    }

    // MARK: - Public Methods

    /// Calculate overall confidence for a parsed payslip
    /// - Parameters:
    ///   - month: The extracted month name
    ///   - year: The extracted year
    ///   - credits: Total credits/earnings
    ///   - debits: Total debits/deductions
    ///   - earnings: Dictionary of earnings
    ///   - deductions: Dictionary of deductions
    /// - Returns: ConfidenceResult with overall and field-level scores
    static func calculateConfidence(
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> ConfidenceResult {
        var fieldConfidences: [String: Double] = [:]
        var totalWeight = 0.0
        var weightedSum = 0.0

        // Month confidence - use shared validator
        let monthConfidence = FieldValidators.monthConfidence(month)
        fieldConfidences["month"] = monthConfidence
        weightedSum += monthConfidence * Weights.month
        totalWeight += Weights.month

        // Year confidence - use shared validator
        let yearConfidence = FieldValidators.yearConfidence(year)
        fieldConfidences["year"] = yearConfidence
        weightedSum += yearConfidence * Weights.year
        totalWeight += Weights.year

        // Net remittance confidence (most critical)
        let netRemittance = credits - debits
        let netConfidence = FieldValidators.amountConfidence(
            netRemittance,
            fieldName: "netRemittance",
            isCritical: true
        )
        fieldConfidences["netRemittance"] = netConfidence
        weightedSum += netConfidence * Weights.netRemittance
        totalWeight += Weights.netRemittance

        // Credits confidence
        let creditsConfidence = FieldValidators.amountConfidence(
            credits,
            fieldName: "credits",
            isCritical: true
        )
        fieldConfidences["credits"] = creditsConfidence
        weightedSum += creditsConfidence * Weights.credits
        totalWeight += Weights.credits

        // Basic pay confidence
        let basicPay = earnings["Basic Pay"] ?? earnings["BPAY"] ?? 0.0
        let basicPayConfidence = FieldValidators.amountConfidence(
            basicPay,
            fieldName: "basicPay",
            isCritical: true
        )
        fieldConfidences["basicPay"] = basicPayConfidence
        weightedSum += basicPayConfidence * Weights.basicPay
        totalWeight += Weights.basicPay

        // Earnings confidence - use shared validator
        let earningsConfidence = FieldValidators.dictionaryConfidence(earnings, allowEmpty: false)
        fieldConfidences["earnings"] = earningsConfidence
        weightedSum += earningsConfidence * Weights.earnings
        totalWeight += Weights.earnings

        // Deductions confidence - use shared validator
        let deductionsConfidence = FieldValidators.dictionaryConfidence(deductions, allowEmpty: true)
        fieldConfidences["deductions"] = deductionsConfidence
        weightedSum += deductionsConfidence * Weights.deductions
        totalWeight += Weights.deductions

        // Calculate overall confidence using weighted average
        let overallConfidence = totalWeight > 0 ? weightedSum / totalWeight : 0.0

        return ConfidenceResult(
            overall: overallConfidence,
            fieldLevel: fieldConfidences,
            methodology: "Universal",
            metadata: [
                "totalWeight": String(format: "%.2f", totalWeight),
                "weightedSum": String(format: "%.2f", weightedSum)
            ]
        )
    }
}
