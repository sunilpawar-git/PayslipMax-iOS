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