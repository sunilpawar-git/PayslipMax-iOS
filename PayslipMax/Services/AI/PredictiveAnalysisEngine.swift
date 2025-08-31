import Foundation
import SwiftData

/// Protocol for AI-powered predictive analysis of financial trends
protocol PredictiveAnalysisEngineProtocol {
    /// Predicts salary progression based on historical data
    func predictSalaryProgression(
        historicalPayslips: [Payslip],
        predictionMonths: Int
    ) async throws -> SalaryProgressionPrediction

    /// Analyzes allowance trends and forecasts future values
    func analyzeAllowanceTrends(
        historicalPayslips: [Payslip],
        targetAllowance: String
    ) async throws -> AllowanceTrendAnalysis

    /// Generates deduction optimization recommendations
    func generateDeductionOptimizations(
        currentPayslips: [Payslip],
        taxRegime: TaxRegime
    ) async throws -> DeductionOptimizationRecommendations

    /// Analyzes seasonal and policy-based variations in payslip data
    func analyzeSeasonalVariations(
        historicalPayslips: [Payslip],
        analysisPeriod: SeasonalAnalysisPeriod
    ) async throws -> SeasonalVariationAnalysis
}

/// Supported tax regimes for optimization
public enum TaxRegime {
    case oldRegime
    case newRegime
    case custom(rates: TaxRateStructure)
}

/// Tax rate structure for custom regime
public struct TaxRateStructure {
    let slab1: Double // 0-2.5L
    let slab2: Double // 2.5L-5L
    let slab3: Double // 5L-10L
    let slab4: Double // Above 10L
}

/// Time period for seasonal analysis
public enum SeasonalAnalysisPeriod {
    case quarterly
    case halfYearly
    case yearly
    case custom(months: Int)
}

/// Prediction of salary progression over time
public struct SalaryProgressionPrediction {
    let predictions: [SalaryPredictionPoint]
    let confidence: Double
    let trendDirection: TrendDirection
    let expectedAnnualGrowth: Double
    let riskFactors: [String]
}

/// Individual prediction point in salary progression
public struct SalaryPredictionPoint {
    let date: Date
    let predictedBasicPay: Double
    let predictedTotalCredits: Double
    let confidence: Double
    let influencingFactors: [String]
}

/// Direction of salary trend
public enum TrendDirection {
    case increasing(percentage: Double)
    case decreasing(percentage: Double)
    case stable
    case volatile
}

/// Analysis of allowance trends
public struct AllowanceTrendAnalysis {
    let allowanceName: String
    let historicalTrend: [TrendPoint]
    let forecast: [ForecastPoint]
    let seasonalityDetected: Bool
    let volatilityIndex: Double
    let recommendations: [String]
}

/// Point in historical trend
public struct TrendPoint {
    let date: Date
    let amount: Double
    let percentageOfBasic: Double
}

/// Forecast point for future allowance
public struct ForecastPoint {
    let date: Date
    let predictedAmount: Double
    let confidence: Double
    let probability: Double
}

/// Deduction optimization recommendations
public struct DeductionOptimizationRecommendations {
    let currentTaxEfficiency: Double
    let potentialSavings: Double
    let recommendations: [DeductionRecommendation]
    let priorityActions: [String]
    let riskAssessment: OptimizationRiskLevel
}

/// Individual deduction recommendation
public struct DeductionRecommendation {
    let deductionType: String
    let currentAmount: Double
    let recommendedAmount: Double
    let potentialSavings: Double
    let feasibility: RecommendationFeasibility
    let rationale: String
}

/// Feasibility of implementing a recommendation
public enum RecommendationFeasibility {
    case high
    case medium
    case low
}

/// Risk level for optimization recommendations
public enum OptimizationRiskLevel {
    case low
    case medium
    case high
}

/// Analysis of seasonal variations
public struct SeasonalVariationAnalysis {
    let detectedPatterns: [SeasonalPattern]
    let peakPeriods: [PeakPeriod]
    let anomalyPeriods: [AnomalyPeriod]
    let policyImpactAnalysis: [PolicyImpact]
    let recommendations: [String]
}

/// Detected seasonal pattern
public struct SeasonalPattern {
    let patternType: SeasonalPatternType
    let frequency: SeasonalFrequency
    let amplitude: Double
    let confidence: Double
    let affectedComponents: [String]
}

/// Type of seasonal pattern
public enum SeasonalPatternType {
    case allowanceIncrease
    case deductionSpike
    case bonusPayment
    case arrearsPayment
    case festivalAdvance

    /// Human-readable description of the pattern type
    public var description: String {
        switch self {
        case .allowanceIncrease:
            return "Allowance Increase"
        case .deductionSpike:
            return "Deduction Spike"
        case .bonusPayment:
            return "Bonus Payment"
        case .arrearsPayment:
            return "Arrears Payment"
        case .festivalAdvance:
            return "Festival Advance"
        }
    }
}

