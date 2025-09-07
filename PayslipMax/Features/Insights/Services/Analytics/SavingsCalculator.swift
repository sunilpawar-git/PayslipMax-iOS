//
//  SavingsCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Calculator for savings rate health category
class SavingsCalculator: CategoryCalculatorProtocol {

    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions

        // Estimate savings rate (assuming 70% of net income goes to expenses)
        let estimatedSavings = max(0, netIncome * 0.30)
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0

        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String

        if savingsRate >= FinancialHealthConstants.excellentSavingsRate {
            score = 95
            status = .excellent
            recommendation = "Excellent savings rate! You're on track for early retirement."
        } else if savingsRate >= FinancialHealthConstants.goodSavingsRate {
            score = 80
            status = .good
            recommendation = "Good savings rate. Consider increasing to 30% for optimal growth."
        } else if savingsRate >= 0.10 {
            score = 60
            status = .fair
            recommendation = "Average savings rate. Aim to save at least 20% of income."
        } else {
            score = 30
            status = .poor
            recommendation = "Low savings rate. Focus on budgeting and expense reduction."
        }

        return HealthCategory(
            name: "Savings Rate",
            score: score,
            weight: FinancialHealthConstants.CategoryWeights.savings,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemGenerator.generateSavingsActionItems(currentRate: savingsRate)
        )
    }
}
