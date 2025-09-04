import SwiftUI
import SwiftData

struct PayslipsView: View {
    // MARK: - State and ObservedObjects
    @ObservedObject private var viewModel: PayslipsViewModel

    @State private var isShowingConfirmDelete = false
    @State private var payslipToDelete: AnyPayslip?
    @Environment(\.modelContext) private var modelContext
    

    
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
                .navigationBarTitleDisplayMode(.large)

        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
        }
        .task {
            // Only load if we haven't already
            if viewModel.filteredPayslips.isEmpty {
                await viewModel.loadPayslips()
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
        .trackPerformance(name: "PayslipsView")
    }
    
    // MARK: - Computed Views for Better Organization
    
    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.groupedPayslips.isEmpty && !viewModel.isLoading {
            EmptyStateView()
        } else {
            payslipsList
        }
    }
    
    private var payslipsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sortedSectionKeys, id: \.self) { key in
                    if let payslipsInSection = viewModel.groupedPayslips[key], !payslipsInSection.isEmpty {
                        ForEach(Array(payslipsInSection.enumerated()), id: \.element.id) { index, payslip in
                            VStack(spacing: 0) {
                                UnifiedPayslipRowView(
                                    payslip: payslip, 
                                    sectionTitle: key,
                                    isFirstInSection: index == 0,
                                    viewModel: viewModel
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        payslipToDelete = payslip
                                        isShowingConfirmDelete = true
                                    } label: {
                                        Label("Delete Payslip", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        sharePayslip(payslip)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                }
                                
                                // Add subtle separator between payslips (except for last item)
                                if index < payslipsInSection.count - 1 {
                                    Rectangle()
                                        .fill(FintechColors.divider.opacity(0.3))
                                        .frame(height: 0.5)
                                        .padding(.leading, 60) // Indent separator to align with content
                                }
                            }
                        }
                        
                        // Add section spacing between different months
                        if key != viewModel.sortedSectionKeys.last {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 24)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(FintechColors.appBackground)
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
                    deletePayslip(payslip)
                    payslipToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                payslipToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Private Actions
    
    private func sharePayslip(_ payslip: AnyPayslip) {
        if let payslipItem = payslip as? PayslipItem {
            viewModel.sharePayslip(payslipItem)
        } else {
            // Handle case where payslip is not a PayslipItem
            print("Cannot share payslip that is not a PayslipItem")
        }
    }
    
    private func deletePayslip(_ payslip: AnyPayslip) {
        viewModel.deletePayslip(payslip, from: modelContext)
        
        // Force an immediate refresh after deletion
        Task {
            // Short delay to let deletion finish
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            await viewModel.loadPayslips()
        }
    }
}

// MARK: - Optimized Subviews

/// Optimized unified row component with better state handling and Apple design principles
struct UnifiedPayslipRowView: View {
    let payslip: AnyPayslip
    let sectionTitle: String
    let isFirstInSection: Bool
    let viewModel: PayslipsViewModel
    
    // Cache expensive calculations
    @State private var formattedNetAmount: String = ""
    
    var body: some View {
        NavigationLink {
            PayslipDetailView(viewModel: PayslipDetailViewModel(payslip: payslip))
        } label: {
            VStack(spacing: 0) {
                // Section header (only show for first item in section)
                if isFirstInSection {
                    HStack {
                        Text(sectionTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                
                // Unified payslip card
                HStack(spacing: 16) {
                    // Left side: Icon and basic info
                    HStack(spacing: 12) {
                        // Document icon with subtle background
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FintechColors.primaryBlue.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(FintechColors.primaryBlue)
                                .font(.system(size: 18))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Employee name or fallback
                            Text(payslip.name.isEmpty ? "Payslip" : formatName(payslip.name))
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.textPrimary)
                                .lineLimit(1)
                            
                            // Subtle subtitle
                            Text("Net Remittance")
                                .font(.subheadline)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side: Financial amount with trend styling
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedNetAmount)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.getAccessibleColor(for: getNetAmount(for: payslip)))
                        
                        // Subtle indicator for positive/negative
                        HStack(spacing: 4) {
                            Image(systemName: getNetAmount(for: payslip) >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(getNetAmount(for: payslip) >= 0 ? FintechColors.successGreen : FintechColors.dangerRed)
                            
                            Text(getNetAmount(for: payslip) >= 0 ? "Credit" : "Debit")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FintechColors.backgroundGray)
                        .shadow(
                            color: FintechColors.shadow,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            self.formattedNetAmount = formatCurrency(getNetAmount(for: payslip))
        }
    }
    
    // Helper to format name (removes single-character components at the end)
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, components.last?.count == 1 {
            return components.dropLast().joined(separator: " ")
        }
        return name
    }
    
    // Helper methods to work with AnyPayslip
    private func getNetAmount(for payslip: AnyPayslip) -> Double {
        return payslip.credits - payslip.debits
    }
    
    // Format currency to avoid dependency on ViewModel
    private func formatCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        
        if absValue >= 1_00_000 { // 1 Lakh or more
            let lakhs = absValue / 1_00_000
            if lakhs >= 10 {
                return "₹\(String(format: "%.0f", lakhs))L"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedLakhs = floor(lakhs * 100) / 100
                return "₹\(String(format: "%.2f", truncatedLakhs))L"
            }
        } else if absValue >= 1_000 { // 1 Thousand or more
            let thousands = absValue / 1_000
            if thousands >= 10 {
                return "₹\(String(format: "%.0f", thousands))K"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedThousands = floor(thousands * 100) / 100
                return "₹\(String(format: "%.2f", truncatedThousands))K"
            }
        } else {
            return "₹\(String(format: "%.0f", absValue))"
        }
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

// MARK: - Empty State View - Use existing one from EmptyStateView.swift
// Removed duplicate EmptyStateView declaration

// MARK: - Empty State View
// Using the existing EmptyStateView from EmptyStateView.swift instead of duplicating it here 