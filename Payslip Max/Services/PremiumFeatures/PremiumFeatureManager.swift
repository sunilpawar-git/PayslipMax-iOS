import Foundation
import StoreKit

/// Enum representing available premium features
enum PremiumFeature: String, CaseIterable {
    case cloudBackup
    case cloudSync
    case advancedAnalytics
    case exportPDF
    case multipleProfiles
    case prioritySupport
    
    var displayName: String {
        switch self {
        case .cloudBackup:
            return "Cloud Backup"
        case .cloudSync:
            return "Cloud Sync"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .exportPDF:
            return "PDF Export"
        case .multipleProfiles:
            return "Multiple Profiles"
        case .prioritySupport:
            return "Priority Support"
        }
    }
    
    var description: String {
        switch self {
        case .cloudBackup:
            return "Securely back up your payslips to the cloud"
        case .cloudSync:
            return "Sync your payslips across all your devices"
        case .advancedAnalytics:
            return "Get detailed insights and analytics about your pay"
        case .exportPDF:
            return "Export your payslips as PDF documents"
        case .multipleProfiles:
            return "Create multiple profiles for different jobs"
        case .prioritySupport:
            return "Get priority customer support"
        }
    }
}

/// Enum representing premium subscription tiers
enum PremiumTier: String, CaseIterable {
    case none
    case basic
    case premium
    case ultimate
    
    var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .basic:
            return "Basic"
        case .premium:
            return "Premium"
        case .ultimate:
            return "Ultimate"
        }
    }
    
    var features: [PremiumFeature] {
        switch self {
        case .none:
            return []
        case .basic:
            return [.cloudBackup]
        case .premium:
            return [.cloudBackup, .cloudSync, .exportPDF]
        case .ultimate:
            return PremiumFeature.allCases
        }
    }
    
    var price: Decimal {
        switch self {
        case .none:
            return 0
        case .basic:
            return 2.99
        case .premium:
            return 4.99
        case .ultimate:
            return 9.99
        }
    }
}

/// Class for managing premium features
class PremiumFeatureManager: ObservableObject {
    /// Published property for the current premium tier
    @Published private(set) var currentTier: PremiumTier = .none
    
    /// Published property for whether premium features are enabled
    @Published private(set) var isPremiumUser: Bool = false
    
    /// Published property for available features
    @Published private(set) var availableFeatures: [PremiumFeature] = []
    
    /// Initializes a new premium feature manager
    init() {
        // In a real implementation, this would load the user's subscription status
        // For now, we'll just set it to the free tier
        self.currentTier = .none
        self.isPremiumUser = false
        self.availableFeatures = currentTier.features
        
        // Load subscription status from UserDefaults for testing
        loadSubscriptionStatus()
    }
    
    /// Checks if a specific feature is available
    /// - Parameter feature: The feature to check
    /// - Returns: Boolean indicating if the feature is available
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return availableFeatures.contains(feature)
    }
    
    /// Upgrades to a premium tier
    /// - Parameter tier: The tier to upgrade to
    /// - Returns: Boolean indicating if the upgrade was successful
    @MainActor
    func upgradeTo(tier: PremiumTier) async -> Bool {
        // In a real implementation, this would initiate a purchase flow
        // For now, we'll just simulate a successful upgrade
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update the tier and available features
        self.currentTier = tier
        self.isPremiumUser = tier != .none
        self.availableFeatures = tier.features
        
        // Save subscription status to UserDefaults for testing
        saveSubscriptionStatus()
        
        return true
    }
    
    /// Restores purchases
    /// - Returns: Boolean indicating if the restore was successful
    @MainActor
    func restorePurchases() async -> Bool {
        // In a real implementation, this would restore purchases from the App Store
        // For now, we'll just simulate a successful restore
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // For testing, we'll just return true
        return true
    }
    
    // MARK: - Private Methods
    
    /// Loads subscription status from UserDefaults
    private func loadSubscriptionStatus() {
        if let tierString = UserDefaults.standard.string(forKey: "premiumTier"),
           let tier = PremiumTier(rawValue: tierString) {
            self.currentTier = tier
            self.isPremiumUser = tier != .none
            self.availableFeatures = tier.features
        }
    }
    
    /// Saves subscription status to UserDefaults
    private func saveSubscriptionStatus() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "premiumTier")
    }
} 