import Foundation
import SwiftUI

/// Generates specific action items for financial health categories
class HealthCategoryActionItemsGenerator: ObservableObject {

    // MARK: - Action Items Generation

    func generateSavingsActionItems(currentRate: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if currentRate < 0.10 {
            items.append(ActionItem(
                title: "Create Budget Plan",
                description: "Track expenses and identify areas to cut spending",
                priority: .high,
                category: .budgeting,
                estimatedImpact: 15,
                timeframe: "1 month"
            ))
        }

        if currentRate < 0.20 {
            items.append(ActionItem(
                title: "Automate Savings",
                description: "Set up automatic transfers to savings account",
                priority: .medium,
                category: .savings,
                estimatedImpact: 10,
                timeframe: "1 week"
            ))
        }

        return items
    }

    func generateTaxActionItems(effectiveRate: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if effectiveRate > 0.25 {
            items.append(ActionItem(
                title: "Tax Planning Review",
                description: "Consult with tax professional for optimization strategies",
                priority: .high,
                category: .tax,
                estimatedImpact: 20,
                timeframe: "1 month"
            ))
        }

        items.append(ActionItem(
            title: "Maximize Deductions",
            description: "Ensure all eligible deductions are claimed",
            priority: .medium,
            category: .tax,
            estimatedImpact: 10,
            timeframe: "Next tax season"
        ))

        return items
    }

    func generateGrowthActionItems(growthRate: Double) -> [ActionItem] {
        var items: [ActionItem] = []

        if growthRate < 0.03 {
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

        if volatility > 0.15 {
            items.append(ActionItem(
                title: "Stabilize Income",
                description: "Diversify income sources or seek more stable employment",
                priority: .high,
                category: .career,
                estimatedImpact: 30,
                timeframe: "6 months"
            ))
        }

        if deductionRatio > 0.35 {
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

    func generateIncomeStabilityActionItems(volatility: Double) -> [ActionItem] {
        if volatility < 0.05 {
            return [
                ActionItem(
                    title: "Invest in Growth",
                    description: "Consider higher-risk investments for better returns",
                    priority: .medium,
                    category: .investments,
                    estimatedImpact: 5,
                    timeframe: "6-12 months"
                )
            ]
        } else if volatility < 0.10 {
            return [
                ActionItem(
                    title: "Build Emergency Fund",
                    description: "Maintain 6 months of expenses",
                    priority: .medium,
                    category: .savings,
                    estimatedImpact: 10,
                    timeframe: "3-6 months"
                )
            ]
        } else if volatility < 0.20 {
            return [
                ActionItem(
                    title: "Diversify Income",
                    description: "Consider additional income streams",
                    priority: .high,
                    category: .career,
                    estimatedImpact: 15,
                    timeframe: "6-12 months"
                ),
                ActionItem(
                    title: "Increase Emergency Fund",
                    description: "Build 8-12 months of expenses",
                    priority: .high,
                    category: .savings,
                    estimatedImpact: 20,
                    timeframe: "12 months"
                )
            ]
        } else {
            return [
                ActionItem(
                    title: "Seek Stable Employment",
                    description: "Look for more stable income sources",
                    priority: .high,
                    category: .career,
                    estimatedImpact: 30,
                    timeframe: "3-6 months"
                ),
                ActionItem(
                    title: "Build Large Emergency Fund",
                    description: "Maintain 12+ months of expenses",
                    priority: .high,
                    category: .savings,
                    estimatedImpact: 25,
                    timeframe: "18 months"
                )
            ]
        }
    }
}
