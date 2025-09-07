import Foundation
import Combine

// MARK: - Subscription Validator Protocol

/// Protocol defining feature access validation and usage tracking
@MainActor
protocol SubscriptionValidatorProtocol {
    /// Check feature access for a specific feature
    /// - Parameter feature: The feature to check access for
    /// - Returns: Access result indicating granted, limited, or denied
    func checkFeatureAccess(_ feature: PremiumInsightFeature) async -> FeatureAccessResult

    /// Record usage of a feature
    /// - Parameter feature: The feature that was used
    func recordFeatureUsage(_ feature: PremiumInsightFeature) async

    /// Get remaining usage for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: Remaining usage count
    func getRemainingUsage(for feature: PremiumInsightFeature) async -> Int

    /// Reset usage tracking (typically for new billing period)
    func resetUsageTracking() async

    /// Observable feature usage data
    var featureUsagePublisher: AnyPublisher<[String: Int], Never> { get }

    // MARK: - Feature Access Helpers

    /// Check if user can access advanced analytics
    func canAccessAdvancedAnalytics() -> Bool

    /// Check if user can access predictive insights
    func canAccessPredictiveInsights() -> Bool

    /// Check if user can access professional recommendations
    func canAccessProfessionalRecommendations() -> Bool

    /// Check if user can access benchmark data
    func canAccessBenchmarkData() -> Bool

    /// Check if user can access goal tracking
    func canAccessGoalTracking() -> Bool

    /// Check if user can access backup features
    func canAccessBackupFeatures() -> Bool

    /// Get remaining free insights count
    func remainingFreeInsights() -> Int

    /// Get remaining free analyses count
    func remainingFreeAnalyses() -> Int
}

// MARK: - Subscription Validator Implementation

@MainActor
@preconcurrency final class SubscriptionValidator: SubscriptionValidatorProtocol {
    // MARK: - Properties

    private let subscriptionService: SubscriptionServiceProtocol
    private let persistenceService: SubscriptionPersistenceProtocol

    private let featureUsageSubject = CurrentValueSubject<[String: Int], Never>([:])

    // Usage limits for free users
    private let maxFreeInsights = 3
    private let maxFreeAnalyses = 1

    // MARK: - Initialization

    init(
        subscriptionService: SubscriptionServiceProtocol,
        persistenceService: SubscriptionPersistenceProtocol
    ) {
        self.subscriptionService = subscriptionService
        self.persistenceService = persistenceService

        // Load initial usage data
        loadFeatureUsage()
    }

    // MARK: - SubscriptionValidatorProtocol Implementation

    var featureUsagePublisher: AnyPublisher<[String: Int], Never> {
        featureUsageSubject.eraseToAnyPublisher()
    }

    func checkFeatureAccess(_ feature: PremiumInsightFeature) async -> FeatureAccessResult {
        // Premium users have full access
        if subscriptionService.hasPremiumAccess() {
            return .granted
        }

        // Check usage limits for free users
        let currentUsage = featureUsageSubject.value[feature.id] ?? 0

        if let limit = getUsageLimit(for: feature), currentUsage >= limit {
            return .limitReached(limit)
        }

        return .limited(remaining: (getUsageLimit(for: feature) ?? 0) - currentUsage)
    }

    func recordFeatureUsage(_ feature: PremiumInsightFeature) async {
        let currentUsage = featureUsageSubject.value[feature.id] ?? 0
        var updatedUsage = featureUsageSubject.value
        updatedUsage[feature.id] = currentUsage + 1

        featureUsageSubject.send(updatedUsage)

        // Persist usage data
        try? await persistenceService.saveFeatureUsage(updatedUsage)
    }

    func getRemainingUsage(for feature: PremiumInsightFeature) async -> Int {
        if subscriptionService.hasPremiumAccess() {
            return Int.max
        }

        let currentUsage = featureUsageSubject.value[feature.id] ?? 0
        let limit = getUsageLimit(for: feature) ?? 0

        return max(0, limit - currentUsage)
    }

    func resetUsageTracking() async {
        let resetUsage: [String: Int] = [:]
        featureUsageSubject.send(resetUsage)

        // Persist reset data
        try? await persistenceService.saveFeatureUsage(resetUsage)
    }

    // MARK: - Feature Access Helpers

    func canAccessAdvancedAnalytics() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func canAccessPredictiveInsights() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func canAccessProfessionalRecommendations() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func canAccessBenchmarkData() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func canAccessGoalTracking() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func canAccessBackupFeatures() -> Bool {
        subscriptionService.hasPremiumAccess()
    }

    func remainingFreeInsights() -> Int {
        if subscriptionService.hasPremiumAccess() { return Int.max }
        return max(0, maxFreeInsights - (featureUsageSubject.value["free_insights"] ?? 0))
    }

    func remainingFreeAnalyses() -> Int {
        if subscriptionService.hasPremiumAccess() { return Int.max }
        return max(0, maxFreeAnalyses - (featureUsageSubject.value["free_analyses"] ?? 0))
    }

    // MARK: - Private Methods

    private func loadFeatureUsage() {
        Task {
            do {
                if let savedUsage = try await persistenceService.loadFeatureUsage() {
                    featureUsageSubject.send(savedUsage)
                }
            } catch {
                // Handle loading error gracefully - use empty usage
                print("Failed to load feature usage: \(error.localizedDescription)")
            }
        }
    }

    private func getUsageLimit(for feature: PremiumInsightFeature) -> Int? {
        switch feature.id {
        case "free_insights":
            return maxFreeInsights
        case "free_analyses":
            return maxFreeAnalyses
        default:
            return feature.usageLimit
        }
    }
}
