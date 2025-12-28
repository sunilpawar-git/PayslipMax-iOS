import Foundation
import Combine

// MARK: - Subscription Service Protocol

/// Protocol defining subscription management operations
@MainActor
protocol SubscriptionServiceProtocol {
    /// Current subscription status
    var isPremiumUser: Bool { get }

    /// Current subscription tier
    var currentSubscription: SubscriptionTier? { get }

    /// Observable subscription state
    var subscriptionStatePublisher: AnyPublisher<SubscriptionState, Never> { get }

    /// Purchase a subscription tier
    /// - Parameter tier: The subscription tier to purchase
    /// - Returns: Result indicating success or failure
    func purchaseSubscription(_ tier: SubscriptionTier) async throws

    /// Restore previous purchases
    func restorePurchases() async throws

    /// Cancel current subscription
    func cancelSubscription() async throws

    /// Check if user has premium access
    func hasPremiumAccess() -> Bool
}

// MARK: - Subscription State

/// Current state of the subscription
struct SubscriptionState: Codable {
    let isPremiumUser: Bool
    let currentSubscription: SubscriptionTier?
    let lastUpdated: Date
}

// MARK: - Subscription Service Implementation

@MainActor
@preconcurrency final class SubscriptionService: SubscriptionServiceProtocol {
    // MARK: - Properties

    private let paymentProcessor: PaymentProcessorProtocol
    private let persistenceService: SubscriptionPersistenceProtocol

    private let subscriptionStateSubject = CurrentValueSubject<SubscriptionState, Never>(
        SubscriptionState(isPremiumUser: false, currentSubscription: nil, lastUpdated: Date())
    )

    // MARK: - Initialization

    init(
        paymentProcessor: PaymentProcessorProtocol,
        persistenceService: SubscriptionPersistenceProtocol
    ) {
        self.paymentProcessor = paymentProcessor
        self.persistenceService = persistenceService

        // Load initial state
        loadSubscriptionState()

        // Listen for debug bypass changes
        setupDebugObserver()
    }

    // MARK: - SubscriptionServiceProtocol Implementation

    var isPremiumUser: Bool {
        // 1. Check Debug Bypass first (Development only)
        if SubscriptionDebugHelper.isBypassEnabled {
            return true
        }

        // 2. Check Real Entitlement Status
        return subscriptionStateSubject.value.isPremiumUser
    }

    var currentSubscription: SubscriptionTier? {
        subscriptionStateSubject.value.currentSubscription
    }

    var subscriptionStatePublisher: AnyPublisher<SubscriptionState, Never> {
        subscriptionStateSubject.eraseToAnyPublisher()
    }

    func hasPremiumAccess() -> Bool {
        isPremiumUser
    }

    func purchaseSubscription(_ tier: SubscriptionTier) async throws {
        do {
            // Process payment via StoreKit
            try await paymentProcessor.processPurchase(for: tier)

            // Update state after successful purchase
            await refreshSubscriptionState()

        } catch {
            throw SubscriptionError.purchaseFailed(error.localizedDescription)
        }
    }

    func restorePurchases() async throws {
        do {
            // Restore via StoreKit
            try await paymentProcessor.restorePurchases()

            // Update state after restore
            await refreshSubscriptionState()

        } catch {
            throw SubscriptionError.restoreFailed(error.localizedDescription)
        }
    }

    func cancelSubscription() async throws {
        do {
            try await paymentProcessor.cancelSubscription()
            // State update happens via transaction listener in PaymentProcessor
        } catch {
            throw SubscriptionError.restoreFailed("Cancellation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func loadSubscriptionState() {
        Task {
            await refreshSubscriptionState()
        }
    }

    private func refreshSubscriptionState() async {
        // Check actual entitlement status from PaymentProcessor (StoreKit)
        // Note: We need to cast to concrete type or add checkEntitlementStatus to protocol
        // For now, we assume PaymentProcessorProtocol will be updated or we cast
        let hasEntitlement: Bool

        if let processor = paymentProcessor as? PaymentProcessor {
            hasEntitlement = await processor.checkEntitlementStatus()
        } else {
            // Fallback for mocks or other implementations
            hasEntitlement = false
        }

        let placeholderTier = SubscriptionTier(
            id: "pro",
            name: "Pro",
            price: 0,
            features: [],
            analysisDepth: .professional,
            updateFrequency: .realTime,
            supportLevel: .priority
        )
        let newState = SubscriptionState(
            isPremiumUser: hasEntitlement,
            currentSubscription: hasEntitlement ? placeholderTier : nil,
            lastUpdated: Date()
        )

        subscriptionStateSubject.send(newState)
    }

    private func setupDebugObserver() {
        // In a real app, we might want to observe UserDefaults changes
        // For now, relies on isPremiumUser computed property checking the flag
    }
}
