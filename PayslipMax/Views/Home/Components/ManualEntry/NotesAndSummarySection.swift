import SwiftUI

/// Notes and summary section for manual payslip entry
struct NotesAndSummarySection: View {
    @Binding var notes: String
    let totalCredits: Double
    let totalDebits: Double
    
    var netAmount: Double {
        totalCredits - totalDebits
    }
    
    var body: some View {
        // Notes Section
        Section {
            TextField("Additional notes or comments", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("notes_field")
                .textFieldStyle(.roundedBorder)
            
        } header: {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
        } footer: {
            Text("Add any additional notes about this payslip")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        // Summary Section
        Section {
            ManualEntrySummaryRow(label: "Total Credits", amount: totalCredits, color: .green)
            ManualEntrySummaryRow(label: "Total Debits", amount: totalDebits, color: .red)
            
            Divider()
            
            ManualEntrySummaryRow(
                label: "Net Amount", 
                amount: netAmount, 
                color: netAmount >= 0 ? .primary : .red,
                isTotal: true
            )
            
        } header: {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

/// Reusable summary row component for manual entry
struct ManualEntrySummaryRow: View {
    let label: String
    let amount: Double
    let color: Color
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(isTotal ? .primary : .secondary)
                .fontWeight(isTotal ? .semibold : .regular)
            
            Spacer()
            
            Text("₹\(amount, specifier: "%.2f")")
                .foregroundColor(color)
                .font(.system(.body, design: .monospaced))
                .fontWeight(isTotal ? .bold : .medium)
        }
        .padding(.vertical, isTotal ? 4 : 2)
    }
}

#Preview {
    Form {
        NotesAndSummarySection(
            notes: .constant("Sample notes about the payslip"),
            totalCredits: 75000,
            totalDebits: 15000
        )
    }
}
