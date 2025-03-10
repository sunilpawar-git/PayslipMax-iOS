import SwiftUI
import SwiftData
import Foundation

@MainActor
final class PayslipsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateDescending
    @Published private(set) var payslips: [any PayslipItemProtocol] = []
    @Published var selectedPayslip: (any PayslipItemProtocol)?
    @Published var showShareSheet = false
    @Published var shareText = ""
    
    // MARK: - Services
    let dataService: DataServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipsViewModel with the specified data service.
    ///
    /// - Parameter dataService: The data service to use for fetching and managing payslips.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Loads payslips from the data service.
    func loadPayslips() async {
        isLoading = true
        
        do {
            // Initialize the data service if it's not already initialized
            if !dataService.isInitialized {
                try await dataService.initialize()
            }
            
            // Fetch payslips
            let fetchedPayslips = try await dataService.fetch(PayslipItem.self)
            
            // Update the published payslips
            self.payslips = fetchedPayslips
            
            isLoading = false
        } catch {
            handleError(error)
            isLoading = false
        }
    }
    
    /// Deletes a payslip from the specified context.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to delete.
    ///   - context: The model context to delete from.
    func deletePayslip(_ payslip: any PayslipItemProtocol, from context: ModelContext) {
        // Since we're using a protocol, we need to handle the concrete type
        if let concretePayslip = payslip as? PayslipItem {
            context.delete(concretePayslip)
            try? context.save()
        } else {
            // Log the error for debugging purposes
            print("Warning: Deletion of non-PayslipItem types is not implemented")
            
            // Notify the user about the error
            self.error = AppError.operationFailed("Cannot delete this type of payslip")
        }
    }
    
    /// Deletes payslips at the specified indices from an array.
    ///
    /// - Parameters:
    ///   - indexSet: The indices of the payslips to delete.
    ///   - payslips: The array of payslips.
    ///   - context: The model context to delete from.
    func deletePayslips(at indexSet: IndexSet, from payslips: [any PayslipItemProtocol], context: ModelContext) {
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
    
    // MARK: - Computed Properties
    
    /// The filtered and sorted payslips based on the current search text and sort order.
    var filteredPayslips: [any PayslipItemProtocol] {
        return filterPayslips(payslips)
    }
    
    /// Whether there are active filters.
    var hasActiveFilters: Bool {
        return !searchText.isEmpty
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        self.error = nil
    }
    
    /// Clears all filters.
    func clearAllFilters() {
        searchText = ""
    }
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
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
    
    // MARK: - Sharing
    
    /// Shares a payslip.
    ///
    /// - Parameter payslip: The payslip to share.
    func sharePayslip(_ payslip: PayslipItem) {
        do {
            // Try to decrypt the payslip if needed
            let payslipToShare = payslip
            try payslipToShare.decryptSensitiveData()
            
            // Set the share text and show the share sheet
            shareText = payslipToShare.formattedDescription()
            showShareSheet = true
        } catch {
            self.error = AppError.from(error)
        }
    }
}

// MARK: - Model Context Protocol

/// A protocol for model contexts.
