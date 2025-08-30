import Foundation
import SwiftData

/// Protocol for AI-powered insights generation
protocol AIInsightsGeneratorProtocol {
    /// Generates comprehensive financial insights from payslip data
    func generateFinancialInsights(
        payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> FinancialInsightsReport

    /// Creates personalized recommendations based on user patterns
    func generatePersonalizedRecommendations(
        payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> PersonalizedRecommendations

    /// Generates natural language explanations for financial data
    func generateNaturalLanguageExplanations(
        insights: [FinancialInsight],
        context: ExplanationContext
    ) async throws -> [NaturalLanguageExplanation]

    /// Prioritizes insights based on user context and importance
    func prioritizeInsights(
        insights: [FinancialInsight],
        userContext: UserContext
    ) async throws -> PrioritizedInsights
}

/// User profile information for personalization
public struct UserProfile {
    let riskTolerance: RiskTolerance
    let financialGoals: [AIFinancialGoal]
    let preferredInsightCategories: [AIInsightCategory]
    let experienceLevel: ExperienceLevel
    let notificationPreferences: NotificationPreferences
}

/// User's risk tolerance level
public enum RiskTolerance {
    case conservative
    case moderate
    case aggressive
}

/// Financial goals for personalization
public enum AIFinancialGoal: String {
    case wealthBuilding = "wealth building"
    case debtReduction = "debt reduction"
    case emergencyFund = "emergency fund"
    case retirementPlanning = "retirement planning"
    case taxOptimization = "tax optimization"
    case investmentPlanning = "investment planning"
}

/// Categories of insights
public enum AIInsightCategory {
    case income
    case expenses
    case taxes
    case investments
    case savings
    case trends
}

/// User experience level
public enum ExperienceLevel {
    case beginner
    case intermediate
    case advanced
}

/// Notification preferences
public struct NotificationPreferences {
    let insightAlerts: Bool
    let anomalyNotifications: Bool
    let monthlyReports: Bool
    let goalReminders: Bool
}

/// Comprehensive financial insights report
public struct FinancialInsightsReport {
    let executiveSummary: String
    let keyInsights: [FinancialInsight]
    let trendAnalysis: TrendAnalysis
    let riskAssessment: RiskAssessment
    let recommendations: [Recommendation]
    let generatedAt: Date
    let confidence: Double
}

/// Individual financial insight
public struct FinancialInsight {
    let id: String
    let category: AIInsightCategory
    let title: String
    let description: String
    let impact: InsightImpact
    let confidence: Double
    let supportingData: [ChartData]
    let timeframe: InsightTimeframe
    let actionable: Bool
}

/// Impact level of an insight
public enum InsightImpact {
    case low
    case medium
    case high
    case critical
}

/// Timeframe for insight relevance
public enum InsightTimeframe {
    case immediate
    case shortTerm // 1-3 months
    case mediumTerm // 3-12 months
    case longTerm // 1+ years
}

/// Trend analysis summary
public struct TrendAnalysis {
    let overallDirection: InsightTrendDirection
    let keyTrends: [KeyTrend]
    let seasonality: SeasonalityAnalysis
    let volatility: VolatilityAnalysis
}

/// Key trend identified
public struct KeyTrend {
    let metric: String
    let direction: InsightTrendDirection
    let magnitude: Double
    let period: String
    let significance: TrendSignificance
}

/// Direction of trend for insights
public enum InsightTrendDirection {
    case stronglyIncreasing
    case increasing
    case stable
    case decreasing
    case stronglyDecreasing
    case volatile
}

/// Significance of trend
public enum TrendSignificance {
    case minor
    case moderate
    case major
    case critical
}

/// Seasonality analysis
public struct SeasonalityAnalysis {
    let detected: Bool
    let patterns: [SeasonalPattern]
    let strength: Double
    let affectedMetrics: [String]
}

/// Volatility analysis
public struct VolatilityAnalysis {
    let overallVolatility: Double
    let riskLevel: VolatilityRiskLevel
    let mostVolatileMetrics: [String]
    let recommendations: [String]
}

/// Risk levels for volatility
public enum VolatilityRiskLevel {
    case low
    case moderate
    case high
    case extreme
}

/// Risk assessment summary
public struct RiskAssessment {
    let overallRisk: RiskLevel
    let riskFactors: [RiskFactor]
    let mitigationStrategies: [String]
    let riskTrend: RiskTrend
}

/// Risk levels
public enum RiskLevel {
    case low
    case moderate
    case high
    case critical
}

/// Individual risk factor
public struct RiskFactor {
    let factor: String
    let impact: RiskLevel
    let probability: Double
    let description: String
}

/// Risk trend over time
public enum RiskTrend {
    case improving
    case stable
    case worsening
}

/// Recommendation for user action
public struct Recommendation {
    let id: String
    let title: String
    let description: String
    let priority: AIRecommendationPriority
    let category: RecommendationCategory
    let effort: EffortLevel
    let potentialBenefit: String
    let timeframe: String
}

/// Priority of recommendation
public enum AIRecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
}

/// Category of recommendation
public enum RecommendationCategory {
    case taxPlanning
    case investment
    case savings
    case expenseManagement
    case riskManagement
    case goalPlanning
}

/// Effort required to implement recommendation
public enum EffortLevel {
    case minimal
    case moderate
    case significant
    case major
}

/// Personalized recommendations report
public struct PersonalizedRecommendations {
    let userSpecificRecommendations: [Recommendation]
    let goalAlignedRecommendations: [GoalRecommendation]
    let riskAdjustedSuggestions: [RiskAdjustedSuggestion]
    let learningBasedInsights: [AILearningInsight]
}

/// Goal-aligned recommendation
public struct GoalRecommendation {
    let goal: AIFinancialGoal
    let recommendations: [Recommendation]
    let progress: Double
    let nextSteps: [String]
}

/// Risk-adjusted suggestion
public struct RiskAdjustedSuggestion {
    let riskTolerance: RiskTolerance
    let suggestions: [Recommendation]
    let rationale: String
}

/// Learning-based insight for AI insights
public struct AILearningInsight {
    let pattern: String
    let insight: String
    let confidence: Double
    let actionableSteps: [String]
}

/// Natural language explanation
public struct NaturalLanguageExplanation {
    let insightId: String
    let explanation: String
    let simplifiedVersion: String?
    let keyTakeaways: [String]
    let relatedConcepts: [String]
}

/// Context for explanation generation
public enum ExplanationContext {
    case beginner
    case intermediate
    case expert
    case executive
}

/// User context for insight prioritization
public struct UserContext {
    let currentGoals: [AIFinancialGoal]
    let recentActions: [UserAction]
    let knowledgeLevel: ExperienceLevel
    let timeConstraints: TimeAvailability
    let riskTolerance: RiskTolerance
}

/// User action for context
public struct UserAction {
    let actionType: String
    let timestamp: Date
    let outcome: String?
}

/// User's time availability
public enum TimeAvailability {
    case limited
    case moderate
    case ample
}

/// Prioritized insights with ranking
public struct PrioritizedInsights {
    let topPriority: [FinancialInsight]
    let highPriority: [FinancialInsight]
    let mediumPriority: [FinancialInsight]
    let lowPriority: [FinancialInsight]
    let rationale: String
}

/// AI-powered insights generator
@MainActor
public final class AIInsightsGenerator: @preconcurrency AIInsightsGeneratorProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let calendar = Calendar.current

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Financial Insights Generation

