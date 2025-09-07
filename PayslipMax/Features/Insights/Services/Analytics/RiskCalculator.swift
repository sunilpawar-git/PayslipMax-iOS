//
//  RiskCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Calculator for risk management health category
class RiskCalculator: CategoryCalculatorProtocol {

    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory {
        // Calculate risk based on income concentration, volatility, and deduction patterns
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean

        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0

        // Risk score (lower is better for risk category)
        let riskScore = (volatility * FinancialHealthConstants.volatilityRiskWeight) +
                       (max(0, deductionRatio - 0.3) * FinancialHealthConstants.deductionRiskWeight)
        let healthScore = max(0, 100 - riskScore)

        let status: HealthCategory.HealthStatus
        let recommendation: String

        if healthScore > 80 {
            status = .excellent
            recommendation = "Low financial risk profile"
        } else if healthScore > 60 {
            status = .good
            recommendation = "Moderate risk, well managed"
        } else if healthScore > 40 {
            status = .fair
            recommendation = "Some risk factors need attention"
        } else {
            status = .poor
            recommendation = "High risk - needs immediate attention"
        }

        return HealthCategory(
            name: "Risk Management",
            score: healthScore,
            weight: FinancialHealthConstants.CategoryWeights.risk,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemGenerator.generateRiskActionItems(volatility: volatility, deductionRatio: deductionRatio)
        )
    }
}
