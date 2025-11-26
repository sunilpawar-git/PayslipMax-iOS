import Foundation
import StoreKit
import Combine

// MARK: - Payment Processor Protocol

/// Protocol defining payment processing operations
protocol PaymentProcessorProtocol {
    /// Process a subscription purchase
    /// - Parameter tier: The subscription tier to purchase
    func processPurchase(for tier: SubscriptionTier) async throws

    /// Restore previous purchases
    func restorePurchases() async throws

    /// Cancel current subscription
    func cancelSubscription() async throws

    /// Check if payment processing is available
    func isPaymentAvailable() async -> Bool
}

// MARK: - Payment Processor Implementation

@MainActor
final class PaymentProcessor: PaymentProcessorProtocol {
    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var products: [String: Product] = [:]

    // Published property for entitlement updates
    @Published private(set) var hasActiveEntitlement = false

    // MARK: - Initialization

    init() {
        // Start listening for transaction updates
        Task {
            await listenForTransactionUpdates()
        }
    }

    // MARK: - PaymentProcessorProtocol Implementation

    func isPaymentAvailable() async -> Bool {
        return AppStore.canMakePayments
    }

    func processPurchase(for tier: SubscriptionTier) async throws {
        // Fetch product if not already cached
        let product = try await fetchProduct(for: tier.id)

        // Purchase
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check the transaction verification
            let transaction = try checkVerified(verification)

            // The transaction is verified. Deliver content to the user.
            await updateEntitlementStatus()

            // Always finish a transaction.
            await transaction.finish()

        case .userCancelled:
            throw SubscriptionError.purchaseFailed("Purchase cancelled by user")

        case .pending:
            throw SubscriptionError.purchaseFailed("Purchase is pending approval")

        @unknown default:
            throw SubscriptionError.purchaseFailed("Unknown purchase result")
        }
    }

    func restorePurchases() async throws {
        // Sync with App Store
        try await AppStore.sync()

        // Update status based on current entitlements
        await updateEntitlementStatus()
    }

    func cancelSubscription() async throws {
        // StoreKit 2 handles cancellation via system settings
        // We can only direct users to manage subscriptions
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            try await AppStore.showManageSubscriptions(in: windowScene)
        }
    }

    // MARK: - Entitlement Checking

    /// Check if user has any active subscription entitlement
    func checkEntitlementStatus() async -> Bool {
        await updateEntitlementStatus()
        return hasActiveEntitlement
    }

    // MARK: - Private Methods

    private func fetchProduct(for id: String) async throws -> Product {
        if let product = products[id] {
            return product
        }

        let products = try await Product.products(for: [id])
        guard let product = products.first else {
            throw SubscriptionError.purchaseFailed("Product not found: \(id)")
        }

        self.products[id] = product
        return product
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                // Deliver content to the user
                await updateEntitlementStatus()

                // Always finish a transaction
                await transaction.finish()
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
    }

    private func updateEntitlementStatus() async {
        var hasPremium = false

        // Iterate through all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is a valid subscription
                if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
                    // Check if not revoked
                    if transaction.revocationDate == nil {
                        hasPremium = true
                    }
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }

        self.hasActiveEntitlement = hasPremium
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it failed verification.
            throw SubscriptionError.purchaseFailed("Transaction verification failed")

        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
}
