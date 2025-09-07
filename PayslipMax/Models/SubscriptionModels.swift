import Foundation

// MARK: - Core Subscription Models

/// Represents a subscription tier with pricing and features
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

/// Represents a premium feature with usage limits and access control
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

// MARK: - Subscription Error Handling

/// Errors that can occur during subscription operations
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

// MARK: - Feature Access Results

/// Result of checking feature access for a user
enum FeatureAccessResult {
    case granted
    case limited(remaining: Int)
    case limitReached(Int)
    case requiresSubscription
}
