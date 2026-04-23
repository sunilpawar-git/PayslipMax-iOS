import XCTest
@testable import PayslipMax

/// Tests for SettingsViewModel's offline mode toggle integration.
@MainActor
final class OfflineModeSettingsTests: XCTestCase {

    private var defaults: UserDefaults!
    private var offlineService: OfflineModeService!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "OfflineSettingsTests")!
        defaults.removePersistentDomain(forName: "OfflineSettingsTests")
        offlineService = OfflineModeService(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "OfflineSettingsTests")
        offlineService = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - SettingsViewModel Integration

    func test_viewModel_defaultOfflineModeIsFalse() {
        let vm = SettingsViewModel(userDefaults: defaults)
        XCTAssertFalse(vm.isOfflineModeEnabled)
    }

    func test_viewModel_toggleOfflineMode_persists() {
        let vm = SettingsViewModel(userDefaults: defaults)
        vm.updateOfflinePreference(enabled: true)
        XCTAssertTrue(vm.isOfflineModeEnabled)

        let freshVM = SettingsViewModel(userDefaults: defaults)
        XCTAssertTrue(freshVM.isOfflineModeEnabled)
    }

    func test_viewModel_disableOfflineMode_persists() {
        let vm = SettingsViewModel(userDefaults: defaults)
        vm.updateOfflinePreference(enabled: true)
        vm.updateOfflinePreference(enabled: false)
        XCTAssertFalse(vm.isOfflineModeEnabled)
    }

    // MARK: - BuildConfiguration

    func test_buildConfig_hasOfflineModeDefault() {
        XCTAssertFalse(
            BuildConfiguration.offlineModeDefault,
            "Offline mode should default to false"
        )
    }
}
