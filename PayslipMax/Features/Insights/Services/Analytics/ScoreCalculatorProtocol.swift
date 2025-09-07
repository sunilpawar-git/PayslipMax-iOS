//
//  ScoreCalculatorProtocol.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Protocol for calculating overall scores and trends in financial analysis
protocol ScoreCalculatorProtocol {
    /// Calculate overall financial health score from category scores
    func calculateOverallScore(categories: [HealthCategory]) async -> Double

    /// Calculate trend based on payslip data
    func calculateScoreTrend(payslips: [PayslipItem]) async -> FinancialHealthScore.ScoreTrend
}
