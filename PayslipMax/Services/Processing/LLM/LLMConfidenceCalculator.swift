import Foundation

/// Calculates confidence scores for LLM-parsed payslips
/// Uses penalty-based approach starting from high baseline
final class LLMConfidenceCalculator {

    // MARK: - Constants

    private struct Penalties {
        static let missingMonth: Double = 0.15
        static let missingYear: Double = 0.15
        static let missingNetRemittance: Double = 0.20
        static let missingGrossPay: Double = 0.10
        static let lowEarningsConfidence: Double = 0.15
        static let lowDeductionsConfidence: Double = 0.05
    }

    private struct BaseConfidence {
        // LLMs are generally reliable, start with high baseline
        static let llm: Double = 0.95
    }

    // MARK: - Public Methods

    /// Calculate confidence scores for LLM-parsed data
    /// - Parameters:
    ///   - response: The raw LLM response object
    ///   - earnings: Parsed earnings dictionary
    ///   - deductions: Parsed deductions dictionary
    /// - Returns: ConfidenceResult with overall and field-level scores
    static func calculateConfidence(
        for response: LLMPayslipResponse,
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> ConfidenceResult {
        var fieldConfidences: [String: Double] = [:]
        var penalties: [Double] = []

        // Start with high base confidence for LLM
        var overallConfidence = BaseConfidence.llm

        // Month field confidence - use shared validator
        if let month = response.month {
            fieldConfidences["month"] = FieldValidators.monthConfidence(month)
            if fieldConfidences["month"]! < 0.5 {
                penalties.append(Penalties.missingMonth)
            }
        } else {
            fieldConfidences["month"] = 0.0
            penalties.append(Penalties.missingMonth)
        }

        // Year field confidence - use shared validator
        if let year = response.year {
            fieldConfidences["year"] = FieldValidators.yearConfidence(year)
            if fieldConfidences["year"]! < 0.7 {
                penalties.append(Penalties.missingYear)
            }
        } else {
            fieldConfidences["year"] = 0.0
            penalties.append(Penalties.missingYear)
        }

        // Net remittance confidence (critical field)
        if let netRemittance = response.netRemittance {
            fieldConfidences["netRemittance"] = FieldValidators.amountConfidence(
                netRemittance,
                fieldName: "netRemittance",
                isCritical: true
            )
            if fieldConfidences["netRemittance"]! < 0.5 {
                penalties.append(Penalties.missingNetRemittance)
            }
        } else {
            fieldConfidences["netRemittance"] = 0.0
            penalties.append(Penalties.missingNetRemittance)
        }

        // Gross pay confidence
        if let grossPay = response.grossPay {
            fieldConfidences["grossPay"] = FieldValidators.amountConfidence(
                grossPay,
                fieldName: "grossPay",
                isCritical: true
            )
            if fieldConfidences["grossPay"]! < 0.5 {
                penalties.append(Penalties.missingGrossPay)
            }
        } else {
            let calculatedGross = earnings.values.reduce(0, +)
            fieldConfidences["grossPay"] = calculatedGross > 0 ? 0.8 : 0.2
            penalties.append(Penalties.missingGrossPay)
        }

        // Earnings confidence - use shared validator
        let earningsConfidence = FieldValidators.dictionaryConfidence(earnings, allowEmpty: false)
        fieldConfidences["earnings"] = earningsConfidence
        if earningsConfidence < 0.5 {
            penalties.append(Penalties.lowEarningsConfidence)
        }

        // Deductions confidence - use shared validator (empty is acceptable)
        let deductionsConfidence = FieldValidators.dictionaryConfidence(deductions, allowEmpty: true)
        fieldConfidences["deductions"] = deductionsConfidence
        if deductionsConfidence < 0.3 {
            penalties.append(Penalties.lowDeductionsConfidence)
        }

        // Apply penalties
        for penalty in penalties {
            overallConfidence -= penalty
        }

        let finalScore = max(0.0, overallConfidence)

        return ConfidenceResult(
            overall: finalScore,
            fieldLevel: fieldConfidences,
            methodology: "LLM",
            metadata: [
                "baseConfidence": String(format: "%.2f", BaseConfidence.llm),
                "penaltiesApplied": "\(penalties.count)"
            ]
        )
    }
}
