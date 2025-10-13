import SwiftUI

/// Editor for user to manually add/edit breakdown of "Other Earnings"
/// Supports quick text entry (e.g., "RH12: 21125, CEA: 5000")
struct MiscellaneousEarningsEditor: View {
    let amount: Double
    @State var breakdown: [String: Double]
    let onSave: ([String: Double]) -> Void
    
    @State private var quickEntryText = ""
    @State private var showError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Total Amount Display
                totalAmountSection
                
                // Quick Text Entry
                quickEntrySection
                
                // Breakdown List
                breakdownList
                
                if let error = showError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Edit Other Earnings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(breakdown)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Total Amount Section
    
    private var totalAmountSection: some View {
        VStack(spacing: 8) {
            Text("Other Earnings")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("₹\(amount, specifier: "%.0f")")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Total from breakdown: ₹\(calculateBreakdownTotal(), specifier: "%.0f")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Entry Section
    
    private var quickEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Entry")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            Text("Format: RH12: 21125, CEA: 5000")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            TextEditor(text: $quickEntryText)
                .frame(height: 80)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            
            Button {
                parseQuickEntry()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("Parse & Add")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Breakdown List
    
    private var breakdownList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breakdown")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            if breakdown.isEmpty {
                Text("No items added yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(Array(breakdown.keys.sorted()), id: \.self) { code in
                        HStack {
                            Text(code)
                                .fontWeight(.medium)
                            Spacer()
                            Text("₹\(breakdown[code] ?? 0, specifier: "%.0f")")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Actions
    
    private func parseQuickEntry() {
        showError = nil
        
        // Parse "CODE1: 1000, CODE2: 2000" format
        let entries = quickEntryText.components(separatedBy: ",")
        
        for entry in entries {
            let parts = entry.components(separatedBy: ":")
            if parts.count == 2 {
                let code = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                let amountStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
                
                if let amount = Double(cleanAmount), amount > 0 {
                    breakdown[code] = amount
                } else {
                    showError = "Invalid amount for \(code)"
                }
            }
        }
        
        if showError == nil {
            quickEntryText = ""
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let sortedKeys = Array(breakdown.keys.sorted())
        for index in offsets {
            breakdown.removeValue(forKey: sortedKeys[index])
        }
    }
    
    private func calculateBreakdownTotal() -> Double {
        return breakdown.values.reduce(0, +)
    }
}

// MARK: - Preview

#Preview {
    MiscellaneousEarningsEditor(
        amount: 27355,
        breakdown: [
            "RH12": 21125,
            "TPTA": 3600,
            "TPTADA": 1980,
            "RSHNA": 650
        ],
        onSave: { _ in }
    )
}

