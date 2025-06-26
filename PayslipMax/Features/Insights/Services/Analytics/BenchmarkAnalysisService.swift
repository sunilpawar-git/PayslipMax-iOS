import Foundation
import SwiftUI

/// Handles benchmark analysis and industry comparisons
@MainActor
class BenchmarkAnalysisService: ObservableObject {
    
    // MARK: - Main Benchmark Analysis
    
    func performBenchmarkAnalysis(payslips: [PayslipItem]) async -> [BenchmarkData] {
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
    
    // MARK: - Tax Rate Calculation
    
    private func calculateEffectiveTaxRate(payslips: [PayslipItem]) -> Double {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        return totalIncome > 0 ? totalTax / totalIncome : 0
    }
    
    // MARK: - Percentile Calculations
    
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
    
    // MARK: - Specialized Benchmark Analysis
    
    func benchmarkSavingsRate(payslips: [PayslipItem]) async -> BenchmarkData {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        let estimatedSavings = max(0, netIncome * 0.30)
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0
        
        let benchmarkSavingsRate = 0.20 // 20% industry benchmark
        
        return BenchmarkData(
            category: .savingsRate,
            userValue: savingsRate,
            benchmarkValue: benchmarkSavingsRate,
            percentile: calculateSavingsPercentile(savingsRate: savingsRate),
            comparison: compareToAverage(userValue: savingsRate, average: benchmarkSavingsRate)
        )
    }
    
    func benchmarkDeductionRatio(payslips: [PayslipItem]) async -> BenchmarkData {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let deductionRatio = totalIncome > 0 ? totalDeductions / totalIncome : 0
        
        let benchmarkDeductionRatio = 0.30 // 30% industry benchmark
        
        return BenchmarkData(
            category: .benefits,
            userValue: deductionRatio,
            benchmarkValue: benchmarkDeductionRatio,
            percentile: calculateDeductionPercentile(deductionRatio: deductionRatio),
            comparison: compareToAverage(userValue: deductionRatio, average: benchmarkDeductionRatio)
        )
    }
    
    func benchmarkIncomeGrowth(payslips: [PayslipItem]) async -> BenchmarkData? {
        guard payslips.count >= 6 else { return nil }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        let benchmarkGrowthRate = 0.05 // 5% annual growth benchmark
        
        return BenchmarkData(
            category: .growthRate,
            userValue: growthRate,
            benchmarkValue: benchmarkGrowthRate,
            percentile: calculateGrowthPercentile(growthRate: growthRate),
            comparison: compareToAverage(userValue: growthRate, average: benchmarkGrowthRate)
        )
    }
    
    // MARK: - Percentile Calculations for Specific Metrics
    
    private func calculateSavingsPercentile(savingsRate: Double) -> Double {
        // Percentile based on savings rate distribution
        if savingsRate >= 0.30 { return 90 }
        if savingsRate >= 0.20 { return 70 }
        if savingsRate >= 0.15 { return 50 }
        if savingsRate >= 0.10 { return 30 }
        return 10
    }
    
    private func calculateDeductionPercentile(deductionRatio: Double) -> Double {
        // Percentile based on deduction ratio (lower is better for user)
        if deductionRatio <= 0.20 { return 90 }
        if deductionRatio <= 0.25 { return 70 }
        if deductionRatio <= 0.30 { return 50 }
        if deductionRatio <= 0.35 { return 30 }
        return 10
    }
    
    private func calculateGrowthPercentile(growthRate: Double) -> Double {
        // Percentile based on income growth rate distribution
        if growthRate >= 0.10 { return 95 }
        if growthRate >= 0.07 { return 80 }
        if growthRate >= 0.05 { return 60 }
        if growthRate >= 0.03 { return 40 }
        if growthRate >= 0.01 { return 25 }
        return 10
    }
    
    // MARK: - Industry-Specific Benchmarks
    
    func getIndustryBenchmarks(industry: String) async -> [String: Double] {
        // This would typically fetch from an API or database
        // For now, return estimated benchmarks
        
        switch industry.lowercased() {
        case "technology", "it":
            return [
                "averageSalary": 1200000,
                "savingsRate": 0.25,
                "taxRate": 0.22,
                "growthRate": 0.08
            ]
        case "finance", "banking":
            return [
                "averageSalary": 1000000,
                "savingsRate": 0.23,
                "taxRate": 0.24,
                "growthRate": 0.06
            ]
        case "healthcare", "medical":
            return [
                "averageSalary": 900000,
                "savingsRate": 0.20,
                "taxRate": 0.23,
                "growthRate": 0.05
            ]
        case "government", "public":
            return [
                "averageSalary": 700000,
                "savingsRate": 0.18,
                "taxRate": 0.20,
                "growthRate": 0.04
            ]
        default:
            return [
                "averageSalary": 800000,
                "savingsRate": 0.20,
                "taxRate": 0.22,
                "growthRate": 0.05
            ]
        }
    }
    
    // MARK: - Regional Benchmarks
    
    func getRegionalBenchmarks(region: String) async -> [String: Double] {
        // Regional cost of living and salary adjustments
        
        switch region.lowercased() {
        case "mumbai", "bangalore", "delhi", "hyderabad":
            return [
                "costOfLivingMultiplier": 1.3,
                "averageSalary": 950000,
                "savingsRate": 0.18, // Lower due to higher costs
                "taxRate": 0.23
            ]
        case "pune", "chennai", "kolkata":
            return [
                "costOfLivingMultiplier": 1.1,
                "averageSalary": 750000,
                "savingsRate": 0.22,
                "taxRate": 0.21
            ]
        default:
            return [
                "costOfLivingMultiplier": 1.0,
                "averageSalary": 600000,
                "savingsRate": 0.25,
                "taxRate": 0.20
            ]
        }
    }
} 