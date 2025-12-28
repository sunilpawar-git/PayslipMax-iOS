import Foundation
import Combine
@testable import PayslipMax

// MARK: - Mock Subscription Service for Validator

@MainActor
class MockSubscriptionValidatorService: SubscriptionServiceProtocol {
    var isPremium: Bool = false
    var currentSubscription: SubscriptionTier?

    private let stateSubject = CurrentValueSubject<SubscriptionState, Never>(
        SubscriptionState(isPremiumUser: false, currentSubscription: nil, lastUpdated: Date())
    )

    var isPremiumUser: Bool {
        return isPremium
    }

    var subscriptionStatePublisher: AnyPublisher<SubscriptionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func purchaseSubscription(_ tier: SubscriptionTier) async throws {
        isPremium = true
    }

    func restorePurchases() async throws {
        // No-op for tests
    }

    func cancelSubscription() async throws {
        isPremium = false
    }

    func hasPremiumAccess() -> Bool {
        return isPremium
    }
}

// MARK: - Mock Persistence Service for Validator

class MockSubscriptionPersistenceForValidator: SubscriptionPersistenceProtocol {
    var saveFeatureUsageCalled = false
    var loadFeatureUsageCalled = false
    var savedUsage: [String: Int]?

    func saveSubscriptionState(_ state: SubscriptionState) async throws {
        // No-op
    }

    func loadSubscriptionState() async throws -> SubscriptionState? {
        return nil
    }

    func saveFeatureUsage(_ usage: [String: Int]) async throws {
        saveFeatureUsageCalled = true
        savedUsage = usage
    }

    func loadFeatureUsage() async throws -> [String: Int]? {
        loadFeatureUsageCalled = true
        return savedUsage
    }

    func clearAllData() async throws {
        savedUsage = nil
    }
}

