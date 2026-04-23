import XCTest
@testable import PayslipMax

/// Tests for OfflineModeService -- persists the user's "100% Offline" preference
/// and gates all network-dependent code paths.
final class OfflineModeServiceTests: XCTestCase {

    private var sut: OfflineModeService!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "OfflineModeTests")!
        defaults.removePersistentDomain(forName: "OfflineModeTests")
        sut = OfflineModeService(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "OfflineModeTests")
        sut = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Default State

    func test_defaultState_offlineModeDisabled() {
        XCTAssertFalse(sut.isOfflineModeEnabled)
    }

    // MARK: - Toggle

    func test_enableOfflineMode_persistsToDefaults() {
        sut.isOfflineModeEnabled = true
        XCTAssertTrue(sut.isOfflineModeEnabled)

        let fresh = OfflineModeService(userDefaults: defaults)
        XCTAssertTrue(fresh.isOfflineModeEnabled)
    }

    func test_disableOfflineMode_persistsToDefaults() {
        sut.isOfflineModeEnabled = true
        sut.isOfflineModeEnabled = false
        XCTAssertFalse(sut.isOfflineModeEnabled)
    }

    // MARK: - Cloud LLM Gating

    func test_isCloudLLMAllowed_trueWhenOffline() {
        sut.isOfflineModeEnabled = false
        XCTAssertTrue(sut.isCloudLLMAllowed)
    }

    func test_isCloudLLMAllowed_falseWhenOffline() {
        sut.isOfflineModeEnabled = true
        XCTAssertFalse(sut.isCloudLLMAllowed)
    }

    // MARK: - Network Gating

    func test_isNetworkAllowed_trueWhenOnline() {
        sut.isOfflineModeEnabled = false
        XCTAssertTrue(sut.isNetworkAllowed)
    }

    func test_isNetworkAllowed_falseWhenOffline() {
        sut.isOfflineModeEnabled = true
        XCTAssertFalse(sut.isNetworkAllowed)
    }
}
