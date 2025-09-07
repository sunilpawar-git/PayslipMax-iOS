import Foundation
import SwiftUI
import SwiftData
import Combine

// Remove the Core import and just reference AppTheme directly

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Whether the view model is loading data.
    @Published var isLoading = false

    /// The error to display to the user.
    @Published var error: AppError?

    /// Whether to use biometric authentication.
    @Published var useBiometricAuth = false

    /// The app's theme/appearance mode - now bound to ThemeManager
    @Published var appTheme: AppTheme = .system

    /// Whether to use dark mode (legacy property, kept for backward compatibility)
    @Published var useDarkMode = false

    /// The payslips to display.
    @Published var payslips: [AnyPayslip] = []

    // MARK: - Private Properties

    /// The security service to use for authentication.
    private let securityService: SecurityServiceProtocol

    /// The data service to use for fetching and saving data.
    let dataService: DataServiceProtocol

    /// The user defaults to use for storing preferences.
    let userDefaults: UserDefaults

    /// The cancellables for managing subscriptions.
    var cancellables = Set<AnyCancellable>()

    /// Flag to prevent circular updates between theme manager and view model
    var isUpdatingTheme = false

    // MARK: - Initialization

    /// Initializes a new SettingsViewModel.
    ///
    /// - Parameters:
    ///   - securityService: The security service to use for authentication.
    ///   - dataService: The data service to use for fetching and saving data.
    ///   - userDefaults: The user defaults to use for storing preferences.
    init(
        securityService: SecurityServiceProtocol? = nil,
        dataService: DataServiceProtocol? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.userDefaults = userDefaults

        // Load preferences from user defaults
        self.useBiometricAuth = userDefaults.bool(forKey: "useBiometricAuth")

        // Sync with ThemeManager without triggering circular updates
        self.appTheme = ThemeManager.shared.currentTheme
        self.useDarkMode = (appTheme == .dark)

        // Set up theme change subscription AFTER initial setup
        setupThemeSubscription()

        // Initialize the data service
        Task {
            do {
                if let dataService = self.dataService as? DataServiceImpl, !dataService.isInitialized {
                    try await self.dataService.initialize()
                }
            } catch {
                await MainActor.run {
                    // Log error but don't show to user yet - wait until they actually try to use it
                    ErrorLogger.log(error)
                }
            }
        }
    }

    /// Sets up the subscription to theme changes from ThemeManager
    private func setupThemeSubscription() {
        ThemeManager.shared.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTheme in
                guard let self = self, !self.isUpdatingTheme else { return }

                self.appTheme = newTheme
                self.useDarkMode = (newTheme == .dark)
            }
            .store(in: &cancellables)
    }

    /// Deinitializer to clean up subscriptions and prevent memory leaks
    deinit {
        cancellables.removeAll()
    }
    
}
