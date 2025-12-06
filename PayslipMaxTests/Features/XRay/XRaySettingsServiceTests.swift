import XCTest
import Combine
@testable import PayslipMax

/// Comprehensive unit tests for XRaySettingsService
@MainActor
final class XRaySettingsServiceTests: XCTestCase {

    var sut: XRaySettingsService!
    var mockSubscriptionValidator: MockSubscriptionValidator!
    var mockUserDefaults: UserDefaults!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()

        // Create mock UserDefaults with unique suite name
        let suiteName = "test.xray.settings.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
        mockUserDefaults.removePersistentDomain(forName: suiteName)

        // Create mock subscription validator
        mockSubscriptionValidator = MockSubscriptionValidator(hasPremium: false)

        // Create SUT
        sut = XRaySettingsService(
            subscriptionValidator: mockSubscriptionValidator,
            userDefaults: mockUserDefaults
        )
    }

    override func tearDown() {
        cancellables = nil
        if let suiteName = mockUserDefaults.dictionaryRepresentation().keys.first {
            mockUserDefaults.removePersistentDomain(forName: suiteName)
        }
        mockUserDefaults = nil
        mockSubscriptionValidator = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_WithNoPersistedValue_DefaultsToFalse() {
        // Then
        XCTAssertFalse(sut.isXRayEnabled)
    }

    func testInit_WithPersistedTrue_LoadsTrueValue() {
        // Given
        mockUserDefaults.set(true, forKey: "xray_salary_enabled")

        // When
        let newSut = XRaySettingsService(
            subscriptionValidator: mockSubscriptionValidator,
            userDefaults: mockUserDefaults
        )

        // Then
        XCTAssertTrue(newSut.isXRayEnabled)
    }

    func testInit_WithPersistedFalse_LoadsFalseValue() {
        // Given
        mockUserDefaults.set(false, forKey: "xray_salary_enabled")

        // When
        let newSut = XRaySettingsService(
            subscriptionValidator: mockSubscriptionValidator,
            userDefaults: mockUserDefaults
        )

        // Then
        XCTAssertFalse(newSut.isXRayEnabled)
    }

    // MARK: - Toggle Tests - Premium User

    func testToggleXRay_WithPremiumUser_TogglesFromFalseToTrue() {
        // Given
        mockSubscriptionValidator.hasPremium = true
        XCTAssertFalse(sut.isXRayEnabled)

        var paywallCalled = false
        let paywallCallback = { paywallCalled = true }

        // When
        sut.toggleXRay(onPaywallRequired: paywallCallback)

        // Then
        XCTAssertTrue(sut.isXRayEnabled)
        XCTAssertFalse(paywallCalled)
    }

    func testToggleXRay_WithPremiumUser_TogglesFromTrueToFalse() {
        // Given
        mockSubscriptionValidator.hasPremium = true
        sut.setXRayEnabled(true)
        XCTAssertTrue(sut.isXRayEnabled)

        var paywallCalled = false
        let paywallCallback = { paywallCalled = true }

        // When
        sut.toggleXRay(onPaywallRequired: paywallCallback)

        // Then
        XCTAssertFalse(sut.isXRayEnabled)
        XCTAssertFalse(paywallCalled)
    }

    func testToggleXRay_WithPremiumUser_TogglesTwice() {
        // Given
        mockSubscriptionValidator.hasPremium = true
        var paywallCalled = false
        let paywallCallback = { paywallCalled = true }

        // When - Toggle ON
        sut.toggleXRay(onPaywallRequired: paywallCallback)
        XCTAssertTrue(sut.isXRayEnabled)

        // When - Toggle OFF
        sut.toggleXRay(onPaywallRequired: paywallCallback)
        XCTAssertFalse(sut.isXRayEnabled)

        // Then
        XCTAssertFalse(paywallCalled)
    }

    // MARK: - Toggle Tests - Free User

    func testToggleXRay_WithFreeUser_CallsPaywallCallback() {
        // Given
        mockSubscriptionValidator.hasPremium = false
        XCTAssertFalse(sut.isXRayEnabled)

        var paywallCalled = false
        let paywallCallback = { paywallCalled = true }

        // When
        sut.toggleXRay(onPaywallRequired: paywallCallback)

        // Then
        XCTAssertTrue(paywallCalled)
        XCTAssertFalse(sut.isXRayEnabled) // State should not change
    }

    func testToggleXRay_WithFreeUser_DoesNotChangeState() {
        // Given
        mockSubscriptionValidator.hasPremium = false
        let initialState = sut.isXRayEnabled

        // When
        sut.toggleXRay(onPaywallRequired: {})

        // Then
        XCTAssertEqual(sut.isXRayEnabled, initialState)
    }

    // MARK: - Persistence Tests

    func testToggleXRay_PersistsToUserDefaults() {
        // Given
        mockSubscriptionValidator.hasPremium = true

        // When
        sut.toggleXRay(onPaywallRequired: {})

        // Then
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
    }

    func testSetXRayEnabled_PersistsToUserDefaults() {
        // When
        sut.setXRayEnabled(true)

        // Then
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
    }

    func testMultipleToggles_PersistsCorrectState() {
        // Given
        mockSubscriptionValidator.hasPremium = true

        // When
        sut.toggleXRay(onPaywallRequired: {}) // ON
        sut.toggleXRay(onPaywallRequired: {}) // OFF
        sut.toggleXRay(onPaywallRequired: {}) // ON

        // Then
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
        XCTAssertTrue(sut.isXRayEnabled)
    }

    // MARK: - Publisher Tests

    func testPublisher_EmitsOnToggle() {
        // Given
        mockSubscriptionValidator.hasPremium = true
        let expectation = XCTestExpectation(description: "Publisher emits")
        var receivedValue: Bool?

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.toggleXRay(onPaywallRequired: {})

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, true)
    }

    func testPublisher_EmitsOnSetXRayEnabled() {
        // Given
        let expectation = XCTestExpectation(description: "Publisher emits")
        var receivedValue: Bool?

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.setXRayEnabled(true)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, true)
    }

    func testPublisher_EmitsMultipleValues() {
        // Given
        mockSubscriptionValidator.hasPremium = true
        let expectation = XCTestExpectation(description: "Publisher emits twice")
        expectation.expectedFulfillmentCount = 2
        var receivedValues: [Bool] = []

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.toggleXRay(onPaywallRequired: {}) // ON
        sut.toggleXRay(onPaywallRequired: {}) // OFF

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [true, false])
    }

    func testPublisher_DoesNotEmitOnFreeUserToggle() {
        // Given
        mockSubscriptionValidator.hasPremium = false
        var receivedValue: Bool?

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValue = value
            }
            .store(in: &cancellables)

        // When
        sut.toggleXRay(onPaywallRequired: {})

        // Give time for publisher to emit (if it would)
        let expectation = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)

        // Then
        XCTAssertNil(receivedValue) // Should not emit
    }

    // MARK: - Edge Cases

    func testToggleXRay_CalledMultipleTimes_HandlesSafely() {
        // Given
        mockSubscriptionValidator.hasPremium = true

        // When - Rapid toggles
        for _ in 0..<10 {
            sut.toggleXRay(onPaywallRequired: {})
        }

        // Then - State should be consistent
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertEqual(sut.isXRayEnabled, persistedValue)
    }

    func testSubscriptionStatusChanges_DuringSession() {
        // Given - Start as free user
        mockSubscriptionValidator.hasPremium = false
        sut.toggleXRay(onPaywallRequired: {})
        XCTAssertFalse(sut.isXRayEnabled)

        // When - User subscribes
        mockSubscriptionValidator.hasPremium = true
        sut.toggleXRay(onPaywallRequired: {})

        // Then - Should now work
        XCTAssertTrue(sut.isXRayEnabled)
    }
}