/// Frequency of seasonal pattern
public enum SeasonalFrequency {
    case monthly
    case quarterly
    case halfYearly
    case yearly
}

/// Period of peak activity
public struct PeakPeriod {
    let startMonth: Int
    let endMonth: Int
    let expectedIncrease: Double
    let affectedComponents: [String]
}

/// Period of anomalous activity
public struct AnomalyPeriod {
    let month: Int
    let deviation: Double
    let possibleCauses: [String]
    let severity: AnomalySeverity
}

/// Severity of anomaly
public enum AnomalySeverity {
    case minor
    case moderate
    case significant
    case critical
}

/// Impact of policy changes
public struct PolicyImpact {
    let policyName: String
    let effectiveDate: Date
    let expectedImpact: Double
    let affectedComponents: [String]
    let confidence: Double
}

/// AI-powered predictive analysis engine
@MainActor
public final class PredictiveAnalysisEngine: @preconcurrency PredictiveAnalysisEngineProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let calendar = Calendar.current

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Salary Progression Prediction

    func predictSalaryProgression(
        historicalPayslips: [Payslip],
        predictionMonths: Int
    ) async throws -> SalaryProgressionPrediction {

        guard !historicalPayslips.isEmpty else {
            throw PredictiveAnalysisError.insufficientData
        }

        let sortedPayslips = historicalPayslips.sorted { $0.timestamp < $1.timestamp }
        let predictions = try generateSalaryPredictions(
            from: sortedPayslips,
            months: predictionMonths
        )

        let trend = analyzeTrend(sortedPayslips)
        let growth = calculateAnnualGrowth(sortedPayslips)
        let risks = identifyRiskFactors(sortedPayslips)

        return SalaryProgressionPrediction(
            predictions: predictions,
            confidence: calculatePredictionConfidence(sortedPayslips),
            trendDirection: trend,
            expectedAnnualGrowth: growth,
            riskFactors: risks
        )
    }

    // MARK: - Allowance Trend Analysis

    func analyzeAllowanceTrends(
        historicalPayslips: [Payslip],
        targetAllowance: String
    ) async throws -> AllowanceTrendAnalysis {

        let allowanceData = extractAllowanceData(historicalPayslips, allowanceName: targetAllowance)

        guard !allowanceData.isEmpty else {
            throw PredictiveAnalysisError.insufficientData
        }

        let historicalTrend = allowanceData.map { point in
            TrendPoint(
                date: point.date,
                amount: point.amount,
                percentageOfBasic: point.percentageOfBasic
            )
        }

        let forecast = try generateAllowanceForecast(allowanceData, months: 12)
        let seasonality = detectSeasonality(allowanceData)
        let volatility = calculateVolatility(allowanceData.map { ($0.amount, $0.date) })
        let recommendations = generateAllowanceRecommendations(allowanceData, seasonality, volatility)

        return AllowanceTrendAnalysis(
            allowanceName: targetAllowance,
            historicalTrend: historicalTrend,
            forecast: forecast,
            seasonalityDetected: seasonality,
            volatilityIndex: volatility,
            recommendations: recommendations
        )
    }

    // MARK: - Deduction Optimization

    func generateDeductionOptimizations(
        currentPayslips: [Payslip],
        taxRegime: TaxRegime
    ) async throws -> DeductionOptimizationRecommendations {

        guard !currentPayslips.isEmpty else {
            throw PredictiveAnalysisError.insufficientData
        }

        let currentEfficiency = calculateTaxEfficiency(currentPayslips, taxRegime: taxRegime)
        let potentialSavings = calculatePotentialSavings(currentPayslips, taxRegime: taxRegime)
        let recommendations = generateDeductionRecommendations(currentPayslips, taxRegime: taxRegime)
        let priorities = identifyPriorityActions(recommendations)
        let risk = assessOptimizationRisk(currentPayslips, recommendations)

        return DeductionOptimizationRecommendations(
            currentTaxEfficiency: currentEfficiency,
            potentialSavings: potentialSavings,
            recommendations: recommendations,
            priorityActions: priorities,
            riskAssessment: risk
        )
    }

    // MARK: - Seasonal Variation Analysis

    func analyzeSeasonalVariations(
        historicalPayslips: [Payslip],
        analysisPeriod: SeasonalAnalysisPeriod
    ) async throws -> SeasonalVariationAnalysis {

        let monthsToAnalyze = monthsInPeriod(analysisPeriod)
        let patterns = detectSeasonalPatterns(historicalPayslips, months: monthsToAnalyze)
        let peaks = identifyPeakPeriods(historicalPayslips, months: monthsToAnalyze)
        let anomalies = detectAnomalies(historicalPayslips, months: monthsToAnalyze)
        let policyImpacts = analyzePolicyImpacts(historicalPayslips)
        let recommendations = generateSeasonalRecommendations(patterns, peaks, anomalies)

        return SeasonalVariationAnalysis(
            detectedPatterns: patterns,
            peakPeriods: peaks,
            anomalyPeriods: anomalies,
            policyImpactAnalysis: policyImpacts,
            recommendations: recommendations
        )
    }

    // MARK: - Private Helper Methods

    private func generateSalaryPredictions(
        from payslips: [Payslip],
        months: Int
    ) throws -> [SalaryPredictionPoint] {

        guard let latestPayslip = payslips.last else { return [] }

        var predictions: [SalaryPredictionPoint] = []
        let baseDate = latestPayslip.timestamp

        for monthOffset in 1...months {
            guard let predictionDate = calendar.date(byAdding: .month, value: monthOffset, to: baseDate) else {
                continue
            }

            let predictedBasic = predictBasicPay(payslips, forMonth: monthOffset)
            let predictedCredits = predictTotalCredits(payslips, forMonth: monthOffset)
            let confidence = calculateMonthlyConfidence(payslips, monthOffset: monthOffset)
            let factors = identifyInfluencingFactors(payslips, monthOffset: monthOffset)

            let prediction = SalaryPredictionPoint(
                date: predictionDate,
                predictedBasicPay: predictedBasic,
                predictedTotalCredits: predictedCredits,
                confidence: confidence,
                influencingFactors: factors
            )

            predictions.append(prediction)
        }

        return predictions
    }

    private func predictBasicPay(_ payslips: [Payslip], forMonth monthOffset: Int) -> Double {
        // Simple linear regression for basic pay progression
        guard payslips.count >= 2 else {
            return payslips.last?.basicPay ?? 0
        }

        let recentPayslips = payslips.suffix(min(12, payslips.count))
        let growthRate = calculateAverageGrowthRate(recentPayslips.map { ($0.timestamp, $0.basicPay) })

        if let lastPay = recentPayslips.last?.basicPay {
            return lastPay * pow(1 + growthRate, Double(monthOffset) / 12.0)
        }

        return 0
    }

    private func predictTotalCredits(_ payslips: [Payslip], forMonth monthOffset: Int) -> Double {
        guard let lastPayslip = payslips.last else { return 0 }

        let lastTotal = lastPayslip.basicPay + lastPayslip.allowances.reduce(0) { $0 + $1.amount }
        let growthRate = calculateAverageGrowthRate(
            payslips.map { ($0.timestamp, $0.basicPay + $0.allowances.reduce(0) { $0 + $1.amount }) }
        )

        return lastTotal * pow(1 + growthRate, Double(monthOffset) / 12.0)
    }

    private func calculateAverageGrowthRate(_ dataPoints: [(Date, Double)]) -> Double {
        guard dataPoints.count >= 2 else { return 0 }

        var totalGrowth = 0.0
        var validComparisons = 0

        for i in 1..<dataPoints.count {
            let (_, current) = dataPoints[i]
            let (_, previous) = dataPoints[i - 1]

            if previous > 0 {
                let growth = (current - previous) / previous
                totalGrowth += growth
                validComparisons += 1
            }
        }

        return validComparisons > 0 ? totalGrowth / Double(validComparisons) : 0
    }

    private func calculatePredictionConfidence(_ payslips: [Payslip]) -> Double {
        let dataPoints = payslips.count
        let timeSpan = calculateTimeSpan(payslips)

        // Confidence increases with more data points and longer time spans
        let dataConfidence = min(1.0, Double(dataPoints) / 24.0) // Max confidence at 24 months
        let timeConfidence = min(1.0, timeSpan / (365.0 * 2)) // Max confidence at 2 years

        return (dataConfidence + timeConfidence) / 2.0
    }

    private func calculateTimeSpan(_ payslips: [Payslip]) -> Double {
        guard let first = payslips.first?.timestamp,
              let last = payslips.last?.timestamp else { return 0 }

        return last.timeIntervalSince(first)
    }

    private func analyzeTrend(_ payslips: [Payslip]) -> TrendDirection {
        guard payslips.count >= 3 else { return .stable }

        let recent = Array(payslips.suffix(6))
        let growthRates = calculateGrowthRates(recent.map { $0.basicPay })

        let avgGrowth = growthRates.reduce(0, +) / Double(growthRates.count)
        let volatility = calculateVolatility(growthRates.map { ($0, Date()) })

        if abs(avgGrowth) < 0.005 { // Less than 0.5% monthly growth
            return .stable
        } else if volatility > 0.1 { // High volatility
            return .volatile
        } else if avgGrowth > 0 {
            return .increasing(percentage: avgGrowth * 12 * 100)
        } else {
            return .decreasing(percentage: abs(avgGrowth) * 12 * 100)
        }
    }

    private func calculateGrowthRates(_ values: [Double]) -> [Double] {
        guard values.count >= 2 else { return [] }

        var rates: [Double] = []
        for i in 1..<values.count {
            let growth = (values[i] - values[i-1]) / values[i-1]
            rates.append(growth)
        }

        return rates
    }

    private func calculateAnnualGrowth(_ payslips: [Payslip]) -> Double {
        guard payslips.count >= 12 else { return 0 }

        let yearlyPayslips = payslips.filter { calendar.component(.month, from: $0.timestamp) == 1 }
        guard yearlyPayslips.count >= 2 else { return 0 }

        let growthRate = calculateAverageGrowthRate(
            yearlyPayslips.map { ($0.timestamp, $0.basicPay) }
        )

        return growthRate * 100 // Convert to percentage
    }

    private func identifyRiskFactors(_ payslips: [Payslip]) -> [String] {
        var risks: [String] = []

        if payslips.count < 6 {
            risks.append("Limited historical data")
        }

        let volatility = calculateVolatility(
            payslips.map { ($0.basicPay, $0.timestamp) }
        )

        if volatility > 0.15 {
            risks.append("High salary volatility detected")
        }

        let recentTrend = analyzeTrend(payslips)
        if case .volatile = recentTrend {
            risks.append("Recent salary instability")
        }

        return risks
    }

    private func calculateMonthlyConfidence(_ payslips: [Payslip], monthOffset: Int) -> Double {
        let baseConfidence = calculatePredictionConfidence(payslips)
        let distancePenalty = 1.0 / (1.0 + Double(monthOffset) / 6.0) // Reduce confidence for distant predictions

        return baseConfidence * distancePenalty
    }

    private func identifyInfluencingFactors(_ payslips: [Payslip], monthOffset: Int) -> [String] {
        var factors: [String] = []

        if monthOffset <= 6 {
            factors.append("Recent salary trend")
        } else {
            factors.append("Long-term growth pattern")
        }

        if detectSeasonality(payslips.map { (date: $0.timestamp, amount: $0.basicPay, percentageOfBasic: 100.0) }) {
            factors.append("Seasonal variations")
        }

        return factors
    }

    private func extractAllowanceData(_ payslips: [Payslip], allowanceName: String) -> [(date: Date, amount: Double, percentageOfBasic: Double)] {
        payslips.compactMap { payslip in
            guard let allowance = payslip.allowances.first(where: { $0.name == allowanceName }) else {
                return nil
            }

            let percentage = payslip.basicPay > 0 ? allowance.amount / payslip.basicPay : 0

            return (payslip.timestamp, allowance.amount, percentage)
        }
    }

    private func generateAllowanceForecast(
        _ data: [(date: Date, amount: Double, percentageOfBasic: Double)],
        months: Int
    ) throws -> [ForecastPoint] {

        guard !data.isEmpty else { return [] }

        let lastDate = data.last!.date
        var forecast: [ForecastPoint] = []

        for monthOffset in 1...months {
            guard let forecastDate = calendar.date(byAdding: .month, value: monthOffset, to: lastDate) else {
                continue
            }

            let predictedAmount = predictAllowanceAmount(data, monthOffset: monthOffset)
            let confidence = calculateAllowanceConfidence(data, monthOffset: monthOffset)

            let forecastPoint = ForecastPoint(
                date: forecastDate,
                predictedAmount: predictedAmount,
                confidence: confidence,
                probability: confidence
            )

            forecast.append(forecastPoint)
        }

        return forecast
    }

    private func predictAllowanceAmount(
        _ data: [(date: Date, amount: Double, percentageOfBasic: Double)],
        monthOffset: Int
    ) -> Double {

        guard !data.isEmpty else { return 0 }

        let amounts = data.map { $0.amount }
        let growthRate = calculateAverageGrowthRate(
            data.map { ($0.date, $0.amount) }
        )

        let lastAmount = amounts.last!
        return lastAmount * pow(1 + growthRate, Double(monthOffset) / 12.0)
    }

    private func calculateAllowanceConfidence(
        _ data: [(date: Date, amount: Double, percentageOfBasic: Double)],
        monthOffset: Int
    ) -> Double {

        let dataPoints = Double(data.count)
        let baseConfidence = min(1.0, dataPoints / 12.0) // Max at 12 months of data
        let distancePenalty = 1.0 / (1.0 + Double(monthOffset) / 6.0)

        return baseConfidence * distancePenalty
    }

    private func detectSeasonality(_ data: [(date: Date, amount: Double, percentageOfBasic: Double)]) -> Bool {
        guard data.count >= 12 else { return false }

        // Simple seasonality detection based on quarterly patterns
        let quarterlyAverages = calculateQuarterlyAverages(data)

        if quarterlyAverages.count >= 4 {
            let variance = calculateVariance(quarterlyAverages)
            let mean = quarterlyAverages.reduce(0, +) / Double(quarterlyAverages.count)

            // If variance is significant relative to mean, seasonality is likely
            return variance / (mean * mean) > 0.1
        }

        return false
    }

    private func calculateQuarterlyAverages(_ data: [(date: Date, amount: Double, percentageOfBasic: Double)]) -> [Double] {
        let groupedByQuarter = Dictionary(grouping: data) { point in
            let components = calendar.dateComponents([.year, .month], from: point.date)
            let quarter = (components.month! - 1) / 3 + 1
            return "\(components.year!)-\(quarter)"
        }

        return groupedByQuarter.values.map { points in
            points.map { $0.amount }.reduce(0, +) / Double(points.count)
        }
    }

    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }

        return squaredDifferences.reduce(0, +) / Double(values.count)
    }

    private func calculateVolatility(_ data: [(Double, Date)]) -> Double {
        guard data.count >= 2 else { return 0 }

        let values = data.map { $0.0 }
        let returns = calculateGrowthRates(values)

        guard !returns.isEmpty else { return 0 }

        let meanReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - meanReturn, 2) }.reduce(0, +) / Double(returns.count)

        return sqrt(variance)
    }

    private func generateAllowanceRecommendations(
        _ data: [(date: Date, amount: Double, percentageOfBasic: Double)],
        _ seasonality: Bool,
        _ volatility: Double
    ) -> [String] {

        var recommendations: [String] = []

        if volatility > 0.2 {
            recommendations.append("High volatility detected - consider diversifying income sources")
        }

        if seasonality {
            recommendations.append("Seasonal patterns detected - plan for variable income months")
        }

        if data.count < 6 {
            recommendations.append("Limited historical data - continue tracking for better predictions")
        }

        let trend = analyzeTrend(data.map { Payslip(
            timestamp: $0.date,
            rank: "",
            serviceNumber: "",
            basicPay: $0.amount,
            allowances: [],
            deductions: [],
            netPay: $0.amount
        )})

        switch trend {
        case .increasing:
            recommendations.append("Positive trend detected - allowance is growing steadily")
        case .decreasing:
            recommendations.append("Declining trend detected - review allowance structure")
        case .volatile:
            recommendations.append("Volatile pattern - consider fixed allowance options")
        case .stable:
            recommendations.append("Stable allowance pattern - predictable income component")
        }

        return recommendations
    }

    private func calculateTaxEfficiency(_ payslips: [Payslip], taxRegime: TaxRegime) -> Double {
        guard !payslips.isEmpty else { return 0 }

        let taxRates = getTaxRates(for: taxRegime)
        var totalIncome = 0.0
        var totalTax = 0.0

        for payslip in payslips {
            let grossIncome = payslip.basicPay + payslip.allowances.reduce(0) { $0 + $1.amount }
            let deductions = payslip.deductions.reduce(0) { $0 + $1.amount }
            let taxableIncome = grossIncome - deductions

            totalIncome += grossIncome
            totalTax += calculateTax(taxableIncome, rates: taxRates)
        }

        return totalIncome > 0 ? (1 - totalTax / totalIncome) : 0
    }

    private func calculatePotentialSavings(_ payslips: [Payslip], taxRegime: TaxRegime) -> Double {
        // Simplified calculation - in real implementation would use detailed tax optimization
        let currentEfficiency = calculateTaxEfficiency(payslips, taxRegime: taxRegime)
        let optimalEfficiency = 0.85 // Assumed optimal tax efficiency

        guard let lastPayslip = payslips.last else { return 0 }

        let annualIncome = (lastPayslip.basicPay + lastPayslip.allowances.reduce(0) { $0 + $1.amount }) * 12
        let currentTax = annualIncome * (1 - currentEfficiency)
        let optimalTax = annualIncome * (1 - optimalEfficiency)

        return max(0, currentTax - optimalTax)
    }

    private func generateDeductionRecommendations(
        _ payslips: [Payslip],
        taxRegime: TaxRegime
    ) -> [DeductionRecommendation] {

        var recommendations: [DeductionRecommendation] = []

        // HRA optimization
        if let hraRecommendation = analyzeHRAOptimization(payslips) {
            recommendations.append(hraRecommendation)
        }

        // Section 80C optimization
        if let section80CRecommendation = analyzeSection80COptimization(payslips) {
            recommendations.append(section80CRecommendation)
        }

        // NPS optimization
        if let npsRecommendation = analyzeNPSOptimization(payslips) {
            recommendations.append(npsRecommendation)
        }

        return recommendations.sorted { $0.potentialSavings > $1.potentialSavings }
    }

    private func analyzeHRAOptimization(_ payslips: [Payslip]) -> DeductionRecommendation? {
        guard let lastPayslip = payslips.last else { return nil }

        let currentHRA = lastPayslip.allowances.first { $0.name.lowercased().contains("hra") }?.amount ?? 0
        let basicPay = lastPayslip.basicPay

        // HRA can be up to 50% of basic pay for metro cities, 40% for non-metro
        let maxHRA = basicPay * 0.5 // Assuming metro city
        let potentialAdditionalHRA = max(0, maxHRA - currentHRA)

        if potentialAdditionalHRA > 1000 { // Only recommend if significant savings
            let taxRate = 0.3 // Assumed tax rate
            let potentialSavings = potentialAdditionalHRA * taxRate

            return DeductionRecommendation(
                deductionType: "House Rent Allowance (HRA)",
                currentAmount: currentHRA,
                recommendedAmount: maxHRA,
                potentialSavings: potentialSavings,
                feasibility: .high,
                rationale: "HRA can be claimed up to 50% of basic pay. You're missing out on ₹\(String(format: "%.0f", potentialAdditionalHRA)) in tax-free HRA."
            )
        }

        return nil
    }

    private func analyzeSection80COptimization(_ payslips: [Payslip]) -> DeductionRecommendation? {
        // Simplified Section 80C analysis
        let max80C = 150000.0 // FY 2023-24 limit
        let current80C = calculateCurrent80CInvestments(payslips) // Calculate from actual data

        let potentialAdditional80C = max80C - current80C

        // Only recommend if there's meaningful additional investment opportunity
        guard potentialAdditional80C > 10000 && current80C < max80C * 0.8 else {
            return nil
        }

        let taxRate = 0.3
        let potentialSavings = potentialAdditional80C * taxRate

        return DeductionRecommendation(
            deductionType: "Section 80C Investments",
            currentAmount: current80C,
            recommendedAmount: max80C,
            potentialSavings: potentialSavings,
            feasibility: .medium,
            rationale: "Section 80C allows deductions up to ₹1.5L. Consider ELSS, PPF, or life insurance investments."
        )
    }

    private func analyzeNPSOptimization(_ payslips: [Payslip]) -> DeductionRecommendation? {
        // Simplified NPS analysis for government employees
        let maxNPS = 50000.0 // Additional deduction for NPS
        let currentNPS = calculateCurrentNPSContributions(payslips) // Calculate from actual data

        let potentialAdditionalNPS = maxNPS - currentNPS

        // Only recommend if there's meaningful additional contribution opportunity
        guard potentialAdditionalNPS > 5000 && currentNPS < maxNPS * 0.9 else {
            return nil
        }

        let taxRate = 0.3
        let potentialSavings = potentialAdditionalNPS * taxRate

        return DeductionRecommendation(
            deductionType: "National Pension System (NPS)",
            currentAmount: currentNPS,
            recommendedAmount: maxNPS,
            potentialSavings: potentialSavings,
            feasibility: .high,
            rationale: "Additional ₹50,000 deduction available under Section 80CCD(1B) for NPS contributions."
        )
    }

    private func getTaxRates(for taxRegime: TaxRegime) -> TaxRateStructure {
        switch taxRegime {
        case .oldRegime:
            return TaxRateStructure(slab1: 0.0, slab2: 0.05, slab3: 0.20, slab4: 0.30)
        case .newRegime:
            return TaxRateStructure(slab1: 0.0, slab2: 0.05, slab3: 0.10, slab4: 0.15)
        case .custom(let rates):
            return rates
        }
    }

    private func calculateTax(_ taxableIncome: Double, rates: TaxRateStructure) -> Double {
        // Simplified tax calculation - would need full tax slab logic in production
        if taxableIncome <= 250000 {
            return 0
        } else if taxableIncome <= 500000 {
            return (taxableIncome - 250000) * rates.slab2
        } else if taxableIncome <= 1000000 {
            return 250000 * rates.slab2 + (taxableIncome - 500000) * rates.slab3
        } else {
            return 250000 * rates.slab2 + 500000 * rates.slab3 + (taxableIncome - 1000000) * rates.slab4
        }
    }

    private func identifyPriorityActions(_ recommendations: [DeductionRecommendation]) -> [String] {
        let highImpact = recommendations.filter { $0.feasibility == .high && $0.potentialSavings > 10000 }
        let quickWins = recommendations.filter { $0.potentialSavings > 5000 }.prefix(3)

        var actions: [String] = []

        if !highImpact.isEmpty {
            actions.append("Focus on high-feasibility recommendations with >₹10K annual savings")
        }

        if quickWins.count >= 2 {
            actions.append("Multiple quick wins available - implement top 2-3 recommendations")
        }

        actions.append("Review current tax regime - New vs Old regime comparison")

        return actions
    }

    private func assessOptimizationRisk(
        _ payslips: [Payslip],
        _ recommendations: [DeductionRecommendation]
    ) -> OptimizationRiskLevel {

        let totalRecommendedChange = recommendations.reduce(0) { $0 + $1.potentialSavings }
        let annualIncome = payslips.last?.basicPay ?? 0 * 12

        let changePercentage = annualIncome > 0 ? totalRecommendedChange / annualIncome : 0

        if changePercentage < 0.05 {
            return .low
        } else if changePercentage < 0.15 {
            return .medium
        } else {
            return .high
        }
    }

    private func monthsInPeriod(_ period: SeasonalAnalysisPeriod) -> Int {
        switch period {
        case .quarterly: return 3
        case .halfYearly: return 6
        case .yearly: return 12
        case .custom(let months): return months
        }
    }

    private func detectSeasonalPatterns(
        _ payslips: [Payslip],
        months: Int
    ) -> [SeasonalPattern] {

        var patterns: [SeasonalPattern] = []

        // Detect bonus patterns (typically March/April)
        if detectBonusPattern(payslips) {
            patterns.append(SeasonalPattern(
                patternType: .bonusPayment,
                frequency: .yearly,
                amplitude: calculateBonusAmplitude(payslips),
                confidence: 0.8,
                affectedComponents: ["Basic Pay", "Allowances"]
            ))
        }

        // Detect festival advance patterns (typically October/November)
        if detectFestivalAdvancePattern(payslips) {
            patterns.append(SeasonalPattern(
                patternType: .festivalAdvance,
                frequency: .yearly,
                amplitude: calculateFestivalAdvanceAmplitude(payslips),
                confidence: 0.7,
                affectedComponents: ["Allowances", "Deductions"]
            ))
        }

        // Detect arrears payment patterns (irregular but significant)
        if detectArrearsPattern(payslips) {
            patterns.append(SeasonalPattern(
                patternType: .arrearsPayment,
                frequency: .halfYearly,
                amplitude: calculateArrearsAmplitude(payslips),
                confidence: 0.6,
                affectedComponents: ["Basic Pay", "Allowances"]
            ))
        }

        return patterns
    }

    private func detectBonusPattern(_ payslips: [Payslip]) -> Bool {
        let marchAprilPayslips = payslips.filter {
            let month = calendar.component(.month, from: $0.timestamp)
            return month == 3 || month == 4
        }

        guard !marchAprilPayslips.isEmpty else { return false }

        let averageBonusMonth = marchAprilPayslips.map { $0.basicPay }.reduce(0, +) / Double(marchAprilPayslips.count)
        let averageOtherMonths = payslips.filter {
            let month = calendar.component(.month, from: $0.timestamp)
            return month != 3 && month != 4
        }.map { $0.basicPay }.reduce(0, +) / Double(max(1, payslips.count - marchAprilPayslips.count))

        return averageBonusMonth > averageOtherMonths * 1.5 // 50% higher than normal
    }

    private func calculateBonusAmplitude(_ payslips: [Payslip]) -> Double {
        // Simplified amplitude calculation
        guard let maxPay = payslips.map({ $0.basicPay }).max(),
              let minPay = payslips.map({ $0.basicPay }).min(),
              minPay > 0 else { return 0 }

        return (maxPay - minPay) / minPay
    }

    private func detectFestivalAdvancePattern(_ payslips: [Payslip]) -> Bool {
        let octNovPayslips = payslips.filter {
            let month = calendar.component(.month, from: $0.timestamp)
            return month == 10 || month == 11
        }

        return !octNovPayslips.isEmpty
    }

    private func calculateFestivalAdvanceAmplitude(_ payslips: [Payslip]) -> Double {
        // Festival advances are typically smaller amounts
        return 0.1 // 10% of monthly pay
    }

    private func detectArrearsPattern(_ payslips: [Payslip]) -> Bool {
        // Look for significant payment spikes
        guard payslips.count >= 3 else { return false }

        for i in 1..<payslips.count {
            let current = payslips[i].basicPay
            let previous = payslips[i-1].basicPay

            if current > previous * 2 { // 100% increase
                return true
            }
        }

        return false
    }

    private func calculateArrearsAmplitude(_ payslips: [Payslip]) -> Double {
        // Arrears can be significant - up to 200% of normal pay
        return 2.0
    }

    private func identifyPeakPeriods(
        _ payslips: [Payslip],
        months: Int
    ) -> [PeakPeriod] {

        var peaks: [PeakPeriod] = []

        // Identify months with consistently higher payments
        let monthlyAverages = calculateMonthlyAverages(payslips)

        for (month, average) in monthlyAverages {
            let overallAverage = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)

            if average > overallAverage * 1.2 { // 20% above average
                peaks.append(PeakPeriod(
                    startMonth: month,
                    endMonth: month,
                    expectedIncrease: (average - overallAverage) / overallAverage,
                    affectedComponents: ["Basic Pay", "Allowances"]
                ))
            }
        }

        return peaks
    }

    private func calculateMonthlyAverages(_ payslips: [Payslip]) -> [Int: Double] {
        let groupedByMonth = Dictionary(grouping: payslips) {
            calendar.component(.month, from: $0.timestamp)
        }

        return groupedByMonth.mapValues { payslips in
            payslips.map { $0.basicPay }.reduce(0, +) / Double(payslips.count)
        }
    }

    private func detectAnomalies(
        _ payslips: [Payslip],
        months: Int
    ) -> [AnomalyPeriod] {

        var anomalies: [AnomalyPeriod] = []
        let monthlyAverages = calculateMonthlyAverages(payslips)
        let overallAverage = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)

        for (month, average) in monthlyAverages {
            let deviation = abs(average - overallAverage) / overallAverage

            if deviation > 0.5 { // 50% deviation
                let severity: AnomalySeverity = deviation > 1.0 ? .critical : deviation > 0.75 ? .significant : .moderate

                anomalies.append(AnomalyPeriod(
                    month: month,
                    deviation: deviation,
                    possibleCauses: identifyPossibleCauses(month, deviation),
                    severity: severity
                ))
            }
        }

        return anomalies
    }

    private func identifyPossibleCauses(_ month: Int, _ deviation: Double) -> [String] {
        var causes: [String] = []

        if month == 3 || month == 4 {
            causes.append("Annual bonus or arrears payment")
        }

        if month == 10 || month == 11 {
            causes.append("Festival advance")
        }

        if month >= 1 && month <= 3 {
            causes.append("Financial year-end adjustments")
        }

        if deviation > 1.0 {
            causes.append("Significant arrears or one-time payment")
        }

        if causes.isEmpty {
            causes.append("Unusual payment pattern - requires review")
        }

        return causes
    }

    private func analyzePolicyImpacts(_ payslips: [Payslip]) -> [PolicyImpact] {
        // This would analyze known policy changes and their impacts
        // For now, returning empty array as this requires domain-specific knowledge
        return []
    }

    private func generateSeasonalRecommendations(
        _ patterns: [SeasonalPattern],
        _ peaks: [PeakPeriod],
        _ anomalies: [AnomalyPeriod]
    ) -> [String] {

        var recommendations: [String] = []

        if !patterns.isEmpty {
            recommendations.append("Plan budget for seasonal payment patterns")
        }

        if !peaks.isEmpty {
            recommendations.append("Build emergency fund for peak spending periods")
        }

        if !anomalies.isEmpty {
            let criticalAnomalies = anomalies.filter { $0.severity == .critical }
            if !criticalAnomalies.isEmpty {
                recommendations.append("Review significant payment anomalies with finance department")
            }
        }

        if patterns.contains(where: { $0.patternType == .festivalAdvance }) {
            recommendations.append("Consider systematic investment plan for festival advance amounts")
        }

        return recommendations
    }

    /// Calculate current 80C investments from payslip data
    private func calculateCurrent80CInvestments(_ payslips: [Payslip]) -> Double {
        // This would analyze actual 80C investments from payslip deductions
        // For now, return a reasonable estimate based on typical investment patterns
        guard let latestPayslip = payslips.last else { return 0.0 }

        // Estimate based on typical deduction patterns
        let totalDeductions = latestPayslip.deductions.reduce(0) { $0 + $1.amount }
        let estimated80C = min(totalDeductions * 0.6, 120000.0) // Assume 60% of deductions are 80C eligible

        return estimated80C
    }

    /// Calculate current NPS contributions from payslip data
    private func calculateCurrentNPSContributions(_ payslips: [Payslip]) -> Double {
        // This would analyze actual NPS contributions from payslip data
        // For now, return a reasonable estimate based on typical government employee patterns
        guard let latestPayslip = payslips.last else { return 0.0 }

        // Estimate based on typical NPS contribution patterns (10% of basic pay)
        let estimatedNPS = latestPayslip.basicPay * 0.1 * 12 // Annual contribution
        let maxReasonable = 40000.0 // Don't assume unrealistic contributions

        return min(estimatedNPS, maxReasonable)
    }
}

/// Errors that can occur during predictive analysis
public enum PredictiveAnalysisError: Error {
    case insufficientData
    case invalidParameters
    case calculationError
}