    func generateFinancialInsights(
        payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> FinancialInsightsReport {

        guard !payslips.isEmpty else {
            throw AIInsightsError.insufficientData
        }

        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }

        // Generate key insights
        let keyInsights = try await generateKeyInsights(sortedPayslips, userProfile: userProfile)

        // Perform trend analysis
        let trendAnalysis = try await analyzeTrends(sortedPayslips)

        // Assess risks
        let riskAssessment = try await assessRisks(sortedPayslips)

        // Generate recommendations
        let recommendations = try await generateRecommendations(sortedPayslips, userProfile: userProfile)

        // Create executive summary
        let executiveSummary = generateExecutiveSummary(keyInsights, trendAnalysis, riskAssessment)

        return FinancialInsightsReport(
            executiveSummary: executiveSummary,
            keyInsights: keyInsights,
            trendAnalysis: trendAnalysis,
            riskAssessment: riskAssessment,
            recommendations: recommendations,
            generatedAt: Date(),
            confidence: calculateOverallConfidence(keyInsights)
        )
    }

    // MARK: - Personalized Recommendations

    func generatePersonalizedRecommendations(
        payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> PersonalizedRecommendations {

        guard !payslips.isEmpty else {
            throw AIInsightsError.insufficientData
        }

        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }

        // Generate user-specific recommendations
        let userSpecific = try await generateUserSpecificRecommendations(sortedPayslips, userProfile: userProfile)

        // Generate goal-aligned recommendations
        let goalAligned = try await generateGoalAlignedRecommendations(sortedPayslips, userProfile: userProfile)

        // Generate risk-adjusted suggestions
        let riskAdjusted = try await generateRiskAdjustedSuggestions(sortedPayslips, userProfile: userProfile)

        // Generate learning-based insights
        let learningBased = try await generateLearningBasedInsights(sortedPayslips, userProfile: userProfile)

        return PersonalizedRecommendations(
            userSpecificRecommendations: userSpecific,
            goalAlignedRecommendations: goalAligned,
            riskAdjustedSuggestions: riskAdjusted,
            learningBasedInsights: learningBased
        )
    }

