import Foundation
import SwiftUI

class PremiumUpgradeViewModel: ObservableObject {
    private let premiumFeatureManager: PremiumFeatureManager
    private let cloudRepository: CloudRepositoryProtocol
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var features: [PremiumFeatureManager.PremiumFeature] = []
    
    init(premiumFeatureManager: PremiumFeatureManager, cloudRepository: CloudRepositoryProtocol) {
        self.premiumFeatureManager = premiumFeatureManager
        self.cloudRepository = cloudRepository
        self.features = PremiumFeatureManager.PremiumFeature.allCases
    }
    
    func upgradeAction() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            try await premiumFeatureManager.upgradeToPremiun()
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Premium features are not yet implemented. Coming soon!"
                self.showError = true
            }
        }
    }
    
    func checkPremiumStatus() async {
        await premiumFeatureManager.checkPremiumStatus()
    }
    
    func isPremiumUser() -> Bool {
        return premiumFeatureManager.isPremiumUser
    }
    
    func isFeatureAvailable(_ feature: PremiumFeatureManager.PremiumFeature) -> Bool {
        return premiumFeatureManager.isFeatureAvailable(feature)
    }
} 