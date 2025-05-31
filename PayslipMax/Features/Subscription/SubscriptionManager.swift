import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var isPremiumUser = false
    @Published var currentSubscription: SubscriptionTier?
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Subscription Tiers
    
    private let subscriptionTiers: [SubscriptionTier] = [
        SubscriptionTier(
            id: "payslipmax_premium_monthly",
            name: "Premium Monthly",
            price: 299.0,
            features: PremiumFeatures.allPremiumFeatures,
            analysisDepth: .professional,
            updateFrequency: .weekly,
            supportLevel: .priority
        ),
        SubscriptionTier(
            id: "payslipmax_premium_yearly",
            name: "Premium Yearly",
            price: 2999.0,
            features: PremiumFeatures.allPremiumFeatures,
            analysisDepth: .professional,
            updateFrequency: .weekly,
            supportLevel: .priority
        ),
        SubscriptionTier(
            id: "payslipmax_pro_monthly",
            name: "Pro Monthly",
            price: 599.0,
            features: PremiumFeatures.allProFeatures,
            analysisDepth: .enterprise,
            updateFrequency: .daily,
            supportLevel: .dedicated
        )
    ]
    
    // MARK: - Feature Usage Tracking
    @Published var featureUsage: [String: Int] = [:]
    private let maxFreeInsights = 3
    private let maxFreeAnalyses = 1
    
    private init() {
        loadSubscriptionState()
        setupStoreKit()
    }
    
    // MARK: - Public Methods
    
    func checkFeatureAccess(_ feature: PremiumInsightFeature) -> FeatureAccessResult {
        if isPremiumUser {
            return .granted
        }
        
        // Check usage limits for free users
        let currentUsage = featureUsage[feature.id] ?? 0
        
        if let limit = feature.usageLimit, currentUsage >= limit {
            return .limitReached(limit)
        }
        
        return .limited(remaining: (feature.usageLimit ?? 0) - currentUsage)
    }
    
    func useFeature(_ feature: PremiumInsightFeature) {
        let currentUsage = featureUsage[feature.id] ?? 0
        featureUsage[feature.id] = currentUsage + 1
        saveUsageData()
    }
    
    func subscribeTo(_ tier: SubscriptionTier) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In a real app, this would use StoreKit 2
            try await performPurchase(tier)
            isPremiumUser = true
            currentSubscription = tier
            saveSubscriptionState()
        } catch {
            self.error = SubscriptionError.purchaseFailed(error.localizedDescription)
            throw error
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        // In a real app, this would restore purchases through StoreKit
        // For demo purposes, we'll simulate restoration
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        } catch {
            // Handle cancellation gracefully
            return
        }
        
        // Check if user previously had subscription
        if userDefaults.bool(forKey: "had_premium_subscription") {
            isPremiumUser = true
            currentSubscription = subscriptionTiers.first
            saveSubscriptionState()
        }
    }
    
    func cancelSubscription() async {
        isLoading = true
        defer { isLoading = false }
        
        // In a real app, this would handle cancellation through App Store
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        } catch {
            // Handle cancellation gracefully
            return
        }
        
        isPremiumUser = false
        currentSubscription = nil
        saveSubscriptionState()
    }
    
    // MARK: - Feature Access Helpers
    
    var canAccessAdvancedAnalytics: Bool {
        isPremiumUser
    }
    
    var canAccessPredictiveInsights: Bool {
        isPremiumUser
    }
    
    var canAccessProfessionalRecommendations: Bool {
        isPremiumUser
    }
    
    var canAccessBenchmarkData: Bool {
        isPremiumUser
    }
    
    var canAccessGoalTracking: Bool {
        isPremiumUser
    }
    
    var remainingFreeInsights: Int {
        if isPremiumUser { return Int.max }
        return max(0, maxFreeInsights - (featureUsage["free_insights"] ?? 0))
    }
    
    var remainingFreeAnalyses: Int {
        if isPremiumUser { return Int.max }
        return max(0, maxFreeAnalyses - (featureUsage["free_analyses"] ?? 0))
    }
    
    // MARK: - Private Methods
    
    private func setupStoreKit() {
        // In a real app, configure StoreKit here
        // For demo purposes, we'll use UserDefaults
    }
    
    private func performPurchase(_ tier: SubscriptionTier) async throws {
        // Simulate purchase process
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        } catch {
            throw SubscriptionError.userCancelled
        }
        
        // For demo, randomly succeed/fail
        if Bool.random() && false { // Always succeed for demo
            throw SubscriptionError.purchaseFailed("Payment was declined")
        }
        
        // Mark as purchased in UserDefaults for demo
        userDefaults.set(true, forKey: "had_premium_subscription")
    }
    
    private func loadSubscriptionState() {
        isPremiumUser = userDefaults.bool(forKey: "is_premium_user")
        
        if let tierData = userDefaults.data(forKey: "current_subscription"),
           let tier = try? JSONDecoder().decode(SubscriptionTier.self, from: tierData) {
            currentSubscription = tier
        }
        
        if let usageData = userDefaults.data(forKey: "feature_usage"),
           let usage = try? JSONDecoder().decode([String: Int].self, from: usageData) {
            featureUsage = usage
        }
    }
    
    private func saveSubscriptionState() {
        userDefaults.set(isPremiumUser, forKey: "is_premium_user")
        
        if let subscription = currentSubscription,
           let tierData = try? JSONEncoder().encode(subscription) {
            userDefaults.set(tierData, forKey: "current_subscription")
        }
    }
    
    private func saveUsageData() {
        if let usageData = try? JSONEncoder().encode(featureUsage) {
            userDefaults.set(usageData, forKey: "feature_usage")
        }
    }
}

// MARK: - Supporting Types

enum FeatureAccessResult {
    case granted
    case limited(remaining: Int)
    case limitReached(Int)
    case requiresSubscription
}

enum SubscriptionError: LocalizedError {
    case purchaseFailed(String)
    case restoreFailed(String)
    case notAvailable
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .notAvailable:
            return "Subscription not available"
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}

// MARK: - Premium Features Configuration

struct PremiumFeatures {
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
        )
    ]
    
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

// MARK: - Extensions

extension PremiumInsightFeature.FeatureCategory {
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

// MARK: - Subscription Pricing Helper

extension SubscriptionManager {
    var availableSubscriptions: [SubscriptionTier] {
        return subscriptionTiers
    }
    
    func formattedPrice(for tier: SubscriptionTier) -> String {
        return "₹\(Int(tier.price))"
    }
    
    func monthlyEquivalent(for tier: SubscriptionTier) -> String {
        if tier.id.contains("yearly") {
            let monthlyPrice = tier.price / 12
            return "₹\(Int(monthlyPrice))/month"
        }
        return "₹\(Int(tier.price))/month"
    }
    
    func savings(for yearlyTier: SubscriptionTier, comparedTo monthlyTier: SubscriptionTier) -> String {
        let yearlyEquivalent = monthlyTier.price * 12
        let savings = yearlyEquivalent - yearlyTier.price
        let percentage = (savings / yearlyEquivalent) * 100
        return "\(Int(percentage))% off"
    }
} 