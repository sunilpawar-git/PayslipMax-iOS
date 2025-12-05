import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Represents the app's theme/appearance mode
public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    /// Light appearance mode.
    case light = "Light"
    /// Dark appearance mode.
    case dark = "Dark"
    /// Use the system's current appearance setting.
    case system = "System"

    /// The stable identifier for the theme, matching its raw value.
    public var id: String { self.rawValue }

    /// The SF Symbol name representing the theme for UI display.
    public var systemImage: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }

    /// The SwiftUI ColorScheme for the theme (nil for system = follow system)
    public var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    #if canImport(UIKit)
    /// The corresponding `UIUserInterfaceStyle` for UIKit integration.
    /// Returns `.unspecified` for the `.system` theme.
    public var uiInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
    #endif
}

/// Notification name for theme changes - use this for consistency
public extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

/// Global theme manager to handle theme changes across the entire app
@MainActor
public class ThemeManager: ObservableObject {
    /// Shared instance of the theme manager
    public static let shared = ThemeManager()

    /// The current app theme
    @Published public private(set) var currentTheme: AppTheme

    /// User defaults key for storing the theme
    private let themeKey = "appTheme"

    /// UserDefaults instance (injectable for testing)
    private let userDefaults: UserDefaults

    /// Flag to track if initial theme application has been attempted
    private var hasAppliedInitialTheme = false

    /// Private initializer for singleton
    private init() {
        self.userDefaults = .standard
        self.currentTheme = Self.loadTheme(from: .standard)
    }

    /// Internal initializer for testing with custom UserDefaults
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.currentTheme = Self.loadTheme(from: userDefaults)
    }

    /// Loads the theme from UserDefaults
    /// - Parameter defaults: The UserDefaults instance to load from
    /// - Returns: The saved theme, or `.system` for new users
    private static func loadTheme(from defaults: UserDefaults) -> AppTheme {
        // Check for saved theme using the new key
        if let themeName = defaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeName) {
            return theme
        }

        // Check for legacy useDarkMode key (migration path)
        // Only apply if user explicitly set dark mode before
        if defaults.object(forKey: "useDarkMode") != nil {
            let useDarkMode = defaults.bool(forKey: "useDarkMode")
            return useDarkMode ? .dark : .light
        }

        // FIX: Default to .system for new users (not .light!)
        // This ensures the app follows system theme by default
        return .system
    }

    /// Apply the current theme when the app becomes ready
    /// Called from PayslipMaxApp after window is available
    public func applyInitialThemeIfNeeded() {
        guard !hasAppliedInitialTheme else { return }
        hasAppliedInitialTheme = true
        applyThemeToAllWindows(currentTheme)
    }

    /// Apply the specified theme to the entire app
    public func applyTheme(_ theme: AppTheme) {
        applyThemeToAllWindows(theme)
        postThemeChangeNotification(theme)
    }

    /// Apply theme to all windows in all scenes
    private func applyThemeToAllWindows(_ theme: AppTheme) {
        #if canImport(UIKit)
        // Get all connected window scenes and apply to ALL windows
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }

            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = theme.uiInterfaceStyle
            }
        }
        #elseif canImport(AppKit)
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

    /// Post notification for theme change
    private func postThemeChangeNotification(_ theme: AppTheme) {
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: self,
            userInfo: ["theme": theme.rawValue, "colorScheme": theme.colorScheme as Any]
        )
    }

    /// Save the theme to user defaults
    private func saveTheme(_ theme: AppTheme) {
        userDefaults.set(theme.rawValue, forKey: themeKey)

        // Also save legacy key for backward compatibility
        userDefaults.set(theme == .dark, forKey: "useDarkMode")
    }

    /// Set a new theme
    public func setTheme(_ theme: AppTheme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
        applyTheme(theme)
        saveTheme(theme)
    }

    // MARK: - Testing Support

    /// Reset the manager for testing purposes
    func resetForTesting() {
        hasAppliedInitialTheme = false
    }
}
