import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for basic financial calculations and summaries from payslip data.
/// Extracted from InsightsViewModel to follow single responsibility principle.
@MainActor
class FinancialSummaryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: String?
    
    // MARK: - Private Properties
    
    /// The payslips to analyze.
    private var payslips: [PayslipItem] = []
    
    /// The data service to use for fetching data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// The total income for the current payslips.
    var totalIncome: Double {
        return FinancialCalculationUtility.shared.aggregateTotalIncome(for: payslips)
    }
    
    /// The total deductions for the current payslips.
    var totalDeductions: Double {
        return FinancialCalculationUtility.shared.aggregateTotalDeductions(for: payslips)
    }
    
    /// The net income for the current payslips.
    var netIncome: Double {
        return FinancialCalculationUtility.shared.aggregateNetIncome(for: payslips)
    }
    
    /// The total tax for the current payslips.
    var totalTax: Double {
        return payslips.reduce(0) { $0 + $1.tax }
    }
    
    /// The average monthly income.
    var averageMonthlyIncome: Double {
        return FinancialCalculationUtility.shared.calculateAverageMonthlyIncome(for: payslips)
    }
    
    /// The average monthly net remittance.
    var averageNetRemittance: Double {
        return FinancialCalculationUtility.shared.calculateAverageNetRemittance(for: payslips)
    }
    
    /// The last updated date string.
    var lastUpdated: String {
        guard let latestPayslip = payslips.first else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: latestPayslip.timestamp)
    }
    
    /// Whether there are multiple payslips for analysis.
    var hasMultiplePayslips: Bool {
        return payslips.count >= 2
    }
    
    /// Whether there's yearly data available.
    var hasYearlyData: Bool {
        let years = Set(payslips.map { Calendar.current.component(.year, from: $0.timestamp) })
        return years.count >= 1 && payslips.count >= 6
    }
    
    /// Top earnings categories.
    var topEarnings: [(category: String, amount: Double, percentage: Double)] {
        return FinancialCalculationUtility.shared.calculateEarningsBreakdown(for: payslips)
    }
    
    /// Top deductions categories.
    var topDeductions: [(category: String, amount: Double, percentage: Double)] {
        return FinancialCalculationUtility.shared.calculateDeductionsBreakdown(for: payslips)
    }
    
    /// Best month by income.
    var bestMonth: String {
        guard let bestPayslip = payslips.max(by: { $0.credits < $1.credits }) else {
            return "N/A"
        }
        return "\(bestPayslip.month) \(bestPayslip.year)"
    }
    
    /// Worst month by income.
    var worstMonth: String {
        guard let worstPayslip = payslips.min(by: { $0.credits < $1.credits }) else {
            return "N/A"
        }
        return "\(worstPayslip.month) \(worstPayslip.year)"
    }
    
    /// Most consistent month.
    var mostConsistentMonth: String {
        let monthlyTotals = Dictionary(grouping: payslips) { payslip in
            payslip.month
        }.mapValues { payslips in
            payslips.map { $0.credits }
        }
        
        var leastVariableMonth = "N/A"
        var lowestVariation = Double.infinity
        
        for (month, incomes) in monthlyTotals {
            guard incomes.count > 1, let stdDev = incomes.standardDeviation else { continue }
            
            if stdDev < lowestVariation {
                lowestVariation = stdDev
                leastVariableMonth = month
            }
        }
        
        return leastVariableMonth
    }
    
    // MARK: - Trend Properties
    
    /// The income trend percentage compared to the previous period.
    var incomeTrend: Double {
        return FinancialCalculationUtility.shared.calculateIncomeTrend(for: payslips.sorted { $0.timestamp < $1.timestamp })
    }
    
    /// The deductions trend percentage compared to the previous period.
    var deductionsTrend: Double {
        return FinancialCalculationUtility.shared.calculateDeductionsTrend(for: payslips.sorted { $0.timestamp < $1.timestamp })
    }
    
    /// The net income trend percentage compared to the previous period.
    var netIncomeTrend: Double {
        return FinancialCalculationUtility.shared.calculateNetIncomeTrend(for: payslips.sorted { $0.timestamp < $1.timestamp })
    }
    
    /// The tax trend percentage compared to the previous period.
    var taxTrend: Double {
        return calculateTrend(for: \.tax)
    }
    
    // MARK: - Initialization
    
    /// Initializes a new FinancialSummaryViewModel.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Updates the payslips data for analysis.
    ///
    /// - Parameter payslips: The payslips to analyze.
    func updatePayslips(_ payslips: [PayslipItem]) {
        self.payslips = payslips
    }
    
    /// Returns the color for the specified category.
    ///
    /// - Parameter category: The category to get the color for.
    /// - Returns: The color for the category.
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Income", "Earnings":
            return FintechColors.successGreen
        case "Debits":
            return FintechColors.dangerRed
        case "Tax":
            return FintechColors.warningAmber
        case "DSOP":
            return FintechColors.primaryBlue
        case "Net", "Net Remittance":
            return FintechColors.secondaryBlue
        default:
            // Generate a consistent color based on the category string
            let hash = abs(category.hashValue)
            let hue = Double(hash % 100) / 100.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
    }
    
    // MARK: - Private Methods
    
    /// Calculates the trend for a specific field.
    ///
    /// - Parameter keyPath: The key path to the field.
    /// - Returns: The trend percentage.
    private func calculateTrend(for keyPath: KeyPath<PayslipItem, Double>) -> Double {
        guard payslips.count >= 2 else { return 0 }
        
        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
        let midpoint = sortedPayslips.count / 2
        
        let firstHalf = Array(sortedPayslips.prefix(midpoint))
        let secondHalf = Array(sortedPayslips.suffix(from: midpoint))
        
        let firstHalfAverage = firstHalf.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(firstHalf.count)
        let secondHalfAverage = secondHalf.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(secondHalf.count)
        
        guard firstHalfAverage > 0 else { return 0 }
        
        return ((secondHalfAverage - firstHalfAverage) / firstHalfAverage) * 100
    }
}

// MARK: - Array Extensions

extension Array where Element == Double {
    /// The average of the array.
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
    
    /// The standard deviation of the array.
    var standardDeviation: Double? {
        guard let avg = average, count > 1 else { return nil }
        let variance = reduce(0) { $0 + pow($1 - avg, 2) } / Double(count - 1)
        return sqrt(variance)
    }
} 