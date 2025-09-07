//
//  ActionItemGenerator.swift
//  PayslipMax
//
//  Created on 2025-01-09 as part of refactoring FinancialHealthAnalyzer
//

import Foundation

/// Implementation of ActionItemGeneratorProtocol for generating financial action items
class ActionItemGenerator: ActionItemGeneratorProtocol {

    func generateSavingsActionItems(currentRate: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if currentRate < 0.10 {
            items.append(ActionItem(
                title: "Create Emergency Budget",
                description: "Track expenses and identify savings opportunities",
                priority: .high,
                category: .budgeting,
                estimatedImpact: 20,
                timeframe: "1 month"
            ))

            items.append(ActionItem(
                title: "Automate Savings",
                description: "Set up automatic transfers to savings account",
                priority: .medium,
                category: .savings,
                estimatedImpact: 15,
                timeframe: "2 weeks"
            ))
        }

        return items
    }

    func generateDeductionActionItems(deductionRatio: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if deductionRatio > FinancialHealthConstants.DeductionRatioThresholds.reviewThreshold {
            items.append(ActionItem(
                title: "Review Deductions",
                description: "Analyze and optimize necessary vs. optional deductions",
                priority: .medium,
                category: .tax,
                estimatedImpact: 15,
                timeframe: "1 month"
            ))
        }

        return items
    }

    func generateGrowthActionItems(growthRate: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if growthRate < FinancialHealthConstants.GrowthRateThresholds.reviewThreshold {
            items.append(ActionItem(
                title: "Skill Development",
                description: "Invest in professional development and certifications",
                priority: .high,
                category: .career,
                estimatedImpact: 25,
                timeframe: "6 months"
            ))

            items.append(ActionItem(
                title: "Performance Review",
                description: "Schedule discussion with manager about advancement",
                priority: .medium,
                category: .career,
                estimatedImpact: 15,
                timeframe: "1 month"
            ))
        }

        return items
    }

    func generateRiskActionItems(volatility: Double, deductionRatio: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if volatility > FinancialHealthConstants.volatilityThreshold {
            items.append(ActionItem(
                title: "Stabilize Income",
                description: "Diversify income sources or seek more stable employment",
                priority: .high,
                category: .career,
                estimatedImpact: 30,
                timeframe: "6 months"
            ))
        }

        if deductionRatio > FinancialHealthConstants.DeductionRatioThresholds.reviewThreshold {
            items.append(ActionItem(
                title: "Review Deductions",
                description: "Analyze and optimize necessary vs. optional deductions",
                priority: .medium,
                category: .budgeting,
                estimatedImpact: 15,
                timeframe: "1 month"
            ))
        }

        return items
    }
}
