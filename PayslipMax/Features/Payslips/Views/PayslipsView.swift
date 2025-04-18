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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            filterButton
                        }
                    }
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
                    } header: {
                        // Optimize section header
                        PayslipSectionHeader(title: key)
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
    
    private var filterButton: some View {
        Button(action: {
            showingFilterSheet = true
        }) {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
        }
        .sheet(isPresented: $showingFilterSheet) {
            PayslipFilterView(
                searchText: $viewModel.searchText,
                sortOrder: $viewModel.sortOrder,
                onApply: {
                    showingFilterSheet = false
                    didChangeFilter = true
                },
                onCancel: {
                    showingFilterSheet = false
                }
            )
        }
    }
    
    // MARK: - Context Menu and Swipe Actions
    
    @ViewBuilder
    private func payslipContextMenu(for payslip: AnyPayslip) -> some View {
        Button(action: {
            Task {
                if let item = payslip as? PayslipItem {
                    viewModel.sharePayslip(item)
                }
            }
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
        
        Button {
            Task {
                if let item = payslip as? PayslipItem {
                    viewModel.sharePayslip(item)
                }
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .tint(.blue)
    }
    
    // MARK: - Helper Methods
    
    /// Get a stable identifier for a payslip to improve list diffing performance
    private func getStableId(for payslip: AnyPayslip) -> String {
        let key = "\(payslip.id)-\(payslip.month)-\(payslip.year)"
        
        // Use cached ID if available to prevent recalculation
        if let cachedId = cachedIdentifiers[key] {
            return cachedId
        }
        
        // Create and cache a stable identifier
        let id = "\(payslip.id)-\(payslip.month)-\(payslip.year)-\(payslip.credits)-\(payslip.debits)"
        cachedIdentifiers[key] = id
        return id
    }
    
    /// Group payslips by month-year for sectioned display
    private var groupedPayslips: [String: [AnyPayslip]] {
        Dictionary(grouping: viewModel.payslips) { payslip in
            let month = payslip.month
            let year = payslip.year
            return "\(month) \(year)"
        }
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
                    
                    if let subtitle = getSubtitle() {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formattedNetAmount)
                    .font(.headline)
                    .foregroundColor(getNetAmount() > 0 ? .green : .red)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .onAppear {
            // Calculate formatted amount only once when the row appears
            formattedNetAmount = formatCurrency(getNetAmount())
        }
    }
    
    // Helper methods to work with AnyPayslip
    private func getNetAmount() -> Double {
        return payslip.credits - payslip.debits
    }
    
    private func getSubtitle() -> String? {
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

// Simple filter view
struct PayslipFilterView: View {
    @Binding var searchText: String
    @Binding var sortOrder: PayslipsViewModel.SortOrder
    let onApply: () -> Void
    let onCancel: () -> Void
    
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
                        onApply()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.accentColor)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Payslips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 