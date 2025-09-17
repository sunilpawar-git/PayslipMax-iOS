import SwiftUI

struct PayslipManualEntryView: View {
    @Binding var payslip: PayslipItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingSuccessAlert = false

    // For manual entry of additional items
    @State private var newEarningName = ""
    @State private var newEarningAmount = ""
    @State private var newDeductionName = ""
    @State private var newDeductionAmount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(formatName(payslip.name))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Month/Year")
                        Spacer()
                        Text("\(payslip.month) \(payslip.year)")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Earnings")) {
                    // Use display name service for clean presentation
                    let displayNameService = DIContainer.shared.makePayslipDisplayNameService()
                    let displayEarnings = displayNameService.getDisplayEarnings(from: payslip.earnings)

                    ForEach(displayEarnings, id: \.displayName) { item in
                        HStack {
                            Text(item.displayName)
                            Spacer()
                            Text("₹\(item.value, specifier: "%.2f")")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        TextField("Component Name", text: $newEarningName)
                        TextField("Amount", text: $newEarningAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }

                    Button("Add Earning") {
                        if !newEarningName.isEmpty, let amount = Double(newEarningAmount) {
                            payslip.earnings[newEarningName] = amount
                            payslip.credits += amount
                            newEarningName = ""
                            newEarningAmount = ""
                        }
                    }
                    .disabled(newEarningName.isEmpty || newEarningAmount.isEmpty)
                }

                Section(header: Text("Deductions")) {
                    ForEach(Array(payslip.deductions.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text("₹\(payslip.deductions[key] ?? 0, specifier: "%.2f")")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        TextField("Component Name", text: $newDeductionName)
                        TextField("Amount", text: $newDeductionAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }

                    Button("Add Deduction") {
                        if !newDeductionName.isEmpty, let amount = Double(newDeductionAmount) {
                            payslip.deductions[newDeductionName] = amount
                            payslip.debits += amount
                            newDeductionName = ""
                            newDeductionAmount = ""
                        }
                    }
                    .disabled(newDeductionName.isEmpty || newDeductionAmount.isEmpty)
                }

                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Earnings")
                        Spacer()
                        Text("₹\(payslip.credits, specifier: "%.2f")")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Total Deductions")
                        Spacer()
                        Text("₹\(payslip.debits, specifier: "%.2f")")
                            .foregroundColor(.red)
                    }

                    HStack {
                        Text("Net Amount")
                        Spacer()
                        Text("₹\(payslip.credits - payslip.debits, specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Complete Payslip Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showingSuccessAlert = true
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Payslip Saved", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your payslip has been saved successfully.")
            }
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
}

#Preview {
    PayslipManualEntryView(payslip: .constant(PayslipItem(
        id: UUID(),
        timestamp: Date(),
        month: "January",
        year: 2023,
        credits: 50000,
        debits: 15000,
        dsop: 5000,
        tax: 3000,
        name: "John Doe",
        accountNumber: "123456789",
        panNumber: "ABCDE1234F",
        pdfData: nil
    )))
}
