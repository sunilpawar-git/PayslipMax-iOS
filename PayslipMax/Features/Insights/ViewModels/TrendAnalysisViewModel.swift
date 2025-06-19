import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for trend analysis and income stability calculations.
/// Extracted from InsightsViewModel to follow single responsibility principle.
@MainActor
class TrendAnalysisViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: String?
    
    /// The trends to display.
    @Published var trends: [TrendItem] = []
    
    // MARK: - Private Properties
    
    /// The payslips to analyze.
    private var payslips: [PayslipItem] = []
    
    /// The data service to use for fetching data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Initialization
    
    /// Initializes a new TrendAnalysisViewModel.
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
        generateTrends()
    }
    
    // MARK: - Private Methods
    
    /// Generates trends based on the payslips.
    private func generateTrends() {
        var newTrends: [TrendItem] = []
        
        guard !payslips.isEmpty else {
            trends = []
            return
        }
        
        // Income growth trend
        let growthTrend = calculateGrowthTrend()
        newTrends.append(growthTrend)
        
        // Income stability trend
        let stabilityTrend = calculateStabilityTrend()
        newTrends.append(stabilityTrend)
        
        // Savings potential trend
        let savingsTrend = calculateSavingsTrend()
        newTrends.append(savingsTrend)
        
        // Future projection trend
        if hasProjectionData() {
            let projectionTrend = calculateProjectionTrend()
            newTrends.append(projectionTrend)
        }
        
        trends = newTrends
    }
    
    /// Calculates income growth trend.
    ///
    /// - Returns: A trend item representing income growth.
    private func calculateGrowthTrend() -> TrendItem {
        guard payslips.count >= 2 else {
            return TrendItem(
                title: "Income Growth",
                description: "Need more data to analyze growth",
                iconName: "chart.line.flattrend.xyaxis",
                color: FintechColors.textSecondary,
                value: nil
            )
        }
        
        let incomeTrend = FinancialCalculationUtility.shared.calculateIncomeTrend(
            for: payslips.sorted { $0.timestamp < $1.timestamp }
        )
        
        let trendDescription: String
        let trendIcon: String
        let trendColor: Color
        
        if incomeTrend > 5 {
            trendDescription = "Your income is growing positively"
            trendIcon = "arrow.up.right.circle.fill"
            trendColor = FintechColors.successGreen
        } else if incomeTrend > -5 {
            trendDescription = "Your income is relatively stable"
            trendIcon = "minus.circle.fill"
            trendColor = FintechColors.primaryBlue
        } else {
            trendDescription = "Your income has been declining"
            trendIcon = "arrow.down.right.circle.fill"
            trendColor = FintechColors.dangerRed
        }
        
        return TrendItem(
            title: "Income Growth",
            description: trendDescription,
            iconName: trendIcon,
            color: trendColor,
            value: String(format: "%.1f%% change", incomeTrend)
        )
    }
    
    /// Calculates income stability trend.
    ///
    /// - Returns: A trend item representing income stability.
    private func calculateStabilityTrend() -> TrendItem {
        let stabilityDescription = incomeStabilityDescription
        let stabilityColor = incomeStabilityColor
        
        let stabilityIcon: String
        switch stabilityDescription {
        case "Very Stable":
            stabilityIcon = "checkmark.seal.fill"
        case "Moderately Stable":
            stabilityIcon = "chart.line.uptrend.xyaxis"
        case "Variable":
            stabilityIcon = "waveform.path.ecg"
        default:
            stabilityIcon = "questionmark.circle"
        }
        
        return TrendItem(
            title: "Income Stability",
            description: stabilityAnalysis,
            iconName: stabilityIcon,
            color: stabilityColor,
            value: stabilityDescription
        )
    }
    
    /// Calculates savings potential trend.
    ///
    /// - Returns: A trend item representing savings potential.
    private func calculateSavingsTrend() -> TrendItem {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { result, payslip in
            result + FinancialCalculationUtility.shared.calculateTotalDeductions(for: payslip)
        }
        let netAmount = totalIncome - totalDeductions
        
        let savingsRatio = totalIncome > 0 ? netAmount / totalIncome : 0
        
        let savingsDescription: String
        let savingsIcon: String
        let savingsColor: Color
        
        if savingsRatio > 0.3 {
            savingsDescription = "You're saving a significant portion of your income"
            savingsIcon = "star.fill"
            savingsColor = FintechColors.successGreen
        } else if savingsRatio > 0.15 {
            savingsDescription = "You're saving a moderate portion of your income"
            savingsIcon = "star.leadinghalf.filled"
            savingsColor = FintechColors.primaryBlue
        } else if savingsRatio > 0 {
            savingsDescription = "You're saving a small portion of your income"
            savingsIcon = "star"
            savingsColor = FintechColors.warningAmber
        } else {
            savingsDescription = "Your expenses exceed your income"
            savingsIcon = "exclamationmark.circle"
            savingsColor = FintechColors.dangerRed
        }
        
        return TrendItem(
            title: "Savings Potential",
            description: savingsDescription,
            iconName: savingsIcon,
            color: savingsColor,
            value: String(format: "%.1f%% of income", savingsRatio * 100)
        )
    }
    
    /// Calculates future income projection trend.
    ///
    /// - Returns: A trend item representing future income projection.
    private func calculateProjectionTrend() -> TrendItem {
        let averageIncome = payslips.map { $0.credits }.average ?? 0
        let growthRate = FinancialCalculationUtility.shared.calculateIncomeTrend(
            for: payslips.sorted { $0.timestamp < $1.timestamp }
        )
        
        let projectedIncome = averageIncome * (1 + growthRate / 100)
        
        let projectionDescription: String
        let projectionColor: Color
        
        if growthRate > 0 {
            projectionDescription = "Based on current trends, your income is projected to grow"
            projectionColor = FintechColors.successGreen
        } else if growthRate == 0 {
            projectionDescription = "Your income is projected to remain stable"
            projectionColor = FintechColors.primaryBlue
        } else {
            projectionDescription = "Based on current trends, your income may decline"
            projectionColor = FintechColors.warningAmber
        }
        
        return TrendItem(
            title: "Future Income Projection",
            description: projectionDescription,
            iconName: "crystal.ball",
            color: projectionColor,
            value: "₹\(String(format: "%.0f", projectedIncome)) avg monthly"
        )
    }
    
    /// Checks if there's enough data for projections.
    ///
    /// - Returns: True if projection data is available.
    private func hasProjectionData() -> Bool {
        return payslips.count >= 6
    }
}

// MARK: - Supporting Extensions

// Array extensions available via FinancialSummaryViewModel 