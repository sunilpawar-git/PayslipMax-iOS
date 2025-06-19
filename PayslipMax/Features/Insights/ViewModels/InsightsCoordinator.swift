import Foundation
import SwiftUI
import Combine

/// Coordinator that orchestrates all insights-related ViewModels.
/// This replaces the monolithic InsightsViewModel and follows the coordinator pattern.
@MainActor
class InsightsCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the coordinator is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: String?
    
    /// The current time range.
    @Published var timeRange: TimeRange = .year {
        didSet {
            updateTimeRange(timeRange)
        }
    }
    
    /// The current insight type.
    @Published var insightType: InsightType = .income {
        didSet {
            updateInsightType(insightType)
        }
    }
    
    /// The insights to display.
    @Published var insights: [InsightItem] = []
    
    // MARK: - Child ViewModels
    
    /// Handles financial summary calculations.
    let financialSummary: FinancialSummaryViewModel
    
    /// Handles trend analysis.
    let trendAnalysis: TrendAnalysisViewModel
    
    /// Handles chart data preparation.
    let chartData: ChartDataViewModel
    
    // MARK: - Private Properties
    
    /// The payslips to analyze.
    private var payslips: [PayslipItem] = []
    
    /// The data service to use for fetching data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Earnings-related insights (income performance and growth).
    var earningsInsights: [InsightItem] {
        return insights.filter { insight in
            return [
                "Income Growth",
                "Savings Rate", 
                "Income Stability",
                "Top Income Component"
            ].contains(insight.title)
        }
    }
    
    /// Deductions-related insights (tax, DSOP, AGIF).
    var deductionsInsights: [InsightItem] {
        return insights.filter { insight in
            return [
                "Tax Rate",
                "DSOP Contribution",
                "Deduction Percentage"
            ].contains(insight.title)
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes a new InsightsCoordinator.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        let service = dataService ?? DIContainer.shared.dataService
        self.dataService = service
        
        // Initialize child ViewModels
        self.financialSummary = FinancialSummaryViewModel(dataService: service)
        self.trendAnalysis = TrendAnalysisViewModel(dataService: service)
        self.chartData = ChartDataViewModel(dataService: service)
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the data with the specified payslips.
    ///
    /// - Parameter payslips: The payslips to analyze (should already be filtered).
    func refreshData(payslips: [PayslipItem]) {
        isLoading = true
        
        // Use the passed payslips directly (they are already filtered by the view)
        self.payslips = payslips
        
        // Update all child ViewModels
        updateChildViewModels()
        
        // Generate insights
        generateInsights()
        
        isLoading = false
    }
    
    /// Updates the time range and refreshes the data.
    ///
    /// - Parameter timeRange: The new time range.
    func updateTimeRange(_ timeRange: TimeRange) {
        chartData.updateTimeRange(timeRange)
    }
    
    /// Updates the insight type and refreshes the data.
    ///
    /// - Parameter insightType: The new insight type.
    func updateInsightType(_ insightType: InsightType) {
        chartData.updateInsightType(insightType)
    }
    
    // MARK: - Private Methods
    
    /// Sets up bindings between child ViewModels.
    private func setupBindings() {
        // Combine loading states
        Publishers.CombineLatest3(
            financialSummary.$isLoading,
            trendAnalysis.$isLoading,
            chartData.$isLoading
        )
        .map { $0 || $1 || $2 }
        .assign(to: &$isLoading)
        
        // Combine error states
        Publishers.CombineLatest3(
            financialSummary.$error,
            trendAnalysis.$error,
            chartData.$error
        )
        .map { error1, error2, error3 in
            error1 ?? error2 ?? error3
        }
        .assign(to: &$error)
    }
    
    /// Updates all child ViewModels with current payslips data.
    private func updateChildViewModels() {
        financialSummary.updatePayslips(payslips)
        trendAnalysis.updatePayslips(payslips)
        chartData.updatePayslips(payslips)
    }
    
    /// Generates insights based on the payslips data.
    private func generateInsights() {
        var newInsights: [InsightItem] = []
        
        guard !payslips.isEmpty else {
            insights = []
            return
        }
        
        // Key Insight #1: Income Growth
        let incomeGrowthInsight = generateIncomeGrowthInsight()
        newInsights.append(incomeGrowthInsight)
        
        // Key Insight #2: Tax Rate Analysis
        let taxRateInsight = generateTaxRateInsight()
        newInsights.append(taxRateInsight)
        
        // Key Insight #3: Income Stability
        let stabilityInsight = generateIncomeStabilityInsight()
        newInsights.append(stabilityInsight)
        
        // Key Insight #4: Top Income Component
        let topIncomeInsight = generateTopIncomeComponentInsight()
        newInsights.append(topIncomeInsight)
        
        // Key Insight #5: DSOP Contribution Analysis
        let dsopInsight = generateDSOPInsight()
        newInsights.append(dsopInsight)
        
        // Key Insight #6: Savings Rate
        let savingsInsight = generateSavingsRateInsight()
        newInsights.append(savingsInsight)
        
        // Key Insight #7: Deduction Percentage Analysis
        let deductionInsight = generateDeductionPercentageInsight()
        newInsights.append(deductionInsight)
        
        insights = newInsights
    }
    
    /// Generates income growth insight.
    ///
    /// - Returns: An insight item for income growth.
    private func generateIncomeGrowthInsight() -> InsightItem {
        guard payslips.count >= 2 else {
            return InsightItem(
                title: "Income Growth",
                description: "Upload more payslips to analyze income growth trends.",
                iconName: "chart.line.uptrend.xyaxis",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyIncomes
            )
        }
        
        let growthTrend = financialSummary.incomeTrend
        
        let description: String
        let iconColor: Color
        
        if growthTrend > 5 {
            description = String(format: "Your income is growing by %.1f%%. Great job!", growthTrend)
            iconColor = FintechColors.successGreen
        } else if growthTrend > -5 {
            description = "Your income is relatively stable with minor fluctuations."
            iconColor = FintechColors.primaryBlue
        } else {
            description = String(format: "Your income shows a declining trend of %.1f%%. Consider reviewing your compensation.", abs(growthTrend))
            iconColor = FintechColors.dangerRed
        }
        
        return InsightItem(
            title: "Income Growth",
            description: description,
            iconName: "arrow.up.right.circle.fill",
            color: iconColor,
            detailItems: generateMonthlyIncomeDetails(),
            detailType: .monthlyIncomes
        )
    }
    
    /// Generates tax rate insight.
    ///
    /// - Returns: An insight item for tax rate analysis.
    private func generateTaxRateInsight() -> InsightItem {
        let totalIncome = financialSummary.totalIncome
        let totalTax = financialSummary.totalTax
        
        guard totalIncome > 0 else {
            return InsightItem(
                title: "Tax Rate",
                description: "Unable to calculate tax rate.",
                iconName: "percent",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyTaxes
            )
        }
        
        let taxRate = (totalTax / totalIncome) * 100
        
        let description = String(format: "Your effective tax rate is %.1f%% of income. This helps understand your take-home pay efficiency.", taxRate)
        let iconColor: Color
        
        if taxRate < 10 {
            iconColor = FintechColors.successGreen
        } else if taxRate < 20 {
            iconColor = FintechColors.primaryBlue
        } else {
            iconColor = FintechColors.warningAmber
        }
        
        return InsightItem(
            title: "Tax Rate",
            description: description,
            iconName: "percent",
            color: iconColor,
            detailItems: generateMonthlyTaxDetails(),
            detailType: .monthlyTaxes
        )
    }
    
    /// Generates income stability insight.
    ///
    /// - Returns: An insight item for income stability.
    private func generateIncomeStabilityInsight() -> InsightItem {
        let stabilityDescription = trendAnalysis.incomeStabilityDescription
        let stabilityColor = trendAnalysis.incomeStabilityColor
        let stabilityAnalysis = trendAnalysis.stabilityAnalysis
        
        return InsightItem(
            title: "Income Stability",
            description: "\(stabilityDescription): \(stabilityAnalysis)",
            iconName: "chart.line.uptrend.xyaxis",
            color: stabilityColor,
            detailItems: generateMonthlyIncomeDetails(),
            detailType: .incomeStabilityData
        )
    }
    
    /// Generates top income component insight.
    ///
    /// - Returns: An insight item for top income component.
    private func generateTopIncomeComponentInsight() -> InsightItem {
        let topEarnings = financialSummary.topEarnings
        
        guard let topComponent = topEarnings.first else {
            return InsightItem(
                title: "Top Income Component",
                description: "Unable to identify top income component.",
                iconName: "chart.pie",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .incomeComponents
            )
        }
        
        return InsightItem(
            title: "Top Income Component",
            description: String(format: "%.1f%% of your total income comes from %@.", 
                                topComponent.percentage, topComponent.category),
            iconName: "chart.pie.fill",
            color: FintechColors.primaryBlue,
            detailItems: generateIncomeComponentsDetails(),
            detailType: .incomeComponents
        )
    }
    
    /// Generates DSOP contribution insight.
    ///
    /// - Returns: An insight item for DSOP contribution.
    private func generateDSOPInsight() -> InsightItem {
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        let totalIncome = financialSummary.totalIncome
        
        guard totalIncome > 0 else {
            return InsightItem(
                title: "DSOP Contribution",
                description: "Unable to calculate DSOP contribution rate.",
                iconName: "building.columns",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyDSOP
            )
        }
        
        let dsopRate = (totalDSOP / totalIncome) * 100
        
        let description = totalDSOP > 0 ? 
            String(format: "Your DSOP contributions (%.1f%% of income) are excellent for wealth building and long-term financial security.", dsopRate) :
            "No DSOP contributions found in your payslips."
        
        return InsightItem(
            title: "DSOP Contribution",
            description: description,
            iconName: "building.columns.fill",
            color: totalDSOP > 0 ? FintechColors.successGreen : FintechColors.textSecondary,
            detailItems: generateDSOPDetails(),
            detailType: .monthlyDSOP
        )
    }
    
    /// Generates savings rate insight.
    ///
    /// - Returns: An insight item for savings rate.
    private func generateSavingsRateInsight() -> InsightItem {
        let totalIncome = financialSummary.totalIncome
        let netIncome = financialSummary.netIncome
        
        guard totalIncome > 0 else {
            return InsightItem(
                title: "Savings Rate",
                description: "Unable to calculate savings rate.",
                iconName: "dollarsign.circle",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyNetIncome
            )
        }
        
        let savingsRate = (netIncome / totalIncome) * 100
        
        let description: String
        let iconColor: Color
        
        if savingsRate > 30 {
            description = String(format: "Excellent! You're saving %.1f%% of your income.", savingsRate)
            iconColor = FintechColors.successGreen
        } else if savingsRate > 15 {
            description = String(format: "Good savings rate of %.1f%%. Consider optimizing further.", savingsRate)
            iconColor = FintechColors.primaryBlue
        } else {
            description = String(format: "Savings rate is %.1f%%. Consider reviewing expenses to increase savings.", savingsRate)
            iconColor = FintechColors.warningAmber
        }
        
        return InsightItem(
            title: "Savings Rate",
            description: description,
            iconName: "dollarsign.circle.fill",
            color: iconColor,
            detailItems: generateMonthlyNetIncomeDetails(),
            detailType: .monthlyNetIncome
        )
    }
    
    /// Generates deduction percentage insight.
    ///
    /// - Returns: An insight item for deduction percentage.
    private func generateDeductionPercentageInsight() -> InsightItem {
        let totalIncome = financialSummary.totalIncome
        let totalDeductions = financialSummary.totalDeductions
        
        guard totalIncome > 0 else {
            return InsightItem(
                title: "Deduction Percentage",
                description: "Unable to calculate deduction percentage.",
                iconName: "minus.circle",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyDeductions
            )
        }
        
        let deductionPercentage = (totalDeductions / totalIncome) * 100
        
        let description: String
        let iconColor: Color
        
        if deductionPercentage < 20 {
            description = String(format: "Very efficient deduction rate of %.1f%% - you're keeping most of your income.", deductionPercentage)
            iconColor = FintechColors.successGreen
        } else if deductionPercentage < 30 {
            description = String(format: "Deductions are %.1f%% of gross pay - reasonable range for most professionals.", deductionPercentage)
            iconColor = FintechColors.primaryBlue
        } else if deductionPercentage < 40 {
            description = String(format: "Deductions are %.1f%% of gross pay. Consider tax optimization strategies like 80C investments, NPS contributions, or ELSS funds.", deductionPercentage)
            iconColor = FintechColors.warningAmber
        } else {
            description = String(format: "High deduction percentage of %.1f%% - strongly recommend reviewing tax-saving options and investment strategies.", deductionPercentage)
            iconColor = FintechColors.dangerRed
        }
        
        return InsightItem(
            title: "Deduction Percentage",
            description: description,
            iconName: "minus.circle.fill",
            color: iconColor,
            detailItems: generateMonthlyDeductionsDetails(),
            detailType: .monthlyDeductions
        )
    }
    
    // MARK: - Detail Generation Methods
    
    /// Generates monthly income breakdown data.
    private func generateMonthlyIncomeDetails() -> [InsightDetailItem] {
        return payslips.map { payslip in
            InsightDetailItem(
                period: "\(payslip.month) \(payslip.year)",
                value: payslip.credits,
                additionalInfo: payslip.credits == payslips.max(by: { $0.credits < $1.credits })?.credits ? "Highest month" : nil
            )
        }.sorted { $0.value > $1.value }
    }
    
    /// Generates monthly tax breakdown data.
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
    
    /// Generates monthly deductions breakdown data.
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
    
    /// Generates monthly net income breakdown data.
    private func generateMonthlyNetIncomeDetails() -> [InsightDetailItem] {
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
    
    /// Generates income components breakdown data.
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