import Foundation
import SwiftUI

@MainActor
final class PremiumUpgradeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage = ""
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published private(set) var isPremium = false
    @Published private(set) var availableFeatures: [PremiumFeatureManager.PremiumFeature] = []
    
    // MARK: - Services
    private let premiumFeatureManager: PremiumFeatureManager
    private let cloudRepository: CloudRepositoryProtocol
    
    // MARK: - Initialization
    init(premiumFeatureManager: PremiumFeatureManager, cloudRepository: CloudRepositoryProtocol) {
        self.premiumFeatureManager = premiumFeatureManager
        self.cloudRepository = cloudRepository
        
        // Load available features
        self.availableFeatures = PremiumFeatureManager.PremiumFeature.allCases
        
        // Check premium status
        Task {
            await checkPremiumStatus()
        }
    }
    
    // MARK: - Public Methods
    func upgradeToPremium() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            try await premiumFeatureManager.upgradeToPremium()
            await checkPremiumStatus()
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    func checkPremiumStatus() async {
        isPremium = await premiumFeatureManager.isPremiumUser()
    }
} 