    // MARK: - Natural Language Explanations

    public func generateNaturalLanguageExplanations(
        insights: [FinancialInsight],
        context: ExplanationContext
    ) async throws -> [NaturalLanguageExplanation] {

        var explanations: [NaturalLanguageExplanation] = []

        for insight in insights {
            let explanation = try await generateExplanation(for: insight, context: context)
            explanations.append(explanation)
        }

        return explanations
    }

    // MARK: - Insight Prioritization

    public func prioritizeInsights(
        insights: [FinancialInsight],
        userContext: UserContext
    ) async throws -> PrioritizedInsights {

        // Score each insight based on user context
        let scoredInsights = insights.map { insight in
            (insight, calculateInsightScore(insight, userContext: userContext))
        }.sorted { $0.1 > $1.1 }

        // Categorize by priority
        let topPriority = scoredInsights.filter { $0.1 >= 0.8 }.map { $0.0 }
        let highPriority = scoredInsights.filter { $0.1 >= 0.6 && $0.1 < 0.8 }.map { $0.0 }
        let mediumPriority = scoredInsights.filter { $0.1 >= 0.4 && $0.1 < 0.6 }.map { $0.0 }
        let lowPriority = scoredInsights.filter { $0.1 < 0.4 }.map { $0.0 }

        let rationale = generatePrioritizationRationale(userContext, insightCounts: (
            topPriority.count,
            highPriority.count,
            mediumPriority.count,
            lowPriority.count
        ))

        return PrioritizedInsights(
            topPriority: topPriority,
            highPriority: highPriority,
            mediumPriority: mediumPriority,
            lowPriority: lowPriority,
            rationale: rationale
        )
    }

    // MARK: - Private Helper Methods

