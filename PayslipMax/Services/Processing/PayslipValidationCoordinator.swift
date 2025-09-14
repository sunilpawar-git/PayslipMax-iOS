import Foundation

/// Protocol for payslip validation coordination
protocol PayslipValidationCoordinatorProtocol {
    /// Validates extracted financial totals against stated totals from payslip
    /// - Parameters:
    ///   - earnings: Dictionary of earnings components
    ///   - deductions: Dictionary of deduction components
    ///   - legacyData: Extracted financial data from legacy patterns
    /// - Returns: Validated totals (credits, debits) preferring stated totals when variance is acceptable
    func validateAndGetTotals(
        earnings: [String: Double],
        deductions: [String: Double],
        legacyData: [String: Double]
    ) -> (credits: Double, debits: Double)
}

/// Service responsible for validating payslip extraction results against stated totals
/// Handles variance calculation and determines whether to use extracted or stated totals
class PayslipValidationCoordinator: PayslipValidationCoordinatorProtocol {

    // MARK: - PayslipValidationCoordinatorProtocol Implementation

    /// Validates extracted financial totals against stated totals from payslip
    /// Performs cross-validation with variance calculations to ensure accuracy
    /// - Parameters:
    ///   - earnings: Dictionary of earnings components
    ///   - deductions: Dictionary of deduction components
    ///   - legacyData: Extracted financial data from legacy patterns
    /// - Returns: Validated totals (credits, debits) preferring stated totals when variance is acceptable
    func validateAndGetTotals(
        earnings: [String: Double],
        deductions: [String: Double],
        legacyData: [String: Double]
    ) -> (credits: Double, debits: Double) {
        print("[PayslipValidationCoordinator] Starting payslip validation")

        // Calculate extracted totals
        let extractedCredits = earnings.values.reduce(0, +)
        let extractedDebits = deductions.values.reduce(0, +)

        // Get stated totals from legacy data
        let statedGrossPay = legacyData["credits"] ?? 0.0
        let statedTotalDeductions = legacyData["debits"] ?? 0.0

        // Validate credits
        var finalCredits = extractedCredits
        if statedGrossPay > 0 {
            let creditsDifference = abs(extractedCredits - statedGrossPay)
            let creditsVariancePercent = (creditsDifference / statedGrossPay) * 100

            print("[PayslipValidationCoordinator] Credits validation - Extracted: ₹\(extractedCredits), Stated: ₹\(statedGrossPay), Variance: \(String(format: "%.1f", creditsVariancePercent))%")

            // If variance is too high, prefer stated total and log warning
            if creditsVariancePercent > 20.0 {
                print("[PayslipValidationCoordinator] WARNING: High variance in credits extraction, using stated total")
                finalCredits = statedGrossPay
            }
        }

        // Validate debits
        var finalDebits = extractedDebits
        if statedTotalDeductions > 0 {
            let debitsDifference = abs(extractedDebits - statedTotalDeductions)
            let debitsVariancePercent = (debitsDifference / statedTotalDeductions) * 100

            print("[PayslipValidationCoordinator] Debits validation - Extracted: ₹\(extractedDebits), Stated: ₹\(statedTotalDeductions), Variance: \(String(format: "%.1f", debitsVariancePercent))%")

            if debitsVariancePercent > 20.0 {
                print("[PayslipValidationCoordinator] WARNING: High variance in debits extraction, using stated total")
                finalDebits = statedTotalDeductions
            }
        }

        print("[PayslipValidationCoordinator] Final validated totals - Credits: ₹\(finalCredits), Debits: ₹\(finalDebits)")
        return (credits: finalCredits, debits: finalDebits)
    }
}
