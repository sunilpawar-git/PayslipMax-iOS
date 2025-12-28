import XCTest
import Combine
@testable import PayslipMax

/// Tests for SubscriptionValidator functionality
@MainActor
final class SubscriptionValidatorTests: XCTestCase {

    private var sut: SubscriptionValidator!
    private var mockSubscriptionService: MockSubscriptionValidatorService!
    private var mockPersistenceService: MockSubscriptionPersistenceForValidator!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockSubscriptionService = MockSubscriptionValidatorService()
        mockPersistenceService = MockSubscriptionPersistenceForValidator()
        sut = SubscriptionValidator(
            subscriptionService: mockSubscriptionService,
            persistenceService: mockPersistenceService
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        sut = nil
        mockSubscriptionService = nil
        mockPersistenceService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Premium Access Tests

    func test_canAccessAdvancedAnalytics_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessAdvancedAnalytics())
    }

    func test_canAccessAdvancedAnalytics_WhenNotPremium_ReturnsFalse() {
        mockSubscriptionService.isPremium = false
        XCTAssertFalse(sut.canAccessAdvancedAnalytics())
    }

    func test_canAccessPredictiveInsights_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessPredictiveInsights())
    }

    func test_canAccessBackupFeatures_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessBackupFeatures())
    }

    func test_canAccessBackupFeatures_WhenNotPremium_ReturnsFalse() {
        mockSubscriptionService.isPremium = false
        XCTAssertFalse(sut.canAccessBackupFeatures())
    }

    func test_canAccessXRayFeature_AlwaysReturnsTrue() {
        mockSubscriptionService.isPremium = false
        XCTAssertTrue(sut.canAccessXRayFeature())
    }

    // MARK: - Feature Access Tests

    func test_checkFeatureAccess_WhenPremium_ReturnsGranted() async {
        mockSubscriptionService.isPremium = true
        let feature = createTestFeature(id: "test_feature")
        let result = await sut.checkFeatureAccess(feature)

        if case .granted = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .granted for premium user")
        }
    }

    func test_checkFeatureAccess_WhenFreeAndUnderLimit_ReturnsLimited() async {
        mockSubscriptionService.isPremium = false
        let feature = createTestFeature(id: "free_insights")
        let result = await sut.checkFeatureAccess(feature)

        if case .limited(let remaining) = result {
            XCTAssertEqual(remaining, 3)
        } else {
            XCTFail("Expected .limited result for free user under limit")
        }
    }

    // MARK: - Usage Tracking Tests

    func test_recordFeatureUsage_CallsPersistence() async {
        mockSubscriptionService.isPremium = false
        let feature = createTestFeature(id: "test_feature")

        await sut.recordFeatureUsage(feature)
        await sut.recordFeatureUsage(feature)

        XCTAssertTrue(mockPersistenceService.saveFeatureUsageCalled)
    }

    func test_resetUsageTracking_ClearsAllUsage() async {
        let feature = createTestFeature(id: "test_feature")
        await sut.recordFeatureUsage(feature)
        await sut.resetUsageTracking()

        let remaining = await sut.getRemainingUsage(for: createTestFeature(id: "free_insights"))
        XCTAssertGreaterThan(remaining, 0)
    }

    // MARK: - Remaining Usage Tests

    func test_getRemainingUsage_WhenPremium_ReturnsMaxInt() async {
        mockSubscriptionService.isPremium = true
        let feature = createTestFeature(id: "test_feature")
        let remaining = await sut.getRemainingUsage(for: feature)
        XCTAssertEqual(remaining, Int.max)
    }

    func test_remainingFreeInsights_WhenPremium_ReturnsMaxInt() {
        mockSubscriptionService.isPremium = true
        XCTAssertEqual(sut.remainingFreeInsights(), Int.max)
    }

    func test_remainingFreeInsights_WhenFreeAndUnused_ReturnsMaxLimit() {
        mockSubscriptionService.isPremium = false
        XCTAssertEqual(sut.remainingFreeInsights(), 3)
    }

    func test_remainingFreeAnalyses_WhenFreeAndUnused_ReturnsMaxLimit() {
        mockSubscriptionService.isPremium = false
        XCTAssertEqual(sut.remainingFreeAnalyses(), 1)
    }

    // MARK: - Publisher Tests

    func test_featureUsagePublisher_EmitsUpdatesOnUsage() async {
        let expectation = expectation(description: "Publisher emits value")
        var receivedUsage: [String: Int]?

        sut.featureUsagePublisher
            .dropFirst()
            .sink { usage in
                receivedUsage = usage
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let feature = createTestFeature(id: "publisher_test")
        await sut.recordFeatureUsage(feature)

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedUsage)
    }

    // MARK: - Additional Feature Access Tests

    func test_canAccessProfessionalRecommendations_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessProfessionalRecommendations())
    }

    func test_canAccessBenchmarkData_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessBenchmarkData())
    }

    func test_canAccessGoalTracking_WhenPremium_ReturnsTrue() {
        mockSubscriptionService.isPremium = true
        XCTAssertTrue(sut.canAccessGoalTracking())
    }

    // MARK: - Helper Methods

    private func createTestFeature(id: String) -> PremiumInsightFeature {
        return PremiumInsightFeature(
            id: id,
            name: "Test Feature",
            description: "Test Description",
            category: .analytics,
            isEnabled: true,
            requiresSubscription: true,
            usageLimit: 3,
            currentUsage: 0
        )
    }
}