    private func generateKeyInsights(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [FinancialInsight] {

        var insights: [FinancialInsight] = []

        // Income stability insight
        if let incomeStability = try await analyzeIncomeStability(payslips) {
            insights.append(incomeStability)
        }

        // Tax efficiency insight
        if let taxEfficiency = try await analyzeTaxEfficiency(payslips) {
            insights.append(taxEfficiency)
        }

        // Deduction optimization insight
        if let deductionOptimization = try await analyzeDeductionOptimization(payslips) {
            insights.append(deductionOptimization)
        }

        // Allowance utilization insight
        if let allowanceUtilization = try await analyzeAllowanceUtilization(payslips) {
            insights.append(allowanceUtilization)
        }

        // Net worth trend insight
        if let netWorthTrend = try await analyzeNetWorthTrend(payslips) {
            insights.append(netWorthTrend)
        }

        return insights
    }

    private func analyzeIncomeStability(_ payslips: [Payslip]) async throws -> FinancialInsight? {
        guard payslips.count >= 3 else { return nil }

        let netPays = payslips.map { $0.netPay }
        let volatility = calculateVolatility(netPays)

        let impact: InsightImpact
        let description: String

        if volatility < 0.05 {
            impact = .low
            description = "Your income shows excellent stability with minimal month-to-month variation."
        } else if volatility < 0.15 {
            impact = .medium
            description = "Your income is reasonably stable but shows some variation that could be planned for."
        } else {
            impact = .high
            description = "Your income shows significant variation that may require careful financial planning."
        }

        return FinancialInsight(
            id: "income_stability",
            category: .income,
            title: "Income Stability Analysis",
            description: description,
            impact: impact,
            confidence: 0.9,
            supportingData: generateStabilityChartData(payslips),
            timeframe: .mediumTerm,
            actionable: volatility >= 0.15
        )
    }

    private func analyzeTaxEfficiency(_ payslips: [Payslip]) async throws -> FinancialInsight? {
        guard !payslips.isEmpty else { return nil }

        let latestPayslip = payslips.last!
        let grossIncome = latestPayslip.basicPay + latestPayslip.allowances.reduce(0) { $0 + $1.amount }
        let totalDeductions = latestPayslip.deductions.reduce(0) { $0 + $1.amount }
        let taxableIncome = grossIncome - totalDeductions

        // Estimate tax (simplified calculation)
        let estimatedTax = calculateEstimatedTax(taxableIncome)
        let effectiveTaxRate = grossIncome > 0 ? estimatedTax / grossIncome : 0

        let impact: InsightImpact
        let description: String

        if effectiveTaxRate < 0.15 {
            impact = .low
            description = "Your tax planning is very effective with a low effective tax rate."
        } else if effectiveTaxRate < 0.25 {
            impact = .medium
            description = "Your tax situation is reasonable but there may be optimization opportunities."
        } else {
            impact = .high
            description = "Your effective tax rate is relatively high. Consider tax-saving investments or deductions."
        }

        return FinancialInsight(
            id: "tax_efficiency",
            category: .taxes,
            title: "Tax Efficiency Analysis",
            description: description,
            impact: impact,
            confidence: 0.85,
            supportingData: generateTaxChartData(payslips),
            timeframe: .shortTerm,
            actionable: effectiveTaxRate >= 0.25
        )
    }

    private func analyzeDeductionOptimization(_ payslips: [Payslip]) async throws -> FinancialInsight? {
        guard !payslips.isEmpty else { return nil }

        let latestPayslip = payslips.last!
        let totalDeductions = latestPayslip.deductions.reduce(0) { $0 + $1.amount }
        let grossIncome = latestPayslip.basicPay + latestPayslip.allowances.reduce(0) { $0 + $1.amount }

        let deductionRate = grossIncome > 0 ? totalDeductions / grossIncome : 0

        let impact: InsightImpact
        let description: String

        if deductionRate > 0.25 {
            impact = .low
            description = "Your deduction strategy is effective with a high deduction rate."
        } else if deductionRate > 0.15 {
            impact = .medium
            description = "Your deductions are reasonable but could potentially be increased."
        } else {
            impact = .high
            description = "Consider increasing your deductions through investments, insurance, or other eligible expenses."
        }

        return FinancialInsight(
            id: "deduction_optimization",
            category: .taxes,
            title: "Deduction Optimization",
            description: description,
            impact: impact,
            confidence: 0.8,
            supportingData: generateDeductionChartData(payslips),
            timeframe: .shortTerm,
            actionable: deductionRate <= 0.15
        )
    }

    private func analyzeAllowanceUtilization(_ payslips: [Payslip]) async throws -> FinancialInsight? {
        guard !payslips.isEmpty else { return nil }

        let latestPayslip = payslips.last!

        // Check for HRA utilization
        let hasHRA = latestPayslip.allowances.contains { $0.name.lowercased().contains("hra") }
        let hasConveyance = latestPayslip.allowances.contains { $0.name.lowercased().contains("conveyance") }

        var utilizationIssues: [String] = []

        if !hasHRA {
            utilizationIssues.append("missing HRA exemption")
        }

        if !hasConveyance {
            utilizationIssues.append("missing conveyance allowance")
        }

        if utilizationIssues.isEmpty {
            return FinancialInsight(
                id: "allowance_utilization",
                category: .income,
                title: "Allowance Utilization",
                description: "Your allowances are well-structured with good tax efficiency.",
                impact: .low,
                confidence: 0.9,
                supportingData: generateAllowanceChartData(latestPayslip),
                timeframe: .shortTerm,
                actionable: false
            )
        } else {
            return FinancialInsight(
                id: "allowance_utilization",
                category: .taxes,
                title: "Allowance Optimization Opportunity",
                description: "Consider claiming additional tax-free allowances: \(utilizationIssues.joined(separator: ", ")).",
                impact: .medium,
                confidence: 0.85,
                supportingData: generateAllowanceChartData(latestPayslip),
                timeframe: .shortTerm,
                actionable: true
            )
        }
    }

    private func analyzeNetWorthTrend(_ payslips: [Payslip]) async throws -> FinancialInsight? {
        guard payslips.count >= 6 else { return nil }

        // Calculate net income trend
        let netIncomes = payslips.map { $0.netPay }
        let trend = calculateTrend(netIncomes)

        let impact: InsightImpact
        let description: String

        switch trend.direction {
        case .stronglyIncreasing:
            impact = .low
            description = "Your net income is trending strongly upward, indicating positive financial momentum."
        case .increasing:
            impact = .low
            description = "Your net income is trending upward with steady growth."
        case .stable:
            impact = .medium
            description = "Your net income is stable. Consider strategies to increase earnings or reduce expenses."
        case .decreasing:
            impact = .high
            description = "Your net income is trending downward. Review expenses and consider income enhancement strategies."
        case .stronglyDecreasing:
            impact = .critical
            description = "Your net income is declining significantly. Immediate attention to financial planning is recommended."
        case .volatile:
            impact = .high
            description = "Your net income shows high volatility. Consider strategies to stabilize your income streams."
        }

        return FinancialInsight(
            id: "net_worth_trend",
            category: .trends,
            title: "Net Income Trend Analysis",
            description: description,
            impact: impact,
            confidence: 0.85,
            supportingData: generateTrendChartData(payslips),
            timeframe: .mediumTerm,
            actionable: trend.direction == .decreasing || trend.direction == .stronglyDecreasing
        )
    }

    private func analyzeTrends(_ payslips: [Payslip]) async throws -> TrendAnalysis {
        let netIncomes = payslips.map { $0.netPay }
        let overallTrend = calculateTrend(netIncomes)

        let keyTrends = [
            KeyTrend(
                metric: "Net Income",
                direction: overallTrend.direction,
                magnitude: overallTrend.magnitude,
                period: "Last \(payslips.count) months",
                significance: determineTrendSignificance(overallTrend.magnitude)
            )
        ]

        let seasonality = SeasonalityAnalysis(
            detected: detectSeasonality(payslips),
            patterns: [], // Would be populated with actual seasonal patterns
            strength: 0.7,
            affectedMetrics: ["Net Income", "Allowances"]
        )

        let volatility = VolatilityAnalysis(
            overallVolatility: calculateVolatility(netIncomes),
            riskLevel: .moderate,
            mostVolatileMetrics: ["Allowances", "Deductions"],
            recommendations: ["Consider building an emergency fund", "Diversify income sources"]
        )

        return TrendAnalysis(
            overallDirection: overallTrend.direction,
            keyTrends: keyTrends,
            seasonality: seasonality,
            volatility: volatility
        )
    }

    private func assessRisks(_ payslips: [Payslip]) async throws -> RiskAssessment {
        var riskFactors: [RiskFactor] = []

        // Income volatility risk
        let netIncomeVolatility = calculateVolatility(payslips.map { $0.netPay })
        if netIncomeVolatility > 0.2 {
            riskFactors.append(RiskFactor(
                factor: "High income volatility",
                impact: .high,
                probability: 0.8,
                description: "Significant month-to-month income variation increases financial uncertainty"
            ))
        }

        // Low savings rate risk
        if let savingsRate = calculateSavingsRate(payslips), savingsRate < 0.1 {
            riskFactors.append(RiskFactor(
                factor: "Low savings rate",
                impact: .moderate,
                probability: 0.9,
                description: "Current savings rate may not support long-term financial goals"
            ))
        }

        let overallRisk: RiskLevel = riskFactors.contains { $0.impact == .critical } ? .critical :
                         riskFactors.contains { $0.impact == .high } ? .high :
                         riskFactors.contains { $0.impact == .moderate } ? .moderate : .low

        return RiskAssessment(
            overallRisk: overallRisk,
            riskFactors: riskFactors,
            mitigationStrategies: generateMitigationStrategies(riskFactors),
            riskTrend: .stable
        )
    }

    private func generateRecommendations(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [Recommendation] {

        var recommendations: [Recommendation] = []

        // Emergency fund recommendation
        if let emergencyFundRec = generateEmergencyFundRecommendation(payslips) {
            recommendations.append(emergencyFundRec)
        }

        // Investment recommendation
        if let investmentRec = generateInvestmentRecommendation(payslips, userProfile: userProfile) {
            recommendations.append(investmentRec)
        }

        // Tax saving recommendation
        if let taxSavingRec = generateTaxSavingRecommendation(payslips) {
            recommendations.append(taxSavingRec)
        }

        return recommendations.sorted(by: { $0.priority.rawValue > $1.priority.rawValue })
    }

    // MARK: - Utility Methods

    private func calculateVolatility(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)

        return sqrt(variance) / mean // Coefficient of variation
    }

    private func calculateTrend(_ values: [Double]) -> (direction: InsightTrendDirection, magnitude: Double) {
        guard values.count >= 2 else { return (.stable, 0) }

        // Simple linear regression
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0.0) { $0 + Double($1) }
        let sumY = values.reduce(0, +)
        let sumXY = (0..<values.count).reduce(0.0) { $0 + Double($1) * values[$1] }
        let sumXX = (0..<values.count).reduce(0.0) { $0 + Double($1 * $1) }

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let magnitude = abs(slope) / (values.first ?? 1.0)

        let direction: InsightTrendDirection
        if slope > 0.01 {
            direction = magnitude > 0.05 ? .stronglyIncreasing : .increasing
        } else if slope < -0.01 {
            direction = magnitude > 0.05 ? .stronglyDecreasing : .decreasing
        } else {
            direction = .stable
        }

        return (direction, magnitude)
    }

