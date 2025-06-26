import Foundation
import SwiftUI

@MainActor
class PredictiveAnalyzer {
    
    // MARK: - Constants
    
    private struct Constants {
        static let minimumDataPoints = 3
        static let retirementYears = 25.0
        static let averageGrowthRate = 0.08
        static let shortTermMonths = 6
        static let mediumTermMonths = 12
        static let longTermMonths = 24
    }
    
    // MARK: - Public Methods
    
    func generatePredictiveInsights(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        guard payslips.count >= Constants.minimumDataPoints else {
            return createInsufficientDataInsights()
        }
        
        var insights: [PredictiveInsight] = []
        
        // Generate different types of predictions concurrently
        async let incomeInsights = predictIncomeProjections(payslips: payslips)
        async let retirementInsights = predictRetirementReadiness(payslips: payslips)
        async let savingsInsights = predictSavingsGrowth(payslips: payslips)
        async let taxInsights = predictTaxOptimization(payslips: payslips)
        async let careerInsights = predictCareerProgression(payslips: payslips)
        
        insights.append(contentsOf: await incomeInsights)
        insights.append(contentsOf: await retirementInsights)
        insights.append(contentsOf: await savingsInsights)
        insights.append(contentsOf: await taxInsights)
        insights.append(contentsOf: await careerInsights)
        
        return insights
    }
    
    // MARK: - Private Prediction Methods
    
    private func createInsufficientDataInsights() -> [PredictiveInsight] {
        return [
            PredictiveInsight(
                type: .netIncomeProjection,
                title: "Upload More Data",
                description: "We need at least 3 months of payslips to provide accurate predictions",
                confidence: 1.0,
                timeframe: .nextQuarter,
                expectedValue: 0,
                recommendation: "Upload recent payslips for personalized insights",
                riskLevel: .low
            )
        ]
    }
    
    private func predictIncomeProjections(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
        let recentIncome = sortedPayslips.prefix(6).map { $0.credits }
        
        guard recentIncome.count >= 3 else { return [] }
        
        // Calculate trend
        let growthRate = calculateIncomeGrowthTrend(payslips: Array(sortedPayslips.prefix(12)))
        let currentAverage = recentIncome.reduce(0, +) / Double(recentIncome.count)
        
        // Short-term projection (6 months)
        let shortTermProjection = currentAverage * (1 + growthRate) * Double(Constants.shortTermMonths)
        let mediumTermProjection = currentAverage * pow(1 + (growthRate / 12), Double(Constants.mediumTermMonths))
        
        var insights: [PredictiveInsight] = []
        
        // 6-month income projection
        insights.append(PredictiveInsight(
            type: .netIncomeProjection,
            title: "6-Month Income Forecast",
            description: "Based on your current growth rate of \(String(format: "%.1f", growthRate * 100))%, your projected income is ₹\(Int(shortTermProjection))",
            confidence: calculateConfidence(dataPoints: recentIncome.count, volatility: calculateVolatility(values: recentIncome)),
            timeframe: .nextQuarter,
            expectedValue: shortTermProjection,
            recommendation: growthRate > 0 ? "Your income trend is positive" : "Consider strategies to improve income growth",
            riskLevel: growthRate < 0 ? .high : .low
        ))
        
        // 12-month income projection
        insights.append(PredictiveInsight(
            type: .netIncomeProjection,
            title: "12-Month Income Forecast",
            description: "Annual income projection: ₹\(Int(mediumTermProjection * 12))",
            confidence: calculateConfidence(dataPoints: recentIncome.count, volatility: calculateVolatility(values: recentIncome)) * 0.8,
            timeframe: .nextYear,
            expectedValue: mediumTermProjection * 12,
            recommendation: "Continue current growth trajectory",
            riskLevel: calculateVolatility(values: recentIncome) > 0.15 ? .medium : .low
        ))
        
        return insights
    }
    
