import Foundation
import SwiftUI

/// Provides centralized access to performance debugging settings
@MainActor
class PerformanceDebugSettings: ObservableObject {
    /// Shared instance of the settings
    static let shared = PerformanceDebugSettings()
    
    /// Whether performance warning logs are enabled
    @Published var isPerformanceWarningLogsEnabled: Bool {
        didSet {
            ViewPerformanceTracker.shared.isLogWarningsEnabled = isPerformanceWarningLogsEnabled
            UserDefaults.standard.set(isPerformanceWarningLogsEnabled, forKey: "isPerformanceWarningLogsEnabled")
            
            // Log the current status when changed
            logCurrentStatus()
        }
    }
    
    /// Private initializer for singleton
    private init() {
        // Load setting from UserDefaults with default value of false
        self.isPerformanceWarningLogsEnabled = UserDefaults.standard.bool(forKey: "isPerformanceWarningLogsEnabled")
        
        // Apply setting to tracker
        ViewPerformanceTracker.shared.isLogWarningsEnabled = self.isPerformanceWarningLogsEnabled
    }
    
    /// Logs the current status of performance tracking
    func logCurrentStatus() {
        let status = isPerformanceWarningLogsEnabled ? "ENABLED" : "DISABLED"
        print("📊 Performance warning logs: \(status)")
        
        if isPerformanceWarningLogsEnabled {
            print("ℹ️ Performance tracking is active. You will see render time warnings in the console.")
            print("ℹ️ Toggle this off using the hammer icon in the navigation bar if these warnings are too verbose.")
        } else {
            print("ℹ️ Performance tracking warnings are silenced. Toggle ON using the hammer icon for detailed view rendering times.")
        }
    }
}

// MARK: - View Extension for Debug Settings

extension View {
    /// Adds a debug menu button to toggle performance logs (only in DEBUG mode)
    func withPerformanceDebugToggle() -> some View {
        #if DEBUG
        return self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let settings = PerformanceDebugSettings.shared
                    settings.isPerformanceWarningLogsEnabled.toggle()
                }) {
                    Image(systemName: "hammer")
                        .symbolVariant(PerformanceDebugSettings.shared.isPerformanceWarningLogsEnabled ? .fill : .none)
                }
            }
        }
        #else
        return self
        #endif
    }
} 