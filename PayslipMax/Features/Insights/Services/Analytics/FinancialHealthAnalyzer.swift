import Foundation
import SwiftUI

@MainActor
class FinancialHealthAnalyzer {
    
    // MARK: - Constants
    
    private struct Constants {
        static let minimumDataPointsForAnalysis = 3
        static let volatilityThreshold = 0.15
        static let goodSavingsRate = 0.20
        static let excellentSavingsRate = 0.30
        static let averageIncomeTaxRate = 0.20
        static let healthyDeductionRatio = 0.25
    }
    
    // MARK: - Public Methods
    
    func calculateFinancialHealthScore(payslips: [PayslipItem]) async -> FinancialHealthScore {
        guard payslips.count >= Constants.minimumDataPointsForAnalysis else {
            return createInsufficientDataScore()
        }
        
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
    
    // MARK: - Private Methods
    
    private func createInsufficientDataScore() -> FinancialHealthScore {
        return FinancialHealthScore(
            overallScore: 50,
            categories: [],
            trend: .stable,
            lastUpdated: Date()
        )
    }
    
    private func calculateHealthCategories(payslips: [PayslipItem]) async -> [HealthCategory] {
        async let incomeStability = calculateIncomeStabilityCategory(payslips: payslips)
        async let savings = calculateSavingsCategory(payslips: payslips)
        async let deductions = calculateDeductionCategory(payslips: payslips)
        async let growth = calculateGrowthCategory(payslips: payslips)
        async let risk = calculateRiskCategory(payslips: payslips)
        
        return await [incomeStability, savings, deductions, growth, risk]
    }
    
    private func calculateIncomeStabilityCategory(payslips: [PayslipItem]) -> HealthCategory {
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        let actionItems: [ActionItem]
        
        if volatility < 0.10 {
            score = 95
            status = .excellent
            recommendation = "Your income is very stable"
            actionItems = []
        } else if volatility < Constants.volatilityThreshold {
            score = 80
            status = .good
            recommendation = "Your income has good stability"
            actionItems = [
                ActionItem(title: "Maintain Consistency", description: "Continue current income strategies", priority: .low, category: .career, estimatedImpact: 5, timeframe: "Ongoing")
            ]
        } else if volatility < 0.20 {
            score = 60
            status = .fair
            recommendation = "Your income has moderate fluctuations"
            actionItems = [
                ActionItem(title: "Diversify Income", description: "Consider additional income streams", priority: .high, category: .career, estimatedImpact: 15, timeframe: "6-12 months"),
                ActionItem(title: "Increase Emergency Fund", description: "Build 8-12 months of expenses", priority: .high, category: .savings, estimatedImpact: 20, timeframe: "12 months")
            ]
        } else {
            score = 30
            status = .poor
            recommendation = "Your income shows high volatility"
            actionItems = [
                ActionItem(title: "Seek Stable Employment", description: "Look for more stable income sources", priority: .high, category: .career, estimatedImpact: 30, timeframe: "3-6 months"),
                ActionItem(title: "Build Large Emergency Fund", description: "Maintain 12+ months of expenses", priority: .high, category: .savings, estimatedImpact: 25, timeframe: "18 months")
            ]
        }
        
        return HealthCategory(
            name: "Income Stability",
            score: score,
            weight: 0.25,
            status: status,
            recommendation: recommendation,
            actionItems: actionItems
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
        
        if savingsRate >= Constants.excellentSavingsRate {
            score = 95
            status = .excellent
            recommendation = "Excellent savings rate! You're on track for early retirement."
        } else if savingsRate >= Constants.goodSavingsRate {
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
            actionItems: generateSavingsActionItems(currentRate: savingsRate)
        )
    }
    
    private func calculateDeductionCategory(payslips: [PayslipItem]) -> HealthCategory {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        // ✅ FIXED: Use correct calculation from FinancialCalculationUtility
        let totalDeductions = payslips.reduce(0) { $0 + FinancialCalculationUtility.shared.calculateTotalDeductions(for: $1) }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        
        let score: Double
        let status: HealthCategory.HealthStatus
        let recommendation: String
        
        if deductionRatio <= 0.20 {
            score = 95
            status = .excellent
            recommendation = "Very efficient deduction management"
        } else if deductionRatio <= 0.30 {
            score = 80
            status = .good
            recommendation = "Good deduction balance"
        } else if deductionRatio <= 0.40 {
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
            weight: 0.20,
            status: status,
            recommendation: recommendation,
            actionItems: generateDeductionActionItems(deductionRatio: deductionRatio)
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
            actionItems: generateGrowthActionItems(growthRate: growthRate)
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
            actionItems: generateRiskActionItems(volatility: volatility, deductionRatio: deductionRatio)
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallScore(categories: [HealthCategory]) -> Double {
        let weightedScore = categories.reduce(0) { $0 + ($1.score * $1.weight) }
        return min(100, max(0, weightedScore))
    }
    
    private func calculateScoreTrend(payslips: [PayslipItem]) -> FinancialHealthScore.ScoreTrend {
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
    
    private func generateSavingsActionItems(currentRate: Double) -> [ActionItem] {
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
    
    private func generateDeductionActionItems(deductionRatio: Double) -> [ActionItem] {
        var items: [ActionItem] = []
        
        if deductionRatio > 0.35 {
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
    
    private func generateGrowthActionItems(growthRate: Double) -> [ActionItem] {
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
    
    private func generateRiskActionItems(volatility: Double, deductionRatio: Double) -> [ActionItem] {
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
} 