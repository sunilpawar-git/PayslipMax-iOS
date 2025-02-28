import SwiftUI
import SwiftData
import Foundation

// Forward declarations for types we need
protocol DataServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
    func save<T: Codable>(_ item: T) async throws
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T]
    func delete<T: Codable>(_ item: T) async throws
}

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

class DIContainer {
    static let shared = DIContainer()
    
    var dataService: DataServiceProtocol {
        fatalError("Not implemented")
    }
    
    var cloudRepository: CloudRepositoryProtocol {
        fatalError("Not implemented")
    }
    
    var premiumFeatureManager: PremiumFeatureManager {
        return PremiumFeatureManager.shared
    }
}

// Placeholder for PayslipItem
class PayslipItem {
    var id: UUID = UUID()
    var name: String = ""
    var month: String = ""
    var year: Int = 0
}

@MainActor
final class PayslipsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateDescending
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var isPremium = false
    
    // MARK: - Services
    private let dataService: DataServiceProtocol
    private let cloudRepository: CloudRepositoryProtocol
    private let premiumFeatureManager: PremiumFeatureManager
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil, 
         cloudRepository: CloudRepositoryProtocol? = nil,
         premiumFeatureManager: PremiumFeatureManager? = nil) {
        let container = DIContainer.shared
        self.dataService = dataService ?? container.dataService
        self.cloudRepository = cloudRepository ?? container.cloudRepository
        self.premiumFeatureManager = premiumFeatureManager ?? container.premiumFeatureManager
        
        // Check premium status on init
        Task {
            await checkPremiumStatus()
        }
    }
    
    // MARK: - Public Methods
    func deletePayslip(_ payslip: PayslipItem, from context: ModelContext) {
        context.delete(payslip)
        try? context.save()
        
        // If premium, sync the deletion to cloud
        Task {
            await syncIfPremium()
        }
    }
    
    func filterPayslips(_ payslips: [PayslipItem]) -> [PayslipItem] {
        guard !searchText.isEmpty else { return payslips }
        
        return payslips.filter { payslip in
            payslip.name.localizedCaseInsensitiveContains(searchText) ||
            payslip.month.localizedCaseInsensitiveContains(searchText) ||
            String(payslip.year).contains(searchText)
        }
    }
    
    // MARK: - Premium Features
    func checkPremiumStatus() async {
        isPremium = await premiumFeatureManager.isPremiumUser()
    }
    
    func syncIfPremium() async {
        guard await premiumFeatureManager.isPremiumUser() else { return }
        
        do {
            isSyncing = true
            try await cloudRepository.syncPayslips()
            lastSyncDate = Date()
            isSyncing = false
        } catch {
            self.error = error
            isSyncing = false
        }
    }
    
    func backupPayslips() async {
        guard await premiumFeatureManager.isPremiumUser() else { return }
        
        do {
            isLoading = true
            try await cloudRepository.backupPayslips()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func restorePayslips() async {
        guard await premiumFeatureManager.isPremiumUser() else { return }
        
        do {
            isLoading = true
            try await cloudRepository.restorePayslips()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Supporting Types
    enum SortOrder {
        case dateAscending
        case dateDescending
        case nameAscending
        case nameDescending
    }
} 