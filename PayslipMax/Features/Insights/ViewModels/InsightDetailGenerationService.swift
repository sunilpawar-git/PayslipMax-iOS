import Foundation
import SwiftData

/// Service responsible for generating detailed breakdowns for insight items.
/// Extracted from InsightsCoordinator to improve modularity and testability.
class InsightDetailGenerationService {
    
    // MARK: - Private Helper Methods
    
    /// Sorts payslips chronologically using month and year information.
    /// - Parameter payslips: The payslips to sort
    /// - Returns: Payslips sorted chronologically (oldest to newest)
    private static func sortChronologically(_ payslips: [PayslipItem]) -> [PayslipItem] {
        return payslips.sorted { (lhs, rhs) in
            // First compare by year
            if lhs.year != rhs.year {
                return lhs.year < rhs.year
            }
            
            // If years are equal, compare by month
            let lhsMonthInt = monthToInt(lhs.month)
            let rhsMonthInt = monthToInt(rhs.month)
            return lhsMonthInt < rhsMonthInt
        }
    }
    
    /// Converts month name to integer for sorting.
    /// - Parameter monthName: The month name (e.g., "January", "Feb")
    /// - Returns: Month number (1-12), defaults to 1 if not found
    private static func monthToInt(_ monthName: String) -> Int {
        let monthMap: [String: Int] = [
            "January": 1, "Jan": 1,
            "February": 2, "Feb": 2,
            "March": 3, "Mar": 3,
            "April": 4, "Apr": 4,
            "May": 5,
            "June": 6, "Jun": 6,
            "July": 7, "Jul": 7,
            "August": 8, "Aug": 8,
            "September": 9, "Sep": 9,
            "October": 10, "Oct": 10,
            "November": 11, "Nov": 11,
            "December": 12, "Dec": 12
        ]
        return monthMap[monthName] ?? 1
    }
    
    // MARK: - Public Static Methods
    
    /// Generates monthly income breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly income breakdown in chronological order.
    static func generateMonthlyIncomeDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        let sortedPayslips = sortChronologically(payslips)
        return sortedPayslips.map { payslip in
            InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.credits,
                additionalInfo: payslip.credits == payslips.max(by: { $0.credits < $1.credits })?.credits ? "Highest month" : nil
            )
        }
    }
    
    /// Generates monthly tax breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly tax breakdown in chronological order.
    static func generateMonthlyTaxDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        let sortedPayslips = sortChronologically(payslips)
        return sortedPayslips.map { payslip in
            let taxRate = payslip.credits > 0 ? (payslip.tax / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.tax,
                additionalInfo: String(format: "%.1f%% of credits", taxRate)
            )
        }
    }
    
    /// Generates monthly deductions breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly deductions breakdown in chronological order.
    static func generateMonthlyDeductionsDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        let sortedPayslips = sortChronologically(payslips)
        return sortedPayslips.map { payslip in
            let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
            let deductionsRate = payslip.credits > 0 ? (totalDeductions / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: totalDeductions,
                additionalInfo: String(format: "%.1f%% of credits", deductionsRate)
            )
        }
    }
    
    /// Generates monthly net income breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly net income breakdown in chronological order.
    static func generateMonthlyNetIncomeDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        let sortedPayslips = sortChronologically(payslips)
        return sortedPayslips.map { payslip in
            let netAmount = payslip.credits - FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
            let netRate = payslip.credits > 0 ? (netAmount / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: netAmount,
                additionalInfo: String(format: "%.1f%% of credits", netRate)
            )
        }
    }
    
    /// Generates DSOP contribution breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing DSOP contribution breakdown in chronological order.
    static func generateDSOPDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        let sortedPayslips = sortChronologically(payslips.filter { $0.dsop > 0 })
        return sortedPayslips.map { payslip in
            let dsopRate = payslip.credits > 0 ? (payslip.dsop / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.dsop,
                additionalInfo: String(format: "%.1f%% of credits", dsopRate)
            )
        }
    }
    
    /// Generates income components breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing income components breakdown sorted by amount (this is appropriate for component analysis).
    static func generateIncomeComponentsDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        var componentTotals: [String: Double] = [:]
        
        for payslip in payslips {
            for (category, amount) in payslip.earnings {
                componentTotals[category, default: 0] += amount
            }
        }
        
        let totalEarnings = componentTotals.values.reduce(0, +)
        
        return componentTotals
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { (category, amount) in
                let percentage = totalEarnings > 0 ? (amount / totalEarnings) * 100 : 0
                return InsightDetailItem(
                    period: category,
                    value: amount,
                    additionalInfo: String(format: "%.1f%% of total income", percentage)
                )
            }
    }
} 