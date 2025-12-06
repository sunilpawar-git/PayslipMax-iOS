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

    /// Toggles X-Ray feature with subscription gating
    /// - Parameter onPaywallRequired: Callback invoked when user needs to subscribe
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

    private let subscriptionValidator: SubscriptionValidatorProtocol
    private let userDefaults: UserDefaults

    // MARK: - Combine

    private let xRayEnabledSubject = PassthroughSubject<Bool, Never>()

    var xRayEnabledPublisher: AnyPublisher<Bool, Never> {
        xRayEnabledSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    /// Initializes the X-Ray settings service
    /// - Parameters:
    ///   - subscriptionValidator: Validator for checking premium access
    ///   - userDefaults: UserDefaults instance for persistence (default: .standard)
    init(
        subscriptionValidator: SubscriptionValidatorProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.subscriptionValidator = subscriptionValidator
        self.userDefaults = userDefaults

        // Load persisted state
        self.isXRayEnabled = userDefaults.bool(forKey: Keys.xRayEnabled)
    }

    // MARK: - Public Methods

    func toggleXRay(onPaywallRequired: @escaping () -> Void) {
        // Check subscription status
        guard subscriptionValidator.canAccessXRayFeature() else {
            // User doesn't have premium access - show paywall
            onPaywallRequired()
            return
        }

        // Toggle the state (didSet will handle publishing)
        isXRayEnabled.toggle()
    }

    // MARK: - Internal Methods (for testing)

    /// Directly sets the X-Ray enabled state (bypassing subscription check)
    /// - Note: For testing purposes only
    func setXRayEnabled(_ enabled: Bool) {
        // Setting isXRayEnabled will trigger didSet which handles publishing
        isXRayEnabled = enabled
    }
}
