import XCTest
import Combine
@testable import PayslipMax

/// Comprehensive tests for SubscriptionValidator functionality
@MainActor
final class SubscriptionValidatorTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: SubscriptionValidator!
    private var mockSubscriptionService: MockSubscriptionValidatorService!
    private var mockPersistenceService: MockSubscriptionPersistenceForValidator!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

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
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessAdvancedAnalytics()

        // Then
        XCTAssertTrue(result)
    }

    func test_canAccessAdvancedAnalytics_WhenNotPremium_ReturnsFalse() {
        // Given
        mockSubscriptionService.isPremium = false

        // When
        let result = sut.canAccessAdvancedAnalytics()

        // Then
        XCTAssertFalse(result)
    }

    func test_canAccessPredictiveInsights_WhenPremium_ReturnsTrue() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessPredictiveInsights()

        // Then
        XCTAssertTrue(result)
    }

    func test_canAccessBackupFeatures_WhenPremium_ReturnsTrue() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessBackupFeatures()

        // Then
        XCTAssertTrue(result)
    }

    func test_canAccessBackupFeatures_WhenNotPremium_ReturnsFalse() {
        // Given
        mockSubscriptionService.isPremium = false

        // When
        let result = sut.canAccessBackupFeatures()

        // Then
        XCTAssertFalse(result)
    }

    func test_canAccessXRayFeature_AlwaysReturnsTrue() {
        // Given - X-Ray is available to all users per implementation
        mockSubscriptionService.isPremium = false

        // When
        let result = sut.canAccessXRayFeature()

        // Then
        XCTAssertTrue(result, "X-Ray should be available to all users")
    }

    // MARK: - Feature Access Tests

    func test_checkFeatureAccess_WhenPremium_ReturnsGranted() async {
        // Given
        mockSubscriptionService.isPremium = true
        let feature = createTestFeature(id: "test_feature")

        // When
        let result = await sut.checkFeatureAccess(feature)

        // Then
        if case .granted = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .granted for premium user")
        }
    }

    func test_checkFeatureAccess_WhenFreeAndUnderLimit_ReturnsLimited() async {
        // Given
        mockSubscriptionService.isPremium = false
        let feature = createTestFeature(id: "free_insights")

        // When
        let result = await sut.checkFeatureAccess(feature)

        // Then
        if case .limited(let remaining) = result {
            XCTAssertEqual(remaining, 3) // Default max free insights
        } else {
            XCTFail("Expected .limited result for free user under limit")
        }
    }

    // MARK: - Usage Tracking Tests

    func test_recordFeatureUsage_CallsPersistence() async {
        // Given
        mockSubscriptionService.isPremium = false
        let feature = createTestFeature(id: "test_feature")

        // When
        await sut.recordFeatureUsage(feature)
        await sut.recordFeatureUsage(feature)

        // Then - verify persistence was called
        XCTAssertTrue(mockPersistenceService.saveFeatureUsageCalled)
    }

    func test_resetUsageTracking_ClearsAllUsage() async {
        // Given
        let feature = createTestFeature(id: "test_feature")
        await sut.recordFeatureUsage(feature)

        // When
        await sut.resetUsageTracking()

        // Then
        let remaining = await sut.getRemainingUsage(for: createTestFeature(id: "free_insights"))
        // For premium users, should be Int.max; for free users, should be reset to limit
        XCTAssertGreaterThan(remaining, 0)
    }

    // MARK: - Remaining Usage Tests

    func test_getRemainingUsage_WhenPremium_ReturnsMaxInt() async {
        // Given
        mockSubscriptionService.isPremium = true
        let feature = createTestFeature(id: "test_feature")

        // When
        let remaining = await sut.getRemainingUsage(for: feature)

        // Then
        XCTAssertEqual(remaining, Int.max)
    }

    func test_remainingFreeInsights_WhenPremium_ReturnsMaxInt() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let remaining = sut.remainingFreeInsights()

        // Then
        XCTAssertEqual(remaining, Int.max)
    }

    func test_remainingFreeInsights_WhenFreeAndUnused_ReturnsMaxLimit() {
        // Given
        mockSubscriptionService.isPremium = false

        // When
        let remaining = sut.remainingFreeInsights()

        // Then
        XCTAssertEqual(remaining, 3) // Default max is 3 per implementation
    }

    func test_remainingFreeAnalyses_WhenFreeAndUnused_ReturnsMaxLimit() {
        // Given
        mockSubscriptionService.isPremium = false

        // When
        let remaining = sut.remainingFreeAnalyses()

        // Then
        XCTAssertEqual(remaining, 1) // Default max is 1 per implementation
    }

    // MARK: - Publisher Tests

    func test_featureUsagePublisher_EmitsUpdatesOnUsage() async {
        // Given
        let expectation = expectation(description: "Publisher emits value")
        var receivedUsage: [String: Int]?

        sut.featureUsagePublisher
            .dropFirst() // Skip initial value
            .sink { usage in
                receivedUsage = usage
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        let feature = createTestFeature(id: "publisher_test")
        await sut.recordFeatureUsage(feature)

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedUsage)
    }

    // MARK: - Additional Feature Access Tests

    func test_canAccessProfessionalRecommendations_WhenPremium_ReturnsTrue() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessProfessionalRecommendations()

        // Then
        XCTAssertTrue(result)
    }

    func test_canAccessBenchmarkData_WhenPremium_ReturnsTrue() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessBenchmarkData()

        // Then
        XCTAssertTrue(result)
    }

    func test_canAccessGoalTracking_WhenPremium_ReturnsTrue() {
        // Given
        mockSubscriptionService.isPremium = true

        // When
        let result = sut.canAccessGoalTracking()

        // Then
        XCTAssertTrue(result)
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

// MARK: - Mock Subscription Service for Validator

@MainActor
class MockSubscriptionValidatorService: SubscriptionServiceProtocol {
    var isPremium: Bool = false
    var currentSubscription: SubscriptionTier? = nil

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
