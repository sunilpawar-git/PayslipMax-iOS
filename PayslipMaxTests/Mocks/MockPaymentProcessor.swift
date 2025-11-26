import Foundation
import Combine
@testable import PayslipMax

@MainActor
class MockPaymentProcessor: PaymentProcessorProtocol {
    var isPaymentAvailableResult = true
    var processPurchaseResult: Result<Void, Error> = .success(())
    var restorePurchasesResult: Result<Void, Error> = .success(())
    var cancelSubscriptionResult: Result<Void, Error> = .success(())
    var hasActiveEntitlement = false

    func isPaymentAvailable() async -> Bool {
        return isPaymentAvailableResult
    }

    func processPurchase(for tier: SubscriptionTier) async throws {
        switch processPurchaseResult {
        case .success:
            hasActiveEntitlement = true
        case .failure(let error):
            throw error
        }
    }

    func restorePurchases() async throws {
        switch restorePurchasesResult {
        case .success:
            hasActiveEntitlement = true
        case .failure(let error):
            throw error
        }
    }

    func cancelSubscription() async throws {
        switch cancelSubscriptionResult {
        case .success:
            hasActiveEntitlement = false
        case .failure(let error):
            throw error
        }
    }

    // Helper for testing
    func checkEntitlementStatus() async -> Bool {
        return hasActiveEntitlement
    }
}
