import Foundation
import SwiftUI
import Combine

// MARK: - Chart Data Models

/// Represents a data point in a chart.
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let category: String
}

/// Represents an item in a chart legend.
struct LegendItem {
    let label: String
    let color: Color
}

// MARK: - Insight Models

/// Represents an insight item.
struct InsightItem {
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

/// Represents a trend item.
struct TrendItem {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let value: String?
}

// MARK: - Enums

/// Represents a time range for filtering data.
enum TimeRange: String, CaseIterable {
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case all = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
}

/// Represents a type of insight to display.
enum InsightType: String, CaseIterable {
    case income = "Earnings"
    case deductions = "Deductions"
    case net = "Net Remittance"
    
    var displayName: String {
        return self.rawValue
    }
}

/// Represents a type of chart to display.
enum ChartType: String, CaseIterable {
    case bar = "Bar"
    case line = "Line"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .bar: return "chart.bar"
        case .line: return "chart.line.uptrend.xyaxis"
        }
    }
}

@MainActor
class InsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: AppError?
    
    /// The chart data to display.
    @Published var chartData: [ChartDataPoint] = []
    
    /// The insights to display.
    @Published var insights: [InsightItem] = []
    
    /// The trends to display.
    @Published var trends: [TrendItem] = []
    
    /// The legend items to display.
    @Published var legendItems: [LegendItem] = []
    
    // MARK: - Private Properties
    
    /// The payslips to analyze.
    private var payslips: [any PayslipItemProtocol] = []
    
    /// The current time range.
    private var timeRange: TimeRange = .year
    
    /// The current insight type.
    private var insightType: InsightType = .income
    
    /// The data service to use for fetching data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// The total income for the selected time range.
    var totalIncome: Double {
        return filteredPayslips.reduce(0) { $0 + $1.credits }
    }
    
    /// The total deductions for the selected time range.
    var totalDeductions: Double {
        return filteredPayslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
    }
    
    /// The net income for the selected time range.
    var netIncome: Double {
        return totalIncome - totalDeductions
    }
    
    /// The total tax for the selected time range.
    var totalTax: Double {
        return filteredPayslips.reduce(0) { $0 + $1.tax }
    }
    
    /// The income trend percentage compared to the previous period.
    var incomeTrend: Double {
        return calculateTrend(for: \.credits)
    }
    
    /// The deductions trend percentage compared to the previous period.
    var deductionsTrend: Double {
        let currentDeductions = filteredPayslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let previousDeductions = previousPeriodPayslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        
        return calculatePercentageChange(from: previousDeductions, to: currentDeductions)
    }
    
    /// The net income trend percentage compared to the previous period.
    var netIncomeTrend: Double {
        let currentNet = filteredPayslips.reduce(0) { $0 + $1.calculateNetAmount() }
        let previousNet = previousPeriodPayslips.reduce(0) { $0 + $1.calculateNetAmount() }
        
        return calculatePercentageChange(from: previousNet, to: currentNet)
    }
    
    /// The tax trend percentage compared to the previous period.
    var taxTrend: Double {
        return calculateTrend(for: \.tax)
    }
    
    /// The maximum value in the chart data.
    var maxChartValue: Double {
        return chartData.map { $0.value }.max() ?? 1.0
    }
    
    /// The total value for the selected insight type.
    var totalForSelectedInsight: Double {
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
    
    /// Initializes a new InsightsViewModel.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the data with the specified payslips.
    ///
    /// - Parameter payslips: The payslips to analyze.
    func refreshData(payslips: [any PayslipItemProtocol]) {
        isLoading = true
        
        self.payslips = payslips
        
        // Generate chart data
        updateChartData()
        
        // Generate insights
        generateInsights()
        
        // Generate trends
        generateTrends()
        
        isLoading = false
    }
    
    /// Updates the time range and refreshes the data.
    ///
    /// - Parameter timeRange: The new time range.
    func updateTimeRange(_ timeRange: TimeRange) {
        self.timeRange = timeRange
        updateChartData()
        generateInsights()
        generateTrends()
    }
    
    /// Updates the insight type and refreshes the data.
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
            return .green
        case "Debits":
            return .red
        case "Tax":
            return .purple
        case "DSOP":
            return .orange
        case "Net", "Net Remittance":
            return .blue
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
        switch insightType {
        case .income:
            generateIncomeChartData()
        case .deductions:
            generateDeductionsChartData()
        case .net:
            generateNetIncomeChartData()
        }
        
        // Update legend items
        updateLegendItems()
    }
    
    /// Generates income chart data.
    private func generateIncomeChartData() {
        let groupedData = groupPayslipsByPeriod(filteredPayslips)
        
        chartData = groupedData.map { period, payslips in
            ChartDataPoint(
                label: period,
                value: payslips.reduce(0) { $0 + $1.credits },
                category: "Earnings"
            )
        }
        .sorted { periodSortValue($0.label) < periodSortValue($1.label) }
    }
    
    /// Generates deductions chart data.
    private func generateDeductionsChartData() {
        let groupedData = groupPayslipsByPeriod(filteredPayslips)
        
        var newChartData: [ChartDataPoint] = []
        
        for (period, payslips) in groupedData.sorted(by: { periodSortValue($0.key) < periodSortValue($1.key) }) {
            let debits = payslips.reduce(0) { $0 + $1.debits }
            let tax = payslips.reduce(0) { $0 + $1.tax }
            let dsop = payslips.reduce(0) { $0 + $1.dsop }
            
            newChartData.append(ChartDataPoint(label: period, value: debits, category: "Debits"))
            newChartData.append(ChartDataPoint(label: period, value: tax, category: "Tax"))
            newChartData.append(ChartDataPoint(label: period, value: dsop, category: "DSOP"))
        }
        
        chartData = newChartData
    }
    
    /// Generates net income chart data.
    private func generateNetIncomeChartData() {
        let groupedData = groupPayslipsByPeriod(filteredPayslips)
        
        chartData = groupedData.map { period, payslips in
            ChartDataPoint(
                label: period,
                value: payslips.reduce(0) { $0 + $1.calculateNetAmount() },
                category: "Net Remittance"
            )
        }
        .sorted { periodSortValue($0.label) < periodSortValue($1.label) }
    }
    
    /// Updates the legend items based on the current chart data.
    private func updateLegendItems() {
        let categories = Set(chartData.map { $0.category })
        legendItems = categories.map { category in
            LegendItem(label: category, color: colorForCategory(category))
        }
    }
    
    /// Generates insights based on the payslips.
    private func generateInsights() {
        var newInsights: [InsightItem] = []
        
        // Only generate insights if we have enough data
        if filteredPayslips.count >= 2 {
            // Highest income month
            if let highestIncome = filteredPayslips.max(by: { $0.credits < $1.credits }) {
                newInsights.append(InsightItem(
                    title: "Highest Income",
                    description: "Your highest income was in \(highestIncome.month) \(highestIncome.year) (₹\(String(format: "%.2f", highestIncome.credits)))",
                    iconName: "arrow.up.right.circle.fill",
                    color: .green
                ))
            }
            
            // Tax percentage
            let totalIncome = filteredPayslips.reduce(0) { $0 + $1.credits }
            let totalTax = filteredPayslips.reduce(0) { $0 + $1.tax }
            if totalIncome > 0 {
                let taxPercentage = (totalTax / totalIncome) * 100
                newInsights.append(InsightItem(
                    title: "Tax Percentage",
                    description: "You pay approximately \(String(format: "%.1f", taxPercentage))% of your income in taxes",
                    iconName: "percent",
                    color: .purple
                ))
            }
            
            // Income stability
            let incomes = filteredPayslips.map { $0.credits }
            if let average = incomes.average, let stdDev = incomes.standardDeviation {
                let variationCoefficient = (stdDev / average) * 100
                
                let stabilityDescription: String
                let stabilityIcon: String
                let stabilityColor: Color
                
                if variationCoefficient < 5 {
                    stabilityDescription = "Your income is very stable with minimal variation"
                    stabilityIcon = "checkmark.seal.fill"
                    stabilityColor = .green
                } else if variationCoefficient < 15 {
                    stabilityDescription = "Your income has moderate stability with some variation"
                    stabilityIcon = "checkmark.circle.fill"
                    stabilityColor = .blue
                } else {
                    stabilityDescription = "Your income shows significant variation between periods"
                    stabilityIcon = "exclamationmark.triangle.fill"
                    stabilityColor = .orange
                }
                
                newInsights.append(InsightItem(
                    title: "Income Stability",
                    description: stabilityDescription,
                    iconName: stabilityIcon,
                    color: stabilityColor
                ))
            }
        }
        
        insights = newInsights
    }
    
    /// Generates trends based on the payslips.
    private func generateTrends() {
        var newTrends: [TrendItem] = []
        
        // Only generate trends if we have enough data
        if filteredPayslips.count >= 3 {
            // Income trend
            let incomeTrendValue = incomeTrend
            let incomeTrendDescription: String
            let incomeTrendIcon: String
            let incomeTrendColor: Color
            
            if incomeTrendValue > 5 {
                incomeTrendDescription = "Your income is increasing significantly"
                incomeTrendIcon = "arrow.up.right"
                incomeTrendColor = .green
            } else if incomeTrendValue > 0 {
                incomeTrendDescription = "Your income is slightly increasing"
                incomeTrendIcon = "arrow.up.right"
                incomeTrendColor = .green
            } else if incomeTrendValue > -5 {
                incomeTrendDescription = "Your income is slightly decreasing"
                incomeTrendIcon = "arrow.down.right"
                incomeTrendColor = .orange
            } else {
                incomeTrendDescription = "Your income is decreasing significantly"
                incomeTrendIcon = "arrow.down.right"
                incomeTrendColor = .red
            }
            
            newTrends.append(TrendItem(
                title: "Income Trend",
                description: incomeTrendDescription,
                iconName: incomeTrendIcon,
                color: incomeTrendColor,
                value: "\(String(format: "%.1f", abs(incomeTrendValue)))% \(incomeTrendValue >= 0 ? "increase" : "decrease")"
            ))
            
            // Savings potential
            let averageIncome = filteredPayslips.map { $0.credits }.average ?? 0
            let averageDeductions = filteredPayslips.map { $0.debits + $0.tax + $0.dsop }.average ?? 0
            let savingsRatio = (averageIncome - averageDeductions) / averageIncome
            
            let savingsDescription: String
            let savingsIcon: String
            let savingsColor: Color
            
            if savingsRatio > 0.3 {
                savingsDescription = "You're saving a significant portion of your income"
                savingsIcon = "star.fill"
                savingsColor = .green
            } else if savingsRatio > 0.15 {
                savingsDescription = "You're saving a moderate portion of your income"
                savingsIcon = "star.leadinghalf.filled"
                savingsColor = .blue
            } else if savingsRatio > 0 {
                savingsDescription = "You're saving a small portion of your income"
                savingsIcon = "star"
                savingsColor = .orange
            } else {
                savingsDescription = "Your expenses exceed your income"
                savingsIcon = "exclamationmark.circle"
                savingsColor = .red
            }
            
            newTrends.append(TrendItem(
                title: "Savings Potential",
                description: savingsDescription,
                iconName: savingsIcon,
                color: savingsColor,
                value: "\(String(format: "%.1f", (savingsRatio * 100)))% of income"
            ))
            
            // Future income prediction
            if filteredPayslips.count >= 6 {
                let sortedPayslips = filteredPayslips.sorted { $0.timestamp < $1.timestamp }
                let incomes = sortedPayslips.map { $0.credits }
                
                if let slope = linearRegressionSlope(incomes) {
                    let predictionDescription: String
                    let predictionIcon: String
                    let predictionColor: Color
                    
                    if slope > 0 {
                        predictionDescription = "Based on your history, your income is projected to increase"
                        predictionIcon = "chart.line.uptrend.xyaxis"
                        predictionColor = .green
                    } else if slope < 0 {
                        predictionDescription = "Based on your history, your income is projected to decrease"
                        predictionIcon = "chart.line.downtrend.xyaxis"
                        predictionColor = .red
                    } else {
                        predictionDescription = "Based on your history, your income is projected to remain stable"
                        predictionIcon = "chart.line.flattrend.xyaxis"
                        predictionColor = .blue
                    }
                    
                    newTrends.append(TrendItem(
                        title: "Income Projection",
                        description: predictionDescription,
                        iconName: predictionIcon,
                        color: predictionColor,
                        value: nil
                    ))
                }
            }
        }
        
        trends = newTrends
    }
    
    /// Groups payslips by period based on the current time range.
    ///
    /// - Parameter payslips: The payslips to group.
    /// - Returns: A dictionary mapping periods to payslips.
    private func groupPayslipsByPeriod(_ payslips: [any PayslipItemProtocol]) -> [String: [any PayslipItemProtocol]] {
        var result: [String: [any PayslipItemProtocol]] = [:]
        
        for payslip in payslips {
            let period: String
            
            switch timeRange {
            case .month:
                period = "\(payslip.month) \(payslip.year)"
            case .quarter:
                let quarter = (monthToInt(payslip.month) - 1) / 3 + 1
                period = "Q\(quarter) \(payslip.year)"
            case .year:
                period = "\(payslip.year)"
            case .all:
                period = "All"
            }
            
            if result[period] == nil {
                result[period] = []
            }
            
            result[period]?.append(payslip)
        }
        
        return result
    }
    
    /// Returns a sort value for the specified period.
    ///
    /// - Parameter period: The period to get the sort value for.
    /// - Returns: The sort value.
    private func periodSortValue(_ period: String) -> String {
        switch timeRange {
        case .month:
            // Format: "Month Year" (e.g., "January 2023")
            let components = period.components(separatedBy: " ")
            if components.count >= 2 {
                let monthName = components[0]
                let yearString = components[1]
                
                if let year = Int(yearString) {
                    let month = monthToInt(monthName)
                    return String(format: "%04d%02d", year, month)
                }
            }
            
        case .quarter:
            // Format: "Q# Year" (e.g., "Q1 2023")
            let components = period.components(separatedBy: " ")
            if components.count >= 2 {
                let quarterString = components[0]
                let yearString = components[1]
                
                if let year = Int(yearString) {
                    // Extract quarter number
                    var quarter = 0
                    if quarterString.hasPrefix("Q") && quarterString.count > 1 {
                        let quarterChar = quarterString.dropFirst().prefix(1)
                        quarter = Int(quarterChar) ?? 0
                    }
                    
                    return String(format: "%04d%02d", year, quarter)
                }
            }
            
        case .year:
            // Format: "Year" (e.g., "2023")
            if let year = Int(period) {
                return String(format: "%04d", year)
            }
            
        case .all:
            return "0"
        }
        
        return period
    }
    
    /// Converts a month name to a month number.
    ///
    /// - Parameter month: The month name.
    /// - Returns: The month number (1-12).
    private func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        if let date = formatter.date(from: month) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Try abbreviated month names
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: month) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Try numeric month
        if let numericMonth = Int(month) {
            return numericMonth
        }
        
        return 0
    }
    
    /// Calculates the trend for the specified key path.
    ///
    /// - Parameter keyPath: The key path to calculate the trend for.
    /// - Returns: The trend percentage.
    private func calculateTrend(for keyPath: KeyPath<any PayslipItemProtocol, Double>) -> Double {
        let currentValue = filteredPayslips.reduce(0) { $0 + $1[keyPath: keyPath] }
        let previousValue = previousPeriodPayslips.reduce(0) { $0 + $1[keyPath: keyPath] }
        
        return calculatePercentageChange(from: previousValue, to: currentValue)
    }
    
    /// Calculates the percentage change from one value to another.
    ///
    /// - Parameters:
    ///   - from: The starting value.
    ///   - to: The ending value.
    /// - Returns: The percentage change.
    private func calculatePercentageChange(from: Double, to: Double) -> Double {
        guard from != 0 else { return 0 }
        return ((to - from) / from) * 100
    }
    
    /// Calculates the linear regression slope for the specified values.
    ///
    /// - Parameter values: The values to calculate the slope for.
    /// - Returns: The slope, or nil if there are not enough values.
    private func linearRegressionSlope(_ values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        
        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumXX = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        return slope
    }
    
    // MARK: - Filtered Payslips
    
    /// The payslips filtered by the current time range.
    private var filteredPayslips: [any PayslipItemProtocol] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch timeRange {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
            return payslips.filter { calendar.isDate($0.timestamp, equalTo: startOfMonth, toGranularity: .month) }
        case .quarter:
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentQuarter = (currentMonth - 1) / 3
            let startMonth = currentQuarter * 3 + 1
            
            var components = calendar.dateComponents([.year], from: currentDate)
            components.month = startMonth
            components.day = 1
            
            let startOfQuarter = calendar.date(from: components)!
            let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter)!
            
            return payslips.filter { $0.timestamp >= startOfQuarter && $0.timestamp < endOfQuarter }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
            return payslips.filter { calendar.isDate($0.timestamp, equalTo: startOfYear, toGranularity: .year) }
        case .all:
        return payslips
        }
    }
    
    /// The payslips from the previous period.
    private var previousPeriodPayslips: [any PayslipItemProtocol] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch timeRange {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
            let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            return payslips.filter { calendar.isDate($0.timestamp, equalTo: startOfPreviousMonth, toGranularity: .month) }
        case .quarter:
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentQuarter = (currentMonth - 1) / 3
            let startMonth = currentQuarter * 3 + 1
            
            var components = calendar.dateComponents([.year], from: currentDate)
            components.month = startMonth
            components.day = 1
            
            let startOfQuarter = calendar.date(from: components)!
            let startOfPreviousQuarter = calendar.date(byAdding: .month, value: -3, to: startOfQuarter)!
            let endOfPreviousQuarter = calendar.date(byAdding: .month, value: 3, to: startOfPreviousQuarter)!
            
            return payslips.filter { $0.timestamp >= startOfPreviousQuarter && $0.timestamp < endOfPreviousQuarter }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
            let startOfPreviousYear = calendar.date(byAdding: .year, value: -1, to: startOfYear)!
            return payslips.filter { calendar.isDate($0.timestamp, equalTo: startOfPreviousYear, toGranularity: .year) }
        case .all:
            return []
        }
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