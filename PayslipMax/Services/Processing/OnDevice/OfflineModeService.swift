import Foundation

/// Protocol for checking offline mode status throughout the app
protocol OfflineModeServiceProtocol {
    var isOfflineModeEnabled: Bool { get set }
    var isCloudLLMAllowed: Bool { get }
    var isNetworkAllowed: Bool { get }
}

/// Manages the "100% Offline Mode" user preference.
/// When enabled, all network calls (cloud LLM, analytics, etc.) are suppressed.
final class OfflineModeService: OfflineModeServiceProtocol {

    private let userDefaults: UserDefaults

    private enum Keys {
        static let offlineMode = "payslipmax_offline_mode"
        static let hasLaunchedBefore = "payslipmax_has_launched"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        applyFirstLaunchDefault()
    }

    var isOfflineModeEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.offlineMode) }
        set { userDefaults.set(newValue, forKey: Keys.offlineMode) }
    }

    var isCloudLLMAllowed: Bool { !isOfflineModeEnabled }
    var isNetworkAllowed: Bool { !isOfflineModeEnabled }

    // MARK: - Private

    /// Seeds the offline flag from BuildConfiguration on first launch only.
    private func applyFirstLaunchDefault() {
        guard !userDefaults.bool(forKey: Keys.hasLaunchedBefore) else { return }
        userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
        userDefaults.set(BuildConfiguration.offlineModeDefault, forKey: Keys.offlineMode)
    }
}
