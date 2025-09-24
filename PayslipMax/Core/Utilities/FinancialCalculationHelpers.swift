import Foundation

// MARK: - Financial Calculation Extensions

extension PayslipDataProtocol {
    /// Calculates net amount using the centralized utility.
    /// This ensures consistent calculation across the project.
    func calculateNetAmountUnified() -> Double {
        return FinancialCalculationUtility.shared.calculateNetIncome(for: self)
    }

    /// Validates financial consistency using the centralized utility.
    /// This helps identify calculation issues.
    func validateFinancialConsistency() -> [String] {
        return FinancialCalculationUtility.shared.validateFinancialConsistency(for: self)
    }
}

// MARK: - Financial Calculation Support Functions

extension FinancialCalculationUtility {
    /// Generic trend calculation helper.
    /// - Parameters:
    ///   - payslips: Array of payslips to analyze
    ///   - getValue: Closure to extract the value to trend
    /// - Returns: Percentage change between first and second half
    func calculateTrend(for payslips: [any PayslipDataProtocol], getValue: (any PayslipDataProtocol) -> Double) -> Double {
        guard payslips.count >= 2 else { return 0 }

        let midPoint = payslips.count / 2
        let earlierPayslips = Array(payslips.prefix(midPoint))
        let laterPayslips = Array(payslips.suffix(payslips.count - midPoint))

        let earlierTotal = earlierPayslips.reduce(0) { $0 + getValue($1) }
        let laterTotal = laterPayslips.reduce(0) { $0 + getValue($1) }

        let avgEarlier = earlierPayslips.isEmpty ? 0 : earlierTotal / Double(earlierPayslips.count)
        let avgLater = laterPayslips.isEmpty ? 0 : laterTotal / Double(laterPayslips.count)

        return calculatePercentageChange(from: avgEarlier, to: avgLater)
    }
}
