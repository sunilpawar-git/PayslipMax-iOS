//
//  FinancialHealthConstants.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Constants used throughout the financial health analysis system
enum FinancialHealthConstants {
    // Analysis thresholds
    static let minimumDataPointsForAnalysis = 3
    static let minimumDataPointsForGrowthAnalysis = 6
    static let volatilityThreshold = 0.15
    static let goodSavingsRate = 0.20
    static let excellentSavingsRate = 0.30
    static let averageIncomeTaxRate = 0.20
    static let healthyDeductionRatio = 0.25

    // Risk calculation weights
    static let volatilityRiskWeight = 50.0
    static let deductionRiskWeight = 100.0

    // Trend analysis
    static let trendChangeThreshold = 0.05
    static let monthsForRecentAnalysis = 12
    static let monthsForTrendAnalysis = 6

    // Category weights
    enum CategoryWeights {
        static let incomeStability = 0.25
        static let savings = 0.30
        static let deductions = 0.20
        static let growth = 0.15
        static let risk = 0.10
    }

    // Volatility thresholds for income stability
    enum VolatilityThresholds {
        static let excellent = 0.10
        static let fair = 0.20
    }

    // Deduction ratio thresholds
    enum DeductionRatioThresholds {
        static let excellent: Double = 0.20
        static let good: Double = 0.30
        static let fair: Double = 0.40
        static let reviewThreshold: Double = 0.35
    }

    // Growth rate thresholds
    enum GrowthRateThresholds {
        static let excellent = 0.10
        static let good = 0.05
        static let poor: Double = 0.0
        static let reviewThreshold = 0.03
    }
}
