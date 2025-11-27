import Foundation

/// Calculates confidence score for simplified payslip parsing
/// Uses totals-based validation to determine data quality
/// Now provides field-level breakdown for transparency
class ConfidenceCalculator {

    // MARK: - Constants

    private struct Points {
        static let grossPay: Double = 0.20
        static let totalDeductions: Double = 0.20
        static let netRemittanceConsistency: Double = 0.50  // Most important
        static let coreFieldsPresent: Double = 0.10
    }

    // MARK: - Confidence Calculation

    /// Calculates confidence score with field-level breakdown
    /// Balanced logic: Requires both totals consistency AND core field presence
    /// - Returns: ConfidenceResult with overall and field-level scores
    func calculate(
        basicPay: Double,
        dearnessAllowance: Double,
        militaryServicePay: Double,
        grossPay: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) async -> ConfidenceResult {
        var fieldConfidences: [String: Double] = [:]
        var score = 0.0

        // Check 1: Gross Pay Extracted (20 points)
        let grossPayConfidence = FieldValidators.amountConfidence(
            grossPay,
            fieldName: "grossPay",
            isCritical: true
        )
        fieldConfidences["grossPay"] = grossPayConfidence

        if grossPay > 0 {
            score += Points.grossPay
        }

        // Check 2: Total Deductions Extracted (20 points)
        let deductionsConfidence = FieldValidators.amountConfidence(
            totalDeductions,
            fieldName: "totalDeductions",
            isCritical: false
        )
        fieldConfidences["totalDeductions"] = deductionsConfidence

        if totalDeductions > 0 {
            score += Points.totalDeductions
        }

        // Check 3: Net Remittance Consistency (50 points) - MOST IMPORTANT
        // Verifies the math: Gross - Deductions = Net
        let totalsConsistency = FieldValidators.totalsConsistencyConfidence(
            gross: grossPay,
            deductions: totalDeductions,
            net: netRemittance
        )
        fieldConfidences["netRemittance"] = totalsConsistency

        if totalsConsistency >= 1.0 {
            score += Points.netRemittanceConsistency  // Perfect match
        } else if totalsConsistency >= 0.8 {
            score += Points.netRemittanceConsistency * 0.8  // Good match
        } else if totalsConsistency >= 0.4 {
            score += Points.netRemittanceConsistency * 0.4  // Acceptable match
        }
        // else: no points (poor match)

        // Check 4: Core Fields Present (10 points)
        // Ensures we're extracting meaningful data, not just random numbers
        let basicPayConfidence = FieldValidators.amountConfidence(basicPay, isCritical: true)
        let daConfidence = FieldValidators.amountConfidence(dearnessAllowance, isCritical: false)
        let mspConfidence = FieldValidators.amountConfidence(militaryServicePay, isCritical: false)
        let dsopConfidence = FieldValidators.amountConfidence(dsop, isCritical: false)
        let agifConfidence = FieldValidators.amountConfidence(agif, isCritical: false)

        fieldConfidences["basicPay"] = basicPayConfidence
        fieldConfidences["dearnessAllowance"] = daConfidence
        fieldConfidences["militaryServicePay"] = mspConfidence
        fieldConfidences["dsop"] = dsopConfidence
        fieldConfidences["agif"] = agifConfidence

        let coreFields = [basicPay, dearnessAllowance, militaryServicePay, dsop, agif]
        let presentCount = coreFields.filter { $0 > 0 }.count

        if presentCount >= 3 {
            score += Points.coreFieldsPresent
        } else if presentCount >= 1 {
            score += Points.coreFieldsPresent * 0.5
        }

        let finalScore = min(1.0, score)

        return ConfidenceResult(
            overall: finalScore,
            fieldLevel: fieldConfidences,
            methodology: "Simplified",
            metadata: [
                "coreFieldsPresent": "\(presentCount)/5",
                "totalsConsistency": String(format: "%.2f", totalsConsistency)
            ]
        )
    }
}

// MARK: - Confidence Level Helpers (Legacy Support)

extension ConfidenceCalculator {

    /// Returns a descriptive level for a confidence score
    /// @deprecated Use ConfidenceLevel.from(score:) instead
    static func confidenceLevel(for score: Double) -> ConfidenceLevel {
        return ConfidenceLevel.from(score: score)
    }

    /// Returns a color for a confidence score
    /// @deprecated Use ConfidenceLevel.from(score:).color instead
    static func confidenceColor(for score: Double) -> String {
        return ConfidenceLevel.from(score: score).color
    }
}

