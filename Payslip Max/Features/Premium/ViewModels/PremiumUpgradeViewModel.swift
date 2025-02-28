import Foundation
import SwiftUI

// Forward declarations
class PremiumFeatureManager {
    static let shared = PremiumFeatureManager()
    var isPremiumUser = false
    var availableFeatures: [PremiumFeature] = []
    
    enum PremiumFeature: String, CaseIterable, Identifiable {
        case cloudBackup = "Cloud Backup"
        case dataSync = "Data Sync"
        case advancedInsights = "Advanced Insights"
        case exportFeatures = "Export Features"
        case prioritySupport = "Priority Support"
        
        var id: String { rawValue }
    }
    
    func upgradeToPremium() async throws {}
    func isPremiumUser() async -> Bool { return isPremiumUser }
}

protocol CloudRepositoryProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
    func syncPayslips() async throws
    func backupPayslips() async throws
    func fetchBackups() async throws -> [PayslipBackup]
    func restorePayslips() async throws
}

struct PayslipBackup: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let payslipCount: Int
    let data: Data
}

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
    init(premiumFeatureManager: PremiumFeatureManager = .shared, cloudRepository: CloudRepositoryProtocol) {
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