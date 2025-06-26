import Foundation
import SwiftUI

/// Handles predictive analytics including salary growth, tax projections, and retirement readiness
@MainActor
class PredictiveAnalyticsService: ObservableObject {
    
    // MARK: - Main Predictive Analytics
    
    func generatePredictiveInsights(payslips: [PayslipItem]) async -> [PredictiveInsight] {
        var insights: [PredictiveInsight] = []
        
        // Salary growth prediction
        insights.append(contentsOf: await predictSalaryGrowth(payslips: payslips))
        
        // Tax projection
        insights.append(contentsOf: await predictTaxLiability(payslips: payslips))
        
        // Retirement readiness
        insights.append(contentsOf: await predictRetirementReadiness(payslips: payslips))
        
        return insights
    }
    
    // MARK: - Salary Growth Prediction
    
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
    
    // MARK: - Tax Liability Prediction
    
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
    
    // MARK: - Retirement Readiness Prediction
    
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
    
    // MARK: - Advanced Predictive Models
    
    func predictIncomeVolatility(payslips: [PayslipItem]) async -> Double {
        guard payslips.count >= 3 else { return 0.0 }
        
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        
        return sqrt(variance) / mean
    }
    
    func predictFinancialStress(payslips: [PayslipItem]) async -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        let volatility = await predictIncomeVolatility(payslips: payslips)
        
        // Stress score based on high deductions and income volatility
        return min(1.0, (deductionRatio * 2.0) + (volatility * 1.5))
    }
    
    func predictCareerGrowthPotential(payslips: [PayslipItem]) async -> Double {
        guard payslips.count >= 6 else { return 0.5 }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        // Convert growth rate to 0-1 scale
        return min(1.0, max(0.0, (growthRate + 0.1) / 0.2))
    }
} 