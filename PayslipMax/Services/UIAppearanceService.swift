import Foundation
#if canImport(UIKit)
import UIKit
import SwiftUI
#elseif canImport(AppKit)
import AppKit
import SwiftUI
#endif

/// Service that handles UI appearance operations requiring UIKit/AppKit
@MainActor
class AppearanceService {
    /// Shared instance 
    static let shared = AppearanceService()
    
    /// Initialize and register for notifications from AppearanceManager
    private init() {
        setupNotificationObservers()
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplyTheme),
            name: Notification.Name("ApplyTheme"),
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
    
    /// Apply theme based on notification
    @objc private func handleApplyTheme(_ notification: Notification) {
        guard let themeName = notification.userInfo?["theme"] as? String,
              let theme = AppTheme(rawValue: themeName) else {
            return
        }
        
        #if canImport(UIKit)
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            let interfaceStyle: UIUserInterfaceStyle
            switch theme {
            case .light:
                interfaceStyle = .light
            case .dark:
                interfaceStyle = .dark
            case .system:
                interfaceStyle = .unspecified
            }
            
            window?.overrideUserInterfaceStyle = interfaceStyle
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