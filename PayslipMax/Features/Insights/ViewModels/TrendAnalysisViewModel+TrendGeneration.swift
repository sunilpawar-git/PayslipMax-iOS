import Foundation
import SwiftUI

// MARK: - Trend Generation

extension TrendAnalysisViewModel {

    /// Generates trends based on the payslips.
    func generateTrends() {
        var newTrends: [TrendItem] = []

        guard !payslips.isEmpty else {
            trends = []
            return
        }

        newTrends.append(calculateGrowthTrend())
        newTrends.append(calculateStabilityTrend())
        newTrends.append(calculateSavingsTrend())

        if hasProjectionData() {
            newTrends.append(calculateProjectionTrend())
        }

        trends = newTrends
    }

    /// Calculates income growth trend.
    func calculateGrowthTrend() -> TrendItem {
        guard payslips.count >= 2 else {
            return TrendItem(
                title: "Earnings Growth",
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
            title: "Earnings Growth",
            description: trendDescription,
            iconName: trendIcon,
            color: trendColor,
            value: String(format: "%.1f%% change", incomeTrend)
        )
    }

    /// Calculates income stability trend.
    func calculateStabilityTrend() -> TrendItem {
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
    func calculateSavingsTrend() -> TrendItem {
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
    func calculateProjectionTrend() -> TrendItem {
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
    func hasProjectionData() -> Bool {
        return payslips.count >= 6
    }
}
