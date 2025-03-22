import SwiftUI
import SwiftData
import Foundation // For AppNotification

struct PayslipsView: View {
    @StateObject private var viewModel = DIContainer.shared.makePayslipsViewModel()
    @State private var showingFilterSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var payslipToDelete: PayslipItem?
    @Environment(\.modelContext) private var modelContext
    @State private var needsRefresh = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .accessibilityIdentifier("payslips_loading")
                } else if viewModel.filteredPayslips.isEmpty {
                    emptyStateView
                        .accessibilityIdentifier("payslips_empty_state")
                } else {
                    payslipListView
                        .accessibilityIdentifier("payslips_list")
                }
            }
            .navigationTitle("Payslips")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .accessibilityIdentifier("filter_button")
                    }
                }
            })
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(
                    searchText: $viewModel.searchText,
                    sortOrder: $viewModel.sortOrder
                )
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheet(items: [viewModel.shareText])
            }
            .alert(
                "Delete Payslip",
                isPresented: $showingDeleteConfirmation,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let payslip = payslipToDelete {
                            deletePayslip(payslip)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("Are you sure you want to delete this payslip? This action cannot be undone.")
                }
            )
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            loadPayslips()
            
            // Set up notification observer for payslip deletion
            NotificationCenter.default.addObserver(
                forName: AppNotification.payslipDeleted,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    await viewModel.loadPayslips()
                }
            }
            
            // Set up notification observer for payslip updates
            NotificationCenter.default.addObserver(
                forName: AppNotification.payslipUpdated,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    await viewModel.loadPayslips()
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadPayslips() {
        Task { @MainActor in
            await viewModel.loadPayslips()
        }
    }
    
    private func deletePayslip(_ payslip: PayslipItem) {
        // First, try to delete any associated PDF file
        let pdfId = payslip.id.uuidString
        do {
            try PDFManager.shared.deletePDF(identifier: pdfId)
            print("Successfully deleted PDF file for payslip: \(pdfId)")
        } catch {
            print("Error deleting PDF file: \(error.localizedDescription)")
        }
        
        // Use the DataService to delete the payslip instead of directly using modelContext
        Task {
            do {
                // Initialize the data service if needed
                if !viewModel.dataService.isInitialized {
                    try await viewModel.dataService.initialize()
                }
                
                // Delete the payslip using the data service
                try await viewModel.dataService.delete(payslip)
                print("Successfully deleted payslip using DataService")
                
                // Refresh the list
                await viewModel.loadPayslips()
                
                // Also delete from local context to ensure UI updates immediately
                modelContext.delete(payslip)
                try modelContext.save()
            } catch {
                print("Error deleting payslip: \(error.localizedDescription)")
                viewModel.error = AppError.message("Failed to delete payslip: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var payslipListView: some View {
        List {
            ForEach(viewModel.filteredPayslips, id: \.id) { payslip in
                NavigationLink {
                    PayslipNavigation.detailView(for: payslip)
                } label: {
                    PayslipListItem(payslip: payslip)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        payslipToDelete = payslip as? PayslipItem
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        // Share payslip
                        if let payslipItem = payslip as? PayslipItem {
                            viewModel.sharePayslip(payslipItem)
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadPayslips()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(viewModel.hasActiveFilters ? "No matching payslips" : "No payslips yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.hasActiveFilters ? 
                 "Try adjusting your filters or search terms" : 
                 "Upload your first payslip to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearAllFilters()
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views

struct PayslipListItem: View {
    let payslip: any PayslipItemProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month and Year Header
            Text("\(payslip.month) \(String(payslip.year))")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Financial Details
            VStack(alignment: .leading, spacing: 8) {
                // Credits
                HStack {
                    Text("Credits:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(formatCurrency(payslip.credits))/-")
                        .foregroundColor(.primary)
                }
                
                // Debits
                HStack {
                    Text("Debits:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(formatCurrency(payslip.debits))/-")
                        .foregroundColor(.primary)
                }
                
                // DSOP
                HStack {
                    Text("DSOP:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(formatCurrency(payslip.dsop))/-")
                        .foregroundColor(.primary)
                }
                
                // Income Tax
                HStack {
                    Text("Income Tax:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(formatCurrency(payslip.tax))/-")
                        .foregroundColor(.primary)
                }
            }
            .font(.system(size: 16))
        }
        .padding(.vertical, 12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 2
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        let number = NSNumber(value: value)
        return formatter.string(from: number) ?? String(format: "%.0f", value)
    }
}

struct PayslipInfoBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .padding(.leading, 8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 6)
        }
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

struct MonthToggleButton: View {
    let month: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(String(month.prefix(3)))
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct PayslipsView_Previews: PreviewProvider {
    static var previews: some View {
        PayslipsView()
    }
}

// MARK: - Filter View

struct FilterView: View {
    @Binding var searchText: String
    @Binding var sortOrder: PayslipsViewModel.SortOrder
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search by name, month, or year", text: $searchText)
                }
                
                Section(header: Text("Sort By")) {
                    Picker("Sort Order", selection: $sortOrder) {
                        Text("Date (Newest First)").tag(PayslipsViewModel.SortOrder.dateDescending)
                        Text("Date (Oldest First)").tag(PayslipsViewModel.SortOrder.dateAscending)
                        Text("Name (A-Z)").tag(PayslipsViewModel.SortOrder.nameAscending)
                        Text("Name (Z-A)").tag(PayslipsViewModel.SortOrder.nameDescending)
                        Text("Amount (Low-High)").tag(PayslipsViewModel.SortOrder.amountAscending)
                        Text("Amount (High-Low)").tag(PayslipsViewModel.SortOrder.amountDescending)
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Share Sheet
