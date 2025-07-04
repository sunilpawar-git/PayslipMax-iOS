import SwiftUI

/// A comprehensive view for manually entering payslip data
struct ManualEntryView: View {
    let onSave: (PayslipManualEntryData) -> Void
    
    // MARK: - Personal Information
    @State private var name = ""
    @State private var month = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var accountNumber = ""
    @State private var panNumber = ""
    @State private var rank = ""
    @State private var serviceNumber = ""
    @State private var postedTo = ""
    
    // MARK: - Financial Summary
    @State private var credits = ""
    @State private var debits = ""
    @State private var tax = ""
    @State private var dsop = ""
    @State private var basicPay = ""
    @State private var dearnessPay = ""
    @State private var militaryServicePay = ""
    
    // MARK: - Dynamic Earnings and Deductions
    @State private var earnings: [String: Double] = [:]
    @State private var deductions: [String: Double] = [:]
    @State private var newEarningName = ""
    @State private var newEarningAmount = ""
    @State private var newDeductionName = ""
    @State private var newDeductionAmount = ""
    
    // MARK: - DSOP Details
    @State private var dsopOpeningBalance = ""
    @State private var dsopClosingBalance = ""
    
    // MARK: - Contact Information
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var contactWebsite = ""
    
    // MARK: - Notes
    @State private var notes = ""
    
