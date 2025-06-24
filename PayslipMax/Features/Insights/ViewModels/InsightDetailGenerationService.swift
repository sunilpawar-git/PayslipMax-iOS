import Foundation

/// Service responsible for generating detailed breakdowns for insight items.
/// Extracted from InsightsCoordinator to improve modularity and testability.
class InsightDetailGenerationService {
    
    // MARK: - Public Static Methods
    
    /// Generates monthly income breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly income breakdown.
    static func generateMonthlyIncomeDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        return payslips.map { payslip in
            InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.credits,
                additionalInfo: payslip.credits == payslips.max(by: { $0.credits < $1.credits })?.credits ? "Highest month" : nil
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly tax breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly tax breakdown.
    static func generateMonthlyTaxDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        return payslips.map { payslip in
            let taxRate = payslip.credits > 0 ? (payslip.tax / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.tax,
                additionalInfo: String(format: "%.1f%% of credits", taxRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly deductions breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly deductions breakdown.
    static func generateMonthlyDeductionsDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        return payslips.map { payslip in
            let totalDeductions = FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
            let deductionsRate = payslip.credits > 0 ? (totalDeductions / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: totalDeductions,
                additionalInfo: String(format: "%.1f%% of credits", deductionsRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly net income breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing monthly net income breakdown.
    static func generateMonthlyNetIncomeDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        return payslips.map { payslip in
            let netAmount = payslip.credits - FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
            let netRate = payslip.credits > 0 ? (netAmount / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: netAmount,
                additionalInfo: String(format: "%.1f%% of credits", netRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates DSOP contribution breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing DSOP contribution breakdown.
    static func generateDSOPDetails(from payslips: [PayslipItem]) -> [InsightDetailItem] {
        return payslips.filter { $0.dsop > 0 }.map { payslip in
            let dsopRate = payslip.credits > 0 ? (payslip.dsop / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.dsop,
                additionalInfo: String(format: "%.1f%% of credits", dsopRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates income components breakdown data.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight detail items showing income components breakdown.
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