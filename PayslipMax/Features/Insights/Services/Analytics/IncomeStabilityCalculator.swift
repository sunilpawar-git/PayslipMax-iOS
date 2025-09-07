//
//  IncomeStabilityCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Calculator for income stability health category
class IncomeStabilityCalculator: CategoryCalculatorProtocol {

    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory {
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean

        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        let actionItems: [ActionItem]

        if volatility < FinancialHealthConstants.VolatilityThresholds.excellent {
            score = 95
            status = .excellent
            recommendation = "Your income is very stable"
            actionItems = []
        } else if volatility < FinancialHealthConstants.volatilityThreshold {
            score = 80
            status = .good
            recommendation = "Your income has good stability"
            actionItems = [
                ActionItem(title: "Maintain Consistency", description: "Continue current income strategies", priority: .low, category: .career, estimatedImpact: 5, timeframe: "Ongoing")
            ]
        } else if volatility < FinancialHealthConstants.VolatilityThresholds.fair {
            score = 60
            status = .fair
            recommendation = "Your income has moderate fluctuations"
            actionItems = [
                ActionItem(title: "Diversify Income", description: "Consider additional income streams", priority: .high, category: .career, estimatedImpact: 15, timeframe: "6-12 months"),
                ActionItem(title: "Increase Emergency Fund", description: "Build 8-12 months of expenses", priority: .high, category: .savings, estimatedImpact: 20, timeframe: "12 months")
            ]
        } else {
            score = 30
            status = .poor
            recommendation = "Your income shows high volatility"
            actionItems = [
                ActionItem(title: "Seek Stable Employment", description: "Look for more stable income sources", priority: .high, category: .career, estimatedImpact: 30, timeframe: "3-6 months"),
                ActionItem(title: "Build Large Emergency Fund", description: "Maintain 12+ months of expenses", priority: .high, category: .savings, estimatedImpact: 25, timeframe: "18 months")
            ]
        }

        return HealthCategory(
            name: "Income Stability",
            score: score,
            weight: FinancialHealthConstants.CategoryWeights.incomeStability,
            status: status,
            recommendation: recommendation,
            actionItems: actionItems
        )
    }
}
