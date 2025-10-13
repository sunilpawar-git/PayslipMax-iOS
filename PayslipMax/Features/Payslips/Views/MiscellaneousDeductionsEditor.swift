import SwiftUI

/// Editor for user to manually add/edit breakdown of "Other Deductions"
/// Supports form-based entry with paycode name and amount fields
struct MiscellaneousDeductionsEditor: View {
    let amount: Double
    @State var breakdown: [String: Double]
    let onSave: ([String: Double]) -> Void
    
    @State private var newPaycodeName = ""
    @State private var newPaycodeAmount = ""
    @State private var showError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Total Amount Display
                totalAmountSection
                
                // Form Entry Section
                formEntrySection
                
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
            .navigationTitle("Edit Other Deductions")
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
            Text("Other Deductions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("₹\(amount, specifier: "%.0f")")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Breakdown Total: ₹\(calculateBreakdownTotal(), specifier: "%.0f")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Remaining balance
            let remaining = amount - calculateBreakdownTotal()
            Text("Remaining: ₹\(remaining, specifier: "%.0f")")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(remaining < 0 ? .red : .green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Form Entry Section
    
    private var formEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Paycode")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Paycode Name Field
                TextField("Code (e.g., EHCESS)", text: $newPaycodeName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .frame(maxWidth: .infinity)
                
                // Amount Field
                TextField("Amount", text: $newPaycodeAmount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                
                // Add Button
                Button(action: addPaycode) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .disabled(newPaycodeName.isEmpty || newPaycodeAmount.isEmpty)
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
    
    private func addPaycode() {
        showError = nil
        
        let code = newPaycodeName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let amountStr = newPaycodeAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
        
        guard !code.isEmpty else {
            showError = "Paycode name cannot be empty"
            return
        }
        
        guard let amountValue = Double(cleanAmount), amountValue > 0 else {
            showError = "Invalid amount. Please enter a valid number."
            return
        }
        
        // Add to breakdown
        breakdown[code] = amountValue
        
        // Clear fields
        newPaycodeName = ""
        newPaycodeAmount = ""
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
    MiscellaneousDeductionsEditor(
        amount: 2905,
        breakdown: [
            "EHCESS": 1905,
            "MISC": 1000
        ],
        onSave: { _ in }
    )
}

