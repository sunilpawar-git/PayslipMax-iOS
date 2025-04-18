import SwiftUI
import SwiftData

struct PayslipsView: View {
    // MARK: - State and ObservedObjects
    @ObservedObject private var viewModel: PayslipsViewModel
    @State private var showingFilterSheet = false
    @State private var isShowingConfirmDelete = false
    @State private var payslipToDelete: AnyPayslip?
    @Environment(\.modelContext) private var modelContext
    
    // Cache identifiers for list stability and performance
    @State private var cachedIdentifiers: [String: String] = [:]
    
    // Performance optimization - track whether filter was changed
    @State private var didChangeFilter = false
    
    // MARK: - Initializer
    init(viewModel: PayslipsViewModel) {
        self.viewModel = viewModel
        
        // Register for performance monitoring
        #if DEBUG
        ViewPerformanceTracker.shared.trackRenderStart(for: "PayslipsView")
        #endif
    }
    
    // MARK: - Main View Body
    var body: some View {
        ZStack {
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
            
            // Overlay loading indicator or error
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
        }
        .task {
            // Only load if we haven't already or if filter changed
            if viewModel.payslips.isEmpty || didChangeFilter {
                await viewModel.loadPayslips()
                didChangeFilter = false
            }
        }
        .onAppear {
            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderStart(for: "PayslipsView")
            #endif
        }
        .onDisappear {
            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderEnd(for: "PayslipsView")
            #endif
        }
        .onChange(of: didChangeFilter) {
            if didChangeFilter {
                Task {
                    await viewModel.loadPayslips()
                    didChangeFilter = false
                }
            }
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
        if viewModel.payslips.isEmpty && !viewModel.isLoading {
            EmptyStateView()
        } else {
            payslipsList
        }
    }
    
    private var payslipsList: some View {
        // Use ScrollViewReader for better scrolling performance
        ScrollViewReader { scrollProxy in
            LazyVStack(spacing: 0) {
                ForEach(groupedPayslips.keys.sorted(by: >), id: \.self) { key in
                    Section {
                        // Use LazyVStack for improved performance with many items
                        LazyVStack(spacing: 1) {
                            if let payslipsForKey = groupedPayslips[key] {
                                ForEach(payslipsForKey, id: \.id) { payslip in
                                    // Create a stable identifier for better diffing
                                    PayslipRowView(payslip: payslip, viewModel: viewModel)
                                        .id(getStableId(for: payslip))
                                        .equatable(PayslipRowContent(payslip: payslip))
                                        .contentShape(Rectangle())
                                        .contextMenu {
                                            payslipContextMenu(for: payslip)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            payslipSwipeActions(for: payslip)
                                        }
                                }
                            }
                        }
                        .equatable(SectionContent(payslips: groupedPayslips[key] ?? []))
                    } header: {
                        // Optimize section header
                        PayslipSectionHeader(title: key)
                            .equatable(key)
                    }
                    .id(key) // Add section ID for scrolling
                }
            }
            .listStyle(PlainListStyle())
        }
        .refreshable {
            // Manual refresh action
            Task {
                await viewModel.loadPayslips()
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this payslip?",
            isPresented: $isShowingConfirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let payslip = payslipToDelete {
                    Task {
                        // Access the ModelContext from the environment
                        viewModel.deletePayslip(payslip, from: modelContext)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Context Menu and Swipe Actions
    
    @ViewBuilder
    private func payslipContextMenu(for payslip: AnyPayslip) -> some View {
        Button(action: {
            viewModel.sharePayslip(payslip)
        }) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button(role: .destructive, action: {
            payslipToDelete = payslip
            isShowingConfirmDelete = true
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func payslipSwipeActions(for payslip: AnyPayslip) -> some View {
        Button(role: .destructive) {
            payslipToDelete = payslip
            isShowingConfirmDelete = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get a stable identifier for a payslip to prevent unnecessary redraws
    private func getStableId(for payslip: AnyPayslip) -> String {
        // Use cached ID if available
        if let cachedId = cachedIdentifiers[payslip.id.uuidString] {
            return cachedId
        }
        
        // Generate a stable ID based on payslip properties
        let stableId = "\(payslip.id)-\(payslip.month)-\(payslip.year)"
        cachedIdentifiers[payslip.id.uuidString] = stableId
        return stableId
    }
    
    /// Group payslips by month and year
    private var groupedPayslips: [String: [AnyPayslip]] {
        Dictionary(grouping: viewModel.payslips) { payslip in
            let month = payslip.month
            let year = payslip.year
            return "\(month) \(year)"
        }
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
        if let index = viewModel.payslips.firstIndex(where: { $0.id == payslip.id }) {
            // Instead we would call a method on the viewModel to handle the deletion
            // like: viewModel.deletePayslip(at: index)
            // For now, just print a message
            print("Would delete payslip at index \(index)")
        }
    }
    
    // MARK: - ID Generation
    
    // Cache for stable identifiers
    @State private var idCache: [String: String] = [:]
    
    /// Generates a stable identifier for a payslip to improve rendering performance.
    private func stableId(for payslip: AnyPayslip) -> String {
        let payslipIdString = payslip.id.uuidString
        
        if let cachedId = idCache[payslipIdString] {
            return cachedId
        }
        
        // Generate a stable identifier based on the payslip's data
        let stableId = "payslip-\(payslip.month)-\(payslip.year)-\(payslip.id.uuidString)"
        idCache[payslipIdString] = stableId
        return stableId
    }
}

// MARK: - Optimized Subviews

/// Extracted section header to avoid unnecessary redraws
struct PayslipSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 16)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
    }
}

/// Optimized row component with better state handling
struct PayslipRowView: View {
    let payslip: AnyPayslip
    let viewModel: PayslipsViewModel
    
    // Cache expensive calculations
    @State private var formattedNetAmount: String = ""
    
    var body: some View {
        NavigationLink(destination: PayslipDetailView(viewModel: PayslipDetailViewModel(payslip: payslip))) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(payslip.month) \(payslip.year)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = getSubtitle(for: payslip) {
                        Text(subtitle)
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
            .padding(.horizontal)
        }
        .onAppear {
            // Use background queue for formatting to avoid main thread work
            BackgroundQueue.shared.async {
                let formattedAmount = formatCurrency(getNetAmount(for: payslip))
                DispatchQueue.main.async {
                    self.formattedNetAmount = formattedAmount
                }
            }
        }
    }
    
    // Helper methods to work with AnyPayslip
    private func getNetAmount(for payslip: AnyPayslip) -> Double {
        return payslip.credits - payslip.debits
    }
    
    private func getSubtitle(for payslip: AnyPayslip) -> String? {
        return payslip.name.isEmpty ? nil : payslip.name
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