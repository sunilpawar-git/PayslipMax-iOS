import SwiftUI
import SwiftData

struct PayslipsView: View {
    @StateObject private var viewModel = DIContainer.shared.makePayslipsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    // Use a more robust approach for the Query
    @Query private var payslips: [PayslipItem]
    
    init() {
        // Initialize the Query with a descriptor
        let sortDescriptors = [SortDescriptor(\PayslipItem.year, order: .reverse)]
        _payslips = Query(sort: sortDescriptors)
    }
    
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var selectedYear: Int?
    @State private var selectedMonths: Set<String> = []
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    
    // Available filter options
    private let availableYears: [Int] = Array((Calendar.current.component(.year, from: Date()) - 5)...Calendar.current.component(.year, from: Date()))
    private let availableMonths = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                
                // Payslips list
                if filteredPayslips.isEmpty {
                    emptyStateView
                } else {
                    payslipsList
                }
            }
            .navigationTitle("Payslips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        Text("Date ↑").tag(PayslipsViewModel.SortOrder.dateAscending)
                        Text("Date ↓").tag(PayslipsViewModel.SortOrder.dateDescending)
                        Text("Name ↑").tag(PayslipsViewModel.SortOrder.nameAscending)
                        Text("Name ↓").tag(PayslipsViewModel.SortOrder.nameDescending)
                            Text("Amount ↑").tag(PayslipsViewModel.SortOrder.amountAscending)
                            Text("Amount ↓").tag(PayslipsViewModel.SortOrder.amountDescending)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .searchable(text: $searchText, prompt: "Search by name, month, or year")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert(isPresented: .constant(viewModel.error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        // Use a different approach to clear the error
                        DispatchQueue.main.async {
                            // This is a workaround since we can't directly set the error property
                            viewModel.clearError()
                        }
                    }
                )
            }
        }
        .onAppear {
            viewModel.searchText = searchText
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPayslips: [any PayslipItemProtocol] {
        var result = viewModel.filterPayslips(payslips.map { $0 as any PayslipItemProtocol }, searchText: searchText)
        
        // Apply additional filters
        if let selectedYear = selectedYear {
            result = result.filter { $0.year == selectedYear }
        }
        
        if !selectedMonths.isEmpty {
            result = result.filter { selectedMonths.contains($0.month) }
        }
        
        if let minAmount = minAmount {
            result = result.filter { $0.credits >= minAmount }
        }
        
        if let maxAmount = maxAmount {
            result = result.filter { $0.credits <= maxAmount }
        }
        
        return result
    }
    
    // MARK: - View Components
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            // Active filters display
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let selectedYear = selectedYear {
                            FilterChip(text: "\(selectedYear)") {
                                self.selectedYear = nil
                            }
                        }
                        
                        ForEach(Array(selectedMonths), id: \.self) { month in
                            FilterChip(text: month) {
                                self.selectedMonths.remove(month)
                            }
                        }
                        
                        if let minAmount = minAmount {
                            FilterChip(text: "Min: ₹\(String(format: "%.0f", minAmount))") {
                                self.minAmount = nil
                            }
                        }
                        
                        if let maxAmount = maxAmount {
                            FilterChip(text: "Max: ₹\(String(format: "%.0f", maxAmount))") {
                                self.maxAmount = nil
                            }
                        }
                        
                        Button(action: {
                            clearAllFilters()
                        }) {
                            Text("Clear All")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.red)
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
            }
            
            Divider()
        }
    }
    
    private var payslipsList: some View {
        List {
            ForEach(filteredPayslips, id: \.id) { payslip in
                NavigationLink {
                    PayslipDetailView(payslip: payslip)
                } label: {
                    PayslipListItem(payslip: payslip)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        if let payslipItem = payslip as? PayslipItem {
                            modelContext.delete(payslipItem)
                            try? modelContext.save()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        // Share payslip
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
            
            Text(hasActiveFilters ? "No matching payslips" : "No payslips yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(hasActiveFilters ? 
                 "Try adjusting your filters or search terms" : 
                 "Upload your first payslip to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearAllFilters()
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var filterSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Year")) {
                    Picker("Select Year", selection: $selectedYear) {
                        Text("Any Year").tag(nil as Int?)
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)").tag(year as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Month")) {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(availableMonths, id: \.self) { month in
                                MonthToggleButton(
                                    month: month,
                                    isSelected: selectedMonths.contains(month),
                                    action: {
                                        if selectedMonths.contains(month) {
                                            selectedMonths.remove(month)
                                        } else {
                                            selectedMonths.insert(month)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .frame(height: 200)
                }
                
                Section(header: Text("Amount Range")) {
                    HStack {
                        Text("Min: ₹")
                        TextField("Minimum", value: $minAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Max: ₹")
                        TextField("Maximum", value: $maxAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button("Reset Filters") {
                        clearAllFilters()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filter Payslips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var hasActiveFilters: Bool {
        selectedYear != nil || !selectedMonths.isEmpty || minAmount != nil || maxAmount != nil
    }
    
    private func clearAllFilters() {
        selectedYear = nil
        selectedMonths.removeAll()
        minAmount = nil
        maxAmount = nil
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