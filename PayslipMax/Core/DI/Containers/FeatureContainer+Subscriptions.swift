import Foundation

// MARK: - Subscription Feature

extension FeatureContainer {

    func makeSubscriptionService() -> SubscriptionServiceProtocol {
        if let service = cachedSubscriptionService {
            return service
        }

        let paymentProcessor = makePaymentProcessor()
        let persistenceService = makeSubscriptionPersistenceService()

        let service = SubscriptionService(
            paymentProcessor: paymentProcessor,
            persistenceService: persistenceService
        )

        cachedSubscriptionService = service
        return service
    }

    func makeSubscriptionValidator() -> SubscriptionValidatorProtocol {
        if let validator = cachedSubscriptionValidator {
            return validator
        }

        let subscriptionService = makeSubscriptionService()
        let persistenceService = makeSubscriptionPersistenceService()

        let validator = SubscriptionValidator(
            subscriptionService: subscriptionService,
            persistenceService: persistenceService
        )

        cachedSubscriptionValidator = validator
        return validator
    }

    func makeSubscriptionManager() -> SubscriptionManager {
        if let manager = cachedSubscriptionManager {
            return manager
        }

        let subscriptionService = makeSubscriptionService()
        let subscriptionValidator = makeSubscriptionValidator()

        let manager = SubscriptionManager(
            subscriptionService: subscriptionService,
            subscriptionValidator: subscriptionValidator
        )

        cachedSubscriptionManager = manager
        return manager
    }

    // MARK: - Subscription Supporting Services

    private func makePaymentProcessor() -> PaymentProcessorProtocol {
        return PaymentProcessor()
    }

    private func makeSubscriptionPersistenceService() -> SubscriptionPersistenceProtocol {
        return SubscriptionPersistenceService()
    }
}
