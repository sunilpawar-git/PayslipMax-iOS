import Foundation

// Import PayslipSection enum from PayslipSectionClassifier
// Note: PayslipSection is defined in PayslipSectionClassifier.swift

/// Service for reconciling parsed totals with stated payslip totals
/// Addresses classification errors that cause total mismatches
protocol TotalReconciliationServiceProtocol {
    func reconcileTotals(
        extractedEarnings: [String: Double],
        extractedDeductions: [String: Double],
        statedGrossPay: Double,
        statedTotalDeductions: Double
    ) async -> ReconciliationResult
}

struct ReconciliationResult {
    let adjustedEarnings: [String: Double]
    let adjustedDeductions: [String: Double]
    let adjustments: [ComponentAdjustment]
    let finalVariance: VarianceReport
    let confidence: Double
}

struct ComponentAdjustment {
    let component: String
    let originalSection: PayslipSection
    let adjustedSection: PayslipSection
    let amount: Double
    let reason: String
}

struct VarianceReport {
    let earningsVariance: Double
    let deductionsVariance: Double
    let earningsVariancePercentage: Double
    let deductionsVariancePercentage: Double
    let isWithinTolerance: Bool
}

class TotalReconciliationService: TotalReconciliationServiceProtocol {
    private let tolerancePercentage: Double = 2.0 // 2% tolerance

    func reconcileTotals(
        extractedEarnings: [String: Double],
        extractedDeductions: [String: Double],
        statedGrossPay: Double,
        statedTotalDeductions: Double
    ) async -> ReconciliationResult {

        print("[TotalReconciliationService] Starting total reconciliation")
        print("[TotalReconciliationService] Stated: Gross ₹\(statedGrossPay), Deductions ₹\(statedTotalDeductions)")

        let extractedGrossTotal = extractedEarnings.values.reduce(0, +)
        let extractedDeductionsTotal = extractedDeductions.values.reduce(0, +)

        print("[TotalReconciliationService] Extracted: Gross ₹\(extractedGrossTotal), Deductions ₹\(extractedDeductionsTotal)")

        var adjustedEarnings = extractedEarnings
        var adjustedDeductions = extractedDeductions
        var adjustments: [ComponentAdjustment] = []

        // Calculate initial variance
        let earningsVariance = extractedGrossTotal - statedGrossPay
        let deductionsVariance = extractedDeductionsTotal - statedTotalDeductions

        print("[TotalReconciliationService] Initial variance: Earnings ₹\(earningsVariance), Deductions ₹\(deductionsVariance)")

        // If variance is significant, attempt corrections
        if abs(earningsVariance) > (statedGrossPay * tolerancePercentage / 100) {
            let corrections = await identifyMisclassifiedComponents(
                earnings: extractedEarnings,
                deductions: extractedDeductions,
                targetEarningsAdjustment: -earningsVariance
            )

            for correction in corrections {
                adjustments.append(correction)

                // Apply the correction
                if correction.originalSection == .earnings {
                    adjustedEarnings.removeValue(forKey: correction.component)
                    adjustedDeductions[correction.component] = correction.amount
                } else {
                    adjustedDeductions.removeValue(forKey: correction.component)
                    adjustedEarnings[correction.component] = correction.amount
                }
            }
        }

        // Calculate final variance
        let finalEarningsTotal = adjustedEarnings.values.reduce(0, +)
        let finalDeductionsTotal = adjustedDeductions.values.reduce(0, +)
        let finalEarningsVariance = finalEarningsTotal - statedGrossPay
        let finalDeductionsVariance = finalDeductionsTotal - statedTotalDeductions

        let varianceReport = VarianceReport(
            earningsVariance: finalEarningsVariance,
            deductionsVariance: finalDeductionsVariance,
            earningsVariancePercentage: abs(finalEarningsVariance / statedGrossPay * 100),
            deductionsVariancePercentage: abs(finalDeductionsVariance / statedTotalDeductions * 100),
            isWithinTolerance: abs(finalEarningsVariance / statedGrossPay * 100) <= tolerancePercentage
        )

        let confidence = calculateConfidence(varianceReport: varianceReport, adjustmentCount: adjustments.count)

        print("[TotalReconciliationService] Final variance: Earnings ₹\(finalEarningsVariance) (\(String(format: "%.1f", varianceReport.earningsVariancePercentage))%)")
        print("[TotalReconciliationService] Reconciliation confidence: \(String(format: "%.1f", confidence * 100))%")

        return ReconciliationResult(
            adjustedEarnings: adjustedEarnings,
            adjustedDeductions: adjustedDeductions,
            adjustments: adjustments,
            finalVariance: varianceReport,
            confidence: confidence
        )
    }

    /// Identifies components that are likely misclassified based on common patterns
    private func identifyMisclassifiedComponents(
        earnings: [String: Double],
        deductions: [String: Double],
        targetEarningsAdjustment: Double
    ) async -> [ComponentAdjustment] {

        var adjustments: [ComponentAdjustment] = []
        var remainingAdjustment = targetEarningsAdjustment

        // Common misclassification patterns based on May 2025 analysis
        let commonMisclassifications = [
            // Transport allowances often misclassified as deductions
            ("TPTA", "Transport allowances typically earnings unless explicit recovery"),
            ("TPTADA", "Transport allowance DA variant typically earnings"),
            ("Transport Allowance Recovery", "May be misnamed - check if actually allowance"),
            ("Transport Allowance DA Recovery", "May be misnamed - check if actually allowance")
        ]

        for (componentPattern, reason) in commonMisclassifications {
            // Check if this component exists in wrong section
            if let deductionAmount = deductions.first(where: { $0.key.contains(componentPattern) })?.value,
               remainingAdjustment > 0 && deductionAmount <= remainingAdjustment + 100 { // 100 rupee tolerance

                adjustments.append(ComponentAdjustment(
                    component: componentPattern,
                    originalSection: .deductions,
                    adjustedSection: .earnings,
                    amount: deductionAmount,
                    reason: reason
                ))
                remainingAdjustment -= deductionAmount
            }
        }

        print("[TotalReconciliationService] Identified \(adjustments.count) potential misclassifications")
        return adjustments
    }

    private func calculateConfidence(varianceReport: VarianceReport, adjustmentCount: Int) -> Double {
        var confidence = 1.0

        // Decrease confidence based on variance
        confidence -= (varianceReport.earningsVariancePercentage / 100) * 0.5
        confidence -= (varianceReport.deductionsVariancePercentage / 100) * 0.5

        // Decrease confidence based on number of adjustments needed
        confidence -= Double(adjustmentCount) * 0.1

        return max(0.0, min(1.0, confidence))
    }
}

// PayslipSection enum already exists in PayslipSectionClassifier.swift
