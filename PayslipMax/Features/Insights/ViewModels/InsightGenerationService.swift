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
    func generateAllInsights(for payslips: [PayslipDTO]) -> [InsightItem] {
        guard !payslips.isEmpty else { return [] }

        return [
            generateIncomeGrowthInsight(for: payslips),
            generateTaxRateInsight(for: payslips),
            generateTopIncomeComponentInsight(for: payslips),
            generateDSOPInsight(for: payslips),
            generateSavingsRateInsight(for: payslips),
            generateDeductionPercentageInsight(for: payslips)
        ]
    }

    // MARK: - Individual Insight Generation

    /// Generates income growth insight.
    func generateIncomeGrowthInsight(for payslips: [PayslipDTO]) -> InsightItem {
        guard payslips.count >= 2 else {
            return InsightItem(
                title: "Earnings Growth",
                description: "Upload more payslips to analyze earnings growth trends.",
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
            description = String(format: "Your earnings are growing by %.1f%%. Great job!", growthTrend)
            iconColor = FintechColors.successGreen
        } else if growthTrend > -5 {
            description = "Your earnings are relatively stable with minor fluctuations."
            iconColor = FintechColors.primaryBlue
        } else {
            description = String(format: "Your earnings show a declining trend of %.1f%%. Consider reviewing your compensation.", abs(growthTrend))
            iconColor = FintechColors.dangerRed
        }

        return InsightItem(
            title: "Earnings Growth",
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
    func generateTaxRateInsight(for payslips: [PayslipDTO]) -> InsightItem {
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

    /// Generates top income component insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for top income component.
    func generateTopIncomeComponentInsight(for payslips: [PayslipDTO]) -> InsightItem {
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
    func generateDSOPInsight(for payslips: [PayslipDTO]) -> InsightItem {
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

    /// Generates net remittance rate insight.
    ///
    /// - Parameter payslips: The payslips to analyze.
    /// - Returns: An insight item for net remittance rate.
    func generateSavingsRateInsight(for payslips: [PayslipDTO]) -> InsightItem {
        let totalIncome = financialSummary.totalIncome
        let netIncome = financialSummary.netIncome

        guard totalIncome > 0 else {
            return InsightItem(
                title: "Net Remittance Rate",
                description: "Unable to calculate net remittance rate.",
                iconName: "dollarsign.circle",
                color: FintechColors.textSecondary,
                detailItems: [],
                detailType: .monthlyNetIncome
            )
        }

        let remittanceRate = (netIncome / totalIncome) * 100

        let description: String
        let iconColor: Color

        if remittanceRate > 30 {
            description = String(format: "Excellent net remittance: %.1f%% of income.", remittanceRate)
            iconColor = FintechColors.successGreen
        } else if remittanceRate > 15 {
            description = String(format: "Healthy net remittance: %.1f%% of income.", remittanceRate)
            iconColor = FintechColors.primaryBlue
        } else {
            description = String(format: "Net remittance is %.1f%% of income. Review deductions to improve take-home.", remittanceRate)
            iconColor = FintechColors.warningAmber
        }

        return InsightItem(
            title: "Net Remittance Rate",
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
    func generateDeductionPercentageInsight(for payslips: [PayslipDTO]) -> InsightItem {
        let totalIncome = financialSummary.totalIncome
        let totalDeductions = financialSummary.totalDeductions

        guard totalIncome > 0 else {
            return InsightItem(
                title: "Deductions",
                description: "Unable to calculate deductions share.",
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
            description = String(format: "Very efficient deductions: %.1f%% of earnings.", deductionPercentage)
            iconColor = FintechColors.successGreen
        } else if deductionPercentage < 30 {
            description = String(format: "Deductions are %.1f%% of earnings - reasonable range.", deductionPercentage)
            iconColor = FintechColors.primaryBlue
        } else if deductionPercentage < 40 {
            description = String(format: "Deductions are %.1f%% of earnings. Consider tax optimization (80C, NPS, ELSS).", deductionPercentage)
            iconColor = FintechColors.warningAmber
        } else {
            description = String(format: "High deductions at %.1f%% of earnings — review tax-saving options.", deductionPercentage)
            iconColor = FintechColors.dangerRed
        }

        return InsightItem(
            title: "Deductions",
            description: description,
            iconName: "minus.circle.fill",
            color: iconColor,
            detailItems: InsightDetailGenerationService.generateMonthlyDeductionsDetails(from: payslips),
            detailType: .monthlyDeductions
        )
    }
}
