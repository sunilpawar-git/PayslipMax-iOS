import SwiftUI
import SwiftData

struct PayslipsView: View {
    // MARK: - State and ObservedObjects
    @ObservedObject private var viewModel: PayslipsViewModel
    @State private var showingFilterSheet = false
    @State private var isShowingConfirmDelete = false
    @State private var payslipToDelete: AnyPayslip?
    @Environment(\.modelContext) private var modelContext
    
    // Performance optimization - track whether filter was changed
    @State private var didChangeFilter = false
    
    // MARK: - Initializer
    init(viewModel: PayslipsViewModel) {
        self.viewModel = viewModel
        
        // Register for performance monitoring - moved to onAppear to fix warning
        // Don't call ViewPerformanceTracker here as it causes a publishing warning
    }
    
    // MARK: - Main View Body
    var body: some View {
        // Use NavigationStack for better performance than NavigationView
        NavigationStack {
            mainContentView
                .navigationTitle("Payslips")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing:
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                )
        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
        }
        .task {
            // Only load if we haven't already or if filter changed
            if viewModel.filteredPayslips.isEmpty || didChangeFilter {
                await viewModel.loadPayslips()
                didChangeFilter = false
            }
        }
        .onAppear {
            // Simplified onAppear - let the global system handle coordination
            print("📱 PayslipsList appeared")
            
            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderStart(for: "PayslipsView")
            #endif
            
            Task {
                // Simple refresh without complex delays and notifications
                await viewModel.loadPayslips()
            }
        }
        .onDisappear {
            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderEnd(for: "PayslipsView")
            #endif
        }
        .trackPerformance(viewName: "PayslipsView")
        .sheet(isPresented: $showingFilterSheet) {
            PayslipFilterView(
                onApplyFilter: { filter in
                    applyFilter(filter)
                },
                onDismiss: {
                    showingFilterSheet = false
                }
            )
        }
    }
    
    // MARK: - Computed Views for Better Organization
    
    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.filteredPayslips.isEmpty && !viewModel.isLoading {
            EmptyStateView()
        } else {
            payslipsList
        }
    }
    
    private var payslipsList: some View {
        List {
            ForEach(sortedSectionKeys, id: \.self) { key in
                Section(header: PayslipSectionHeader(title: key)) {
                    ForEach(groupedPayslips[key] ?? [], id: \.id) { payslip in
                        PayslipRowView(payslip: payslip, viewModel: viewModel)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    payslipToDelete = payslip
                                    isShowingConfirmDelete = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .id(payslip.id)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .animation(.default, value: viewModel.filteredPayslips.count)
        .refreshable {
            // Use async/await pattern for refreshing
            await viewModel.loadPayslips()
            // Also notify other components to refresh
            PayslipEvents.notifyRefreshRequired()
        }
        .confirmationDialog(
            "Are you sure you want to delete this payslip?",
            isPresented: $isShowingConfirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let payslip = payslipToDelete {
                    viewModel.deletePayslip(payslip, from: modelContext)
                    payslipToDelete = nil
                    
                    // Force an immediate refresh after confirmation
                    Task {
                        // Short delay to let deletion finish
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        await viewModel.loadPayslips()
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                payslipToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Group payslips by month and year
    private var groupedPayslips: [String: [AnyPayslip]] {
        Dictionary(grouping: viewModel.filteredPayslips) { payslip in
            let month = payslip.month
            let year = payslip.year
            return "\(month) \(year)"
        }
    }
    
    /// Sort section keys chronologically (newest first)
    private var sortedSectionKeys: [String] {
        let sorted = groupedPayslips.keys.sorted { key1, key2 in
            let date1 = createDateFromSectionKey(key1)
            let date2 = createDateFromSectionKey(key2)
            return date1 > date2 // Newest first (descending order)
        }
        
        #if DEBUG
        print("PayslipsView: Section sorting order:")
        for (index, key) in sorted.enumerated() {
            let date = createDateFromSectionKey(key)
            print("  \(index + 1). \(key) - \(date)")
        }
        #endif
        
        return sorted
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
    
    /// Converts a month name to an integer for sorting
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
    
    // MARK: - Private Actions
    
    private func applyFilter(_ filter: PayslipFilter) {
        // In a real app, this would filter the payslips based on the filter
        showingFilterSheet = false
        
        // Update the UI based on the filter
        if !filter.searchText.isEmpty {
            // Implement the filter logic here
        }
    }
    
    private func toggleFilterSheet() {
        showingFilterSheet.toggle()
    }
    
    private func sharePayslip(_ payslip: AnyPayslip) {
        if let payslipItem = payslip as? PayslipItem {
            viewModel.sharePayslip(payslipItem)
        } else {
            // Handle case where payslip is not a PayslipItem
            print("Cannot share payslip that is not a PayslipItem")
        }
    }
    
    private func deletePayslip(_ payslip: AnyPayslip) {
        // In a real app, this would delete the payslip from the database
        // We can't directly modify viewModel.payslips as it's likely readonly
        if let index = viewModel.filteredPayslips.firstIndex(where: { $0.id == payslip.id }) {
            // Instead we would call a method on the viewModel to handle the deletion
            // like: viewModel.deletePayslip(at: index)
            // For now, just print a message
            print("Would delete payslip at index \(index)")
        }
    }
}

// MARK: - Optimized Subviews

/// Extracted section header to avoid unnecessary redraws
struct PayslipSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

/// Optimized row component with better state handling
struct PayslipRowView: View {
    let payslip: AnyPayslip
    let viewModel: PayslipsViewModel
    
    // Cache expensive calculations
    @State private var formattedNetAmount: String = ""
    
    var body: some View {
        NavigationLink {
            PayslipDetailView(viewModel: PayslipDetailViewModel(payslip: payslip))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Show employee name instead of duplicate month/year
                    Text(payslip.name.isEmpty ? "Payslip" : payslip.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Show additional details if available
                    if !payslip.name.isEmpty {
                        Text("Net Salary")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formattedNetAmount)
                    .font(.headline)
                    .foregroundColor(getNetAmount(for: payslip) > 0 ? .green : .red)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            self.formattedNetAmount = formatCurrency(getNetAmount(for: payslip))
        }
    }
    
    // Helper methods to work with AnyPayslip
    private func getNetAmount(for payslip: AnyPayslip) -> Double {
        return payslip.credits - payslip.debits
    }
    
    // Format currency to avoid dependency on ViewModel
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(value)"
    }
}

// MARK: - Equatable Helper Structs

struct PayslipRowContent: Equatable {
    let payslip: AnyPayslip
    
    static func == (lhs: PayslipRowContent, rhs: PayslipRowContent) -> Bool {
        return lhs.payslip.id == rhs.payslip.id &&
               lhs.payslip.month == rhs.payslip.month &&
               lhs.payslip.year == rhs.payslip.year &&
               lhs.payslip.credits == rhs.payslip.credits &&
               lhs.payslip.debits == rhs.payslip.debits &&
               lhs.payslip.name == rhs.payslip.name
    }
}

struct SectionContent: Equatable {
    let payslips: [AnyPayslip]
    
    static func == (lhs: SectionContent, rhs: SectionContent) -> Bool {
        guard lhs.payslips.count == rhs.payslips.count else { return false }
        
        for (index, lhsPayslip) in lhs.payslips.enumerated() {
            let rhsPayslip = rhs.payslips[index]
            if lhsPayslip.id != rhsPayslip.id {
                return false
            }
        }
        
        return true
    }
}

// Filter model for payslips
struct PayslipFilter {
    let searchText: String
    let sortOrder: PayslipsViewModel.SortOrder
}

// Simple filter view
struct PayslipFilterView: View {
    let onApplyFilter: (PayslipFilter) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search by name, month, or year", text: $searchText)
                }
                
                Section(header: Text("Sort By")) {
                    Picker("Sort Order", selection: $sortOrder) {
                        ForEach(PayslipsViewModel.SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("Apply Filters") {
                        onApplyFilter(PayslipFilter(searchText: searchText, sortOrder: sortOrder))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.accentColor)
                    
                    Button("Cancel") {
                        onDismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Payslips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @State private var searchText: String = ""
    @State private var sortOrder: PayslipsViewModel.SortOrder = .dateDescending
} 