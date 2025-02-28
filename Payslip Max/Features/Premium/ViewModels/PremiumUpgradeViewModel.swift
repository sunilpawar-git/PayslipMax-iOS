import Foundation
import SwiftUI

// Import the necessary types from Core/Network
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

// Forward declarations for types we need
protocol CloudRepositoryProtocol {
    func syncPayslips() async throws
    func backupPayslips() async throws
    func fetchBackups() async throws -> [PayslipBackup]
    func restorePayslips() async throws
}

struct PayslipBackup: Codable {
    let id: UUID
    let timestamp: Date
    let payslipCount: Int
    let data: Data
}

class PremiumFeatureManager {
    // Singleton instance
    static let shared = PremiumFeatureManager()
    
    // Premium status
    private var _isPremiumUser = false
    
    // Available premium features
    enum PremiumFeature: String, CaseIterable {
        case cloudBackup
        case dataSync
        case advancedInsights
        case exportFeatures
        case prioritySupport
    }
    
    // Check if user is premium
    func isPremiumUser() async -> Bool {
        // In a real implementation, this would check with the server
        // For now, return the local value
        return _isPremiumUser
    }
    
    // Check if a specific feature is available
    func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
        return await isPremiumUser()
    }
    
    // Upgrade to premium
    func upgradeToPremium() async throws {
        // In a real implementation, this would initiate a payment flow
        // For now, just set the flag to true
        _isPremiumUser = true
    }
    
    // Downgrade from premium (for testing)
    func downgradeFromPremium() {
        _isPremiumUser = false
    }
}

@MainActor
final class PremiumUpgradeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isPremium = false
    @Published private(set) var availableFeatures: [PremiumFeature] = []
    
    // MARK: - Services
    private let premiumFeatureManager: PremiumFeatureManager
    private let cloudRepository: CloudRepositoryProtocol
    
    // MARK: - Premium Features
    enum PremiumFeature: String, CaseIterable, Identifiable {
        case cloudBackup = "Cloud Backup"
        case dataSync = "Data Sync"
        case advancedInsights = "Advanced Insights"
        case exportFeatures = "Export Features"
        case prioritySupport = "Priority Support"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .cloudBackup:
                return "Securely back up your payslips to the cloud"
            case .dataSync:
                return "Sync your payslips across all your devices"
            case .advancedInsights:
                return "Get detailed insights and analytics about your finances"
            case .exportFeatures:
                return "Export your payslips in various formats"
            case .prioritySupport:
                return "Get priority support from our team"
            }
        }
        
        var iconName: String {
            switch self {
            case .cloudBackup:
                return "icloud"
            case .dataSync:
                return "arrow.triangle.2.circlepath"
            case .advancedInsights:
                return "chart.bar.xaxis"
            case .exportFeatures:
                return "square.and.arrow.up"
            case .prioritySupport:
                return "person.fill.checkmark"
            }
        }
    }
    
    // MARK: - Initialization
    init(premiumFeatureManager: PremiumFeatureManager, cloudRepository: CloudRepositoryProtocol) {
        self.premiumFeatureManager = premiumFeatureManager
        self.cloudRepository = cloudRepository
        
        // Check premium status on init
        Task {
            await checkPremiumStatus()
        }
    }
    
    // MARK: - Public Methods
    func checkPremiumStatus() async {
        isPremium = await premiumFeatureManager.isPremiumUser()
        
        // Set available features
        availableFeatures = PremiumFeature.allCases
    }
    
    func upgradeToPremium() async {
        do {
            isLoading = true
            try await premiumFeatureManager.upgradeToPremium()
            isPremium = true
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func restorePurchases() async {
        do {
            isLoading = true
            // In a real implementation, this would restore purchases from the App Store
            try await premiumFeatureManager.upgradeToPremium()
            isPremium = true
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 