    private func predictRetirementReadiness(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        
        let dsopRate = totalIncome > 0 ? totalDSOP / totalIncome : 0
        let monthsOfData = Double(payslips.count)
        let annualDSOPContribution = totalDSOP * (12.0 / monthsOfData)
        
        // Assuming 25 years to retirement and 8% annual growth
        let futureValue = annualDSOPContribution * (pow(1 + Constants.averageGrowthRate, Constants.retirementYears) - 1) / Constants.averageGrowthRate
        
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
    
    private func predictSavingsGrowth(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate monthly savings potential
        let estimatedMonthlySavings = (netIncome / Double(payslips.count)) * 0.20 // Assume 20% savings rate
        
        if estimatedMonthlySavings > 1000 {
            let oneYearSavings = estimatedMonthlySavings * 12
            let fiveYearSavings = estimatedMonthlySavings * 12 * 5 * (1 + Constants.averageGrowthRate)
            
            return [
                PredictiveInsight(
                    type: .savingsGoal,
                    title: "Savings Growth Potential",
                    description: "With 20% savings rate, you could save ₹\(Int(oneYearSavings)) in 1 year, ₹\(Int(fiveYearSavings)) in 5 years with 8% returns",
                    confidence: 0.7,
                    timeframe: .nextYear,
                    expectedValue: oneYearSavings,
                    recommendation: "Consider systematic investment plan (SIP) for better returns",
                    riskLevel: .low
                )
            ]
        }
        
        return []
    }
    
    private func predictTaxOptimization(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let currentTaxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        // Estimate potential tax savings through optimization
        let potentialSavings = totalIncome * 0.05 // Assume 5% potential savings
        
        if currentTaxRate > 0.15 && potentialSavings > 5000 {
            return [
                PredictiveInsight(
                    type: .taxProjection,
                    title: "Tax Optimization Opportunity",
                    description: "You could potentially save ₹\(Int(potentialSavings)) annually through tax optimization strategies",
                    confidence: 0.8,
                    timeframe: .nextYear,
                    expectedValue: potentialSavings,
                    recommendation: "Consider maximizing deductions under 80C, 80D, and other sections",
                    riskLevel: .low
                )
            ]
        }
        
        return []
    }
    
    private func predictCareerProgression(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        guard payslips.count >= 6 else { return [] }
        
        let growthRate = calculateIncomeGrowthTrend(payslips: payslips)
        
        if growthRate > 0.05 { // 5% or higher growth
            let currentIncome = payslips.prefix(3).reduce(0) { $0 + $1.credits } / 3
            let projectedIncomeIn2Years = currentIncome * pow(1 + growthRate, 24)
            
            return [
                PredictiveInsight(
                    type: .salaryGrowth,
                    title: "Career Progression Outlook",
                    description: "With current growth rate of \(String(format: "%.1f", growthRate * 100))%, your income could reach ₹\(Int(projectedIncomeIn2Years)) in 2 years",
                    confidence: 0.6,
                    timeframe: .fiveYears,
                    expectedValue: projectedIncomeIn2Years,
                    recommendation: "Continue current career trajectory and consider skill development",
                    riskLevel: .low
                )
            ]
        } else if growthRate < 0.02 { // Less than 2% growth
            return [
                PredictiveInsight(
                    type: .salaryGrowth,
                    title: "Career Development Needed",
                    description: "Your income growth of \(String(format: "%.1f", growthRate * 100))% is below market average",
                    confidence: 0.8,
                    timeframe: .nextYear,
                    expectedValue: 0,
                    recommendation: "Consider upskilling, job change, or performance improvement initiatives",
                    riskLevel: .medium
                )
            ]
        }
        
        return []
    }
    
    // MARK: - Helper Methods
    
    private func calculateIncomeGrowthTrend(payslips: [PayslipItem]) -> Double {
        guard payslips.count >= 6 else { return 0 }
        
        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
        let incomes = sortedPayslips.map { $0.credits }
        
        // Simple linear regression to find growth trend
        let n = Double(incomes.count)
        let sumX = (0..<incomes.count).reduce(0, +)
        let sumY = incomes.reduce(0, +)
        let sumXY = zip(0..<incomes.count, incomes).reduce(0) { $0 + Double($1.0) * $1.1 }
        let sumX2 = (0..<incomes.count).reduce(0) { $0 + $1 * $1 }
        
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * Double(sumX2) - Double(sumX) * Double(sumX))
        let avgIncome = sumY / n
        
        // Convert slope to monthly growth rate
        return avgIncome > 0 ? slope / avgIncome : 0
    }
    
    private func calculateVolatility(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance) / mean
    }
    
    private func calculateConfidence(dataPoints: Int, volatility: Double) -> Double {
        // More data points and lower volatility = higher confidence
        let dataConfidence = min(1.0, Double(dataPoints) / 12.0) // Max confidence at 12 months
        let volatilityPenalty = max(0, 1.0 - volatility * 2) // Reduce confidence for high volatility
        
        return dataConfidence * volatilityPenalty * 0.9 // Max 90% confidence
    }
} 