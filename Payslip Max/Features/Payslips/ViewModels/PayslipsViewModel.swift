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
    func deletePayslip(_ payslip: PayslipItem, from context: ModelContextProtocol) {
        context.delete(payslip)
        try? context.save()
    }
    
    // Delete payslips at specified indices from an array
    func deletePayslips(at indexSet: IndexSet, from payslips: [PayslipItem], context: ModelContextProtocol) {
        for index in indexSet {
            if index < payslips.count {
                deletePayslip(payslips[index], from: context)
            }
        }
    }
    
    func filterPayslips(_ payslips: [PayslipItem], searchText: String? = nil) -> [PayslipItem] {
        var filteredPayslips = payslips
        
        // Apply search filter
        let searchQuery = searchText ?? self.searchText
        if !searchQuery.isEmpty {
            filteredPayslips = filteredPayslips.filter { payslip in
                payslip.name.localizedCaseInsensitiveContains(searchQuery) ||
                payslip.month.localizedCaseInsensitiveContains(searchQuery) ||
                String(payslip.year).localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .dateAscending:
            filteredPayslips.sort { $0.year == $1.year ? monthToInt($0.month) < monthToInt($1.month) : $0.year < $1.year }
        case .dateDescending:
            filteredPayslips.sort { $0.year == $1.year ? monthToInt($0.month) > monthToInt($1.month) : $0.year > $1.year }
        case .amountAscending:
            filteredPayslips.sort { $0.credits < $1.credits }
        case .amountDescending:
            filteredPayslips.sort { $0.credits > $1.credits }
        case .nameAscending:
            filteredPayslips.sort { $0.name < $1.name }
        case .nameDescending:
            filteredPayslips.sort { $0.name > $1.name }
        }
        
        return filteredPayslips
    }
    
    // Helper function to convert month name to integer for sorting
    private func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        if let date = formatter.date(from: month) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // If month is a number string, convert directly
        if let monthNum = Int(month) {
            return monthNum
        }
        
        return 0 // Default for unknown month format
    }
    
    // MARK: - Supporting Types
    enum SortOrder: String, CaseIterable, Identifiable {
        case dateAscending = "Date (Oldest First)"
        case dateDescending = "Date (Newest First)"
        case amountAscending = "Amount (Low to High)"
        case amountDescending = "Amount (High to Low)"
        case nameAscending = "Name (A to Z)"
        case nameDescending = "Name (Z to A)"
        
        var id: String { self.rawValue }
    }
} 