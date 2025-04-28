import Foundation
import SwiftUI // For CGFloat

/// Defines global constants used throughout the PayslipMax application.
/// Encapsulates constants related to app identity, security settings, and UI dimensions.
enum AppConstants {
    // MARK: - App-wide constants
    
    /// The name of the application.
    static let appName = "PayslipMax"
    
    /// The current version number of the application.
    static let appVersion = "1.0.0"
    
    /// The unique identifier for the application in the App Store.
    /// **Note:** Replace "YOUR_APP_STORE_ID" with the actual App Store ID.
    static let appStoreId = "YOUR_APP_STORE_ID"
    
    // MARK: - Security constants
    
    /// Defines constants related to application security settings.
    enum Security {
        /// The maximum number of allowed failed login attempts before potential lockout or other action.
        static let maxLoginAttempts = 3
        
        /// The duration of inactivity after which a user session is considered timed out (in seconds).
        static let sessionTimeout: TimeInterval = 15 * 60 // 15 minutes
        
        /// The interval at which security keys (e.g., encryption keys) should be rotated (in seconds).
        static let keyRotationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    // MARK: - UI constants
    
    /// Defines constants related to user interface dimensions and styling.
    enum UI {
        /// The standard corner radius used for UI elements like buttons and cards.
        static let cornerRadius: CGFloat = 10
        
        /// The default padding value used around UI elements and containers.
        static let defaultPadding: CGFloat = 16
        
        /// The default spacing value used between adjacent UI elements.
        static let defaultSpacing: CGFloat = 8
    }
} 