// MARK: - Mock Subscription Validator

@MainActor
final class MockSubscriptionValidator: SubscriptionValidatorProtocol {
    var hasPremium: Bool

    init(hasPremium: Bool) {
        self.hasPremium = hasPremium
    }

    // MARK: - Feature Access Helpers

    func canAccessAdvancedAnalytics() -> Bool { hasPremium }
    func canAccessPredictiveInsights() -> Bool { hasPremium }
    func canAccessProfessionalRecommendations() -> Bool { hasPremium }
    func canAccessBenchmarkData() -> Bool { hasPremium }
    func canAccessGoalTracking() -> Bool { hasPremium }
    func canAccessBackupFeatures() -> Bool { hasPremium }
    func canAccessXRayFeature() -> Bool { hasPremium }

    func remainingFreeInsights() -> Int {
        hasPremium ? Int.max : 3
    }

    func remainingFreeAnalyses() -> Int {
        hasPremium ? Int.max : 1
    }

    // MARK: - Feature Usage Tracking (No-op for tests)

    var featureUsagePublisher: AnyPublisher<[String: Int], Never> {
        Just([:]).eraseToAnyPublisher()
    }

    func checkFeatureAccess(_ feature: PremiumInsightFeature) async -> FeatureAccessResult {
        hasPremium ? .granted : .limitReached(0)
    }

    func recordFeatureUsage(_ feature: PremiumInsightFeature) async {
        // No-op for tests
    }

    func getRemainingUsage(for feature: PremiumInsightFeature) async -> Int {
        hasPremium ? Int.max : 0
    }

    func resetUsageTracking() async {
        // No-op for tests
    }
}
