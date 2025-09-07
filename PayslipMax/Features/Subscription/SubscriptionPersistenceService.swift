import Foundation

// MARK: - Subscription Persistence Protocol

/// Protocol defining data persistence operations for subscription management
protocol SubscriptionPersistenceProtocol {
    /// Save subscription state
    /// - Parameter state: The subscription state to save
    func saveSubscriptionState(_ state: SubscriptionState) async throws

    /// Load subscription state
    /// - Returns: The saved subscription state, or nil if none exists
    func loadSubscriptionState() async throws -> SubscriptionState?

    /// Save feature usage data
    /// - Parameter usage: Dictionary of feature usage data
    func saveFeatureUsage(_ usage: [String: Int]) async throws

    /// Load feature usage data
    /// - Returns: Dictionary of feature usage data, or nil if none exists
    func loadFeatureUsage() async throws -> [String: Int]?

    /// Clear all subscription data (for testing or reset)
    func clearAllData() async throws
}

// MARK: - Subscription Persistence Implementation

@MainActor
final class SubscriptionPersistenceService: SubscriptionPersistenceProtocol {
    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // UserDefaults keys
    private enum Keys {
        static let isPremiumUser = "is_premium_user"
        static let currentSubscription = "current_subscription"
        static let featureUsage = "feature_usage"
        static let subscriptionState = "subscription_state"
        static let hadPremiumSubscription = "had_premium_subscription"
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SubscriptionPersistenceProtocol Implementation

    func saveSubscriptionState(_ state: SubscriptionState) async throws {
        let data = try jsonEncoder.encode(state)
        userDefaults.set(data, forKey: Keys.subscriptionState)

        // Also save individual components for backward compatibility
        userDefaults.set(state.isPremiumUser, forKey: Keys.isPremiumUser)
        userDefaults.set(state.isPremiumUser, forKey: Keys.hadPremiumSubscription)

        if let subscription = state.currentSubscription {
            let subscriptionData = try jsonEncoder.encode(subscription)
            userDefaults.set(subscriptionData, forKey: Keys.currentSubscription)
        }
    }

    func loadSubscriptionState() async throws -> SubscriptionState? {
        // Try to load the complete state first
        if let data = userDefaults.data(forKey: Keys.subscriptionState),
           let state = try? jsonDecoder.decode(SubscriptionState.self, from: data) {
            return state
        }

        // Fallback to loading individual components
        return try loadLegacySubscriptionState()
    }

    func saveFeatureUsage(_ usage: [String: Int]) async throws {
        let data = try jsonEncoder.encode(usage)
        userDefaults.set(data, forKey: Keys.featureUsage)
    }

    func loadFeatureUsage() async throws -> [String: Int]? {
        guard let data = userDefaults.data(forKey: Keys.featureUsage) else {
            return nil
        }

        return try jsonDecoder.decode([String: Int].self, from: data)
    }

    func clearAllData() async throws {
        userDefaults.removeObject(forKey: Keys.subscriptionState)
        userDefaults.removeObject(forKey: Keys.isPremiumUser)
        userDefaults.removeObject(forKey: Keys.currentSubscription)
        userDefaults.removeObject(forKey: Keys.featureUsage)
        userDefaults.removeObject(forKey: Keys.hadPremiumSubscription)
    }

    // MARK: - Private Methods

    private func loadLegacySubscriptionState() throws -> SubscriptionState? {
        let isPremiumUser = userDefaults.bool(forKey: Keys.isPremiumUser)

        var currentSubscription: SubscriptionTier?
        if let subscriptionData = userDefaults.data(forKey: Keys.currentSubscription) {
            currentSubscription = try? jsonDecoder.decode(SubscriptionTier.self, from: subscriptionData)
        }

        // If we have any data, create a subscription state
        if isPremiumUser || currentSubscription != nil {
            return SubscriptionState(
                isPremiumUser: isPremiumUser,
                currentSubscription: currentSubscription,
                lastUpdated: Date()
            )
        }

        return nil
    }
}

// MARK: - Migration Helpers

extension SubscriptionPersistenceService {
    /// Migrate from legacy storage format to new format
    func migrateLegacyData() async throws {
        // Check if we need to migrate
        guard userDefaults.data(forKey: Keys.subscriptionState) == nil else {
            return // Already migrated
        }

        // Load legacy data
        if let legacyState = try loadLegacySubscriptionState() {
            // Save in new format
            try await saveSubscriptionState(legacyState)

            // Clean up legacy keys
            userDefaults.removeObject(forKey: Keys.isPremiumUser)
            userDefaults.removeObject(forKey: Keys.currentSubscription)
        }
    }
}
