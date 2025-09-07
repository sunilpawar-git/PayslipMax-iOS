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
    }

    // MARK: - SubscriptionServiceProtocol Implementation

    var isPremiumUser: Bool {
        subscriptionStateSubject.value.isPremiumUser
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
            // Process payment
            guard await paymentProcessor.isPaymentAvailable() else {
                throw SubscriptionError.notAvailable
            }
            try await paymentProcessor.processPurchase(for: tier)

            // Update subscription state
            let newState = SubscriptionState(
                isPremiumUser: true,
                currentSubscription: tier,
                lastUpdated: Date()
            )

            subscriptionStateSubject.send(newState)

            // Persist the new state
            try await persistenceService.saveSubscriptionState(newState)

        } catch {
            // Handle payment failure
            throw SubscriptionError.purchaseFailed(error.localizedDescription)
        }
    }

    func restorePurchases() async throws {
        do {
            // Attempt to restore purchases
            guard await paymentProcessor.isPaymentAvailable() else {
                throw SubscriptionError.notAvailable
            }
            try await paymentProcessor.restorePurchases()

            // Check if restoration was successful
            if let restoredState = try await persistenceService.loadSubscriptionState() {
                subscriptionStateSubject.send(restoredState)
            } else {
                throw SubscriptionError.restoreFailed("No previous purchases found")
            }

        } catch {
            throw SubscriptionError.restoreFailed(error.localizedDescription)
        }
    }

    func cancelSubscription() async throws {
        do {
            // Process cancellation
            guard await paymentProcessor.isPaymentAvailable() else {
                throw SubscriptionError.notAvailable
            }
            try await paymentProcessor.cancelSubscription()

            // Update subscription state
            let cancelledState = SubscriptionState(
                isPremiumUser: false,
                currentSubscription: nil,
                lastUpdated: Date()
            )

            subscriptionStateSubject.send(cancelledState)

            // Persist the cancelled state
            try await persistenceService.saveSubscriptionState(cancelledState)

        } catch {
            throw SubscriptionError.restoreFailed("Cancellation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func loadSubscriptionState() {
        Task {
            do {
                if let savedState = try await persistenceService.loadSubscriptionState() {
                    subscriptionStateSubject.send(savedState)
                }
            } catch {
                // Handle loading error gracefully - use default state
                print("Failed to load subscription state: \(error.localizedDescription)")
            }
        }
    }
}
