import Foundation
#if canImport(UIKit)
import UIKit
import SwiftUI
#elseif canImport(AppKit)
import AppKit
import SwiftUI
#endif

/// Service that handles UI appearance operations requiring UIKit/AppKit
/// Phase 2C: Converted to dual-mode pattern supporting both singleton and DI
@MainActor
class AppearanceService {
    /// Phase 2C: Shared instance maintained for backward compatibility
    static let shared = AppearanceService()

    /// Phase 2C: Private initializer for singleton pattern
    private init() {
        setupNotificationObservers()
    }

    /// Phase 2C: Public initializer for dependency injection
    /// - Parameter setupNotifications: Whether to setup notification observers (default: true)
    init(setupNotifications: Bool = true) {
        if setupNotifications {
            setupNotificationObservers()
        }
    }

    /// Setup notification observers to handle appearance manager events
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigureTabBar),
            name: Notification.Name("ConfigureTabBarAppearance"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigureNavigationBar),
            name: Notification.Name("ConfigureNavigationBarAppearance"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUITestingSetup),
            name: Notification.Name("SetupForUITesting"),
            object: nil
        )

        // Listen to both legacy and new theme notification names for compatibility
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplyTheme),
            name: Notification.Name("ApplyTheme"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeDidChange),
            name: .themeDidChange,
            object: nil
        )
    }

    // MARK: - UI Configuration Methods

    /// Configure tab bar appearance
    @objc private func handleConfigureTabBar() {
        #if canImport(UIKit)
        // Set the tab bar appearance to use system background color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()

        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        #endif
    }

    /// Configure navigation bar appearance
    @objc private func handleConfigureNavigationBar() {
        #if canImport(UIKit)
        // Set the navigation bar appearance to use system background color
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance

        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
        #endif
    }

    /// Setup UI testing configuration
    @objc private func handleUITestingSetup() {
        #if canImport(UIKit)
        // Ensure tab bar buttons are accessible
        UITabBar.appearance().isAccessibilityElement = true

        // Make tab bar items more discoverable
        for item in UITabBar.appearance().items ?? [] {
            item.isAccessibilityElement = true
            if let title = item.title {
                item.accessibilityLabel = title
                item.accessibilityIdentifier = title
            }
        }

        // Disable animations for testing
        UIView.setAnimationsEnabled(false)
        #endif
    }

    /// Apply theme based on legacy notification
    @objc private func handleApplyTheme(_ notification: Notification) {
        guard let themeName = notification.userInfo?["theme"] as? String,
              let theme = AppTheme(rawValue: themeName) else {
            return
        }
        applyThemeToAllWindows(theme)
    }

    /// Handle unified theme change notification
    @objc private func handleThemeDidChange(_ notification: Notification) {
        guard let themeName = notification.userInfo?["theme"] as? String,
              let theme = AppTheme(rawValue: themeName) else {
            return
        }
        applyThemeToAllWindows(theme)
    }

    /// Apply theme to all windows in all scenes
    private func applyThemeToAllWindows(_ theme: AppTheme) {
        #if canImport(UIKit)
        // Apply to ALL windows in ALL scenes, not just the first
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }

            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = theme.uiInterfaceStyle
            }
        }
        #elseif canImport(AppKit)
        // For macOS, use the appearance property of NSApp
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
        #endif
    }

    /// Initialize the service in app startup
    static func initialize() {
        // This is called to ensure the singleton is created and notification observers are registered
        _ = AppearanceService.shared
    }
}
