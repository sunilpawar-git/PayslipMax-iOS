import SwiftUI

/// Dynamic earnings section allowing users to add custom earnings
struct DynamicEarningsSection: View {
    @Binding var earnings: [String: Double]
    @Binding var newEarningName: String
    @Binding var newEarningAmount: String
    
    var body: some View {
        Section {
            // Display existing earnings
            ForEach(Array(earnings.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("₹\(earnings[key] ?? 0, specifier: "%.2f")")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                    
                    Button(action: {
                        earnings.removeValue(forKey: key)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Remove \(key)")
                }
            }
            
            // Add new earning
            VStack(spacing: 8) {
                TextField("Earning Name (e.g., HRA, TA)", text: $newEarningName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("new_earning_name_field")
                
                CurrencyTextField("Amount", value: $newEarningAmount)
                    .accessibilityIdentifier("new_earning_amount_field")
                
                Button(action: addEarning) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Earning")
                    }
                    .foregroundColor(.blue)
                }
                .disabled(newEarningName.isEmpty || newEarningAmount.isEmpty)
                .buttonStyle(.borderless)
                .accessibilityIdentifier("add_earning_button")
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("Additional Earnings")
                .font(.headline)
                .foregroundColor(.primary)
        } footer: {
            Text("Add any additional earnings not covered in basic pay")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func addEarning() {
        guard !newEarningName.isEmpty,
              let amount = Double(newEarningAmount) else { return }
        
        earnings[newEarningName] = amount
        newEarningName = ""
        newEarningAmount = ""
    }
}

#Preview {
    Form {
        DynamicEarningsSection(
            earnings: .constant(["HRA": 10000, "TA": 2000]),
            newEarningName: .constant(""),
            newEarningAmount: .constant("")
        )
    }
}
