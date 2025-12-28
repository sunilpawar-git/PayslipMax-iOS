import Foundation
@testable import PayslipMax

/// Shared mock subscription service for testing subscription-related functionality
@MainActor
final class MockSubscriptionService: SubscriptionServiceProtocol {

    // MARK: - Mock State

    var isPremium: Bool = false
    var currentSubscription: SubscriptionTier? = nil

    // MARK: - Call Tracking

    var purchaseSubscriptionCalled = false
    var restorePurchasesCalled = false
    var cancelSubscriptionCalled = false
    var hasPremiumAccessCalled = false

    // MARK: - Error Simulation

    var shouldThrowError = false
    var errorToThrow: Error = SubscriptionError.purchaseFailed("Mock error")

    // MARK: - Publisher

    private let stateSubject = CurrentValueSubject<SubscriptionState, Never>(
        SubscriptionState(isPremiumUser: false, currentSubscription: nil, lastUpdated: Date())
    )

    var subscriptionStatePublisher: AnyPublisher<SubscriptionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var isPremiumUser: Bool {
        return isPremium
    }

    // MARK: - SubscriptionServiceProtocol Implementation

    func purchaseSubscription(_ tier: SubscriptionTier) async throws {
        purchaseSubscriptionCalled = true
        if shouldThrowError { throw errorToThrow }
        isPremium = true
        updateState()
    }

    func restorePurchases() async throws {
        restorePurchasesCalled = true
        if shouldThrowError { throw errorToThrow }
    }

    func cancelSubscription() async throws {
        cancelSubscriptionCalled = true
        if shouldThrowError { throw errorToThrow }
        isPremium = false
        updateState()
    }

    func hasPremiumAccess() -> Bool {
        hasPremiumAccessCalled = true
        return isPremium
    }

    // MARK: - Helpers

    private func updateState() {
        stateSubject.send(SubscriptionState(
            isPremiumUser: isPremium,
            currentSubscription: currentSubscription,
            lastUpdated: Date()
        ))
    }

    func reset() {
        isPremium = false
        currentSubscription = nil
        purchaseSubscriptionCalled = false
        restorePurchasesCalled = false
        cancelSubscriptionCalled = false
        hasPremiumAccessCalled = false
        shouldThrowError = false
    }
}

import Combine
