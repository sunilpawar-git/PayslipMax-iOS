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
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isOfflineModeEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.offlineMode) }
        set { userDefaults.set(newValue, forKey: Keys.offlineMode) }
    }

    /// Whether cloud-based LLM calls are permitted
    var isCloudLLMAllowed: Bool { !isOfflineModeEnabled }

    /// Whether any network calls are permitted
    var isNetworkAllowed: Bool { !isOfflineModeEnabled }
}
