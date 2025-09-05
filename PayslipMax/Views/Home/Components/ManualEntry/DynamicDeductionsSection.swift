import SwiftUI

/// Dynamic deductions section allowing users to add custom deductions
struct DynamicDeductionsSection: View {
    @Binding var deductions: [String: Double]
    @Binding var newDeductionName: String
    @Binding var newDeductionAmount: String
    
    var body: some View {
        Section {
            // Display existing deductions
            ForEach(Array(deductions.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("₹\(deductions[key] ?? 0, specifier: "%.2f")")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                    
                    Button(action: {
                        deductions.removeValue(forKey: key)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Remove \(key)")
                }
            }
            
            // Add new deduction
            VStack(spacing: 8) {
                TextField("Deduction Name (e.g., CGHS, NPS)", text: $newDeductionName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("new_deduction_name_field")
                
                CurrencyTextField("Amount", value: $newDeductionAmount)
                    .accessibilityIdentifier("new_deduction_amount_field")
                
                Button(action: addDeduction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Deduction")
                    }
                    .foregroundColor(.blue)
                }
                .disabled(newDeductionName.isEmpty || newDeductionAmount.isEmpty)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("add_deduction_button")
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("Additional Deductions")
                .font(.headline)
                .foregroundColor(.primary)
        } footer: {
            Text("Add any additional deductions not covered in basic amounts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func addDeduction() {
        guard !newDeductionName.isEmpty,
              let amount = Double(newDeductionAmount) else { return }
        
        deductions[newDeductionName] = amount
        newDeductionName = ""
        newDeductionAmount = ""
    }
}

#Preview {
    Form {
        DynamicDeductionsSection(
            deductions: .constant(["CGHS": 1500, "NPS": 6000]),
            newDeductionName: .constant(""),
            newDeductionAmount: .constant("")
        )
    }
}
