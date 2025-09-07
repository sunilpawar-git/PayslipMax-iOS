import Foundation
import SwiftUI

@MainActor
class FinancialHealthAnalyzer {

    // MARK: - Dependencies
    private let categoryCalculators: [any CategoryCalculatorProtocol]
    private let scoreCalculator: ScoreCalculatorProtocol
    private let actionItemGenerator: ActionItemGeneratorProtocol

    // MARK: - Initialization

    init(
        categoryCalculators: [any CategoryCalculatorProtocol]? = nil,
        scoreCalculator: ScoreCalculatorProtocol? = nil,
        actionItemGenerator: ActionItemGeneratorProtocol? = nil
    ) {
        // Use provided dependencies or create defaults
        self.categoryCalculators = categoryCalculators ?? [
            IncomeStabilityCalculator(),
            SavingsCalculator(),
            DeductionCalculator(),
            GrowthCalculator(),
            RiskCalculator()
        ]
        self.scoreCalculator = scoreCalculator ?? ScoreCalculator()
        self.actionItemGenerator = actionItemGenerator ?? ActionItemGenerator()
    }

    // MARK: - Public Methods

    func calculateFinancialHealthScore(payslips: [PayslipItem]) async -> FinancialHealthScore {
        guard payslips.count >= FinancialHealthConstants.minimumDataPointsForAnalysis else {
            return createInsufficientDataScore()
        }

        let recentPayslips = Array(payslips.prefix(FinancialHealthConstants.monthsForRecentAnalysis))

        let categories = await calculateHealthCategories(payslips: recentPayslips)
        let overallScore = await scoreCalculator.calculateOverallScore(categories: categories)
        let trend = await scoreCalculator.calculateScoreTrend(payslips: payslips)

        return FinancialHealthScore(
            overallScore: overallScore,
            categories: categories,
            trend: trend,
            lastUpdated: Date()
        )
    }

    // MARK: - Private Methods

    private func createInsufficientDataScore() -> FinancialHealthScore {
        return FinancialHealthScore(
            overallScore: 50,
            categories: [],
            trend: .stable,
            lastUpdated: Date()
        )
    }

    private func calculateHealthCategories(payslips: [PayslipItem]) async -> [HealthCategory] {
        await withTaskGroup(of: HealthCategory.self) { group in
            for calculator in categoryCalculators {
                group.addTask {
                    await calculator.calculateCategory(payslips: payslips, actionItemGenerator: self.actionItemGenerator)
                }
            }

            var results: [HealthCategory] = []
            for await category in group {
                results.append(category)
            }
            return results
        }
    }
}
