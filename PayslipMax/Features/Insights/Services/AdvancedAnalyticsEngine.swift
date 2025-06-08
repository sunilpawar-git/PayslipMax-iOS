import Foundation
import SwiftUI
import Combine

@MainActor
class AdvancedAnalyticsEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var financialHealthScore: FinancialHealthScore?
    @Published var predictiveInsights: [PredictiveInsight] = []
    @Published var professionalRecommendations: [ProfessionalRecommendation] = []
    @Published var advancedMetrics: AdvancedMetrics?
    @Published var benchmarkData: [BenchmarkData] = []
    @Published var financialGoals: [FinancialGoal] = []
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private struct AnalyticsConstants {
        static let minimumDataPointsForAnalysis = 3
        static let volatilityThreshold = 0.15
        static let goodSavingsRate = 0.20
        static let excellentSavingsRate = 0.30
        static let averageIncomeTaxRate = 0.20
        static let healthyDeductionRatio = 0.25
    }
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    // MARK: - Main Analysis Function
    
    func performComprehensiveAnalysis(payslips: [PayslipItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        guard payslips.count >= AnalyticsConstants.minimumDataPointsForAnalysis else {
            await handleInsufficientData()
            return
        }
        
        // Run all analyses in parallel
        async let healthScore = calculateFinancialHealthScore(payslips: payslips)
        async let predictions = generatePredictiveInsights(payslips: payslips)
        async let recommendations = generateProfessionalRecommendations(payslips: payslips)
        async let metrics = calculateAdvancedMetrics(payslips: payslips)
        async let benchmarks = performBenchmarkAnalysis(payslips: payslips)
        async let goals = analyzeMilestoneProgress(payslips: payslips)
        
        // Await all results
        financialHealthScore = await healthScore
        predictiveInsights = await predictions
        professionalRecommendations = await recommendations
        advancedMetrics = await metrics
        benchmarkData = await benchmarks
        financialGoals = await goals
    }
    
    // MARK: - Financial Health Score Calculation
    
    private func calculateFinancialHealthScore(payslips: [PayslipItem]) async -> FinancialHealthScore {
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
    
    private func calculateHealthCategories(payslips: [PayslipItem]) async -> [HealthCategory] {
        return [
            calculateIncomeStabilityCategory(payslips: payslips),
            calculateSavingsCategory(payslips: payslips),
            calculateTaxEfficiencyCategory(payslips: payslips),
            calculateGrowthCategory(payslips: payslips),
            calculateRiskCategory(payslips: payslips)
        ]
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
        
        if volatility < 0.05 {
            score = 95
            status = .excellent
            recommendation = "Your income is exceptionally stable"
            actionItems = [
                ActionItem(title: "Invest in Growth", description: "Consider higher-risk investments for better returns", priority: .medium, category: .investments, estimatedImpact: 5, timeframe: "6-12 months")
            ]
        } else if volatility < 0.10 {
            score = 80
            status = .good
            recommendation = "Your income shows good stability"
            actionItems = [
                ActionItem(title: "Build Emergency Fund", description: "Maintain 6 months of expenses", priority: .medium, category: .savings, estimatedImpact: 10, timeframe: "3-6 months")
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
        
        if savingsRate >= AnalyticsConstants.excellentSavingsRate {
            score = 95
            status = .excellent
            recommendation = "Excellent savings rate! You're on track for early retirement."
        } else if savingsRate >= AnalyticsConstants.goodSavingsRate {
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
            actionItems: generateTaxActionItems(effectiveRate: effectiveTaxRate)
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
    
    private func generateSavingsActionItems(currentRate: Double) -> [ActionItem] {
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
    
    private func generateTaxActionItems(effectiveRate: Double) -> [ActionItem] {
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
    
    // MARK: - Predictive Analytics
    
    private func generatePredictiveInsights(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        var insights: [PredictiveInsight] = []
        
        // Salary growth prediction
        insights.append(contentsOf: await predictSalaryGrowth(payslips: payslips))
        
        // Tax projection
        insights.append(contentsOf: await predictTaxLiability(payslips: payslips))
        
        // Retirement readiness
        insights.append(contentsOf: await predictRetirementReadiness(payslips: payslips))
        
        return insights
    }
    
    private func predictSalaryGrowth(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        guard payslips.count >= 6 else { return [] }
        
        // Simple linear regression for salary prediction
        let incomes = payslips.enumerated().map { (index, payslip) in
            (Double(index), payslip.credits)
        }
        
        // Calculate slope (growth rate)
        let n = Double(incomes.count)
        let sumX = incomes.reduce(0) { $0 + $1.0 }
        let sumY = incomes.reduce(0) { $0 + $1.1 }
        let sumXY = incomes.reduce(0) { $0 + ($1.0 * $1.1) }
        let sumX2 = incomes.reduce(0) { $0 + ($1.0 * $1.0) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Predict next month
        let nextMonthIncome = slope * n + intercept
        let currentIncome = payslips.first?.credits ?? 0
        
        let confidence = min(0.9, max(0.3, 1.0 - abs(slope) / currentIncome))
        
        return [PredictiveInsight(
            type: .salaryGrowth,
            title: "Salary Growth Projection",
            description: "Based on your income trend, next month's salary is projected to be ₹\(Int(nextMonthIncome))",
            confidence: confidence,
            timeframe: .nextMonth,
            expectedValue: nextMonthIncome,
            recommendation: slope > 0 ? "Continue your excellent performance" : "Consider discussing career advancement",
            riskLevel: slope < 0 ? .high : .low
        )]
    }
    
    private func predictTaxLiability(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        // Project annual tax
        let monthsOfData = payslips.count
        let annualProjectedIncome = totalIncome * (12.0 / Double(monthsOfData))
        let projectedAnnualTax = annualProjectedIncome * effectiveRate
        
        return [PredictiveInsight(
            type: .taxProjection,
            title: "Annual Tax Projection",
            description: "Your projected annual tax liability is ₹\(Int(projectedAnnualTax))",
            confidence: 0.8,
            timeframe: .nextYear,
            expectedValue: projectedAnnualTax,
            recommendation: effectiveRate > 0.25 ? "Consider tax planning strategies" : "Tax rate is reasonable",
            riskLevel: effectiveRate > 0.30 ? .high : .low
        )]
    }
    
    private func predictRetirementReadiness(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        
        let dsopRate = totalIncome > 0 ? totalDSOP / totalIncome : 0
        let monthsOfData = Double(payslips.count)
        let annualDSOPContribution = totalDSOP * (12.0 / monthsOfData)
        
        // Assuming 25 years to retirement and 8% annual growth
        let yearsToRetirement = 25.0
        let growthRate = 0.08
        let futureValue = annualDSOPContribution * (pow(1 + growthRate, yearsToRetirement) - 1) / growthRate
        
        return [PredictiveInsight(
            type: .retirementReadiness,
            title: "Retirement Projection",
            description: "At current DSOP contribution rate, your retirement fund could be ₹\(Int(futureValue)) in 25 years",
            confidence: 0.6,
            timeframe: .fiveYears,
            expectedValue: futureValue,
            recommendation: dsopRate < 0.12 ? "Consider increasing DSOP contributions" : "Good retirement savings rate",
            riskLevel: dsopRate < 0.10 ? .high : .low
        )]
    }
    
    // MARK: - Professional Recommendations
    
    private func generateProfessionalRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        var recommendations: [ProfessionalRecommendation] = []
        
        // Tax optimization recommendations
        recommendations.append(contentsOf: await generateTaxOptimizationRecommendations(payslips: payslips))
        
        // Career growth recommendations
        recommendations.append(contentsOf: await generateCareerGrowthRecommendations(payslips: payslips))
        
        // Investment strategy recommendations
        recommendations.append(contentsOf: await generateInvestmentRecommendations(payslips: payslips))
        
        return recommendations
    }
    
    private func generateTaxOptimizationRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        if effectiveRate > 0.25 {
            return [ProfessionalRecommendation(
                category: .taxOptimization,
                title: "High Tax Rate Optimization",
                summary: "Your effective tax rate of \(String(format: "%.1f", effectiveRate * 100))% is above average",
                detailedAnalysis: "Analysis shows potential for significant tax savings through strategic planning and deduction optimization.",
                actionSteps: [
                    "Review all available deductions and exemptions",
                    "Consider tax-saving investments under Section 80C",
                    "Evaluate salary restructuring opportunities",
                    "Consult with a tax professional for advanced strategies"
                ],
                potentialSavings: totalIncome * 0.05, // 5% potential savings
                priority: .high,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    private func generateCareerGrowthRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        guard payslips.count >= 6 else { return [] }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        if growthRate < 0.03 { // Less than 3% growth
            return [ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Accelerate Career Progression",
                summary: "Your income growth of \(String(format: "%.1f", growthRate * 100))% is below industry average",
                detailedAnalysis: "Slow income growth may indicate opportunities for career advancement or skill development to increase earning potential.",
                actionSteps: [
                    "Identify key skills in demand in your field",
                    "Pursue relevant certifications or training",
                    "Network within your industry",
                    "Document and communicate your achievements",
                    "Consider lateral moves or role expansion"
                ],
                potentialSavings: recentAverage * 0.20, // 20% potential income increase
                priority: .medium,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    private func generateInvestmentRecommendations(payslips: [PayslipItem]) async -> [ProfessionalRecommendation] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate available for investment (assuming 70% goes to expenses)
        let availableForInvestment = netIncome * 0.30
        
        if availableForInvestment > 10000 { // Minimum threshold for investment advice
            return [ProfessionalRecommendation(
                category: .investmentStrategy,
                title: "Investment Opportunity Analysis",
                summary: "You have approximately ₹\(Int(availableForInvestment)) available for investments",
                detailedAnalysis: "Based on your income stability and risk profile, we recommend a diversified investment approach.",
                actionSteps: [
                    "Allocate 60% to equity mutual funds for long-term growth",
                    "Invest 30% in debt instruments for stability",
                    "Keep 10% in liquid funds for emergencies",
                    "Review and rebalance portfolio quarterly",
                    "Consider SIP for rupee cost averaging"
                ],
                potentialSavings: availableForInvestment * 0.12 * 5, // 12% annual returns over 5 years
                priority: .medium,
                source: .aiAnalysis
            )]
        }
        
        return []
    }
    
    // MARK: - Advanced Metrics Calculation
    
    private func calculateAdvancedMetrics(payslips: [PayslipItem]) async -> AdvancedMetrics {
        let incomes = payslips.map { $0.credits }
        let meanIncome = incomes.reduce(0, +) / Double(incomes.count)
        
        // Income volatility
        let variance = incomes.map { pow($0 - meanIncome, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / meanIncome
        
        // Year-over-year growth
        let yoyGrowth = calculateYearOverYearGrowth(payslips: payslips)
        
        // Monthly growth rate
        let monthlyGrowth = calculateMonthlyGrowthRate(payslips: payslips)
        
        // Income stability score
        let stabilityScore = max(0, 100 - (volatility * 100))
        
        // Tax efficiency metrics
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveTaxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        let taxOptimizationScore = max(0, 100 - (effectiveTaxRate * 200)) // Score decreases as tax rate increases
        
        // Financial ratios
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let estimatedSavings = max(0, netIncome * 0.30) // Estimate 30% of net as savings
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        let netIncomeGrowthRate = calculateNetIncomeGrowthRate(payslips: payslips)
        
        // Risk indicators
        let financialRiskScore = calculateFinancialRiskScore(volatility: volatility, deductionRatio: deductionRatio)
        let incomeConcentrationRisk = 100.0 // Assume 100% concentration in salary (could be improved with additional data)
        
        return AdvancedMetrics(
            incomeVolatility: volatility,
            yearOverYearGrowth: yoyGrowth,
            monthlyGrowthRate: monthlyGrowth,
            incomeStabilityScore: stabilityScore,
            effectiveTaxRate: effectiveTaxRate,
            taxOptimizationScore: taxOptimizationScore,
            potentialTaxSavings: totalIncome * 0.05, // Estimate 5% potential savings
            savingsRate: savingsRate,
            deductionToIncomeRatio: deductionRatio,
            netIncomeGrowthRate: netIncomeGrowthRate,
            salaryBenchmarkPercentile: nil, // Would require external data
            careerProgressionScore: nil, // Would require role/industry data
            financialRiskScore: financialRiskScore,
            incomeConcentrationRisk: incomeConcentrationRisk
        )
    }
    
    // MARK: - Helper Methods for Advanced Metrics
    
    private func calculateYearOverYearGrowth(payslips: [PayslipItem]) -> Double {
        let currentYearPayslips = payslips.filter { Calendar.current.component(.year, from: $0.timestamp) == Calendar.current.component(.year, from: Date()) }
        let previousYearPayslips = payslips.filter { Calendar.current.component(.year, from: $0.timestamp) == Calendar.current.component(.year, from: Date()) - 1 }
        
        guard !currentYearPayslips.isEmpty && !previousYearPayslips.isEmpty else { return 0 }
        
        let currentYearAvg = currentYearPayslips.reduce(0) { $0 + $1.credits } / Double(currentYearPayslips.count)
        let previousYearAvg = previousYearPayslips.reduce(0) { $0 + $1.credits } / Double(previousYearPayslips.count)
        
        return previousYearAvg > 0 ? (currentYearAvg - previousYearAvg) / previousYearAvg : 0
    }
    
    private func calculateMonthlyGrowthRate(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 2 else { return 0 }
        
        let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
        let recent = sortedPayslips[0].credits
        let previous = sortedPayslips[1].credits
        
        return previous > 0 ? (recent - previous) / previous : 0
    }
    
    private func calculateNetIncomeGrowthRate(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 6 else { return 0 }
        
        let recent3Months = Array(payslips.prefix(3))
        let previous3Months = Array(payslips.dropFirst(3).prefix(3))
        
        let recentNetAvg = recent3Months.reduce(0) { $0 + ($1.credits - $1.debits - $1.tax - $1.dsop) } / 3
        let previousNetAvg = previous3Months.reduce(0) { $0 + ($1.credits - $1.debits - $1.tax - $1.dsop) } / 3
        
        return previousNetAvg > 0 ? (recentNetAvg - previousNetAvg) / previousNetAvg : 0
    }
    
    private func calculateFinancialRiskScore(volatility: Double, deductionRatio: Double) -> Double {
        // Higher volatility and deduction ratio = higher risk
        let volatilityRisk = min(100, volatility * 200) // Scale volatility to 0-100
        let deductionRisk = max(0, (deductionRatio - 0.3) * 200) // Risk increases above 30% deductions
        
        return (volatilityRisk + deductionRisk) / 2
    }
    
    // MARK: - Benchmark Analysis
    
    private func performBenchmarkAnalysis(payslips: [PayslipItem]) async -> [BenchmarkData] {
        // This would typically involve API calls to get industry benchmarks
        // For now, we'll use estimated benchmarks
        
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let monthsOfData = Double(payslips.count)
        let annualIncome = totalIncome * (12.0 / monthsOfData)
        
        return [
            BenchmarkData(
                category: .salary,
                userValue: annualIncome,
                benchmarkValue: 800000, // Industry average
                percentile: calculatePercentile(userValue: annualIncome, benchmark: 800000),
                comparison: compareToAverage(userValue: annualIncome, average: 800000)
            ),
            BenchmarkData(
                category: .taxRate,
                userValue: calculateEffectiveTaxRate(payslips: payslips),
                benchmarkValue: 0.20,
                percentile: 60,
                comparison: .average
            )
        ]
    }
    
    private func calculateEffectiveTaxRate(payslips: [PayslipItem]) -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        return totalIncome > 0 ? totalTax / totalIncome : 0
    }
    
    private func calculatePercentile(userValue: Double, benchmark: Double) -> Double {
        // Simplified percentile calculation
        return min(95, max(5, (userValue / benchmark) * 50))
    }
    
    private func compareToAverage(userValue: Double, average: Double) -> BenchmarkData.ComparisonResult {
        let ratio = userValue / average
        if ratio > 1.1 {
            return .aboveAverage((ratio - 1) * 100)
        } else if ratio < 0.9 {
            return .belowAverage((1 - ratio) * 100)
        } else {
            return .average
        }
    }
    
    // MARK: - Goal Analysis
    
    private func analyzeMilestoneProgress(payslips: [PayslipItem]) async -> [FinancialGoal] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        // Emergency fund goal
        let monthlyExpenses = netIncome * 0.70 / monthsOfData // Estimate 70% of net goes to expenses
        let emergencyFundTarget = monthlyExpenses * 6 // 6 months of expenses
        let currentSavings = netIncome * 0.30 // Estimate current savings
        
        return [
            FinancialGoal(
                type: .emergencyFund,
                title: "Emergency Fund",
                targetAmount: emergencyFundTarget,
                currentAmount: currentSavings,
                targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                category: .shortTerm,
                isAchievable: true,
                recommendedMonthlyContribution: (emergencyFundTarget - currentSavings) / 12,
                projectedAchievementDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())
            )
        ]
    }
    
    // MARK: - Error Handling
    
    private func handleInsufficientData() async {
        financialHealthScore = FinancialHealthScore(
            overallScore: 50,
            categories: [],
            trend: .stable,
            lastUpdated: Date()
        )
        
        predictiveInsights = []
        professionalRecommendations = [
            ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Upload More Payslips",
                summary: "We need more data to provide accurate insights",
                detailedAnalysis: "Please upload at least 3 months of payslips for comprehensive analysis.",
                actionSteps: ["Upload recent payslips", "Ensure data accuracy"],
                potentialSavings: nil,
                priority: .medium,
                source: .aiAnalysis
            )
        ]
    }
} 