import SwiftUI
import SwiftData
import Foundation

@MainActor
final class PayslipsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateDescending
    
    // MARK: - Services
    private let dataService: DataServiceProtocol
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    func deletePayslip(_ payslip: PayslipItem, from context: ModelContext) {
        context.delete(payslip)
        try? context.save()
    }
    
    func filterPayslips(_ payslips: [PayslipItem]) -> [PayslipItem] {
        guard !searchText.isEmpty else { return payslips }
        
        return payslips.filter { payslip in
            payslip.name.localizedCaseInsensitiveContains(searchText) ||
            payslip.month.localizedCaseInsensitiveContains(searchText) ||
            String(payslip.year).contains(searchText)
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