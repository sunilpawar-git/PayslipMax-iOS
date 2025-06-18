import Foundation
import SwiftUI
import Combine
import Charts

// MARK: - Additional Models

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
    @Published var error: String?
    
    /// The chart data to display.
    @Published var chartData: [ChartData] = []
    
    /// The insights to display.
    @Published var insights: [InsightItem] = []
    
    /// The trends to display.
    @Published var trends: [TrendItem] = []
    
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
    
    /// The total income for the selected time range.
    var totalIncome: Double {
        return FinancialCalculationUtility.shared.aggregateTotalIncome(for: payslips)
    }
    
    /// The total deductions for the selected time range.
    var totalDeductions: Double {
        return FinancialCalculationUtility.shared.aggregateTotalDeductions(for: payslips)
    }
    
    /// The net income for the selected time range.
    var netIncome: Double {
        return FinancialCalculationUtility.shared.aggregateNetIncome(for: payslips)
    }
    
    /// The total tax for the selected time range.
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
    
    /// Income stability description.
    var incomeStabilityDescription: String {
        let variation = incomeVariation
        let avgIncome = payslips.map { $0.credits }.average ?? 0
        
        guard avgIncome > 0 else { return "Insufficient Data" }
        
        let variationPercentage = (variation / avgIncome) * 100
        
        if variationPercentage < 5 {
            return "Very Stable"
        } else if variationPercentage < 15 {
            return "Moderately Stable"
        } else {
            return "Variable"
        }
    }
    
    /// Income stability color.
    var incomeStabilityColor: Color {
        let description = incomeStabilityDescription
        switch description {
        case "Very Stable": return FintechColors.successGreen
        case "Moderately Stable": return FintechColors.primaryBlue
        case "Variable": return FintechColors.warningAmber
        default: return FintechColors.textSecondary
        }
    }
    
    /// Income variation amount.
    var incomeVariation: Double {
        let incomes = payslips.map { $0.credits }
        guard let stdDev = incomes.standardDeviation else { return 0 }
        return stdDev
    }
    
    /// Stability analysis text.
    var stabilityAnalysis: String {
        let variation = incomeVariation
        let avgIncome = payslips.map { $0.credits }.average ?? 0
        
        guard avgIncome > 0 else { return "Need more data for analysis" }
        
        let variationPercentage = (variation / avgIncome) * 100
        
        if variationPercentage < 5 {
            return "Your income is very consistent month to month, indicating stable employment."
        } else if variationPercentage < 15 {
            return "Your income has some variation, which is normal for most jobs with variable components."
        } else {
            return "Your income varies significantly. Consider reviewing variable pay components."
        }
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
    /// - Parameter payslips: The payslips to analyze (should already be filtered).
    func refreshData(payslips: [PayslipItem]) {
        isLoading = true
        
        // Use the passed payslips directly (they are already filtered by the view)
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
        var newChartData: [ChartData] = []
        var newLegendItems: [LegendItem] = []
        
        let groupedPayslips = groupPayslipsByPeriod(payslips)
        
        for (period, periodPayslips) in groupedPayslips.sorted(by: { $0.key < $1.key }) {
            let value: Double
            let category: String
            
            switch insightType {
            case .income:
                value = periodPayslips.reduce(0) { $0 + $1.credits }
                category = "Earnings"
            case .deductions:
                value = periodPayslips.reduce(0) { $0 + $1.debits }
                category = "Deductions"
            case .net:
                value = periodPayslips.reduce(0) { $0 + $1.credits - $1.debits }
                category = "Net Remittance"
            }
            
            newChartData.append(ChartData(
                label: period,
                value: value,
                category: category
            ))
        }
        
        // Create legend items
        newLegendItems.append(LegendItem(
            label: insightType.displayName,
            color: colorForCategory(insightType.displayName)
        ))
        
        chartData = newChartData
        legendItems = newLegendItems
    }
    
    /// Generates insights based on the payslips.
    private func generateInsights() {
        var newInsights: [InsightItem] = []
        
        // Only generate insights if we have data
        guard !payslips.isEmpty else {
            insights = []
            return
        }
        
        // 1. Highest income insight
        if let highestIncome = payslips.max(by: { $0.credits < $1.credits }) {
            newInsights.append(InsightItem(
                title: "Highest Income",
                description: "Your highest income was in \(highestIncome.month) \(highestIncome.year) (₹\(String(format: "%.0f", highestIncome.credits)))",
                iconName: "arrow.up.circle.fill",
                color: FintechColors.successGreen,
                detailItems: generateMonthlyIncomeDetails(),
                detailType: .monthlyIncomes
            ))
        }
        
        // 2. Tax percentage insight
        let totalIncomeForTax = payslips.reduce(0) { $0 + $1.credits }
        let totalTaxPaid = payslips.reduce(0) { $0 + $1.tax }
        if totalIncomeForTax > 0 {
            let taxPercentage = (totalTaxPaid / totalIncomeForTax) * 100
            let taxDescription = taxPercentage < 10 ? "You're in a low tax bracket (\(String(format: "%.1f", taxPercentage))%)" : 
                                taxPercentage < 20 ? "You pay a moderate amount in taxes (\(String(format: "%.1f", taxPercentage))%)" :
                                "You're in a higher tax bracket (\(String(format: "%.1f", taxPercentage))%)"
            
            newInsights.append(InsightItem(
                title: "Tax Rate",
                description: taxDescription,
                iconName: "percent",
                color: FintechColors.warningAmber,
                detailItems: generateMonthlyTaxDetails(),
                detailType: .monthlyTaxes
            ))
        }
        
        // 3. Income growth insight
        if payslips.count >= 2 {
            let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
            let firstIncome = sortedPayslips.first?.credits ?? 0
            let lastIncome = sortedPayslips.last?.credits ?? 0
            
            if firstIncome > 0 {
                let growthRate = ((lastIncome - firstIncome) / firstIncome) * 100
                let growthDescription = growthRate > 5 ? "Your income is growing well (\(String(format: "%.1f", abs(growthRate)))%)" :
                                      growthRate > 0 ? "Your income is slightly increasing (\(String(format: "%.1f", abs(growthRate)))%)" :
                                      growthRate > -5 ? "Your income is slightly decreasing (\(String(format: "%.1f", abs(growthRate)))%)" :
                                      "Your income has decreased significantly (\(String(format: "%.1f", abs(growthRate)))%)"
                
                let growthColor = growthRate > 0 ? FintechColors.successGreen : FintechColors.dangerRed
                
                newInsights.append(InsightItem(
                    title: "Income Growth",
                    description: growthDescription,
                    iconName: growthRate >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    color: growthColor,
                    detailItems: generateMonthlyIncomeDetails(),
                    detailType: .monthlyIncomes
                ))
            }
        }
        
        // 4. Savings potential insight
        let avgIncome = payslips.map { $0.credits }.average ?? 0
        let avgDeductions = payslips.map { $0.debits }.average ?? 0
        let netAmount = avgIncome - avgDeductions
        
        if avgIncome > 0 {
            let savingsRate = (netAmount / avgIncome) * 100
            let savingsDescription = savingsRate > 30 ? "Excellent savings potential (\(String(format: "%.1f", savingsRate))%)" :
                                   savingsRate > 15 ? "Good savings opportunity (\(String(format: "%.1f", savingsRate))%)" :
                                   savingsRate > 0 ? "Limited savings potential (\(String(format: "%.1f", savingsRate))%)" :
                                   "Expenses exceed income"
            
            let savingsColor = savingsRate > 30 ? FintechColors.successGreen :
                              savingsRate > 15 ? FintechColors.primaryBlue :
                              savingsRate > 0 ? FintechColors.warningAmber :
                              FintechColors.dangerRed
            
            newInsights.append(InsightItem(
                title: "Savings Rate",
                description: savingsDescription,
                iconName: "dollarsign.circle.fill",
                color: savingsColor,
                detailItems: generateMonthlyIncomeDetails().map { item in
                    let payslip = payslips.first { "\($0.month) \($0.year)" == item.period }
                    let netAmount = (payslip?.credits ?? 0) - (payslip != nil ? FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip!) : 0)
                    return InsightDetailItem(
                        period: item.period,
                        value: netAmount,
                        additionalInfo: String(format: "%.1f%% savings potential", netAmount / max(item.value, 1) * 100)
                    )
                },
                detailType: .monthlyNetIncome
            ))
        }
        
        // 5. Income stability insight (if multiple payslips)
        if payslips.count >= 3 {
            let incomes = payslips.map { $0.credits }
            if let average = incomes.average, let stdDev = incomes.standardDeviation {
                let variationCoefficient = (stdDev / average) * 100
                
                let stabilityDescription: String
                let stabilityColor: Color
                
                if variationCoefficient < 5 {
                    stabilityDescription = "Very stable income pattern (±₹\(String(format: "%.0f", stdDev)))"
                    stabilityColor = FintechColors.successGreen
                } else if variationCoefficient < 15 {
                    stabilityDescription = "Moderately stable income (±₹\(String(format: "%.0f", stdDev)))"
                    stabilityColor = FintechColors.primaryBlue
                } else {
                    stabilityDescription = "Income varies significantly (±₹\(String(format: "%.0f", stdDev)))"
                    stabilityColor = FintechColors.warningAmber
                }
                
                newInsights.append(InsightItem(
                    title: "Income Stability",
                    description: stabilityDescription,
                    iconName: "chart.line.uptrend.xyaxis",
                    color: stabilityColor,
                    detailItems: generateMonthlyIncomeDetails().map { item in
                        InsightDetailItem(
                            period: item.period,
                            value: item.value,
                            additionalInfo: String(format: "Variation: ±₹%.0f from avg", abs(item.value - (incomes.average ?? 0)))
                        )
                    },
                    detailType: .incomeStabilityData
                ))
            }
        }
        
        // 6. DSOP contribution insight
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        if totalDSOP > 0 && totalIncomeForTax > 0 {
            let dsopRate = (totalDSOP / totalIncomeForTax) * 100
            let dsopDescription = dsopRate > 15 ? "Excellent retirement savings (\(String(format: "%.1f", dsopRate))%)" :
                                 dsopRate > 10 ? "Good retirement planning (\(String(format: "%.1f", dsopRate))%)" :
                                 "Consider increasing DSOP contribution (\(String(format: "%.1f", dsopRate))%)"
            
            newInsights.append(InsightItem(
                title: "DSOP Contribution",
                description: dsopDescription,
                iconName: "building.columns.fill",
                color: FintechColors.chartSecondary,
                detailItems: generateDSOPDetails(),
                detailType: .monthlyDSOP
            ))
        }
        
        // 7. Deduction percentage insight with component analysis
        let totalGrossPay = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + FinancialCalculationUtility.shared.calculateTotalDeductions(for: $1) }
        
        if totalGrossPay > 0 {
            let deductionPercentage = (totalDeductions / totalGrossPay) * 100
            
            // Analyze deduction components to provide specific guidance
            var deductionComponents: [String: Double] = [:]
            var totalTax: Double = 0
            var totalDSOP: Double = 0
            var totalAGIF: Double = 0
            
            for payslip in payslips {
                totalTax += payslip.tax
                totalDSOP += payslip.dsop
                
                // Check for AGIF in deductions dictionary
                if let agif = payslip.deductions["AGIF"] {
                    totalAGIF += agif
                }
                
                // Add other deduction components
                for (key, value) in payslip.deductions {
                    deductionComponents[key, default: 0] += value
                }
            }
            
            // Categorize components
            deductionComponents["Income Tax"] = totalTax
            if totalDSOP > 0 { deductionComponents["DSOP"] = totalDSOP }
            if totalAGIF > 0 { deductionComponents["AGIF"] = totalAGIF }
            
            // Find the largest deduction component
            let sortedComponents = deductionComponents.sorted { $0.value > $1.value }
            let topDeductionComponent = sortedComponents.first
            
            let deductionColor: Color
            
            // Build base message with component analysis
            var baseMessage = "Approximately \(String(format: "%.1f", deductionPercentage))% of your gross pay goes towards deductions"
            
            // Add component-specific guidance
            if let topComponent = topDeductionComponent, totalDeductions > 0 {
                let componentPercentage = (topComponent.value / totalDeductions) * 100
                let componentName = topComponent.key
                
                // Determine if this is a "good" or "optimizable" deduction
                if componentName.uppercased().contains("DSOP") || componentName.uppercased().contains("AGIF") {
                    // Good deductions - retirement savings and insurance
                    baseMessage += ". \(componentName) (\(String(format: "%.1f", componentPercentage))% of deductions) is excellent for long-term wealth building"
                } else if componentName.uppercased().contains("TAX") || componentName.uppercased().contains("ITAX") {
                    // Optimizable deductions - tax can be reduced through investments
                    baseMessage += ". Income Tax (\(String(format: "%.1f", componentPercentage))% of deductions) can be optimized through tax-saving investments like 80C, NPS, ELSS"
                } else {
                    // Other deductions
                    baseMessage += ". \(componentName) is your largest deduction component (\(String(format: "%.1f", componentPercentage))%)"
                }
            }
            
            // Determine color based on percentage and optimization potential
            if deductionPercentage < 20 {
                baseMessage += " - very efficient"
                deductionColor = FintechColors.successGreen
            } else if deductionPercentage < 30 {
                baseMessage += " - reasonable range"
                deductionColor = FintechColors.primaryBlue
            } else if deductionPercentage < 40 {
                if totalTax > totalDSOP + totalAGIF {
                    baseMessage += " - consider tax optimization strategies"
                } else {
                    baseMessage += " - review for optimization opportunities"
                }
                deductionColor = FintechColors.warningAmber
            } else {
                if totalTax > totalDSOP + totalAGIF {
                    baseMessage += " - high tax burden, urgent need for investment planning"
                } else {
                    baseMessage += " - review recommended for efficiency"
                }
                deductionColor = FintechColors.dangerRed
            }
            
            newInsights.append(InsightItem(
                title: "Deduction Rate",
                description: baseMessage,
                iconName: "minus.circle.fill",
                color: deductionColor,
                detailItems: generateMonthlyDeductionsDetails(),
                detailType: .monthlyDeductions
            ))
        }
        
        // 8. Best performing component insight
        if !payslips.isEmpty {
            var componentTotals: [String: Double] = [:]
            
            for payslip in payslips {
                for (category, amount) in payslip.earnings {
                    componentTotals[category, default: 0] += amount
                }
            }
            
            let sortedComponents = componentTotals
                .filter { $0.value > 0 }
                .sorted { $0.value > $1.value }
            
            if let topComponent = sortedComponents.first {
                let totalEarnings = componentTotals.values.reduce(0, +)
                let percentage = totalEarnings > 0 ? (topComponent.value / totalEarnings) * 100 : 0
                
                newInsights.append(InsightItem(
                    title: "Top Income Component",
                    description: "\(topComponent.key) is your largest income source (\(String(format: "%.1f", percentage))%)",
                    iconName: "star.circle.fill",
                    color: FintechColors.primaryBlue,
                    detailItems: generateIncomeComponentsDetails(),
                    detailType: .incomeComponents
                ))
            }
        }
        
        insights = newInsights
    }
    
    /// Generates trends based on the payslips.
    private func generateTrends() {
        var newTrends: [TrendItem] = []
        
        // Only generate trends if we have enough data
        if payslips.count >= 3 {
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
                value: String(format: "%.1f%%", abs(incomeTrendValue))
            ))
            
            // Savings potential
            let averageIncome = payslips.map { $0.credits }.average ?? 0
            let averageDeductions = payslips.map { $0.debits }.average ?? 0
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
            if payslips.count >= 6 {
                let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
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
                        predictionIcon = "chart.line.uptrend.xyaxis"
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
    private func groupPayslipsByPeriod(_ payslips: [PayslipItem]) -> [String: [PayslipItem]] {
        var result: [String: [PayslipItem]] = [:]
        
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
    private func calculateTrend(for keyPath: KeyPath<PayslipItem, Double>) -> Double {
        // For simplified trend calculation, compare first half vs second half of current period
        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
        guard sortedPayslips.count >= 2 else { return 0 }
        
        let midPoint = sortedPayslips.count / 2
        let earlierPayslips = Array(sortedPayslips.prefix(midPoint))
        let laterPayslips = Array(sortedPayslips.suffix(sortedPayslips.count - midPoint))
        
        let earlierValue = earlierPayslips.reduce(0) { $0 + $1[keyPath: keyPath] }
        let laterValue = laterPayslips.reduce(0) { $0 + $1[keyPath: keyPath] }
        
        let avgEarlier = earlierPayslips.isEmpty ? 0 : earlierValue / Double(earlierPayslips.count)
        let avgLater = laterPayslips.isEmpty ? 0 : laterValue / Double(laterPayslips.count)
        
        return calculatePercentageChange(from: avgEarlier, to: avgLater)
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
    
    // MARK: - Helper Methods for Period-Based Filtering
    
    /// Creates a date from a payslip's month and year properties.
    ///
    /// - Parameter payslip: The payslip to create a date from.
    /// - Returns: A date representing the payslip's period.
    private func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        let calendar = Calendar.current
        let monthNumber = monthToInt(payslip.month)
        
        var components = DateComponents()
        components.year = payslip.year
        components.month = monthNumber
        components.day = 1
        
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Filtered Payslips
    
    /// The payslips filtered by the current time range.
    private var filteredPayslips: [PayslipItem] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch timeRange {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return calendar.isDate(payslipDate, equalTo: startOfMonth, toGranularity: .month) 
            }
        case .quarter:
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentQuarter = (currentMonth - 1) / 3
            let startMonth = currentQuarter * 3 + 1
            
            var components = calendar.dateComponents([.year], from: currentDate)
            components.month = startMonth
            components.day = 1
            
            let startOfQuarter = calendar.date(from: components)!
            let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter)!
            
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return payslipDate >= startOfQuarter && payslipDate < endOfQuarter 
            }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return calendar.isDate(payslipDate, equalTo: startOfYear, toGranularity: .year) 
            }
        case .all:
            return payslips
        }
    }
    
    /// The payslips from the previous period.
    private var previousPeriodPayslips: [PayslipItem] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch timeRange {
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
            let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return calendar.isDate(payslipDate, equalTo: startOfPreviousMonth, toGranularity: .month) 
            }
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
            
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return payslipDate >= startOfPreviousQuarter && payslipDate < endOfPreviousQuarter 
            }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
            let startOfPreviousYear = calendar.date(byAdding: .year, value: -1, to: startOfYear)!
            return payslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return calendar.isDate(payslipDate, equalTo: startOfPreviousYear, toGranularity: .year) 
            }
        case .all:
            return []
        }
    }
    
    // MARK: - Insight Detail Generation Methods
    
    /// Generates monthly income breakdown data
    private func generateMonthlyIncomeDetails() -> [InsightDetailItem] {
        return payslips.map { payslip in
            InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.credits,
                additionalInfo: payslip.credits == payslips.max(by: { $0.credits < $1.credits })?.credits ? "Highest month" : nil
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly tax breakdown data
    private func generateMonthlyTaxDetails() -> [InsightDetailItem] {
        return payslips.map { payslip in
            let taxRate = payslip.credits > 0 ? (payslip.tax / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.tax,
                additionalInfo: String(format: "%.1f%% of credits", taxRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly deductions breakdown data
    private func generateMonthlyDeductionsDetails() -> [InsightDetailItem] {
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
    
    /// Generates DSOP contribution breakdown data
    private func generateDSOPDetails() -> [InsightDetailItem] {
        return payslips.filter { $0.dsop > 0 }.map { payslip in
            let dsopRate = payslip.credits > 0 ? (payslip.dsop / payslip.credits) * 100 : 0
            return InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.dsop,
                additionalInfo: String(format: "%.1f%% of credits", dsopRate)
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates income components breakdown data
    private func generateIncomeComponentsDetails() -> [InsightDetailItem] {
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

// MARK: - Model Compatibility

/// Extension to adapt existing data to our new component models
extension InsightsViewModel {
    // Removed duplicate updateTimeRange function
} 