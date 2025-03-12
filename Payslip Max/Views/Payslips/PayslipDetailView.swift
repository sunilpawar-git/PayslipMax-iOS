import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

// Define a notification name for payslip deletion
extension Notification.Name {
    static let payslipDeleted = Notification.Name("PayslipDeleted")
}

struct PayslipDetailView: View {
    let payslip: any PayslipItemProtocol
    @StateObject private var viewModel: PayslipDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showingDeleteConfirmation = false
    
    // States for editing personal details
    @State private var isEditingPersonalDetails = false
    @State private var editedName = ""
    @State private var editedAccountNumber = ""
    @State private var editedPanNumber = ""
    @State private var nameWasEdited = false
    @State private var accountNumberWasEdited = false
    @State private var panNumberWasEdited = false
    @State private var showSaveAlert = false
    
    // Add state variables for editing the entire payslip
    @State private var isEditingPayslip = false
    @State private var editedCredits = ""
    @State private var editedDebits = ""
    @State private var editedDSOP = ""
    @State private var editedTax = ""
    @State private var editedEarnings: [String: String] = [:]
    @State private var editedDeductions: [String: String] = [:]
    
    init(payslip: any PayslipItemProtocol, viewModel: PayslipDetailViewModel? = nil) {
        self.payslip = payslip
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: PayslipDetailViewModel(payslip: payslip))
        }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let decryptedPayslip = viewModel.decryptedPayslip {
                List {
                    // PERSONAL DETAILS SECTION
                    Section(header: HStack {
                        Text("PERSONAL DETAILS")
                            .font(.headline)
                        Spacer()
                        Text("\(decryptedPayslip.month) \(decryptedPayslip.year)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !isEditingPayslip {
                            Button(action: {
                                startEditingPayslip(decryptedPayslip)
                            }) {
                                Label("Edit", systemImage: "pencil.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }) {
                        if isEditingPayslip {
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Name:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Name", text: $editedName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: editedName) { oldValue, newValue in
                                            nameWasEdited = newValue != decryptedPayslip.name
                                        }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Account:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Account Number", text: $editedAccountNumber)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: editedAccountNumber) { oldValue, newValue in
                                            accountNumberWasEdited = newValue != decryptedPayslip.accountNumber
                                        }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("PAN:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("PAN Number", text: $editedPanNumber)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.trailing)
                                        .onChange(of: editedPanNumber) { oldValue, newValue in
                                            panNumberWasEdited = newValue != decryptedPayslip.panNumber
                                        }
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Name:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(decryptedPayslip.name)
                                        .font(.body)
                                        .multilineTextAlignment(.trailing)
                                    
                                    if viewModel.wasFieldManuallyEdited(field: "name") {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.footnote)
                                            .help("This field was manually edited")
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Account:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(decryptedPayslip.accountNumber)
                                        .font(.body)
                                        .multilineTextAlignment(.trailing)
                                    
                                    if viewModel.wasFieldManuallyEdited(field: "accountNumber") {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.footnote)
                                            .help("This field was manually edited")
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("PAN:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(decryptedPayslip.panNumber)
                                        .font(.body)
                                        .multilineTextAlignment(.trailing)
                                    
                                    if viewModel.wasFieldManuallyEdited(field: "panNumber") {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.footnote)
                                            .help("This field was manually edited")
                                    }
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)

                                // Add legend for edited fields in view mode
                                if viewModel.wasFieldManuallyEdited(field: "name") || 
                                   viewModel.wasFieldManuallyEdited(field: "accountNumber") || 
                                   viewModel.wasFieldManuallyEdited(field: "panNumber") {
                                    HStack {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("Manually edited field")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // FINANCIAL DETAILS SECTION
                    Section(header: Text("FINANCIAL DETAILS")) {
                        if isEditingPayslip {
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Credits:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Credits", text: $editedCredits)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                HStack {
                                    Text("Debits:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Debits", text: $editedDebits)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                HStack {
                                    Text("DSOP:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("DSOP", text: $editedDSOP)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                HStack {
                                    Text("Income Tax:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Income Tax", text: $editedTax)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                DetailRow(title: "Net Amount", value: calculateNetAmount())
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal)
                        } else {
                            DetailRow(title: "Credits", value: viewModel.formatCurrency(decryptedPayslip.credits))
                            DetailRow(title: "Debits", value: viewModel.formatCurrency(decryptedPayslip.debits))
                            DetailRow(title: "DSOP", value: viewModel.formatCurrency(decryptedPayslip.dsop))
                            DetailRow(title: "Income Tax", value: viewModel.formatCurrency(decryptedPayslip.tax))
                            DetailRow(title: "Net Amount", value: viewModel.formattedNetAmount)
                        }
                    }
                    
                    // EARNINGS BREAKDOWN SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.earnings.isEmpty {
                        Section(header: Text("EARNINGS BREAKDOWN")) {
                            if isEditingPayslip {
                                ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                    if let value = payslipItem.earnings[key], value > 0 {
                                        HStack {
                                            Text(key)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            TextField("", text: Binding(
                                                get: { self.editedEarnings[key] ?? "" },
                                                set: { self.editedEarnings[key] = $0 }
                                            ))
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 120)
                                        }
                                    }
                                }
                                // Add total earnings row
                                let totalEarnings = calculateTotalEditedEarnings()
                                DetailRow(title: "Gross Pay", value: formatCurrencyWithoutDecimals(totalEarnings))
                                    .fontWeight(.bold)
                            } else {
                                ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                    if let value = payslipItem.earnings[key], value > 0 {
                                        DetailRow(title: key, value: viewModel.formatCurrency(value))
                                    }
                                }
                                // Add total earnings row
                                let totalEarnings = payslipItem.earnings.values.reduce(0, +)
                                DetailRow(title: "Gross Pay", value: viewModel.formatCurrency(totalEarnings))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    
                    // DEDUCTIONS BREAKDOWN SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.deductions.isEmpty {
                        Section(header: Text("DEDUCTIONS BREAKDOWN")) {
                            if isEditingPayslip {
                                ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                    if let value = payslipItem.deductions[key], value > 0 {
                                        HStack {
                                            Text(key)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            TextField("", text: Binding(
                                                get: { self.editedDeductions[key] ?? "" },
                                                set: { self.editedDeductions[key] = $0 }
                                            ))
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 120)
                                        }
                                    }
                                }
                                // Add total deductions row
                                let totalDeductions = calculateTotalEditedDeductions()
                                DetailRow(title: "Total Deductions", value: formatCurrencyWithoutDecimals(totalDeductions))
                                    .fontWeight(.bold)
                            } else {
                                ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                    if let value = payslipItem.deductions[key], value > 0 {
                                        DetailRow(title: key, value: viewModel.formatCurrency(value))
                                    }
                                }
                                // Add total deductions row
                                let totalDeductions = payslipItem.deductions.values.reduce(0, +)
                                DetailRow(title: "Total Deductions", value: viewModel.formatCurrency(totalDeductions))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    
                    // Save/Cancel buttons when in edit mode
                    if isEditingPayslip {
                        Section {
                            HStack {
                                Button(action: {
                                    savePayslipChanges()
                                }) {
                                    Text("Save All Changes")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            
                            HStack {
                                Button(action: {
                                    cancelEditing()
                                }) {
                                    Text("Cancel")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // INCOME TAX DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("INCOME TAX DETAILS")) {
                            if let statementPeriod = viewModel.extractedData["statementPeriod"], !statementPeriod.isEmpty {
                                DetailRow(title: "Statement Period", value: statementPeriod)
                            }
                            
                            if let incomeTaxDeducted = viewModel.extractedData["incomeTaxDeducted"], !incomeTaxDeducted.isEmpty {
                                DetailRow(title: "Income Tax Deducted", value: "₹\(incomeTaxDeducted)")
                            }
                            
                            if let edCessDeducted = viewModel.extractedData["edCessDeducted"], !edCessDeducted.isEmpty {
                                DetailRow(title: "Ed. Cess Deducted", value: "₹\(edCessDeducted)")
                            }
                            
                            if let totalTaxPayable = viewModel.extractedData["totalTaxPayable"], !totalTaxPayable.isEmpty {
                                DetailRow(title: "Total Tax Payable", value: "₹\(totalTaxPayable)")
                            }
                            
                            // Add additional tax details from the screenshot
                            if let grossSalary = viewModel.extractedData["grossSalary"], !grossSalary.isEmpty {
                                DetailRow(title: "Gross Salary", value: "₹\(grossSalary)")
                            }
                            
                            if let standardDeduction = viewModel.extractedData["standardDeduction"], !standardDeduction.isEmpty {
                                DetailRow(title: "Standard Deduction", value: "₹\(standardDeduction)")
                            }
                            
                            if let netTaxableIncome = viewModel.extractedData["netTaxableIncome"], !netTaxableIncome.isEmpty {
                                DetailRow(title: "Net Taxable Income", value: "₹\(netTaxableIncome)")
                            }
                        }
                    }
                    
                    // DSOP DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("DSOP DETAILS")) {
                            if let dsopOpeningBalance = viewModel.extractedData["dsopOpeningBalance"], !dsopOpeningBalance.isEmpty {
                                DetailRow(title: "Opening Balance", value: "₹\(dsopOpeningBalance)")
                            }
                            
                            if let dsopSubscription = viewModel.extractedData["dsopSubscription"], !dsopSubscription.isEmpty {
                                DetailRow(title: "Subscription", value: "₹\(dsopSubscription)")
                            }
                            
                            if let dsopMiscAdj = viewModel.extractedData["dsopMiscAdj"], !dsopMiscAdj.isEmpty {
                                DetailRow(title: "Misc Adj", value: "₹\(dsopMiscAdj)")
                            }
                            
                            if let dsopWithdrawal = viewModel.extractedData["dsopWithdrawal"], !dsopWithdrawal.isEmpty {
                                DetailRow(title: "Withdrawal", value: "₹\(dsopWithdrawal)")
                            }
                            
                            if let dsopRefund = viewModel.extractedData["dsopRefund"], !dsopRefund.isEmpty {
                                DetailRow(title: "Refund", value: "₹\(dsopRefund)")
                            }
                            
                            if let dsopClosingBalance = viewModel.extractedData["dsopClosingBalance"], !dsopClosingBalance.isEmpty {
                                DetailRow(title: "Closing Balance", value: "₹\(dsopClosingBalance)")
                            }
                        }
                    }
                    
                    // CONTACT DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("CONTACT DETAILS")) {
                            if let contactSAOLW = viewModel.extractedData["contactSAOLW"], !contactSAOLW.isEmpty {
                                DetailRow(title: "SAO(LW)", value: contactSAOLW)
                            }
                            
                            if let contactAAOLW = viewModel.extractedData["contactAAOLW"], !contactAAOLW.isEmpty {
                                DetailRow(title: "AAO(LW)", value: contactAAOLW)
                            }
                            
                            if let contactSAOTW = viewModel.extractedData["contactSAOTW"], !contactSAOTW.isEmpty {
                                DetailRow(title: "SAO(TW)", value: contactSAOTW)
                            }
                            
                            if let contactAAOTW = viewModel.extractedData["contactAAOTW"], !contactAAOTW.isEmpty {
                                DetailRow(title: "AAO(TW)", value: contactAAOTW)
                            }
                            
                            if let contactProCivil = viewModel.extractedData["contactProCivil"], !contactProCivil.isEmpty {
                                DetailRow(title: "PRO CIVIL", value: contactProCivil)
                            }
                            
                            if let contactProArmy = viewModel.extractedData["contactProArmy"], !contactProArmy.isEmpty {
                                DetailRow(title: "PRO ARMY", value: contactProArmy)
                            }
                            
                            if let contactWebsite = viewModel.extractedData["contactWebsite"], !contactWebsite.isEmpty {
                                DetailRow(title: "Website", value: contactWebsite)
                            }
                            
                            if let contactEmailTADA = viewModel.extractedData["contactEmailTADA"], !contactEmailTADA.isEmpty {
                                DetailRow(title: "TA/DA Email", value: contactEmailTADA)
                            }
                            
                            if let contactEmailLedger = viewModel.extractedData["contactEmailLedger"], !contactEmailLedger.isEmpty {
                                DetailRow(title: "Ledger Email", value: contactEmailLedger)
                            }
                            
                            if let contactEmailRankPay = viewModel.extractedData["contactEmailRankPay"], !contactEmailRankPay.isEmpty {
                                DetailRow(title: "Rank Pay Email", value: contactEmailRankPay)
                            }
                            
                            if let contactEmailGeneral = viewModel.extractedData["contactEmailGeneral"], !contactEmailGeneral.isEmpty {
                                DetailRow(title: "General Query Email", value: contactEmailGeneral)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Payslip Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                if let url = try await viewModel.getPDFURL() {
                                    pdfURL = url
                                    ShareSheet.share(items: [url] as [Any]) {
                                        showShareSheet = false
                                    }
                                }
                            } catch {
                                viewModel.error = error as? AppError ?? AppError.message("Failed to prepare PDF for sharing")
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert(
            "Delete Payslip",
            isPresented: $showingDeleteConfirmation,
            actions: {
                Button("Delete", role: .destructive) {
                    deletePayslip()
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Are you sure you want to delete this payslip? This action cannot be undone.")
            }
        )
        .alert(
            "Details Updated",
            isPresented: $showSaveAlert,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text("Your personal details have been updated. These changes will be used for future insights and analysis.")
            }
        )
        .errorAlert(error: $viewModel.error)
        .task {
            await viewModel.loadDecryptedData()
        }
    }
    
    private func deletePayslip() {
        if let payslipItem = payslip as? PayslipItem {
            // First, try to delete any associated PDF file
            let pdfId = payslipItem.id.uuidString
            do {
                try PDFManager.shared.deletePDF(identifier: pdfId)
                print("Successfully deleted PDF file for payslip: \(pdfId)")
            } catch {
                print("Error deleting PDF file: \(error.localizedDescription)")
            }
            
            // Use the DataService to delete the payslip
            Task {
                do {
                    // Initialize the data service if needed
                    if !viewModel.dataService.isInitialized {
                        try await viewModel.dataService.initialize()
                    }
                    
                    // Delete the payslip using the data service
                    try await viewModel.dataService.delete(payslipItem)
                    print("Successfully deleted payslip using DataService")
                    
                    // Also delete from local context to ensure UI updates immediately
                    modelContext.delete(payslipItem)
                    try modelContext.save()
                    
                    // Post a notification that a payslip was deleted
                    NotificationCenter.default.post(name: .payslipDeleted, object: nil)
                    
                    // Dismiss the view after successful deletion
                    dismiss()
                } catch {
                    print("Error deleting payslip: \(error.localizedDescription)")
                    viewModel.error = AppError.message("Failed to delete payslip: \(error.localizedDescription)")
                }
            }
        } else {
            viewModel.error = AppError.message("Cannot delete this type of payslip")
        }
    }
    
    // Add helper methods for editing the entire payslip
    private func startEditingPayslip(_ payslip: any PayslipItemProtocol) {
        isEditingPayslip = true
        
        // Initialize personal details
        editedName = payslip.name
        editedAccountNumber = payslip.accountNumber
        editedPanNumber = payslip.panNumber
        nameWasEdited = false
        accountNumberWasEdited = false
        panNumberWasEdited = false
        
        // Initialize financial details without decimal places
        editedCredits = String(format: "%.0f", payslip.credits)
        editedDebits = String(format: "%.0f", payslip.debits)
        editedDSOP = String(format: "%.0f", payslip.dsop)
        editedTax = String(format: "%.0f", payslip.tax)
        
        // Initialize earnings and deductions without decimal places
        if let payslipItem = payslip as? PayslipItem {
            editedEarnings = [:]
            for (key, value) in payslipItem.earnings {
                if value > 0 {
                    editedEarnings[key] = String(format: "%.0f", value)
                }
            }
            
            editedDeductions = [:]
            for (key, value) in payslipItem.deductions {
                if value > 0 {
                    editedDeductions[key] = String(format: "%.0f", value)
                }
            }
        }
    }
    
    private func cancelEditing() {
        isEditingPayslip = false
        nameWasEdited = false
        accountNumberWasEdited = false
        panNumberWasEdited = false
    }
    
    private func savePayslipChanges() {
        guard let payslipItem = viewModel.decryptedPayslip as? PayslipItem else {
            viewModel.error = AppError.message("Cannot update payslip: Invalid payslip type")
            return
        }
        
        // Update personal details
        payslipItem.name = editedName
        payslipItem.accountNumber = editedAccountNumber
        payslipItem.panNumber = editedPanNumber
        
        // Update financial details
        payslipItem.credits = Double(editedCredits) ?? payslipItem.credits
        payslipItem.debits = Double(editedDebits) ?? payslipItem.debits
        payslipItem.dsop = Double(editedDSOP) ?? payslipItem.dsop
        payslipItem.tax = Double(editedTax) ?? payslipItem.tax
        
        // Update earnings
        for (key, valueString) in editedEarnings {
            if let value = Double(valueString) {
                payslipItem.earnings[key] = value
            }
        }
        
        // Update deductions
        for (key, valueString) in editedDeductions {
            if let value = Double(valueString) {
                payslipItem.deductions[key] = value
            }
        }
        
        // Save the updated payslip
        viewModel.updatePayslip(payslipItem)
        
        // Track which fields were edited
        if editedName != payslipItem.name {
            viewModel.trackEditedField("name")
        }
        
        if editedAccountNumber != payslipItem.accountNumber {
            viewModel.trackEditedField("accountNumber")
        }
        
        if editedPanNumber != payslipItem.panNumber {
            viewModel.trackEditedField("panNumber")
        }
        
        // Exit edit mode and show confirmation
        isEditingPayslip = false
        showSaveAlert = true
    }
    
    private func calculateNetAmount() -> String {
        let credits = Double(editedCredits) ?? 0
        let debits = Double(editedDebits) ?? 0
        let dsop = Double(editedDSOP) ?? 0
        let tax = Double(editedTax) ?? 0
        
        let netAmount = credits - debits - dsop - tax
        return String(format: "%.0f", netAmount)
    }
    
    private func calculateTotalEditedEarnings() -> Double {
        var total: Double = 0
        for (_, valueString) in editedEarnings {
            if let value = Double(valueString) {
                total += value
            }
        }
        return total
    }
    
    private func calculateTotalEditedDeductions() -> Double {
        var total: Double = 0
        for (_, valueString) in editedDeductions {
            if let value = Double(valueString) {
                total += value
            }
        }
        return total
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

// Add a helper method to format currency without decimal places
private func formatCurrencyWithoutDecimals(_ value: Double) -> String {
    return String(format: "%.0f", value)
}
