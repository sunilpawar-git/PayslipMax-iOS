import Foundation
import SwiftUI

/// Handles calculation of advanced financial metrics including volatility, growth rates, and risk analysis
@MainActor
class AdvancedMetricsCalculator: ObservableObject {
    
    // MARK: - Main Advanced Metrics Calculation
    
    func calculateAdvancedMetrics(payslips: [PayslipItem]) async -> AdvancedMetrics {
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
    
    // MARK: - Growth Rate Calculations
    
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
    
    // MARK: - Risk Analysis
    
    private func calculateFinancialRiskScore(volatility: Double, deductionRatio: Double) -> Double {
        // Higher volatility and deduction ratio = higher risk
        let volatilityRisk = min(100, volatility * 200) // Scale volatility to 0-100
        let deductionRisk = max(0, (deductionRatio - 0.3) * 200) // Risk increases above 30% deductions
        
        return (volatilityRisk + deductionRisk) / 2
    }
    
    // MARK: - Specialized Metrics
    
    func calculateIncomeStabilityIndex(payslips: [PayslipItem]) async -> Double {
        guard payslips.count >= 3 else { return 50.0 }
        
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let coefficientOfVariation = sqrt(variance) / mean
        
        // Convert to 0-100 scale (lower variation = higher stability)
        return max(0, 100 - (coefficientOfVariation * 100))
    }
    
    func calculateTaxEfficiencyRatio(payslips: [PayslipItem]) async -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        
        guard totalIncome > 0 else { return 0 }
        
        let effectiveRate = totalTax / totalIncome
        // Efficiency score: lower tax rate = higher efficiency
        return max(0, 1.0 - effectiveRate)
    }
    
    func calculateSavingsProjection(payslips: [PayslipItem], months: Int) async -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let monthsOfData = Double(payslips.count)
        
        let monthlyNetIncome = netIncome / monthsOfData
        let estimatedMonthlySavings = monthlyNetIncome * 0.30 // Assume 30% savings rate
        
        return estimatedMonthlySavings * Double(months)
    }
    
    func calculateDebtToIncomeRatio(payslips: [PayslipItem]) async -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        
        guard totalIncome > 0 else { return 0 }
        
        return totalDeductions / totalIncome
    }
    
    func calculateFinancialMomentum(payslips: [PayslipItem]) async -> Double {
        guard payslips.count >= 6 else { return 0.5 }
        
        let recent3Months = Array(payslips.prefix(3))
        let previous3Months = Array(payslips.dropFirst(3).prefix(3))
        
        let recentAvg = recent3Months.reduce(0) { $0 + $1.credits } / 3
        let previousAvg = previous3Months.reduce(0) { $0 + $1.credits } / 3
        
        let momentum = previousAvg > 0 ? (recentAvg - previousAvg) / previousAvg : 0
        
        // Convert to 0-1 scale where 0.5 is neutral
        return 0.5 + (momentum * 0.5)
    }
    
    // MARK: - Statistical Analysis
    
    func calculateIncomePercentiles(payslips: [PayslipItem]) async -> [String: Double] {
        let incomes = payslips.map { $0.credits }.sorted()
        
        guard !incomes.isEmpty else { return [:] }
        
        return [
            "25th": percentile(values: incomes, percentile: 0.25),
            "50th": percentile(values: incomes, percentile: 0.50),
            "75th": percentile(values: incomes, percentile: 0.75),
            "90th": percentile(values: incomes, percentile: 0.90)
        ]
    }
    
    private func percentile(values: [Double], percentile: Double) -> Double {
        let index = percentile * Double(values.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        
        if lower == upper {
            return values[lower]
        } else {
            let weight = index - Double(lower)
            return values[lower] * (1 - weight) + values[upper] * weight
        }
    }
    
    func calculateSeasonalityIndex(payslips: [PayslipItem]) async -> Double {
        guard payslips.count >= 12 else { return 0.0 }
        
        // Group payslips by month
        var monthlyIncomes: [Int: [Double]] = [:]
        
        for payslip in payslips {
            let month = Calendar.current.component(.month, from: payslip.timestamp)
            monthlyIncomes[month, default: []].append(payslip.credits)
        }
        
        // Calculate average income for each month
        let monthlyAverages = monthlyIncomes.mapValues { incomes in
            incomes.reduce(0, +) / Double(incomes.count)
        }
        
        guard monthlyAverages.count >= 6 else { return 0.0 }
        
        let overallAverage = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)
        let variance = monthlyAverages.values.map { pow($0 - overallAverage, 2) }.reduce(0, +) / Double(monthlyAverages.count)
        
        // Seasonality index: higher variance indicates more seasonality
        return sqrt(variance) / overallAverage
    }
} 