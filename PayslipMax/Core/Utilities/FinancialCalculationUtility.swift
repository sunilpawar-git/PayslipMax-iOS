import Foundation

/// Centralized utility for uniform financial calculations across the PayslipMax project.
/// This ensures consistent calculation logic and prevents double-counting errors.
class FinancialCalculationUtility {
    
    // MARK: - Singleton
    static let shared = FinancialCalculationUtility()
    private init() {}
    
    // MARK: - Core Financial Calculations
    
    /// Calculates the correct total deductions for a payslip.
    /// Uses debits as the authoritative total (which already includes all deductions).
    /// - Parameter payslip: The payslip to calculate deductions for
    /// - Returns: The total deductions amount
    func calculateTotalDeductions(for payslip: any PayslipDataProtocol) -> Double {
        // The debits field is the authoritative total deductions
        // It already includes tax, dsop, and all other deductions
        return payslip.debits
    }
    
    /// Calculates the correct net income for a payslip.
    /// Net income = credits - debits (debits already includes all deductions)
    /// - Parameter payslip: The payslip to calculate net income for
    /// - Returns: The net income amount
    func calculateNetIncome(for payslip: any PayslipDataProtocol) -> Double {
        return payslip.credits - payslip.debits
    }
    
    /// Aggregates total income across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total income across all payslips
    func aggregateTotalIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + $1.credits }
    }
    
    /// Aggregates total deductions across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total deductions across all payslips
    func aggregateTotalDeductions(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + calculateTotalDeductions(for: $1) }
    }
    
    /// Aggregates net income across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total net income across all payslips
    func aggregateNetIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + calculateNetIncome(for: $1) }
    }
    
    /// Calculates average monthly income from a set of payslips.
    /// - Parameter payslips: Array of payslips to calculate average from
    /// - Returns: Average monthly income or 0 if no payslips
    func calculateAverageMonthlyIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        guard !payslips.isEmpty else { return 0 }
        let totalIncome = aggregateTotalIncome(for: payslips)
        return totalIncome / Double(payslips.count)
    }
    
    /// Calculates average monthly net remittance from a set of payslips.
    /// - Parameter payslips: Array of payslips to calculate average from
    /// - Returns: Average monthly net remittance or 0 if no payslips
    func calculateAverageNetRemittance(for payslips: [any PayslipDataProtocol]) -> Double {
        guard !payslips.isEmpty else { return 0 }
        let totalNetIncome = aggregateNetIncome(for: payslips)
        return totalNetIncome / Double(payslips.count)
    }
    
    // MARK: - Category Breakdown Calculations
    
    /// Creates a unified earnings breakdown from multiple payslips.
    /// Aggregates earnings by category across all payslips.
    /// - Parameter payslips: Array of payslips to analyze
    /// - Returns: Dictionary of category totals with percentages
    func calculateEarningsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        var categoryTotals: [String: Double] = [:]
        
        for payslip in payslips {
            for (category, amount) in payslip.earnings {
                categoryTotals[category, default: 0] += amount
            }
        }
        
        let totalIncome = categoryTotals.values.reduce(0, +)
        
        return categoryTotals
            .compactMap { (category, amount) in
                guard amount > 0 else { return nil }
                let percentage = totalIncome > 0 ? (amount / totalIncome) * 100 : 0
                return (category: category, amount: amount, percentage: percentage)
            }
            .sorted { $0.amount > $1.amount }
    }
    
    /// Creates a unified deductions breakdown from multiple payslips.
    /// Prevents double-counting of tax and DSOP by checking if they're already in deductions dictionary.
    /// - Parameter payslips: Array of payslips to analyze
    /// - Returns: Dictionary of category totals with percentages
    func calculateDeductionsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        var categoryTotals: [String: Double] = [:]
        
        for payslip in payslips {
            // Add deductions from the detailed breakdown
            for (category, amount) in payslip.deductions {
                categoryTotals[category, default: 0] += amount
            }
            
            // Only add tax and DSOP if they're NOT already in deductions dictionary
            // This prevents double-counting
            if payslip.tax > 0 && !payslip.deductions.keys.contains(where: { key in
                key.uppercased().contains("TAX") || key.uppercased().contains("ITAX")
            }) {
                categoryTotals["Income Tax", default: 0] += payslip.tax
            }
            
            if payslip.dsop > 0 && payslip.deductions["DSOP"] == nil {
                categoryTotals["DSOP", default: 0] += payslip.dsop
            }
        }
        
        let totalDeductions = categoryTotals.values.reduce(0, +)
        
        return categoryTotals
            .compactMap { (category, amount) in
                guard amount > 0 else { return nil }
                let percentage = totalDeductions > 0 ? (amount / totalDeductions) * 100 : 0
                return (category: category, amount: amount, percentage: percentage)
            }
            .sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Trend Calculations
    
    /// Calculates percentage change between two values.
    /// - Parameters:
    ///   - from: The original value
    ///   - to: The new value
    /// - Returns: Percentage change (positive for increase, negative for decrease)
    func calculatePercentageChange(from: Double, to: Double) -> Double {
        guard from > 0 else { return 0 }
        return ((to - from) / from) * 100
    }
    
    /// Calculates income trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in income trend
    func calculateIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return calculateTrend(for: payslips, getValue: { $0.credits })
    }
    
    /// Calculates deductions trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in deductions trend
    func calculateDeductionsTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return calculateTrend(for: payslips, getValue: { calculateTotalDeductions(for: $0) })
    }
    
    /// Calculates net income trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in net income trend
    func calculateNetIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return calculateTrend(for: payslips, getValue: { calculateNetIncome(for: $0) })
    }
    
    /// Calculates growth rate between current and previous values.
    /// - Parameters:
    ///   - current: The current value
    ///   - previous: The previous value
    /// - Returns: Growth rate as a percentage
    func calculateGrowthRate(current: Double, previous: Double) -> Double {
        return calculatePercentageChange(from: previous, to: current)
    }
    
    // MARK: - Validation Methods
    
    /// Validates that financial calculations are consistent across a payslip.
    /// - Parameter payslip: The payslip to validate
    /// - Returns: Array of validation issues found
    func validateFinancialConsistency(for payslip: any PayslipDataProtocol) -> [String] {
        var issues: [String] = []
        
        // Check if debits equals sum of deductions + tax + dsop (should NOT be the case)
        let deductionsSum = payslip.deductions.values.reduce(0, +)
        let manualSum = deductionsSum + payslip.tax + payslip.dsop
        
        if abs(payslip.debits - manualSum) < 1.0 && payslip.tax > 0 && payslip.dsop > 0 {
            issues.append("Possible double-counting: debits equals deductions + tax + dsop")
        }
        
        // Check if DSOP is in both deductions dictionary and dsop property
        if let dsopInDeductions = payslip.deductions["DSOP"], payslip.dsop > 0 {
            if abs(dsopInDeductions - payslip.dsop) < 1.0 {
                issues.append("DSOP is duplicated in both deductions dictionary and dsop property")
            }
        }
        
        // Check if tax is in both deductions dictionary and tax property
        let taxInDeductions = payslip.deductions.first { key, _ in
            key.uppercased().contains("TAX") || key.uppercased().contains("ITAX")
        }
        
        if let (_, taxAmount) = taxInDeductions, payslip.tax > 0 {
            if abs(taxAmount - payslip.tax) < 1.0 {
                issues.append("Tax is duplicated in both deductions dictionary and tax property")
            }
        }
        
        return issues
    }
    
    // MARK: - Private Helper Methods
    
    /// Generic trend calculation helper.
    /// - Parameters:
    ///   - payslips: Array of payslips to analyze
    ///   - getValue: Closure to extract the value to trend
    /// - Returns: Percentage change between first and second half
    private func calculateTrend(for payslips: [any PayslipDataProtocol], getValue: (any PayslipDataProtocol) -> Double) -> Double {
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

// MARK: - PayslipDataProtocol Extension

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