    private func calculateEstimatedTax(_ taxableIncome: Double) -> Double {
        // Simplified tax calculation - would use actual tax slabs in production
        if taxableIncome <= 250000 {
            return 0
        } else if taxableIncome <= 500000 {
            return (taxableIncome - 250000) * 0.05
        } else if taxableIncome <= 1000000 {
            return 25000 + (taxableIncome - 500000) * 0.20
        } else {
            return 125000 + (taxableIncome - 1000000) * 0.30
        }
    }

    private func detectSeasonality(_ payslips: [Payslip]) -> Bool {
        guard payslips.count >= 12 else { return false }

        // Simple seasonality detection based on monthly patterns
        let monthlyAverages = Dictionary(grouping: payslips) {
            calendar.component(.month, from: $0.timestamp)
        }.mapValues { payslips in
            payslips.map { $0.netPay }.reduce(0, +) / Double(payslips.count)
        }

        let values = monthlyAverages.values.sorted()
        if let min = values.first, let max = values.last, min > 0 {
            return (max - min) / min > 0.15 // 15% variation indicates seasonality
        }

        return false
    }

    private func calculateSavingsRate(_ payslips: [Payslip]) -> Double? {
        guard let latest = payslips.last else { return nil }

        let netIncome = latest.netPay
        let estimatedExpenses = netIncome * 0.8 // Assume 80% of income is spent
        let savings = netIncome - estimatedExpenses

        return savings / netIncome
    }

