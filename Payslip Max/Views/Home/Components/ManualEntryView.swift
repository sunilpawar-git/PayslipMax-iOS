import SwiftUI

/// A view for manually entering payslip data
struct ManualEntryView: View {
    let onSave: (PayslipManualEntryData) -> Void
    
    @State private var name = ""
    @State private var month = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var credits = ""
    @State private var debits = ""
    @State private var tax = ""
    @State private var dsop = ""
    @State private var location = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("name_field")
                    TextField("Month", text: $month)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("month_field")
                    
                    Picker("Year", selection: $year) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .accessibilityIdentifier("year_field")
                    
                    TextField("Location", text: $location)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("location_field")
                }
                
                Section(header: Text("Financial Details")) {
                    TextField("Credits", text: $credits)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("credits_field")
                    
                    TextField("Debits", text: $debits)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("debits_field")
                    
                    TextField("Tax", text: $tax)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("tax_field")
                    
                    TextField("DSOP", text: $dsop)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("dsop_field")
                }
                
                Section {
                    Button("Save") {
                        savePayslip()
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save_button")
                }
                
                // Add extra padding at the bottom to move fields away from system gesture area
                Section {
                    Color.clear.frame(height: 50)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            }
            .accessibilityIdentifier("cancel_button"))
            .onAppear {
                // Add a small delay before focusing on fields
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This helps avoid gesture conflicts on form appearance
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !month.isEmpty && !credits.isEmpty
    }
    
    private func savePayslip() {
        let data = PayslipManualEntryData(
            name: name,
            month: month,
            year: year,
            credits: Double(credits) ?? 0,
            debits: Double(debits) ?? 0,
            tax: Double(tax) ?? 0,
            dsop: Double(dsop) ?? 0
        )
        
        onSave(data)
        dismiss()
    }
} 