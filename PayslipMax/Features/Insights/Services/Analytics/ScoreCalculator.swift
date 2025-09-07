//
//  ScoreCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Implementation of ScoreCalculatorProtocol for calculating financial health scores
class ScoreCalculator: ScoreCalculatorProtocol {

    func calculateOverallScore(categories: [HealthCategory]) async -> Double {
        let weightedScore = categories.reduce(0) { $0 + ($1.score * $1.weight) }
        return min(100, max(0, weightedScore))
    }

    func calculateScoreTrend(payslips: [PayslipItem]) async -> FinancialHealthScore.ScoreTrend {
        guard payslips.count >= FinancialHealthConstants.monthsForTrendAnalysis else {
            return .stable
        }

        let recent3Months = Array(payslips.prefix(3))
        let previous3Months = Array(payslips.dropFirst(3).prefix(3))

        let recentAvgIncome = recent3Months.reduce(0) { $0 + $1.credits } / 3
        let previousAvgIncome = previous3Months.reduce(0) { $0 + $1.credits } / 3

        let change = previousAvgIncome > 0 ? (recentAvgIncome - previousAvgIncome) / previousAvgIncome : 0

        if change > FinancialHealthConstants.trendChangeThreshold {
            return .improving(change * 100)
        } else if change < -FinancialHealthConstants.trendChangeThreshold {
            return .declining(abs(change) * 100)
        } else {
            return .stable
        }
    }
}
