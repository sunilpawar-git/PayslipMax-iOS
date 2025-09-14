import Foundation
import SwiftUI

/// Service responsible for generating individual insights from payslip data.
/// Extracted from InsightsCoordinator to reduce complexity and improve testability.
@MainActor
class InsightGenerationService {

    // MARK: - Dependencies

    private let financialSummary: FinancialSummaryViewModel
    private let trendAnalysis: TrendAnalysisViewModel

    // MARK: - Initialization

    init(financialSummary: FinancialSummaryViewModel, trendAnalysis: TrendAnalysisViewModel) {
        self.financialSummary = financialSummary
        self.trendAnalysis = trendAnalysis
    }

    // MARK: - Public Methods

    /// Generates all insights for the given payslips.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An array of insight items.
    func generateAllInsights(for payslips: [PayslipItem]) -> [InsightItem] {
        guard !payslips.isEmpty else { return [] }

        return [
            generateIncomeGrowthInsight(for: payslips),
            generateTaxRateInsight(for: payslips),
            generateIncomeStabilityInsight(for: payslips),
            generateTopIncomeComponentInsight(for: payslips),
            generateDSOPInsight(for: payslips),
            generateSavingsRateInsight(for: payslips),
            generateDeductionPercentageInsight(for: payslips)
        ]
    }

    // MARK: - Individual Insight Generation

    /// Generates income growth insight.
    func generateIncomeGrowthInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateMonthlyIncomeDetails(from: payslips),
            detailType: .monthlyIncomes
        )
    }

    /// Generates tax rate insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for tax rate analysis.
    func generateTaxRateInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateMonthlyTaxDetails(from: payslips),
            detailType: .monthlyTaxes
        )
    }

    /// Generates income stability insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for income stability.
    func generateIncomeStabilityInsight(for payslips: [PayslipItem]) -> InsightItem {
        let stabilityDescription = trendAnalysis.incomeStabilityDescription
        let stabilityColor = trendAnalysis.incomeStabilityColor
        let stabilityAnalysis = trendAnalysis.stabilityAnalysis

        return InsightItem(
            title: "Income Stability",
            description: "\(stabilityDescription): \(stabilityAnalysis)",
            iconName: "chart.line.uptrend.xyaxis",
            color: stabilityColor,
            detailItems: InsightDetailGenerationService.generateMonthlyIncomeDetails(from: payslips),
            detailType: .incomeStabilityData
        )
    }

    /// Generates top income component insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for top income component.
    func generateTopIncomeComponentInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateIncomeComponentsDetails(from: payslips),
            detailType: .incomeComponents
        )
    }

    /// Generates DSOP contribution insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for DSOP contribution.
    func generateDSOPInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateDSOPDetails(from: payslips),
            detailType: .monthlyDSOP
        )
    }

    /// Generates savings rate insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for savings rate.
    func generateSavingsRateInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateMonthlyNetIncomeDetails(from: payslips),
            detailType: .monthlyNetIncome
        )
    }

    /// Generates deduction percentage insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for deduction percentage.
    func generateDeductionPercentageInsight(for payslips: [PayslipItem]) -> InsightItem {
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
            detailItems: InsightDetailGenerationService.generateMonthlyDeductionsDetails(from: payslips),
            detailType: .monthlyDeductions
        )
    }
}
