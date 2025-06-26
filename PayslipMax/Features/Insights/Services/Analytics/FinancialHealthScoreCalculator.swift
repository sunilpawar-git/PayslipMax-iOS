import Foundation
import SwiftUI

/// Handles calculation of financial health scores and health category analysis
@MainActor
class FinancialHealthScoreCalculator: ObservableObject {
    
    // MARK: - Dependencies
    private let actionItemsGenerator: HealthCategoryActionItemsGenerator
    
    // MARK: - Initialization
    init(actionItemsGenerator: HealthCategoryActionItemsGenerator = HealthCategoryActionItemsGenerator()) {
        self.actionItemsGenerator = actionItemsGenerator
    }
    
    // MARK: - Constants
    private struct HealthConstants {
        static let minimumDataPointsForAnalysis = 3
        static let volatilityThreshold = 0.15
        static let goodSavingsRate = 0.20
        static let excellentSavingsRate = 0.30
        static let averageIncomeTaxRate = 0.20
        static let healthyDeductionRatio = 0.25
    }
    
    // MARK: - Main Health Score Calculation
    
    func calculateFinancialHealthScore(payslips: [PayslipItem]) async -> FinancialHealthScore {
        let recentPayslips = Array(payslips.prefix(12)) // Last 12 months
        
        let categories = await calculateHealthCategories(payslips: recentPayslips)
        let overallScore = calculateOverallScore(categories: categories)
        let trend = calculateScoreTrend(payslips: payslips)
        
        return FinancialHealthScore(
            overallScore: overallScore,
            categories: categories,
            trend: trend,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Health Categories Calculation
    
    private func calculateHealthCategories(payslips: [PayslipItem]) async -> [HealthCategory] {
        return [
            calculateIncomeStabilityCategory(payslips: payslips),
            calculateSavingsCategory(payslips: payslips),
            calculateTaxEfficiencyCategory(payslips: payslips),
            calculateGrowthCategory(payslips: payslips),
            calculateRiskCategory(payslips: payslips)
        ]
    }
    
    // MARK: - Individual Category Calculators
    
    private func calculateIncomeStabilityCategory(payslips: [PayslipItem]) -> HealthCategory {
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        
        if volatility < 0.05 {
            score = 95
            status = .excellent
            recommendation = "Your income is exceptionally stable"
        } else if volatility < 0.10 {
            score = 80
            status = .good
            recommendation = "Your income shows good stability"
        } else if volatility < 0.20 {
            score = 60
            status = .fair
            recommendation = "Your income has moderate fluctuations"
        } else {
            score = 30
            status = .poor
            recommendation = "Your income shows high volatility"
        }
        
        return HealthCategory(
            name: "Income Stability",
            score: score,
            weight: 0.25,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateIncomeStabilityActionItems(volatility: volatility)
        )
    }
    
    private func calculateSavingsCategory(payslips: [PayslipItem]) -> HealthCategory {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate savings rate (assuming 70% of net income goes to expenses)
        let estimatedSavings = max(0, netIncome * 0.30)
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        
        if savingsRate >= HealthConstants.excellentSavingsRate {
            score = 95
            status = .excellent
            recommendation = "Excellent savings rate! You're on track for early retirement."
        } else if savingsRate >= HealthConstants.goodSavingsRate {
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
            weight: 0.30,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateSavingsActionItems(currentRate: savingsRate)
        )
    }
    
    private func calculateTaxEfficiencyCategory(payslips: [PayslipItem]) -> HealthCategory {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveTaxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        
        if effectiveTaxRate < 0.15 {
            score = 90
            status = .excellent
            recommendation = "Excellent tax efficiency"
        } else if effectiveTaxRate < 0.25 {
            score = 70
            status = .good
            recommendation = "Good tax management"
        } else if effectiveTaxRate < 0.35 {
            score = 50
            status = .fair
            recommendation = "Consider tax optimization strategies"
        } else {
            score = 25
            status = .poor
            recommendation = "High tax burden - urgent optimization needed"
        }
        
        return HealthCategory(
            name: "Tax Efficiency",
            score: score,
            weight: 0.20,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateTaxActionItems(effectiveRate: effectiveTaxRate)
        )
    }
    
    private func calculateGrowthCategory(payslips: [PayslipItem]) -> HealthCategory {
        guard payslips.count >= 6 else {
            return HealthCategory(name: "Income Growth", score: 50, weight: 0.15, status: .fair,
                                recommendation: "Need more data for growth analysis",
                                actionItems: [])
        }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        
        if growthRate > 0.10 {
            score = 95
            status = .excellent
            recommendation = "Exceptional income growth!"
        } else if growthRate > 0.05 {
            score = 80
            status = .good
            recommendation = "Strong income growth trend"
        } else if growthRate > 0 {
            score = 60
            status = .fair
            recommendation = "Modest growth, consider career advancement"
        } else {
            score = 30
            status = .poor
            recommendation = "Declining income - focus on skill development"
        }
        
        return HealthCategory(
            name: "Income Growth",
            score: score,
            weight: 0.15,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateGrowthActionItems(growthRate: growthRate)
        )
    }
    
    private func calculateRiskCategory(payslips: [PayslipItem]) -> HealthCategory {
        // Calculate risk based on income concentration, volatility, and deduction patterns
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean
        
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        
        // Risk score (lower is better for risk category)
        let riskScore = (volatility * 50) + (max(0, deductionRatio - 0.3) * 100)
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
            weight: 0.10,
            status: status,
            recommendation: recommendation,
            actionItems: actionItemsGenerator.generateRiskActionItems(volatility: volatility, deductionRatio: deductionRatio)
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallScore(categories: [HealthCategory]) -> Double {
        let weightedScore = categories.reduce(0) { $0 + ($1.score * $1.weight) }
        return min(100, max(0, weightedScore))
    }
    
    private func calculateScoreTrend(payslips: [PayslipItem]) -> FinancialHealthScore.ScoreTrend {
        // This would ideally compare against historical health scores
        // For now, we'll use a simplified version based on recent vs older data
        guard payslips.count >= 6 else { return .stable }
        
        let recent3Months = Array(payslips.prefix(3))
        let previous3Months = Array(payslips.dropFirst(3).prefix(3))
        
        let recentAvgIncome = recent3Months.reduce(0) { $0 + $1.credits } / 3
        let previousAvgIncome = previous3Months.reduce(0) { $0 + $1.credits } / 3
        
        let change = previousAvgIncome > 0 ? (recentAvgIncome - previousAvgIncome) / previousAvgIncome : 0
        
        if change > 0.05 {
            return .improving(change * 100)
        } else if change < -0.05 {
            return .declining(abs(change) * 100)
        } else {
            return .stable
        }
    }
    

} 