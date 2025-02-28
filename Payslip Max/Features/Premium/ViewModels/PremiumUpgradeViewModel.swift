import Foundation
import SwiftUI

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