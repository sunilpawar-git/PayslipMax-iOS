import Foundation
import SwiftUI

// MARK: - Financial Health Models

struct FinancialHealthScore {
    let overallScore: Double // 0-100
    let categories: [HealthCategory]
    let trend: ScoreTrend
    let lastUpdated: Date
    
    enum ScoreTrend {
        case improving(Double)
        case declining(Double)
        case stable
    }
}

struct HealthCategory {
    let name: String
    let score: Double // 0-100
    let weight: Double // Importance weight
    let status: HealthStatus
    let recommendation: String
    let actionItems: [ActionItem]
    
    enum HealthStatus {
        case excellent, good, fair, poor, critical
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return Color(.systemBlue)
            case .fair: return .orange
            case .poor: return Color(.systemRed)
            case .critical: return Color(.systemPurple)
            }
        }
    }
}

struct ActionItem {
    let title: String
    let description: String
    let priority: Priority
    let category: ActionCategory
    let estimatedImpact: Double // Potential score improvement
    let timeframe: String
    
    enum Priority {
        case high, medium, low
    }
    
    enum ActionCategory {
        case budgeting, savings, tax, investments, debt, career
    }
}

// MARK: - Predictive Analytics Models

struct PredictiveInsight: Identifiable {
    let id: UUID = UUID()
    let type: PredictionType
    let title: String
    let description: String
    let confidence: Double // 0-1
    let timeframe: PredictionTimeframe
    let expectedValue: Double?
    let recommendation: String
    let riskLevel: RiskLevel
    
    enum PredictionType {
        case salaryGrowth, taxProjection, savingsGoal, retirementReadiness
        case bonusExpectation, deductionChanges, netIncomeProjection
    }
    
    enum PredictionTimeframe {
        case nextMonth, nextQuarter, nextYear, fiveYears
    }
    
    enum RiskLevel {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange  
            case .high: return .red
            }
        }
    }
}

// MARK: - Professional Recommendations

struct ProfessionalRecommendation: Identifiable {
    let id: UUID = UUID()
    let category: RecommendationCategory
    let title: String
    let summary: String
    let detailedAnalysis: String
    let actionSteps: [String]
    let potentialSavings: Double?
    let priority: Priority
    let source: RecommendationSource
    
    enum RecommendationCategory {
        case taxOptimization, careerGrowth, investmentStrategy
        case retirementPlanning, emergencyFund, debtManagement
        case salaryNegotiation, benefitsOptimization
    }
    
    enum Priority {
        case critical, high, medium, low
    }
    
    enum RecommendationSource {
        case aiAnalysis, industryBenchmark, regulatoryChange, userPattern
    }
}

// MARK: - Advanced Metrics

struct AdvancedMetrics {
    // Income Stability & Growth
    let incomeVolatility: Double
    let yearOverYearGrowth: Double
    let monthlyGrowthRate: Double
    let incomeStabilityScore: Double
    
    // Tax Efficiency
    let effectiveTaxRate: Double
    let taxOptimizationScore: Double
    let potentialTaxSavings: Double
    
    // Financial Ratios
    let savingsRate: Double
    let deductionToIncomeRatio: Double
    let netIncomeGrowthRate: Double
    
    // Career Progression
    let salaryBenchmarkPercentile: Double?
    let careerProgressionScore: Double?
    
    // Risk Indicators
    let financialRiskScore: Double
    let incomeConcentrationRisk: Double
}

// MARK: - Comparative Analysis

struct BenchmarkData {
    let category: BenchmarkCategory
    let userValue: Double
    let benchmarkValue: Double
    let percentile: Double
    let comparison: ComparisonResult
    
    enum BenchmarkCategory {
        case salary, taxRate, savingsRate, benefits
        case growthRate, totalCompensation
    }
    
    enum ComparisonResult {
        case aboveAverage(Double)
        case average
        case belowAverage(Double)
        
        var description: String {
            switch self {
            case .aboveAverage(let percentage):
                return "\(Int(percentage))% above average"
            case .average:
                return "At average level"
            case .belowAverage(let percentage):
                return "\(Int(percentage))% below average"
            }
        }
    }
}

// MARK: - Goal Tracking

struct FinancialGoal: Identifiable {
    let id: UUID = UUID()
    let type: GoalType
    let title: String
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: Date
    let category: GoalCategory
    let isAchievable: Bool
    let recommendedMonthlyContribution: Double
    let projectedAchievementDate: Date?
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    enum GoalType {
        case savings, investment, emergencyFund, retirementContribution
        case debtPayoff, majorPurchase, education
    }
    
    enum GoalCategory {
        case shortTerm, mediumTerm, longTerm
    }
}

// MARK: - Market Intelligence

struct MarketIntelligence {
    let industryTrends: [IndustryTrend]
    let salaryBenchmarks: [SalaryBenchmark]
    let economicIndicators: [EconomicIndicator]
    let regulatoryUpdates: [RegulatoryUpdate]
    
    struct IndustryTrend {
        let industry: String
        let trend: String
        let impact: String
        let relevanceScore: Double
    }
    
    struct SalaryBenchmark {
        let role: String
        let experience: String
        let location: String
        let medianSalary: Double
        let growthProjection: Double
    }
    
    struct EconomicIndicator {
        let name: String
        let value: Double
        let trend: String
        let impact: String
    }
    
    struct RegulatoryUpdate {
        let title: String
        let description: String
        let effectiveDate: Date
        let impact: String
    }
}

// MARK: - Premium Feature Models

struct PremiumInsightFeature: Codable {
    let id: String
    let name: String
    let description: String
    let category: FeatureCategory
    let isEnabled: Bool
    let requiresSubscription: Bool
    let usageLimit: Int?
    let currentUsage: Int
    
    enum FeatureCategory: Codable {
        case analytics, predictions, recommendations, comparisons
        case goalTracking, marketIntelligence, taxOptimization
    }
}

struct SubscriptionTier: Codable {
    let id: String
    let name: String
    let price: Double
    let features: [PremiumInsightFeature]
    let analysisDepth: AnalysisDepth
    let updateFrequency: UpdateFrequency
    let supportLevel: SupportLevel
    
    enum AnalysisDepth: Codable {
        case basic, standard, professional, enterprise
    }
    
    enum UpdateFrequency: Codable {
        case monthly, weekly, daily, realTime
    }
    
    enum SupportLevel: Codable {
        case basic, priority, dedicated
    }
} 