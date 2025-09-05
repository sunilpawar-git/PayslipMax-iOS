import SwiftUI

/// DSOP (Defence Savings and Other Provident Fund) details section
struct DSOpDetailsSection: View {
    @Binding var dsopOpeningBalance: String
    @Binding var dsopClosingBalance: String
    
    var body: some View {
        Section {
            CurrencyTextField("Opening Balance", value: $dsopOpeningBalance)
                .accessibilityIdentifier("dsop_opening_balance_field")
            
            CurrencyTextField("Closing Balance", value: $dsopClosingBalance)
                .accessibilityIdentifier("dsop_closing_balance_field")
            
            // Show balance difference if both values are provided
            if let opening = Double(dsopOpeningBalance),
               let closing = Double(dsopClosingBalance) {
                let difference = closing - opening
                
                HStack {
                    Text("Balance Change")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("₹\(difference, specifier: "%.2f")")
                        .foregroundColor(difference >= 0 ? .green : .red)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
            
        } header: {
            HStack {
                Text("DSOP Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // Show info about DSOP
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("DSOP Information")
            }
        } footer: {
            Text("Defence Savings and Other Provident Fund details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    Form {
        DSOpDetailsSection(
            dsopOpeningBalance: .constant("150000"),
            dsopClosingBalance: .constant("155000")
        )
    }
}
