import SwiftUI
import SwiftData
import Foundation

@MainActor
final class PayslipsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published var searchText = "" {
        didSet {
            updateGroupedData()
        }
    }
    @Published var sortOrder: SortOrder = .dateDescending {
        didSet {
            updateGroupedData()
        }
    }
    @Published private(set) var payslips: [AnyPayslip] = []
    @Published var selectedPayslip: AnyPayslip?
    @Published var showShareSheet = false
    @Published var shareText = ""
    
    // MARK: - Processed Data
    @Published private(set) var groupedPayslips: [String: [AnyPayslip]] = [:]
    @Published private(set) var sortedSectionKeys: [String] = []

    // MARK: - Services
    let dataService: DataServiceProtocol
    
    // MARK: - Private Properties
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipsViewModel with the specified data service.
    ///
    /// - Parameter dataService: The data service to use for fetching and managing payslips.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
        
        // Register for notifications
        setupNotificationHandlers()
    }
    
    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Clears the payslips array
    func clearPayslips() {
        self.payslips = []
    }
    
    /// Loads payslips from the data service.
    func loadPayslips() async {
        // Use global loading system
        GlobalLoadingManager.shared.startLoading(
            operationId: "payslips_load",
            message: "Loading payslips..."
        )
        
        do {
            let loadedPayslips = try await dataService.fetch(PayslipItem.self)
            
            await MainActor.run {
                // Store the loaded payslips (filtering/sorting is handled in computed properties)
                self.payslips = loadedPayslips
                self.updateGroupedData() // Update grouped data after loading
                print("PayslipsViewModel: Loaded \(loadedPayslips.count) payslips and applied sorting with order: \(self.sortOrder)")
            }
        } catch {
            await MainActor.run {
                self.error = AppError.from(error)
                print("PayslipsViewModel: Error loading payslips: \(error.localizedDescription)")
            }
        }
        
        // Stop loading operation
        GlobalLoadingManager.shared.stopLoading(operationId: "payslips_load")
    }
    
    /// Deletes a payslip from the specified context.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to delete.
    ///   - context: The model context to delete from.
    func deletePayslip(_ payslip: AnyPayslip, from context: ModelContext) {
        // Since we're using a protocol, we need to handle the concrete type
        if let concretePayslip = payslip as? PayslipItem {
            Task {
                do {
                    // First delete from the context (UI update)
                    context.delete(concretePayslip)
                    
                    // Save the context immediately
                    try context.save()
                    print("Successfully deleted from UI context")
                    
                    // Immediately remove from the local array on main thread for UI update
                    await MainActor.run {
                        if let index = self.payslips.firstIndex(where: { $0.id == payslip.id }) {
                            self.payslips.remove(at: index)
                            print("Removed payslip from UI array, new count: \(self.payslips.count)")
                        } else {
                            print("Warning: Could not find payslip with ID \(payslip.id) in local array")
                        }
                    }
                    
                    // Force a full deletion through the data service to ensure all contexts are updated
                    try await self.dataService.delete(concretePayslip)
                    print("Successfully deleted from data service")
                    
                    // Flush all pending changes in the current context
                    context.processPendingChanges()
                    
                    // Notify other components about the deletion
                    PayslipEvents.notifyPayslipDeleted(id: payslip.id)
                    
                    // Force reload all payslips after a short delay to ensure consistency
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await loadPayslips()
                    
                } catch {
                    print("Error deleting payslip: \(error)")
                    await MainActor.run {
                        self.error = AppError.deleteFailed("Failed to delete payslip: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Log the error for debugging purposes
            print("Warning: Deletion of non-PayslipItem types is not implemented")
            
            // Notify the user about the error
            DispatchQueue.main.async {
                self.error = AppError.operationFailed("Cannot delete this type of payslip")
            }
        }
    }
    
    /// Deletes payslips at the specified indices from an array.
    ///
    /// - Parameters:
    ///   - indexSet: The indices of the payslips to delete.
    ///   - payslips: The array of payslips.
    ///   - context: The model context to delete from.
    func deletePayslips(at indexSet: IndexSet, from payslips: [AnyPayslip], context: ModelContext) {
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
    func filterPayslips(_ payslips: [AnyPayslip], searchText: String? = nil) -> [AnyPayslip] {
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
            filteredPayslips.sort { lhs, rhs in
                // Primary sort by timestamp if available, fallback to year/month
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate < rhsDate
            }
        case .dateDescending:
            filteredPayslips.sort { lhs, rhs in
                // Primary sort by timestamp if available, fallback to year/month
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate > rhsDate
            }
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
    var filteredPayslips: [AnyPayslip] {
        let result = filterPayslips(payslips)
        
        #if DEBUG
        print("PayslipsViewModel: Filtered payslips count: \(result.count), Sort order: \(sortOrder)")
        print("PayslipsViewModel: First 5 payslips chronologically:")
        for (index, payslip) in result.prefix(5).enumerated() {
            let date = createDateFromPayslip(payslip)
            print("  \(index + 1). \(payslip.month) \(payslip.year) - \(date)")
        }
        #endif
        
        return result
    }
    
    /// Whether there are active filters.
    var hasActiveFilters: Bool {
        return !searchText.isEmpty
    }
    
    // MARK: - Data Processing
    
    private func updateGroupedData() {
        let filtered = filterPayslips(payslips)
        
        // Group payslips by month and year
        let grouped = Dictionary(grouping: filtered) { payslip in
            let month = payslip.month
            let year = payslip.year
            return "\(month) \(year)"
        }
        
        // Sort section keys chronologically (newest first)
        let sortedKeys = grouped.keys.sorted {
            let date1 = createDateFromSectionKey($0)
            let date2 = createDateFromSectionKey($1)
            return date1 > date2 // Newest first (descending order)
        }
        
        self.groupedPayslips = grouped
        self.sortedSectionKeys = sortedKeys
    }
    
    /// Creates a Date object from a section key (e.g., "January 2025")
    private func createDateFromSectionKey(_ key: String) -> Date {
        let components = key.split(separator: " ")
        guard components.count == 2,
              let yearInt = Int(components[1]) else {
            return Date.distantPast // Fallback for invalid format
        }
        
        let monthString = String(components[0])
        let monthInt = monthToInt(monthString)
        
        var dateComponents = DateComponents()
        dateComponents.year = yearInt
        dateComponents.month = monthInt > 0 ? monthInt : 1
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
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
    
    /// Creates a Date object from a payslip for proper chronological sorting
    ///
    /// - Parameter payslip: The payslip to create a date from
    /// - Returns: A Date object representing the payslip's time period
    private func createDateFromPayslip(_ payslip: AnyPayslip) -> Date {
        // First try to use the timestamp property if it's a meaningful date
        if let payslipItem = payslip as? PayslipItem {
            let timestamp = payslipItem.timestamp
            // Check if timestamp is recent enough to be meaningful (not a default/placeholder date)
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
            if timestamp > oneYearAgo {
                return timestamp
            }
        }
        
        // Fallback to creating date from month and year
        let monthInt = monthToInt(payslip.month)
        let year = payslip.year
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthInt > 0 ? monthInt : 1 // Default to January if month parsing fails
        dateComponents.day = 1 // Use first day of the month
        
        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    /// Applies sorting to payslips based on current sort order
    /// - Parameter payslips: The payslips to sort
    /// - Returns: Sorted payslips
    private func applySorting(to payslips: [AnyPayslip]) -> [AnyPayslip] {
        var sortedPayslips = payslips
        
        switch sortOrder {
        case .dateAscending:
            sortedPayslips.sort { lhs, rhs in
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate < rhsDate
            }
        case .dateDescending:
            sortedPayslips.sort { lhs, rhs in
                let lhsDate = createDateFromPayslip(lhs)
                let rhsDate = createDateFromPayslip(rhs)
                return lhsDate > rhsDate
            }
        case .amountAscending:
            sortedPayslips.sort { $0.credits < $1.credits }
        case .amountDescending:
            sortedPayslips.sort { $0.credits > $1.credits }
        case .nameAscending:
            sortedPayslips.sort { $0.name < $1.name }
        case .nameDescending:
            sortedPayslips.sort { $0.name > $1.name }
        }
        
        return sortedPayslips
    }
    
    /// Applies filtering to payslips based on search text
    /// - Parameter payslips: The payslips to filter
    /// - Returns: Filtered payslips
    private func applyFiltering(to payslips: [AnyPayslip]) -> [AnyPayslip] {
        guard !searchText.isEmpty else { return payslips }
        
        return payslips.filter { payslip in
            payslip.name.localizedCaseInsensitiveContains(searchText) ||
            payslip.month.localizedCaseInsensitiveContains(searchText) ||
            String(payslip.year).localizedCaseInsensitiveContains(searchText)
        }
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
    func sharePayslip(_ payslip: AnyPayslip) {
        Task {
            do {
                // Try to get a PayslipItem from AnyPayslip
                guard let payslipItem = payslip as? PayslipItem else {
                    await MainActor.run {
                        self.error = AppError.message("Cannot share this type of payslip")
                    }
                    return
                }
                
                // Try to decrypt the payslip if needed
                try await payslipItem.decryptSensitiveData()
                
                // Set the share text and show the share sheet
                await MainActor.run {
                    shareText = payslipItem.formattedDescription()
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.error = AppError.from(error)
                }
            }
        }
    }
    
    // MARK: - Notification Handling
    
    /// Sets up notification handlers for payslip events
    private func setupNotificationHandlers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsRefresh),
            name: .payslipsRefresh,
            object: nil
        )
        
        // Add observer for forced refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsForcedRefresh),
            name: .payslipsForcedRefresh,
            object: nil
        )
    }
    
    /// Handler for payslips refresh notification
    @objc private func handlePayslipsRefresh() {
        Task {
            await loadPayslips()
        }
    }
    
    /// Handler for forced refresh notifications - more aggressive than regular refresh
    @objc private func handlePayslipsForcedRefresh() {
        Task {
            // Reset our payslips array first
            await MainActor.run {
                self.clearPayslips()
                self.isLoading = true
            }
            
            // Small delay to ensure UI updates and contexts reset
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Reset the data service to force a clean state
            if let dataServiceImpl = dataService as? DataServiceImpl {
                // Process pending changes to flush any operations
                dataServiceImpl.processPendingChanges()
                
                // Additional call to ensure data is refreshed
                dataServiceImpl.processPendingChanges()
            }
            
            // Reinitialize the data service to force a clean fetch
            try? await dataService.initialize()
            
            // Additional delay to ensure context is fully reset
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Now load the payslips with fresh fetch
            let fetchedPayslips = try? await dataService.fetchRefreshed(PayslipItem.self)
            
            await MainActor.run {
                if let payslips = fetchedPayslips {
                    self.payslips = payslips
                    print("PayslipsViewModel: Force refreshed with \(payslips.count) payslips")
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Model Context Protocol

/// A protocol for model contexts.
