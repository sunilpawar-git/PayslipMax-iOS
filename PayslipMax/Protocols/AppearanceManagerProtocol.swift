import Foundation

/// Protocol for managing UI appearance configuration throughout the app
@MainActor
protocol AppearanceManagerProtocol {
    /// Configures the global appearance of UITabBar
    func configureTabBarAppearance()

    /// Configures the global appearance of UINavigationBar
    func configureNavigationBarAppearance()

    /// Sets up configurations suitable for UI testing environments
    func configureForUITesting()

    /// Applies all appearance configurations
    func applyAllConfigurations()
}
