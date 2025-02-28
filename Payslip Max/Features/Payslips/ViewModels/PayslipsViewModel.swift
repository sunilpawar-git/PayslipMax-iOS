import SwiftUI
import SwiftData
import Foundation

// Import the necessary types from our Core modules
import Payslip_Max.Core.Network.NetworkTypes

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