    // MARK: - Cached Calculations
    @State private var totalCredits: Double = 0.0
    @State private var totalDebits: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
            Form {
            // Personal Information Section
            Section(header: Text("Personal Information")) {
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
                    
                TextField("Account Number", text: $accountNumber)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("account_number_field")
                
                TextField("PAN Number", text: $panNumber)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("pan_number_field")
                
                TextField("Rank (Optional)", text: $rank)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("rank_field")
                
                TextField("Service Number (Optional)", text: $serviceNumber)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("service_number_field")
                
                TextField("Posted To (Optional)", text: $postedTo)
                        .autocorrectionDisabled(true)
                    .accessibilityIdentifier("posted_to_field")
                }
                
            // Basic Financial Information
            Section(header: Text("Basic Financial Information")) {
                TextField("Basic Pay", text: $basicPay)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("basic_pay_field")
                
                TextField("Dearness Pay", text: $dearnessPay)
                        .keyboardType(.decimalPad)
                    .accessibilityIdentifier("dearness_pay_field")
                    
                TextField("Military Service Pay", text: $militaryServicePay)
                        .keyboardType(.decimalPad)
                    .accessibilityIdentifier("military_service_pay_field")
                    
                    TextField("Tax", text: $tax)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("tax_field")
                    
                    TextField("DSOP", text: $dsop)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("dsop_field")
                }
                
            // Dynamic Earnings Section
            Section(header: Text("Additional Earnings")) {
                ForEach(Array(earnings.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text("₹\(earnings[key] ?? 0, specifier: "%.2f")")
                            .foregroundColor(.green)
                        Button("Remove") {
                            earnings.removeValue(forKey: key)
                            recalculateTotals()
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                
                HStack {
                    TextField("Earning Name", text: $newEarningName)
                        .accessibilityIdentifier("new_earning_name_field")
                    TextField("Amount", text: $newEarningAmount)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                        .accessibilityIdentifier("new_earning_amount_field")
                    Button("Add") {
                        addNewEarning()
                    }
                    .disabled(newEarningName.isEmpty || newEarningAmount.isEmpty)
                }
            }
            
            // Dynamic Deductions Section
            Section(header: Text("Additional Deductions")) {
                ForEach(Array(deductions.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text("₹\(deductions[key] ?? 0, specifier: "%.2f")")
                            .foregroundColor(.red)
                        Button("Remove") {
                            deductions.removeValue(forKey: key)
                            recalculateTotals()
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                
                HStack {
                    TextField("Deduction Name", text: $newDeductionName)
                        .accessibilityIdentifier("new_deduction_name_field")
                    TextField("Amount", text: $newDeductionAmount)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                        .accessibilityIdentifier("new_deduction_amount_field")
                    Button("Add") {
                        addNewDeduction()
                    }
                    .disabled(newDeductionName.isEmpty || newDeductionAmount.isEmpty)
                }
                }
                
            // DSOP Details Section
            Section(header: Text("DSOP Details (Optional)")) {
                TextField("Opening Balance", text: $dsopOpeningBalance)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("dsop_opening_balance_field")
                
                TextField("Closing Balance", text: $dsopClosingBalance)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("dsop_closing_balance_field")
            }
            
            // Contact Information Section
            Section(header: Text("Contact Information (Optional)")) {
                TextField("Phone Number", text: $contactPhone)
                    .keyboardType(.phonePad)
                    .accessibilityIdentifier("contact_phone_field")
                
                TextField("Email Address", text: $contactEmail)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("contact_email_field")
                
                TextField("Website", text: $contactWebsite)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                    .accessibilityIdentifier("contact_website_field")
            }
            
            // Notes Section
            Section(header: Text("Notes (Optional)")) {
                TextField("Additional Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("notes_field")
            }
            
            // Summary Section
            Section(header: Text("Summary")) {
                HStack {
                    Text("Total Earnings")
                    Spacer()
                    Text("₹\(totalCredits, specifier: "%.2f")")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Deductions")
                    Spacer()
                    Text("₹\(totalDebits, specifier: "%.2f")")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Net Amount")
                    Spacer()
                    Text("₹\(totalCredits - totalDebits, specifier: "%.2f")")
                        .fontWeight(.bold)
                }
            }
            
            // Save Button Section
            Section {
                Button("Save Payslip") {
                    savePayslip()
                }
                .disabled(!isValid)
                .accessibilityIdentifier("save_button")
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(isValid ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            
            // Extra padding at the bottom
                Section {
                    Color.clear.frame(height: 50)
                }
            }
            .navigationTitle("Manual Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                dismiss()
            }
                .accessibilityIdentifier("cancel_button")
            }
        }
            .onAppear {
            // Initialize basic earnings from individual fields
            updateEarningsFromBasicFields()
            // Initialize cached calculations
            recalculateTotals()
        }
        .onChange(of: basicPay) { recalculateTotals() }
        .onChange(of: dearnessPay) { recalculateTotals() }
        .onChange(of: militaryServicePay) { recalculateTotals() }
        .onChange(of: tax) { recalculateTotals() }
        .onChange(of: dsop) { recalculateTotals() }
        .onChange(of: earnings) { recalculateTotals() }
        .onChange(of: deductions) { recalculateTotals() }
            }
    
    // MARK: - Helper Methods
    
    private var isValid: Bool {
        !name.isEmpty && !month.isEmpty && (totalCredits > 0 || !basicPay.isEmpty)
    }
    
    private func addNewEarning() {
        if !newEarningName.isEmpty, let amount = Double(newEarningAmount), amount > 0 {
            earnings[newEarningName] = amount
            newEarningName = ""
            newEarningAmount = ""
            recalculateTotals()
        }
    }
    
    private func addNewDeduction() {
        if !newDeductionName.isEmpty, let amount = Double(newDeductionAmount), amount > 0 {
            deductions[newDeductionName] = amount
            newDeductionName = ""
            newDeductionAmount = ""
            recalculateTotals()
        }
    }
    
    private func recalculateTotals() {
        updateEarningsFromBasicFields()
        totalCredits = calculateTotalCredits()
        totalDebits = calculateTotalDebits()
    }
    
    private func updateEarningsFromBasicFields() {
        // Update earnings dictionary with basic fields
        if let basicPayValue = Double(basicPay), basicPayValue > 0 {
            earnings["BPAY"] = basicPayValue
        }
        if let dearnessPay = Double(dearnessPay), dearnessPay > 0 {
            earnings["DA"] = dearnessPay
        }
        if let militaryServicePay = Double(militaryServicePay), militaryServicePay > 0 {
            earnings["MSP"] = militaryServicePay
        }
    }
    
    private func calculateTotalCredits() -> Double {
        updateEarningsFromBasicFields()
        return earnings.values.reduce(0, +)
    }
    
    private func calculateTotalDebits() -> Double {
        var total = deductions.values.reduce(0, +)
        if let taxValue = Double(tax), taxValue > 0 {
            total += taxValue
        }
        if let dsopValue = Double(dsop), dsopValue > 0 {
            total += dsopValue
        }
        return total
    }
    
    private func savePayslip() {
        updateEarningsFromBasicFields()
        
        // Add tax and dsop to deductions if they have values
        if let taxValue = Double(tax), taxValue > 0 {
            deductions["ITAX"] = taxValue
        }
        if let dsopValue = Double(dsop), dsopValue > 0 {
            deductions["DSOP"] = dsopValue
        }
        
        // Recalculate totals one final time before saving
        recalculateTotals()
        
        let data = PayslipManualEntryData(
            name: name,
            month: month,
            year: year,
            accountNumber: accountNumber,
            panNumber: panNumber,
            rank: rank,
            serviceNumber: serviceNumber,
            postedTo: postedTo,
            credits: totalCredits,
            debits: totalDebits,
            tax: Double(tax) ?? 0,
            dsop: Double(dsop) ?? 0,
            earnings: earnings,
            deductions: deductions,
            basicPay: Double(basicPay) ?? 0,
            dearnessPay: Double(dearnessPay) ?? 0,
            militaryServicePay: Double(militaryServicePay) ?? 0,
            netRemittance: totalCredits - totalDebits,
            incomeTax: Double(tax) ?? 0,
            dsopOpeningBalance: Double(dsopOpeningBalance),
            dsopClosingBalance: Double(dsopClosingBalance),
            contactPhones: contactPhone.isEmpty ? [] : [contactPhone],
            contactEmails: contactEmail.isEmpty ? [] : [contactEmail],
            contactWebsites: contactWebsite.isEmpty ? [] : [contactWebsite],
            source: "Manual Entry",
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(data)
        dismiss()
    }
}

#Preview {
    NavigationView {
        ManualEntryView(onSave: { _ in })
    }
} 