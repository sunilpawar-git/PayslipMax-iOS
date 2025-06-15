import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Represents the app's theme/appearance mode
public enum AppTheme: String, CaseIterable, Identifiable {
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

/// Global theme manager to handle theme changes across the entire app
@MainActor
public class ThemeManager: ObservableObject {
    /// Shared instance of the theme manager
    public static let shared = ThemeManager()
    
    /// The current app theme
    @Published public var currentTheme: AppTheme {
        didSet {
            applyTheme(currentTheme)
            saveTheme(currentTheme)
        }
    }
    
    /// User defaults key for storing the theme
    private let themeKey = "appTheme"
    
    /// Private initializer for singleton
    private init() {
        // Load saved theme or default to system
        if let themeName = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeName) {
            self.currentTheme = theme
        } else {
            // For backward compatibility
            let useDarkMode = UserDefaults.standard.bool(forKey: "useDarkMode")
            self.currentTheme = useDarkMode ? .dark : .light
        }
        
        // Apply the theme immediately
        applyTheme(currentTheme)
    }
    
    /// Apply the specified theme to the entire app
    public func applyTheme(_ theme: AppTheme) {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }
            
            window.overrideUserInterfaceStyle = theme.uiInterfaceStyle
            
            // Force update all existing views
            window.setNeedsDisplay()
            
            // Post notification for any components that need to update
            NotificationCenter.default.post(
                name: Notification.Name("ThemeChanged"),
                object: nil,
                userInfo: ["theme": theme.rawValue]
            )
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
    
    /// Save the theme to user defaults
    private func saveTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        
        // Also save legacy key for backward compatibility
        UserDefaults.standard.set(theme == .dark, forKey: "useDarkMode")
    }
    
    /// Set a new theme
    public func setTheme(_ theme: AppTheme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
    }
} 