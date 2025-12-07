import XCTest
import Combine
@testable import PayslipMax

/// Unit tests for XRaySettingsService (always-on behavior)
@MainActor
final class XRaySettingsServiceTests: XCTestCase {

    var sut: XRaySettingsService!
    var mockUserDefaults: UserDefaults!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()

        let suiteName = "test.xray.settings.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
        mockUserDefaults.removePersistentDomain(forName: suiteName)

        sut = XRaySettingsService(userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        cancellables = nil
        if let suiteName = mockUserDefaults.dictionaryRepresentation().keys.first {
            mockUserDefaults.removePersistentDomain(forName: suiteName)
        }
        mockUserDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInit_DefaultsToTrue() {
        XCTAssertTrue(sut.isXRayEnabled)
    }

    func testInit_WithPersistedTrue_StaysTrue() {
        mockUserDefaults.set(true, forKey: "xray_salary_enabled")
        let newSut = XRaySettingsService(userDefaults: mockUserDefaults)
        XCTAssertTrue(newSut.isXRayEnabled)
    }

    func testInit_WithPersistedFalse_IsForcedTrue() {
        mockUserDefaults.set(false, forKey: "xray_salary_enabled")
        let newSut = XRaySettingsService(userDefaults: mockUserDefaults)
        XCTAssertTrue(newSut.isXRayEnabled)
    }

    // MARK: - Toggle (compatibility no-op)

    func testToggleXRay_KeepsEnabledAndDoesNotCallPaywall() {
        var paywallCalled = false
        sut.toggleXRay { paywallCalled = true }
        XCTAssertTrue(sut.isXRayEnabled)
        XCTAssertFalse(paywallCalled)
    }

    func testMultipleToggles_RemainsEnabled() {
        for _ in 0..<5 { sut.toggleXRay(onPaywallRequired: {}) }
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
        XCTAssertTrue(sut.isXRayEnabled)
    }

    // MARK: - Persistence

    func testToggleXRay_PersistsToUserDefaults() {
        sut.toggleXRay(onPaywallRequired: {})
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
    }

    func testSetXRayEnabled_PersistsToUserDefaults() {
        sut.setXRayEnabled(true)
        let persistedValue = mockUserDefaults.bool(forKey: "xray_salary_enabled")
        XCTAssertTrue(persistedValue)
    }

    // MARK: - Publisher

    func testPublisher_EmitsOnToggle() {
        let expectation = XCTestExpectation(description: "Publisher emits")
        var receivedValue: Bool?

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.toggleXRay(onPaywallRequired: {})

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, true)
    }

    func testPublisher_EmitsOnSetXRayEnabled() {
        let expectation = XCTestExpectation(description: "Publisher emits")
        var receivedValue: Bool?

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.setXRayEnabled(true)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, true)
    }

    func testPublisher_EmitsMultipleValues() {
        let expectation = XCTestExpectation(description: "Publisher emits twice")
        expectation.expectedFulfillmentCount = 2
        var receivedValues: [Bool] = []

        sut.xRayEnabledPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.toggleXRay(onPaywallRequired: {})
        sut.toggleXRay(onPaywallRequired: {})

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [true, true])
    }
}