    private func determineTrendSignificance(_ magnitude: Double) -> TrendSignificance {
        if magnitude > 0.2 { return .critical }
        else if magnitude > 0.1 { return .major }
        else if magnitude > 0.05 { return .moderate }
        else { return .minor }
    }

    // MARK: - Chart Data Generation Methods

    private func generateStabilityChartData(_ payslips: [Payslip]) -> [ChartData] {
        return payslips.map { payslip in
            let monthName = calendar.monthSymbols[calendar.component(.month, from: payslip.timestamp) - 1]
            return ChartData(
                label: monthName,
                value: payslip.netPay,
                category: "Net Income"
            )
        }
    }

    private func generateTaxChartData(_ payslips: [Payslip]) -> [ChartData] {
        return payslips.suffix(6).map { payslip in
            let monthName = calendar.monthSymbols[calendar.component(.month, from: payslip.timestamp) - 1]
            let gross = payslip.basicPay + payslip.allowances.reduce(0) { $0 + $1.amount }
            let deductions = payslip.deductions.reduce(0) { $0 + $1.amount }
            let taxable = gross - deductions
            return ChartData(
                label: monthName,
                value: taxable,
                category: "Taxable Income"
            )
        }
    }

    private func generateDeductionChartData(_ payslips: [Payslip]) -> [ChartData] {
        return payslips.suffix(6).map { payslip in
            let monthName = calendar.monthSymbols[calendar.component(.month, from: payslip.timestamp) - 1]
            let deductions = payslip.deductions.reduce(0) { $0 + $1.amount }
            return ChartData(
                label: monthName,
                value: deductions,
                category: "Deductions"
            )
        }
    }

    private func generateAllowanceChartData(_ payslip: Payslip) -> [ChartData] {
        return payslip.allowances.map { allowance in
            ChartData(
                label: allowance.name,
                value: allowance.amount,
                category: "Allowances"
            )
        }
    }

    private func generateTrendChartData(_ payslips: [Payslip]) -> [ChartData] {
        return payslips.map { payslip in
            let monthName = calendar.monthSymbols[calendar.component(.month, from: payslip.timestamp) - 1]
            return ChartData(
                label: monthName,
                value: payslip.netPay,
                category: "Net Income Trend"
            )
        }
    }

    // MARK: - Additional Helper Methods

