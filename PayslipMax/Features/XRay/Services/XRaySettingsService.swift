import Foundation
import Combine

// MARK: - Protocol

/// Protocol for managing X-Ray feature settings
@MainActor
protocol XRaySettingsServiceProtocol: AnyObject, ObservableObject {
    /// Current state of X-Ray feature
    var isXRayEnabled: Bool { get set }

    /// Publisher for X-Ray enabled state changes
    var xRayEnabledPublisher: AnyPublisher<Bool, Never> { get }

    /// No-op; X-Ray is always enabled (kept for compatibility)
    @MainActor func toggleXRay(onPaywallRequired: @escaping () -> Void)
}

// MARK: - Implementation

/// Service for managing X-Ray feature settings with UserDefaults persistence
@MainActor
final class XRaySettingsService: XRaySettingsServiceProtocol, ObservableObject {

    // MARK: - Constants

    private enum Keys {
        static let xRayEnabled = "xray_salary_enabled"
    }

    // MARK: - Published Properties

    @Published var isXRayEnabled: Bool {
        didSet {
            // Persist to UserDefaults
            userDefaults.set(isXRayEnabled, forKey: Keys.xRayEnabled)
            // Notify observers
            xRayEnabledSubject.send(isXRayEnabled)
        }
    }

    // MARK: - Dependencies

    private let userDefaults: UserDefaults

    // MARK: - Combine

    private let xRayEnabledSubject = PassthroughSubject<Bool, Never>()

    var xRayEnabledPublisher: AnyPublisher<Bool, Never> {
        xRayEnabledSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    /// Initializes the X-Ray settings service
    /// - Parameters:
    ///   - userDefaults: UserDefaults instance for persistence (default: .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // X-Ray is always enabled for all users. If a legacy false value is found,
        // force-enable it to maintain the always-on experience.
        let persisted = userDefaults.object(forKey: Keys.xRayEnabled) as? Bool
        let initialEnabled = persisted == false ? true : (persisted ?? true)

        self.isXRayEnabled = initialEnabled
        self.userDefaults.set(true, forKey: Keys.xRayEnabled)
    }

    // MARK: - Public Methods

    func toggleXRay(onPaywallRequired: @escaping () -> Void) {
        // Always-on: ensure true and emit
        if !isXRayEnabled {
            isXRayEnabled = true
        }
        xRayEnabledSubject.send(isXRayEnabled)
    }

    // MARK: - Internal Methods (for testing)

    /// Directly sets the X-Ray enabled state (bypassing subscription check)
    /// - Note: For testing purposes only
    func setXRayEnabled(_ enabled: Bool) {
        // Setting isXRayEnabled will trigger didSet which handles publishing
        isXRayEnabled = enabled
    }
}
