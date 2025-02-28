import Foundation
import SwiftUI

enum FeatureError: Error {
    case premiumRequired
    case notImplemented
    case notAvailable
}

class PremiumFeatureManager: ObservableObject {
    static let shared = PremiumFeatureManager()
    
    @Published private(set) var isPremiumUser = false
    @Published private(set) var availableFeatures: [PremiumFeature] = []
    
    enum PremiumFeature: CaseIterable {
        case cloudBackup
        case crossDeviceSync
        case advancedAnalytics
        case exportReports
        
        var title: String {
            switch self {
            case .cloudBackup: return "Cloud Backup"
            case .crossDeviceSync: return "Cross-Device Sync"
            case .advancedAnalytics: return "Advanced Analytics"
            case .exportReports: return "Export Reports"
            }
        }
        
        var description: String {
            switch self {
            case .cloudBackup: return "Securely store your payslips in the cloud"
            case .crossDeviceSync: return "Access your payslips on all your devices"
            case .advancedAnalytics: return "Get deeper insights into your finances"
            case .exportReports: return "Export detailed reports in multiple formats"
            }
        }
        
        var icon: String {
            switch self {
            case .cloudBackup: return "icloud"
            case .crossDeviceSync: return "devices.homekit"
            case .advancedAnalytics: return "chart.bar"
            case .exportReports: return "square.and.arrow.up"
            }
        }
    }
    
    private init() {
        // In the future, this will check for premium status
        // For now, always set to false
        self.isPremiumUser = false
        self.availableFeatures = []
    }
    
    func checkPremiumStatus() async {
        // This will be implemented in Phase 2
        // For now, do nothing
    }
    
    func upgradeToPremiun() async throws {
        // This will be implemented in Phase 2
        throw FeatureError.notImplemented
    }
    
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        return isPremiumUser && availableFeatures.contains(feature)
    }
} 