import Foundation

// MARK: - Premium Features Configuration

/// Configuration for premium and free features available in the app
struct PremiumFeatures {
    /// All premium features available in the Pro subscription
    static let allPremiumFeatures: [PremiumInsightFeature] = [
        PremiumInsightFeature(
            id: "advanced_analytics",
            name: "Advanced Analytics",
            description: "Detailed financial health scoring and trend analysis",
            category: .analytics,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "predictive_insights",
            name: "Predictive Insights",
            description: "AI-powered predictions for salary growth and financial trends",
            category: .predictions,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "professional_recommendations",
            name: "Professional Recommendations",
            description: "Expert advice on tax optimization and career growth",
            category: .recommendations,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "benchmark_comparisons",
            name: "Industry Benchmarks",
            description: "Compare your salary and benefits with industry standards",
            category: .comparisons,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "goal_tracking",
            name: "Financial Goal Tracking",
            description: "Set and track financial milestones and savings goals",
            category: .goalTracking,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "tax_optimization",
            name: "Tax Optimization",
            description: "Advanced tax planning strategies and optimization tips",
            category: .taxOptimization,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "xray_salary",
            name: "X-Ray Salary",
            description: "Visual month-to-month payslip comparisons with smart change indicators",
            category: .comparisons,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        )
    ]

    /// All features available in the Pro subscription (premium + additional pro features)
    static let allProFeatures: [PremiumInsightFeature] = allPremiumFeatures + [
        PremiumInsightFeature(
            id: "market_intelligence",
            name: "Market Intelligence",
            description: "Real-time market data and economic indicators",
            category: .marketIntelligence,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "custom_reports",
            name: "Custom Reports",
            description: "Generate detailed financial reports and export data",
            category: .analytics,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: nil,
            currentUsage: 0
        )
    ]

    /// Free features available to all users
    static let freeFeatures: [PremiumInsightFeature] = [
        PremiumInsightFeature(
            id: "basic_insights",
            name: "Basic Insights",
            description: "Simple income and deduction summaries",
            category: .analytics,
            isEnabled: true,
            requiresSubscription: false,
            usageLimit: 5,
            currentUsage: 0
        ),
        PremiumInsightFeature(
            id: "basic_charts",
            name: "Basic Charts",
            description: "Simple visualization of your payslip data",
            category: .analytics,
            isEnabled: true,
            requiresSubscription: false,
            usageLimit: 10,
            currentUsage: 0
        )
    ]
}

// MARK: - Feature Category Extensions

extension PremiumInsightFeature.FeatureCategory {
    /// User-friendly display name for the category
    var displayName: String {
        switch self {
        case .analytics: return "Analytics"
        case .predictions: return "Predictions"
        case .recommendations: return "Recommendations"
        case .comparisons: return "Comparisons"
        case .goalTracking: return "Goal Tracking"
        case .marketIntelligence: return "Market Intelligence"
        case .taxOptimization: return "Tax Optimization"
        }
    }

    /// SF Symbol icon name for the category
    var icon: String {
        switch self {
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .predictions: return "crystal.ball"
        case .recommendations: return "lightbulb"
        case .comparisons: return "chart.bar.xaxis"
        case .goalTracking: return "target"
        case .marketIntelligence: return "globe"
        case .taxOptimization: return "percent"
        }
    }
}
