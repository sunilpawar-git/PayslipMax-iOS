//
//  DeductionCalculator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Calculator for deduction efficiency health category
class DeductionCalculator: CategoryCalculatorProtocol {

    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        // ✅ FIXED: Use correct calculation from FinancialCalculationUtility
        let totalDeductions = payslips.reduce(0) { $0 + FinancialCalculationUtility.shared.calculateTotalDeductions(for: $1) }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0

        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String

        if deductionRatio <= FinancialHealthConstants.DeductionRatioThresholds.excellent {
            score = 95
            status = .excellent
            recommendation = "Very efficient deduction management"
        } else if deductionRatio <= FinancialHealthConstants.DeductionRatioThresholds.good {
            score = 80
            status = .good
            recommendation = "Good deduction balance"
        } else if deductionRatio <= FinancialHealthConstants.DeductionRatioThresholds.fair {
            score = 60
            status = .fair
            recommendation = "Consider optimizing deductions"
        } else {
            score = 30
            status = .poor
            recommendation = "High deduction ratio needs review"
        }

        return HealthCategory(
            name: "Deduction Efficiency",
            score: score,
            weight: FinancialHealthConstants.CategoryWeights.deductions,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemGenerator.generateDeductionActionItems(deductionRatio: deductionRatio)
        )
    }
}
