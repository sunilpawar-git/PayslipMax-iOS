import SwiftUI

/// A comprehensive view for manually entering payslip data
/// Composed of focused section components for better maintainability
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
                ManualEntryHeaderSection()

                // Main Form Content
                Form {
                    // Personal Information Section
                    PersonalInformationSection(
                        name: $name,
                        month: $month,
                        year: $year,
                        accountNumber: $accountNumber,
                        panNumber: $panNumber,
                        rank: $rank,
                        serviceNumber: $serviceNumber,
                        postedTo: $postedTo
                    )

                    // Basic Financial Information
                    BasicFinancialSection(
                        credits: $credits,
                        debits: $debits,
                        tax: $tax,
                        dsop: $dsop,
                        basicPay: $basicPay,
                        dearnessPay: $dearnessPay,
                        militaryServicePay: $militaryServicePay
                    )

                    // Dynamic Earnings Section
                    DynamicEarningsSection(
                        earnings: $earnings,
                        newEarningName: $newEarningName,
                        newEarningAmount: $newEarningAmount
                    )

                    // Dynamic Deductions Section
                    DynamicDeductionsSection(
                        deductions: $deductions,
                        newDeductionName: $newDeductionName,
                        newDeductionAmount: $newDeductionAmount
                    )

                    // DSOP Details Section
                    DSOpDetailsSection(
                        dsopOpeningBalance: $dsopOpeningBalance,
                        dsopClosingBalance: $dsopClosingBalance
                    )

                    // Contact Information Section
                    ContactInformationSection(
                        contactPhone: $contactPhone,
                        contactEmail: $contactEmail,
                        contactWebsite: $contactWebsite
                    )

                    // Notes and Summary Section
                    NotesAndSummarySection(
                        notes: $notes,
                        totalCredits: totalCredits,
                        totalDebits: totalDebits
                    )
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Manual Entry")
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

    // MARK: - Business Logic

    private var isValid: Bool {
        !name.isEmpty && !month.isEmpty &&
        (!credits.isEmpty || !basicPay.isEmpty)
    }

    private func updateEarningsFromBasicFields() {
        if let basicPayValue = Double(basicPay), basicPayValue > 0 {
            earnings["Basic Pay"] = basicPayValue
        }
        if let dearnessValue = Double(dearnessPay), dearnessValue > 0 {
            earnings["Dearness Allowance"] = dearnessValue
        }
        if let militaryValue = Double(militaryServicePay), militaryValue > 0 {
            earnings["Military Service Pay"] = militaryValue
        }
    }

    private func recalculateTotals() {
        // Calculate total credits
        let creditsValue = Double(credits) ?? 0
        let earningsTotal = earnings.values.reduce(0, +)
        totalCredits = max(creditsValue, earningsTotal)

        // Calculate total debits
        let debitsValue = Double(debits) ?? 0
        let taxValue = Double(tax) ?? 0
        let dsopValue = Double(dsop) ?? 0
        let deductionsTotal = deductions.values.reduce(0, +)

        totalDebits = max(debitsValue, deductionsTotal + taxValue + dsopValue)
    }

    private func savePayslip() {
        // Update earnings from basic fields one more time
        updateEarningsFromBasicFields()

        let payslipData = PayslipManualEntryData(
            name: name,
            month: month,
            year: year,
            accountNumber: accountNumber,
            panNumber: panNumber,
            rank: rank.isEmpty ? "" : rank,
            serviceNumber: serviceNumber.isEmpty ? "" : serviceNumber,
            postedTo: postedTo.isEmpty ? "" : postedTo,
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

        onSave(payslipData)
        dismiss()
    }
}

#Preview {
    ManualEntryView { _ in
        print("Payslip saved")
    }
}
