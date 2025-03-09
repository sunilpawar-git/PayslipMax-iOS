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
    
    /// Initializes a new PayslipsViewModel with the specified data service.
    ///
    /// - Parameter dataService: The data service to use for fetching and managing payslips.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Deletes a payslip from the specified context.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to delete.
    ///   - context: The model context to delete from.
    func deletePayslip(_ payslip: any PayslipItemProtocol, from context: ModelContextProtocol) {
        // Since we're using a protocol, we need to handle the concrete type
        if let concretePayslip = payslip as? PayslipItem {
            context.delete(concretePayslip)
            try? context.save()
        } else {
            // Log the error for debugging purposes
            print("Warning: Deletion of non-PayslipItem types is not implemented")
            
            // Notify the user about the error
            self.error = NSError(
                domain: "PayslipsViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot delete this type of payslip"]
            )
        }
    }
    
    /// Deletes payslips at the specified indices from an array.
    ///
    /// - Parameters:
    ///   - indexSet: The indices of the payslips to delete.
    ///   - payslips: The array of payslips.
    ///   - context: The model context to delete from.
    func deletePayslips(at indexSet: IndexSet, from payslips: [any PayslipItemProtocol], context: ModelContextProtocol) {
        for index in indexSet {
            if index < payslips.count {
                deletePayslip(payslips[index], from: context)
            }
        }
    }
    
    /// Filters and sorts payslips based on the search text and sort order.
    ///
    /// - Parameters:
    ///   - payslips: The payslips to filter and sort.
    ///   - searchText: The text to search for. If nil, the view model's searchText is used.
    /// - Returns: The filtered and sorted payslips.
    func filterPayslips(_ payslips: [any PayslipItemProtocol], searchText: String? = nil) -> [any PayslipItemProtocol] {
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
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        self.error = nil
    }
    
    // MARK: - Helper Methods
    
    /// Converts a month name to an integer for sorting.
    ///
    /// - Parameter month: The month name to convert.
    /// - Returns: The month as an integer (1-12), or 0 if the conversion fails.
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
    
    /// The sort order for payslips.
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