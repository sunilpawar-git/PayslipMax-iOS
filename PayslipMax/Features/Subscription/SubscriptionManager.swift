import Foundation
import Combine

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isPremiumUser = false
    @Published var currentSubscription: SubscriptionTier?
    @Published var isLoading = false
    @Published var error: SubscriptionError?

    // MARK: - Properties
    @Published var featureUsage: [String: Int] = [:]

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let subscriptionService: SubscriptionServiceProtocol
    private let subscriptionValidator: SubscriptionValidatorProtocol

    // MARK: - Subscription Tiers
    private let subscriptionTiers: [SubscriptionTier] = [
        SubscriptionTier(
            id: "payslipmax_pro_yearly",
            name: "Pro Yearly",
            price: 99.0,
            features: PremiumFeatures.freeFeatures,
            analysisDepth: .basic,
            updateFrequency: .monthly,
            supportLevel: .basic
        )
    ]

    // MARK: - Initialization

    init(
        subscriptionService: SubscriptionServiceProtocol,
        subscriptionValidator: SubscriptionValidatorProtocol
    ) {
        self.subscriptionService = subscriptionService
        self.subscriptionValidator = subscriptionValidator

        setupSubscriptions()
    }

    // MARK: - Public Properties

    var availableSubscriptions: [SubscriptionTier] {
        subscriptionTiers
    }

    // MARK: - Public Methods

    func checkFeatureAccess(_ feature: PremiumInsightFeature) async -> FeatureAccessResult {
        await subscriptionValidator.checkFeatureAccess(feature)
    }

    func useFeature(_ feature: PremiumInsightFeature) async {
        await subscriptionValidator.recordFeatureUsage(feature)
    }

    func subscribeTo(_ tier: SubscriptionTier) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await subscriptionService.purchaseSubscription(tier)
        } catch {
            self.error = error as? SubscriptionError ?? .purchaseFailed(error.localizedDescription)
            throw error
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await subscriptionService.restorePurchases()
        } catch {
            self.error = error as? SubscriptionError ?? .restoreFailed(error.localizedDescription)
        }
    }

    func cancelSubscription() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await subscriptionService.cancelSubscription()
        } catch {
            self.error = error as? SubscriptionError ?? .restoreFailed(error.localizedDescription)
        }
    }

    // MARK: - Feature Access Helpers

    var canAccessAdvancedAnalytics: Bool {
        get async {
            await subscriptionValidator.canAccessAdvancedAnalytics()
        }
    }

    var canAccessPredictiveInsights: Bool {
        get async {
            await subscriptionValidator.canAccessPredictiveInsights()
        }
    }

    var canAccessProfessionalRecommendations: Bool {
        get async {
            await subscriptionValidator.canAccessProfessionalRecommendations()
        }
    }

    var canAccessBenchmarkData: Bool {
        get async {
            await subscriptionValidator.canAccessBenchmarkData()
        }
    }

    var canAccessGoalTracking: Bool {
        get async {
            await subscriptionValidator.canAccessGoalTracking()
        }
    }

    var canAccessBackupFeatures: Bool {
        get async {
            await subscriptionValidator.canAccessBackupFeatures()
        }
    }

    var remainingFreeInsights: Int {
        get async {
            await subscriptionValidator.remainingFreeInsights()
        }
    }

    var remainingFreeAnalyses: Int {
        get async {
            await subscriptionValidator.remainingFreeAnalyses()
        }
    }

    // MARK: - Private Methods

    private func setupSubscriptions() {
        // Subscribe to subscription service state changes
        subscriptionService.subscriptionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isPremiumUser = state.isPremiumUser
                self?.currentSubscription = state.currentSubscription
            }
            .store(in: &cancellables)

        // Subscribe to feature usage changes
        subscriptionValidator.featureUsagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] usage in
                self?.featureUsage = usage
            }
            .store(in: &cancellables)
    }
}

// MARK: - Subscription Pricing Helper

extension SubscriptionManager {
    func formattedPrice(for tier: SubscriptionTier) -> String {
        "₹\(Int(tier.price))/year"
    }

    func monthlyEquivalent(for tier: SubscriptionTier) -> String {
        if tier.id.contains("yearly") {
            let monthlyPrice = tier.price / 12
            return "₹\(Int(monthlyPrice))/month"
        }
        return "₹\(Int(tier.price))/month"
    }

    func savings(for yearlyTier: SubscriptionTier, comparedTo monthlyTier: SubscriptionTier) -> String {
        let yearlyEquivalent = monthlyTier.price * 12
        let savings = yearlyEquivalent - yearlyTier.price
        let percentage = (savings / yearlyEquivalent) * 100
        return "\(Int(percentage))% off"
    }
} 