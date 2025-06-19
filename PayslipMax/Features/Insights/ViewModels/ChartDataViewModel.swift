import Foundation
import SwiftUI
import Combine
import Charts

/// ViewModel responsible for chart data preparation and visualization logic.
/// Extracted from InsightsViewModel to follow single responsibility principle.
@MainActor
class ChartDataViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: String?
    
    /// The chart data to display.
    @Published var chartData: [ChartData] = []
    
    /// The legend items to display.
    @Published var legendItems: [LegendItem] = []
    
    // MARK: - Private Properties
    
    /// The payslips to analyze.
    private var payslips: [PayslipItem] = []
    
    /// The current time range.
    private var timeRange: TimeRange = .year
    
    /// The current insight type.
    private var insightType: InsightType = .income
    
    /// The data service to use for fetching data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// The maximum value in the chart data.
    var maxChartValue: Double {
        return chartData.map { $0.value }.max() ?? 1.0
    }
    
    /// The total value for the selected insight type.
    var totalForSelectedInsight: Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { result, payslip in
            result + FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
        }
        let netIncome = totalIncome - totalDeductions
        
        switch insightType {
        case .income:
            return totalIncome
        case .deductions:
            return totalDeductions
        case .net:
            return netIncome
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes a new ChartDataViewModel.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Updates the payslips data for chart generation.
    ///
    /// - Parameter payslips: The payslips to analyze.
    func updatePayslips(_ payslips: [PayslipItem]) {
        self.payslips = payslips
        updateChartData()
    }
    
    /// Updates the time range and refreshes the chart data.
    ///
    /// - Parameter timeRange: The new time range.
    func updateTimeRange(_ timeRange: TimeRange) {
        self.timeRange = timeRange
        updateChartData()
    }
    
    /// Updates the insight type and refreshes the chart data.
    ///
    /// - Parameter insightType: The new insight type.
    func updateInsightType(_ insightType: InsightType) {
        self.insightType = insightType
        updateChartData()
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
    
    /// Updates the chart data based on the current time range and insight type.
    private func updateChartData() {
        var newChartData: [ChartData] = []
        var newLegendItems: [LegendItem] = []
        
        let groupedPayslips = groupPayslipsByPeriod(payslips)
        
        for (period, periodPayslips) in groupedPayslips.sorted(by: { $0.key < $1.key }) {
            let value: Double
            let category: String
            
            switch insightType {
            case .income:
                value = periodPayslips.reduce(0) { $0 + $1.credits }
                category = "Income"
            case .deductions:
                value = periodPayslips.reduce(0) { result, payslip in
                    result + FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
                }
                category = "Deductions"
            case .net:
                let income = periodPayslips.reduce(0) { $0 + $1.credits }
                let deductions = periodPayslips.reduce(0) { result, payslip in
                    result + FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
                }
                value = income - deductions
                category = "Net"
            }
            
            let chartDataItem = ChartData(
                period: period,
                value: value,
                category: category,
                date: createDateFromPeriod(period)
            )
            newChartData.append(chartDataItem)
        }
        
        // Generate legend items
        let categories = Set(newChartData.map { $0.category })
        for category in categories {
            let categoryData = newChartData.filter { $0.category == category }
            let totalValue = categoryData.reduce(0) { $0 + $1.value }
            
            let legendItem = LegendItem(
                category: category,
                color: colorForCategory(category),
                value: totalValue,
                percentage: calculatePercentage(totalValue, in: newChartData)
            )
            newLegendItems.append(legendItem)
        }
        
        chartData = newChartData
        legendItems = newLegendItems.sorted { $0.value > $1.value }
    }
    
    /// Groups payslips by the current time period.
    ///
    /// - Parameter payslips: The payslips to group.
    /// - Returns: A dictionary of period strings to payslips.
    private func groupPayslipsByPeriod(_ payslips: [PayslipItem]) -> [String: [PayslipItem]] {
        switch timeRange {
        case .month:
            return Dictionary(grouping: payslips) { payslip in
                "\(payslip.month) \(payslip.year)"
            }
        case .quarter:
            return Dictionary(grouping: payslips) { payslip in
                let quarter = getQuarter(from: payslip.month)
                return "Q\(quarter) \(payslip.year)"
            }
        case .year:
            return Dictionary(grouping: payslips) { payslip in
                "\(payslip.year)"
            }
        case .all:
            return Dictionary(grouping: payslips) { payslip in
                "\(payslip.month) \(payslip.year)"
            }
        }
    }
    
    /// Creates a date from a period string.
    ///
    /// - Parameter period: The period string to convert.
    /// - Returns: A date representing the period.
    private func createDateFromPeriod(_ period: String) -> Date {
        let calendar = Calendar.current
        
        if period.contains("Q") {
            // Quarter format: "Q1 2023"
            let components = period.components(separatedBy: " ")
            guard components.count == 2,
                  let quarterString = components.first,
                  let year = Int(components.last ?? ""),
                  quarterString.count == 2,
                  let quarter = Int(String(quarterString.dropFirst())) else {
                return Date()
            }
            
            let month = (quarter - 1) * 3 + 1
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = 1
            
            return calendar.date(from: dateComponents) ?? Date()
        } else if period.count == 4, let year = Int(period) {
            // Year format: "2023"
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = 1
            dateComponents.day = 1
            
            return calendar.date(from: dateComponents) ?? Date()
        } else {
            // Month format: "January 2023"
            let components = period.components(separatedBy: " ")
            guard components.count == 2,
                  let monthName = components.first,
                  let year = Int(components.last ?? "") else {
                return Date()
            }
            
            let monthNumber = monthToInt(monthName)
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = monthNumber
            dateComponents.day = 1
            
            return calendar.date(from: dateComponents) ?? Date()
        }
    }
    
    /// Gets the quarter number from a month name.
    ///
    /// - Parameter month: The month name.
    /// - Returns: The quarter number (1-4).
    private func getQuarter(from month: String) -> Int {
        let monthNumber = monthToInt(month)
        return (monthNumber - 1) / 3 + 1
    }
    
    /// Converts a month name to its numeric representation.
    ///
    /// - Parameter month: The month name.
    /// - Returns: The month number (1-12).
    private func monthToInt(_ month: String) -> Int {
        let monthNames = [
            "January": 1, "February": 2, "March": 3, "April": 4,
            "May": 5, "June": 6, "July": 7, "August": 8,
            "September": 9, "October": 10, "November": 11, "December": 12
        ]
        return monthNames[month] ?? 1
    }
    
    /// Calculates the percentage of a value within the total chart data.
    ///
    /// - Parameters:
    ///   - value: The value to calculate percentage for.
    ///   - chartData: The chart data to calculate against.
    /// - Returns: The percentage as a value between 0 and 100.
    private func calculatePercentage(_ value: Double, in chartData: [ChartData]) -> Double {
        let total = chartData.reduce(0) { $0 + $1.value }
        guard total > 0 else { return 0 }
        return (value / total) * 100
    }
}

// Note: ChartData and LegendItem models are defined in InsightsModels.swift 