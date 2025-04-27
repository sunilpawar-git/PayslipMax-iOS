import Foundation
import UIKit

/// Manages UI appearance configuration throughout the app
@MainActor
class AppearanceManager {
    // MARK: - Properties
    
    /// Shared instance of AppearanceManager
    static let shared = AppearanceManager()
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton usage.
    private init() {
        // Private initializer to enforce singleton usage
    }
    
    // MARK: - Configuration Methods
    
    /// Configures the global appearance of `UITabBar` using `UITabBarAppearance`.
    /// Sets a default background style suitable for standard and scroll edge appearances.
    func configureTabBarAppearance() {
        // Set the tab bar appearance to use system background color
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    /// Configures the global appearance of `UINavigationBar` using `UINavigationBarAppearance`.
    /// Sets a default background style suitable for standard, compact, and scroll edge appearances.
    func configureNavigationBarAppearance() {
        // Set the navigation bar appearance to use system background color
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
    }
    
    /// Sets up specific configurations suitable for UI testing environments.
    /// This typically involves improving accessibility discoverability and disabling animations.
    func setupForUITesting() {
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
        
        // Other testing configuration
        configureForTestingEnvironment()
        
        // Log test setup
        print("Setting up for UI testing mode")
    }
    
    /// Configures specific UI settings suitable for the testing environment.
    /// Currently disables UIView animations to prevent flakiness in UI tests.
    private func configureForTestingEnvironment() {
        // Enable additional accessibility identifiers
        // Disable animations
        UIView.setAnimationsEnabled(false)
    }
} 