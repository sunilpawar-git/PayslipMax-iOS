import SwiftUI
import SwiftData

struct PayslipsView: View {
    @StateObject private var viewModel = DIContainer.shared.makePayslipsViewModel()
    @State private var showingFilterSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var payslipToDelete: PayslipItem?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.filteredPayslips.isEmpty {
                    emptyStateView
                } else {
                    payslipListView
                }
            }
            .navigationTitle("Payslips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(
                    searchText: $viewModel.searchText,
                    sortOrder: $viewModel.sortOrder
                )
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                CustomShareSheet(text: viewModel.shareText)
            }
            .alert(
                "Delete Payslip",
                isPresented: $showingDeleteConfirmation,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let payslip = payslipToDelete {
                            modelContext.delete(payslip)
                            try? modelContext.save()
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
        }
    }
    
    // MARK: - Methods
    
    private func loadPayslips() {
        Task {
            await viewModel.loadPayslips()
        }
    }
    
    // MARK: - Computed Properties
    
    private var payslipListView: some View {
        List {
            ForEach(viewModel.filteredPayslips, id: \.id) { payslip in
                NavigationLink {
                    PayslipDetailView(payslip: payslip)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(payslip.month) \(payslip.year)")
                        .font(.headline)
                    
                    Text(payslip.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(String(format: "%.2f", payslip.credits))")
                        .font(.headline)
                    
                    Text("Net: ₹\(String(format: "%.2f", payslip.calculateNetAmount()))")
                        .font(.caption)
                        .foregroundColor(payslip.calculateNetAmount() >= 0 ? .green : .red)
                }
            }
            
            HStack(spacing: 12) {
                PayslipInfoBadge(title: "Tax", value: "₹\(String(format: "%.0f", payslip.tax))")
                PayslipInfoBadge(title: "Debits", value: "₹\(String(format: "%.0f", payslip.debits))")
                PayslipInfoBadge(title: "DSPOF", value: "₹\(String(format: "%.0f", payslip.dspof))")
                
                Spacer()
                
                Text(formatDate(payslip.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
