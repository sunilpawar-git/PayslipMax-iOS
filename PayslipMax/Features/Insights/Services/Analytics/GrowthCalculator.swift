//
//  GrowthCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Calculator for income growth health category
class GrowthCalculator: CategoryCalculatorProtocol {

    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory {
        guard payslips.count >= FinancialHealthConstants.minimumDataPointsForGrowthAnalysis else {
            return HealthCategory(
                name: "Income Growth",
                score: 50,
                weight: FinancialHealthConstants.CategoryWeights.growth,
                status: .fair,
                recommendation: "Need more data for growth analysis",
                actionItems: []
            )
        }

        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))

        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage :
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)

        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0

        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String

        if growthRate > FinancialHealthConstants.GrowthRateThresholds.excellent {
            score = 95
            status = .excellent
            recommendation = "Exceptional income growth!"
        } else if growthRate > FinancialHealthConstants.GrowthRateThresholds.good {
            score = 80
            status = .good
            recommendation = "Strong income growth trend"
        } else if growthRate > FinancialHealthConstants.GrowthRateThresholds.poor {
            score = 60
            status = .fair
            recommendation = "Modest growth, consider career advancement"
        } else {
            score = 30
            status = .poor
            recommendation = "Declining income - focus on skill development"
        }

        return HealthCategory(
            name: "Income Growth",
            score: score,
            weight: FinancialHealthConstants.CategoryWeights.growth,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemGenerator.generateGrowthActionItems(growthRate: growthRate)
        )
    }
}
