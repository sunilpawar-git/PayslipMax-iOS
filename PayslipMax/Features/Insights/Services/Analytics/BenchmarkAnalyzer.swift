import Foundation

@MainActor
class BenchmarkAnalyzer {
    // MARK: - Constants
    private struct Constants {
        static let minimumDataPoints = 3
        static let industryAverageTaxRate = 0.20
        static let industryAverageSavingsRate = 0.15
        static let industryAverageGrowthRate = 0.05
    }
    
    // MARK: - Public Methods
    func performBenchmarkAnalysis(payslips: [PayslipItem]) async -> [BenchmarkData] {
        guard payslips.count >= Constants.minimumDataPoints else { return [] }
        
        var benchmarks: [BenchmarkData] = []
        
        // Income Benchmarks
        if let incomeBenchmark = await analyzeIncomeBenchmarks(payslips: payslips) {
            benchmarks.append(incomeBenchmark)
        }
        
        // Tax Efficiency Benchmarks
        if let taxBenchmark = await analyzeTaxBenchmarks(payslips: payslips) {
            benchmarks.append(taxBenchmark)
        }
        
        // Savings Rate Benchmarks
        if let savingsBenchmark = await analyzeSavingsBenchmarks(payslips: payslips) {
            benchmarks.append(savingsBenchmark)
        }
        
        // Growth Rate Benchmarks
        if let growthBenchmark = await analyzeGrowthBenchmarks(payslips: payslips) {
            benchmarks.append(growthBenchmark)
        }
        
        return benchmarks
    }
    
    // MARK: - Private Methods
    private func analyzeIncomeBenchmarks(payslips: [PayslipItem]) async -> BenchmarkData? {
        let averageIncome = payslips.reduce(0) { $0 + $1.credits } / Double(payslips.count)
        
        // Placeholder - actual industry data needed
        let industryAverage = 75000.0
        let percentile = calculatePercentile(value: averageIncome, average: industryAverage)
        
        let comparison = determineComparison(current: averageIncome, benchmark: industryAverage)
        
        return BenchmarkData(
            category: .salary,
            userValue: averageIncome,
            benchmarkValue: industryAverage,
            percentile: percentile,
            comparison: comparison
        )
    }
    
    private func analyzeTaxBenchmarks(payslips: [PayslipItem]) async -> BenchmarkData? {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        let effectiveTaxRate = totalIncome > 0 ? totalTax / totalIncome : 0
        
        let percentile = calculatePercentile(
            value: effectiveTaxRate,
            average: Constants.industryAverageTaxRate,
            lowerIsBetter: true
        )
        
        let comparison = determineComparison(current: effectiveTaxRate, benchmark: Constants.industryAverageTaxRate, lowerIsBetter: true)
        
        return BenchmarkData(
            category: .taxRate,
            userValue: effectiveTaxRate,
            benchmarkValue: Constants.industryAverageTaxRate,
            percentile: percentile,
            comparison: comparison
        )
    }
    
    private func analyzeSavingsBenchmarks(payslips: [PayslipItem]) async -> BenchmarkData? {
        let totalIncome = payslips.reduce(0) { $0 + $1.credits }
        let totalDeductions = payslips.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
        let netIncome = totalIncome - totalDeductions
        
        // Estimate savings rate (30% of net income)
        let estimatedSavings = netIncome * 0.30
        let savingsRate = totalIncome > 0 ? estimatedSavings / totalIncome : 0
        
        // Industry average savings rate
        let industryAverageSavingsRate = 0.20
        let percentile = calculatePercentile(value: savingsRate, average: industryAverageSavingsRate)
        
        let comparison = determineComparison(current: savingsRate, benchmark: industryAverageSavingsRate)
        
        return BenchmarkData(
            category: .savingsRate,
            userValue: savingsRate,
            benchmarkValue: industryAverageSavingsRate,
            percentile: percentile,
            comparison: comparison
        )
    }
    
    private func analyzeGrowthBenchmarks(payslips: [PayslipItem]) async -> BenchmarkData? {
        guard payslips.count >= 6 else { return nil }
        
        let recent6Months = Array(payslips.prefix(6))
        let previous6Months = Array(payslips.dropFirst(6).prefix(6))
        
        let recentAverage = recent6Months.reduce(0) { $0 + $1.credits } / 6
        let previousAverage = previous6Months.isEmpty ? recentAverage : 
                             previous6Months.reduce(0) { $0 + $1.credits } / Double(previous6Months.count)
        
        let growthRate = previousAverage > 0 ? (recentAverage - previousAverage) / previousAverage : 0
        
        // Industry average growth rate
        let industryAverageGrowth = 0.05 // 5% annual growth
        let annualizedGrowthRate = growthRate * 2 // Convert 6-month to annual
        
        let percentile = calculatePercentile(value: annualizedGrowthRate, average: industryAverageGrowth)
        
        let comparison = determineComparison(current: annualizedGrowthRate, benchmark: industryAverageGrowth)
        
        return BenchmarkData(
            category: .growthRate,
            userValue: annualizedGrowthRate,
            benchmarkValue: industryAverageGrowth,
            percentile: percentile,
            comparison: comparison
        )
    }
    
    private func calculatePercentile(value: Double, average: Double, lowerIsBetter: Bool = false) -> Double {
        // Simple percentile calculation - replace with actual distribution data
        let ratio = value / average
        let basePercentile = (ratio - 0.5) * 100
        return lowerIsBetter ? 100 - basePercentile : basePercentile
    }
    
    private func determineComparison(current: Double, benchmark: Double, lowerIsBetter: Bool = false) -> BenchmarkData.ComparisonResult {
        let difference = abs(current - benchmark) / benchmark * 100
        
        if lowerIsBetter {
            if current < benchmark * 0.9 {
                return .aboveAverage(difference)
            } else if current > benchmark * 1.1 {
                return .belowAverage(difference)
            } else {
                return .average
            }
        } else {
            if current > benchmark * 1.1 {
                return .aboveAverage(difference)
            } else if current < benchmark * 0.9 {
                return .belowAverage(difference)
            } else {
                return .average
            }
        }
    }
} 