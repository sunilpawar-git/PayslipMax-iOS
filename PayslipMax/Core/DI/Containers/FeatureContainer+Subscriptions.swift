import Foundation

// MARK: - Subscription Feature

extension FeatureContainer {

    func makeSubscriptionService() -> SubscriptionServiceProtocol {
        if let service = _subscriptionService {
            return service
        }

        let paymentProcessor = makePaymentProcessor()
        let persistenceService = makeSubscriptionPersistenceService()

        let service = SubscriptionService(
            paymentProcessor: paymentProcessor,
            persistenceService: persistenceService
        )

        _subscriptionService = service
        return service
    }

    func makeSubscriptionValidator() -> SubscriptionValidatorProtocol {
        if let validator = _subscriptionValidator {
            return validator
        }

        let subscriptionService = makeSubscriptionService()
        let persistenceService = makeSubscriptionPersistenceService()

        let validator = SubscriptionValidator(
            subscriptionService: subscriptionService,
            persistenceService: persistenceService
        )

        _subscriptionValidator = validator
        return validator
    }

    func makeSubscriptionManager() -> SubscriptionManager {
        if let manager = _subscriptionManager {
            return manager
        }

        let subscriptionService = makeSubscriptionService()
        let subscriptionValidator = makeSubscriptionValidator()

        let manager = SubscriptionManager(
            subscriptionService: subscriptionService,
            subscriptionValidator: subscriptionValidator
        )

        _subscriptionManager = manager
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
