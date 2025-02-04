import Foundation
import SwiftUI // For CGFloat

enum AppConstants {
    // App-wide constants
    static let appName = "Payslip Max"
    static let appVersion = "1.0.0"
    static let appStoreId = "YOUR_APP_STORE_ID"
    
    // Security constants
    enum Security {
        static let maxLoginAttempts = 3
        static let sessionTimeout: TimeInterval = 15 * 60 // 15 minutes
        static let keyRotationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    // UI constants
    enum UI {
        static let cornerRadius: CGFloat = 10
        static let defaultPadding: CGFloat = 16
        static let defaultSpacing: CGFloat = 8
    }
} 