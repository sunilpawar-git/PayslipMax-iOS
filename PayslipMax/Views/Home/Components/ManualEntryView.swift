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
    
    // MARK: - UI State
    @State private var showingSaveConfirmation = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section with Title and Subtitle
                headerSection
                
                // Main Form Content
                Form {
                    // Personal Information Section
                    personalInformationSection
                    
                    // Basic Financial Information
                    basicFinancialSection
                    
                    // Dynamic Earnings Section
                    additionalEarningsSection
                    
                    // Dynamic Deductions Section
                    additionalDeductionsSection
                    
                    // DSOP Details Section
                    dsopDetailsSection
                    
                    // Contact Information Section
                    contactInformationSection
                    
                    // Notes Section
                    notesSection
                    
                    // Summary Section
                    summarySection
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel_button")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showingSaveConfirmation = true
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("save_button")
                }
            }
            .alert("Save Payslip", isPresented: $showingSaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    savePayslip()
                }
            } message: {
                Text("Are you sure you want to save this payslip?")
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
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Payslip")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Enter your payslip details manually")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Personal Information Section
    private var personalInformationSection: some View {
        Section {
            TextField("Full Name", text: $name)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("name_field")
                .textFieldStyle()
            
            TextField("Month (e.g., January)", text: $month)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("month_field")
                .textFieldStyle()
            
            Picker("Year", selection: $year) {
                ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("year_field")
            
            TextField("Account Number", text: $accountNumber)
                .autocorrectionDisabled(true)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("account_number_field")
                .textFieldStyle()
            
            TextField("PAN Number", text: $panNumber)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.characters)
                .accessibilityIdentifier("pan_number_field")
                .textFieldStyle()
            
            TextField("Rank (Optional)", text: $rank)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("rank_field")
                .textFieldStyle()
            
            TextField("Service Number (Optional)", text: $serviceNumber)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("service_number_field")
                .textFieldStyle()
            
            TextField("Posted To (Optional)", text: $postedTo)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("posted_to_field")
                .textFieldStyle()
        } header: {
            Text("Personal Information")
        } footer: {
            Text("Enter your basic personal and service details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Basic Financial Section
    private var basicFinancialSection: some View {
        Section {
            CurrencyTextField(title: "Basic Pay", text: $basicPay)
                .accessibilityIdentifier("basic_pay_field")
            
            CurrencyTextField(title: "Dearness Pay", text: $dearnessPay)
                .accessibilityIdentifier("dearness_pay_field")
            
            CurrencyTextField(title: "Military Service Pay", text: $militaryServicePay)
                .accessibilityIdentifier("military_service_pay_field")
            
            CurrencyTextField(title: "Income Tax", text: $tax)
                .accessibilityIdentifier("tax_field")
            
            CurrencyTextField(title: "DSOP", text: $dsop)
                .accessibilityIdentifier("dsop_field")
        } header: {
            Text("Basic Financial Information")
        } footer: {
            Text("Enter the main salary components and deductions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Additional Earnings Section
    private var additionalEarningsSection: some View {
        Section {
            ForEach(Array(earnings.keys.sorted()), id: \.self) { key in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(key)
                            .font(.body)
                        Text("Earning")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("₹\(earnings[key] ?? 0, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Button {
                        earnings.removeValue(forKey: key)
                        recalculateTotals()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 12) {
                TextField("Earning Name", text: $newEarningName)
                    .accessibilityIdentifier("new_earning_name_field")
                    .textFieldStyle(.roundedBorder)
                
                TextField("Amount", text: $newEarningAmount)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("new_earning_amount_field")
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                
                Button {
                    addNewEarning()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(newEarningName.isEmpty || newEarningAmount.isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Additional Earnings")
        } footer: {
            Text("Add any extra allowances or bonuses")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Additional Deductions Section
    private var additionalDeductionsSection: some View {
        Section {
            ForEach(Array(deductions.keys.sorted()), id: \.self) { key in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(key)
                            .font(.body)
                        Text("Deduction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("₹\(deductions[key] ?? 0, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Button {
                        deductions.removeValue(forKey: key)
                        recalculateTotals()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 12) {
                TextField("Deduction Name", text: $newDeductionName)
                    .accessibilityIdentifier("new_deduction_name_field")
                    .textFieldStyle(.roundedBorder)
                
                TextField("Amount", text: $newDeductionAmount)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("new_deduction_amount_field")
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                
                Button {
                    addNewDeduction()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(newDeductionName.isEmpty || newDeductionAmount.isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Additional Deductions")
        } footer: {
            Text("Add any extra deductions or contributions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - DSOP Details Section
    private var dsopDetailsSection: some View {
        Section {
            CurrencyTextField(title: "Opening Balance", text: $dsopOpeningBalance)
                .accessibilityIdentifier("dsop_opening_balance_field")
            
            CurrencyTextField(title: "Closing Balance", text: $dsopClosingBalance)
                .accessibilityIdentifier("dsop_closing_balance_field")
        } header: {
            Text("DSOP Details")
        } footer: {
            Text("Optional: Enter DSOP account balance details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Contact Information Section
    private var contactInformationSection: some View {
        Section {
            TextField("Phone Number", text: $contactPhone)
                .keyboardType(.phonePad)
                .accessibilityIdentifier("contact_phone_field")
                .textFieldStyle()
            
            TextField("Email Address", text: $contactEmail)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("contact_email_field")
                .textFieldStyle()
            
            TextField("Website", text: $contactWebsite)
                .keyboardType(.URL)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("contact_website_field")
                .textFieldStyle()
        } header: {
            Text("Contact Information")
        } footer: {
            Text("Optional: Add contact details for this payslip")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        Section {
            TextField("Additional Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityIdentifier("notes_field")
                .textFieldStyle()
        } header: {
            Text("Notes")
        } footer: {
            Text("Optional: Add any additional information or comments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Total Earnings")
                        .font(.body)
                    Spacer()
                    Text("₹\(totalCredits, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Total Deductions")
                        .font(.body)
                    Spacer()
                    Text("₹\(totalDebits, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                HStack {
                    Text("Net Amount")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("₹\(totalCredits - totalDebits, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Summary")
        } footer: {
            Text("Review your payslip totals before saving")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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

// MARK: - Custom Components

/// A reusable currency text field component
struct CurrencyTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("₹")
                    .foregroundColor(.secondary)
                TextField("0.00", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func textFieldStyle() -> some View {
        self
            .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        ManualEntryView(onSave: { _ in })
    }
}