    private func generateExecutiveSummary(
        _ insights: [FinancialInsight],
        _ trendAnalysis: TrendAnalysis,
        _ riskAssessment: RiskAssessment
    ) -> String {

        let highImpactInsights = insights.filter { $0.impact == .high || $0.impact == .critical }.count
        let trendDirection = trendAnalysis.overallDirection
        let riskLevel = riskAssessment.overallRisk

        var summary = "Your financial overview shows "

        switch trendDirection {
        case .stronglyIncreasing:
            summary += "strong positive momentum with increasing income trends. "
        case .increasing:
            summary += "steady growth in your financial position. "
        case .stable:
            summary += "financial stability with consistent performance. "
        case .decreasing:
            summary += "some challenges with declining trends that need attention. "
        case .stronglyDecreasing:
            summary += "significant challenges requiring immediate action. "
        case .volatile:
            summary += "high volatility that requires careful monitoring and stabilization strategies. "
        }

        if highImpactInsights > 0 {
            summary += "There are \(highImpactInsights) important insights requiring your attention. "
        }

        switch riskLevel {
        case .low:
            summary += "Your financial risk profile appears manageable."
        case .moderate:
            summary += "Consider reviewing your risk management strategies."
        case .high:
            summary += "Your financial situation carries elevated risks that should be addressed."
        case .critical:
            summary += "Immediate attention is needed to address critical financial risks."
        }

        return summary
    }

    private func calculateOverallConfidence(_ insights: [FinancialInsight]) -> Double {
        guard !insights.isEmpty else { return 0 }

        let totalConfidence = insights.reduce(0) { $0 + $1.confidence }
        return totalConfidence / Double(insights.count)
    }

