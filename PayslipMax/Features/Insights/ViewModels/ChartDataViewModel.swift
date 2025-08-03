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
        case .trends:
            return totalIncome // Default to income for trends
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
            case .trends:
                value = periodPayslips.reduce(0) { $0 + $1.credits }
                category = "Trends"
            }
            
            let chartDataItem = ChartData(
                label: period,
                value: value,
                category: category
            )
            newChartData.append(chartDataItem)
        }
        
        // Generate legend items
        let categories = Set(newChartData.map { $0.category })
        for category in categories {
            let categoryData = newChartData.filter { $0.category == category }
            let _ = categoryData.reduce(0) { $0 + $1.value }
            
            let legendItem = LegendItem(
                label: category,
                color: colorForCategory(category)
            )
            newLegendItems.append(legendItem)
        }
        
        chartData = newChartData
        legendItems = newLegendItems
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
    
    // Date creation removed since not needed for simplified chart models
    
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
    
    // Percentage calculation removed since LegendItem doesn't have percentage property
}

// Note: ChartData and LegendItem models are defined in InsightsModels.swift 