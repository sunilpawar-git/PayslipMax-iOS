//
//  CategoryCalculatorProtocol.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Protocol for calculating individual health categories in financial analysis
protocol CategoryCalculatorProtocol {
    /// Calculate a specific health category for the given payslips
    /// - Parameters:
    ///   - payslips: Array of payslip items to analyze
    ///   - actionItemGenerator: Generator for creating action items based on analysis
    /// - Returns: Calculated health category
    func calculateCategory(payslips: [PayslipItem], actionItemGenerator: ActionItemGeneratorProtocol) async -> HealthCategory
}