    private func generateUserSpecificRecommendations(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [Recommendation] {

        // This would be customized based on user profile
        // For now, return general recommendations
        return try await generateRecommendations(payslips, userProfile: userProfile)
    }

    private func generateGoalAlignedRecommendations(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [GoalRecommendation] {

        guard let profile = userProfile else { return [] }

        return profile.financialGoals.map { goal in
            GoalRecommendation(
                goal: goal,
                recommendations: [], // Would be populated based on specific goal
                progress: 0.5, // Placeholder
                nextSteps: ["Define specific targets", "Track progress regularly"]
            )
        }
    }

    private func generateRiskAdjustedSuggestions(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [RiskAdjustedSuggestion] {

        let riskTolerance = userProfile?.riskTolerance ?? .moderate

        let suggestions = [
            Recommendation(
                id: "risk_adjusted_1",
                title: "Emergency Fund Building",
                description: "Build a robust emergency fund based on your risk tolerance",
                priority: .high,
                category: .savings,
                effort: .moderate,
                potentialBenefit: "Financial security and peace of mind",
                timeframe: "3-6 months"
            )
        ]

        return [RiskAdjustedSuggestion(
            riskTolerance: riskTolerance,
            suggestions: suggestions,
            rationale: "Based on your \(riskTolerance) risk tolerance, focus on stability and security"
        )]
    }

    private func generateLearningBasedInsights(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) async throws -> [AILearningInsight] {

        // This would analyze user behavior patterns
        return [
            AILearningInsight(
                pattern: "Consistent salary credits",
                insight: "Your income patterns are highly predictable",
                confidence: 0.9,
                actionableSteps: ["Set up automatic savings", "Plan major expenses around salary dates"]
            )
        ]
    }

    private func generateExplanation(
        for insight: FinancialInsight,
        context: ExplanationContext
    ) async throws -> NaturalLanguageExplanation {

        let explanation = generateContextualExplanation(insight, context: context)
        let simplified = context == .beginner ? generateSimplifiedExplanation(insight) : nil
        let takeaways = generateKeyTakeaways(insight)
        let concepts = generateRelatedConcepts(insight)

        return NaturalLanguageExplanation(
            insightId: insight.id,
            explanation: explanation,
            simplifiedVersion: simplified,
            keyTakeaways: takeaways,
            relatedConcepts: concepts
        )
    }

    private func generateContextualExplanation(_ insight: FinancialInsight, context: ExplanationContext) -> String {
        // Generate explanation based on user context
        switch context {
        case .beginner:
            return "Simply put, \(insight.description.lowercased()) This means you should consider taking action to improve your financial situation."
        case .intermediate:
            return insight.description + " This insight is based on analyzing your income patterns, expenses, and financial trends over time."
        case .expert:
            return insight.description + " The analysis uses statistical methods to identify patterns in your financial data and provides actionable recommendations."
        case .executive:
            return "Executive Summary: \(insight.title) - \(insight.description) Recommended action: Review and implement suggested improvements."
        }
    }

    private func generateSimplifiedExplanation(_ insight: FinancialInsight) -> String {
        return "In simple terms: \(insight.description.lowercased())"
    }

    private func generateKeyTakeaways(_ insight: FinancialInsight) -> [String] {
        return [
            insight.title,
            insight.description,
            "Impact level: \(insight.impact)",
            "Action needed: \(insight.actionable ? "Yes" : "Monitor only")"
        ]
    }

    private func generateRelatedConcepts(_ insight: FinancialInsight) -> [String] {
        switch insight.category {
        case .income:
            return ["Income stability", "Salary progression", "Bonus patterns"]
        case .taxes:
            return ["Tax brackets", "Deductions", "Tax planning"]
        case .expenses:
            return ["Budgeting", "Expense tracking", "Cost optimization"]
        case .investments:
            return ["Portfolio diversification", "Risk assessment", "Returns"]
        case .savings:
            return ["Emergency fund", "Savings rate", "Financial goals"]
        case .trends:
            return ["Trend analysis", "Forecasting", "Pattern recognition"]
        }
    }

    private func calculateInsightScore(_ insight: FinancialInsight, userContext: UserContext) -> Double {
        var score = 0.0

        // Impact weight
        switch insight.impact {
        case .critical: score += 0.4
        case .high: score += 0.3
        case .medium: score += 0.2
        case .low: score += 0.1
        }

        // Goal alignment
        if userContext.currentGoals.contains(where: { goal in
            insight.category == .income && goal == .wealthBuilding ||
            insight.category == .taxes && goal == .taxOptimization ||
            insight.category == .investments && goal == .investmentPlanning
        }) {
            score += 0.2
        }

        // Experience level adjustment
        switch userContext.knowledgeLevel {
        case .beginner:
            score += insight.actionable ? 0.1 : 0.05
        case .intermediate:
            score += 0.1
        case .advanced:
            score += insight.confidence * 0.1
        }

        // Time availability
        if userContext.timeConstraints == .limited && insight.timeframe == .immediate {
            score += 0.1
        }

        return min(score, 1.0)
    }

    private func generatePrioritizationRationale(
        _ userContext: UserContext,
        insightCounts: (top: Int, high: Int, medium: Int, low: Int)
    ) -> String {

        return "Prioritized \(insightCounts.top) top-priority insights based on your \(userContext.currentGoals.first?.rawValue ?? "financial goals"), \(userContext.knowledgeLevel) experience level, and \(userContext.riskTolerance) risk tolerance. Focus on high-impact items first for maximum benefit."
    }

    private func generateMitigationStrategies(_ riskFactors: [RiskFactor]) -> [String] {
        return riskFactors.map { factor in
            switch factor.factor {
            case "High income volatility":
                return "Build emergency fund covering 6-12 months of expenses"
            case "Low savings rate":
                return "Set up automatic savings transfers and track expenses diligently"
            default:
                return "Review financial planning with professional advisor"
            }
        }
    }

    private func generateEmergencyFundRecommendation(_ payslips: [Payslip]) -> Recommendation? {
        guard !payslips.isEmpty else { return nil }

        return Recommendation(
            id: "emergency_fund",
            title: "Build Emergency Fund",
            description: "Establish a 6-month emergency fund based on your average monthly income",
            priority: .high,
            category: .savings,
            effort: .moderate,
            potentialBenefit: "Financial security during unexpected events",
            timeframe: "3-6 months"
        )
    }

    private func generateInvestmentRecommendation(
        _ payslips: [Payslip],
        userProfile: UserProfile?
    ) -> Recommendation? {

        let riskTolerance = userProfile?.riskTolerance ?? .moderate

        return Recommendation(
            id: "investment_planning",
            title: "Start Systematic Investment Plan",
            description: "Begin investing 20-30% of your income based on your \(riskTolerance) risk tolerance",
            priority: .medium,
            category: .investment,
            effort: .moderate,
            potentialBenefit: "Long-term wealth creation through compound growth",
            timeframe: "Ongoing"
        )
    }

    private func generateTaxSavingRecommendation(_ payslips: [Payslip]) -> Recommendation? {
        return Recommendation(
            id: "tax_saving",
            title: "Optimize Tax Savings",
            description: "Maximize tax deductions through eligible investments and expenses",
            priority: .high,
            category: .taxPlanning,
            effort: .moderate,
            potentialBenefit: "Significant tax savings and better financial planning",
            timeframe: "Immediate"
        )
    }
}

// Extension for average calculation removed - using existing implementation

/// Errors that can occur during AI insights generation
public enum AIInsightsError: Error {
    case insufficientData
    case invalidInput
    case calculationError
}
