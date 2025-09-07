//
//  ActionItemGeneratorProtocol.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Protocol for generating action items based on financial analysis metrics
protocol ActionItemGeneratorProtocol {
    /// Generate action items for savings rate analysis
    func generateSavingsActionItems(currentRate: Double) -> [ActionItem]

    /// Generate action items for deduction ratio analysis
    func generateDeductionActionItems(deductionRatio: Double) -> [ActionItem]

    /// Generate action items for growth rate analysis
    func generateGrowthActionItems(growthRate: Double) -> [ActionItem]

    /// Generate action items for risk analysis
    func generateRiskActionItems(volatility: Double, deductionRatio: Double) -> [ActionItem]
}
