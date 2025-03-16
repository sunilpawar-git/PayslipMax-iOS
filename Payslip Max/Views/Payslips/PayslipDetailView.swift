import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

// Define a notification name for payslip deletion
extension Notification.Name {
    static let payslipDeleted = Notification.Name("PayslipDeleted")
    static let payslipUpdated = Notification.Name("PayslipUpdated")
}

struct PayslipDetailView: View {
    let payslip: any PayslipItemProtocol
    @StateObject private var viewModel: PayslipDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showingDeleteConfirmation = false
    @State private var showCategorizedView = false
    
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
    
    // Add state variables for editing Income Tax details
    @State private var editedIncomeTaxDetails: [String: String] = [:]
    
    // Add state variables for editing DSOP details
    @State private var editedDSOPDetails: [String: String] = [:]
    
    init(payslip: any PayslipItemProtocol, viewModel: PayslipDetailViewModel? = nil) {
        self.payslip = payslip
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: PayslipDetailViewModel(payslip: payslip))
        }
        
        // Initialize edited values with current payslip values
        _editedName = State(initialValue: payslip.name)
        _editedAccountNumber = State(initialValue: payslip.accountNumber)
        _editedPanNumber = State(initialValue: payslip.panNumber)
        
        // Initialize financial values
        _editedCredits = State(initialValue: String(format: "%.2f", payslip.credits))
        _editedDebits = State(initialValue: String(format: "%.2f", payslip.debits))
        _editedDSOP = State(initialValue: String(format: "%.2f", payslip.dsop))
        _editedTax = State(initialValue: String(format: "%.2f", payslip.tax))
        
        // Initialize earnings and deductions
        var initialEarnings: [String: String] = [:]
        for (key, value) in payslip.earnings {
            initialEarnings[key] = String(format: "%.2f", value)
        }
        _editedEarnings = State(initialValue: initialEarnings)
        
        var initialDeductions: [String: String] = [:]
        for (key, value) in payslip.deductions {
            initialDeductions[key] = String(format: "%.2f", value)
        }
        _editedDeductions = State(initialValue: initialDeductions)
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let decryptedPayslip = viewModel.decryptedPayslip {
                List {
                    // PERSONAL DETAILS SECTION
                    Section(header: VStack(alignment: .leading, spacing: 4) {
                        Text("\(decryptedPayslip.month) \(String(decryptedPayslip.year))")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("PERSONAL DETAILS")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("personal_details_header")
                            Spacer()
                            if !isEditingPayslip {
                                Button(action: {
                                    startEditingPayslip(decryptedPayslip)
                                }) {
                                    Label("Edit", systemImage: "pencil.circle")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .accessibilityIdentifier("edit_button")
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
                        }
                    }
                    
                    // Add this after the personal details section and before the financial details section
                    if !viewModel.unknownComponents.isEmpty && !isEditingPayslip {
                        Section(header: Text("NEW COMPONENTS").accessibilityIdentifier("new_components_header")) {
                            UnknownComponentsView(viewModel: viewModel)
                        }
                    }
                    
                    // FINANCIAL DETAILS SECTION
                    Section(header: Text("FINANCIAL DETAILS").accessibilityIdentifier("financial_details_header")) {
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
                            }
                        } else {
                        DetailRow(title: "Credits", value: viewModel.formatCurrency(decryptedPayslip.credits))
                            .accessibilityIdentifier("credits_row")
                        DetailRow(title: "Debits", value: viewModel.formatCurrency(decryptedPayslip.debits))
                            .accessibilityIdentifier("debits_row")
                        DetailRow(title: "DSOP", value: viewModel.formatCurrency(decryptedPayslip.dsop))
                            .accessibilityIdentifier("dsop_row")
                        DetailRow(title: "Income Tax", value: viewModel.formatCurrency(decryptedPayslip.tax))
                            .accessibilityIdentifier("income_tax_row")
                        }
                    }
                    
                    // Add this after the deductions section
                    if let payslipItem = decryptedPayslip as? PayslipItem, !isEditingPayslip {
                        Section(header: Text("NET REMITTANCE").accessibilityIdentifier("net_remittance_header")) {
                            // Use credits minus debits for net remittance (what actually goes to the bank)
                            NetRemittanceView(totalEarnings: payslipItem.credits, totalDeductions: payslipItem.debits)
                        }
                    }
                    
                    // EARNINGS & DEDUCTIONS SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem, 
                       !payslipItem.earnings.isEmpty || !payslipItem.deductions.isEmpty {
                        
                        Section(header: HStack {
                            Text("EARNINGS & DEDUCTIONS")
                                .accessibilityIdentifier("earnings_deductions_header")
                        }) {
                            if !isEditingPayslip {
                                // Remove the categorized view completely
                            }
                        }
                    }
                    
                    // EARNINGS BREAKDOWN SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem {
                        Section(header: Text("EARNINGS BREAKDOWN")) {
                            if isEditingPayslip {
                                // Standard earnings components
                                let standardEarningsKeys = ["BPAY", "DA", "MSP", "HRA"]
                                
                                // Display standard earnings first
                                ForEach(standardEarningsKeys, id: \.self) { key in
                                    if let value = payslipItem.earnings[key], value > 1 {
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
                                
                                // Display non-standard earnings
                                ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                    if !standardEarningsKeys.contains(key), let value = payslipItem.earnings[key], value > 1 {
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
                                // Standard earnings components
                                let standardEarningsKeys = ["BPAY", "DA", "MSP", "HRA"]
                                
                                // Display standard earnings first
                                ForEach(standardEarningsKeys, id: \.self) { key in
                                    if let value = payslipItem.earnings[key], value > 1 {
                                        DetailRow(title: key, value: viewModel.formatCurrency(value))
                                    }
                                }
                                
                                // Display non-standard earnings
                                ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                    if !standardEarningsKeys.contains(key), let value = payslipItem.earnings[key], value > 1 {
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
                    if let payslipItem = decryptedPayslip as? PayslipItem {
                        Section(header: Text("DEDUCTIONS BREAKDOWN")) {
                            if isEditingPayslip {
                                // Standard deductions components
                                let standardDeductionsKeys = ["DSOP", "AGIF", "ITAX"]
                                
                                // Display standard deductions first
                                ForEach(standardDeductionsKeys, id: \.self) { key in
                                    if let value = payslipItem.deductions[key], value > 1 {
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
                                
                                // Display non-standard deductions
                                ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                    if !standardDeductionsKeys.contains(key), let value = payslipItem.deductions[key], value > 1 {
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
                                // Standard deductions components
                                let standardDeductionsKeys = ["DSOP", "AGIF", "ITAX"]
                                
                                // Display standard deductions first
                                ForEach(standardDeductionsKeys, id: \.self) { key in
                                    if let value = payslipItem.deductions[key], value > 1 {
                                        DetailRow(title: key, value: viewModel.formatCurrency(value))
                                    }
                                }
                                
                                // Display non-standard deductions
                                ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                    if !standardDeductionsKeys.contains(key), let value = payslipItem.deductions[key], value > 1 {
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
                    
                    // INCOME TAX DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("INCOME TAX DETAILS")) {
                            if isEditingPayslip {
                                // Editing mode for Income Tax details
                                if let statementPeriod = viewModel.extractedData["statementPeriod"] {
                                    HStack {
                                        Text("Statement Period:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["statementPeriod"] ?? statementPeriod },
                                            set: { self.editedIncomeTaxDetails["statementPeriod"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let incomeTaxDeducted = viewModel.extractedData["incomeTaxDeducted"] {
                                    HStack {
                                        Text("Income Tax Deducted:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["incomeTaxDeducted"] ?? incomeTaxDeducted },
                                            set: { self.editedIncomeTaxDetails["incomeTaxDeducted"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let edCessDeducted = viewModel.extractedData["edCessDeducted"] {
                                    HStack {
                                        Text("Ed. Cess Deducted:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["edCessDeducted"] ?? edCessDeducted },
                                            set: { self.editedIncomeTaxDetails["edCessDeducted"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let totalTaxPayable = viewModel.extractedData["totalTaxPayable"] {
                                    HStack {
                                        Text("Total Tax Payable:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["totalTaxPayable"] ?? totalTaxPayable },
                                            set: { self.editedIncomeTaxDetails["totalTaxPayable"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let grossSalary = viewModel.extractedData["grossSalary"] {
                                    HStack {
                                        Text("Gross Salary:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["grossSalary"] ?? grossSalary },
                                            set: { self.editedIncomeTaxDetails["grossSalary"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let standardDeduction = viewModel.extractedData["standardDeduction"] {
                                    HStack {
                                        Text("Standard Deduction:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["standardDeduction"] ?? standardDeduction },
                                            set: { self.editedIncomeTaxDetails["standardDeduction"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let netTaxableIncome = viewModel.extractedData["netTaxableIncome"] {
                                    HStack {
                                        Text("Net Taxable Income:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedIncomeTaxDetails["netTaxableIncome"] ?? netTaxableIncome },
                                            set: { self.editedIncomeTaxDetails["netTaxableIncome"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                            } else {
                                // View mode for Income Tax details
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
                    }
                    
                    // DSOP DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("DSOP DETAILS")) {
                            if isEditingPayslip {
                                // Editing mode for DSOP details
                                if let dsopOpeningBalance = viewModel.extractedData["dsopOpeningBalance"] {
                                    HStack {
                                        Text("Opening Balance:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopOpeningBalance"] ?? dsopOpeningBalance },
                                            set: { self.editedDSOPDetails["dsopOpeningBalance"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let dsopSubscription = viewModel.extractedData["dsopSubscription"] {
                                    HStack {
                                        Text("Subscription:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopSubscription"] ?? dsopSubscription },
                                            set: { self.editedDSOPDetails["dsopSubscription"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let dsopMiscAdj = viewModel.extractedData["dsopMiscAdj"] {
                                    HStack {
                                        Text("Misc Adj:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopMiscAdj"] ?? dsopMiscAdj },
                                            set: { self.editedDSOPDetails["dsopMiscAdj"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let dsopWithdrawal = viewModel.extractedData["dsopWithdrawal"] {
                                    HStack {
                                        Text("Withdrawal:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopWithdrawal"] ?? dsopWithdrawal },
                                            set: { self.editedDSOPDetails["dsopWithdrawal"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let dsopRefund = viewModel.extractedData["dsopRefund"] {
                                    HStack {
                                        Text("Refund:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopRefund"] ?? dsopRefund },
                                            set: { self.editedDSOPDetails["dsopRefund"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                                
                                if let dsopClosingBalance = viewModel.extractedData["dsopClosingBalance"] {
                                    HStack {
                                        Text("Closing Balance:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: { self.editedDSOPDetails["dsopClosingBalance"] ?? dsopClosingBalance },
                                            set: { self.editedDSOPDetails["dsopClosingBalance"] = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 150)
                                    }
                                }
                            } else {
                                // View mode for DSOP details
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
                    }
                    
                    // Add the diagnostics section at the end of the List
                    Section(header: Text("DIAGNOSTICS").accessibilityIdentifier("diagnostics_header")) {
                        Button(action: {
                            viewModel.showDiagnostics = true
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass.circle")
                                    .foregroundColor(.blue)
                                Text("View Extraction Patterns")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .accessibilityIdentifier("view_extraction_patterns_button")
                        .disabled(!(viewModel.decryptedPayslip is PayslipItem))
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
                    
                    // CONTACT DETAILS SECTION
                    Section(header: Text("CONTACT DETAILS")) {
                        if let contactSAOLW = viewModel.extractedData["contactSAOLW"], !contactSAOLW.isEmpty {
                            ContactDetailRow(title: "SAO(LW)", value: contactSAOLW)
                        }
                        
                        if let contactAAOLW = viewModel.extractedData["contactAAOLW"], !contactAAOLW.isEmpty {
                            ContactDetailRow(title: "AAO(LW)", value: contactAAOLW)
                        }
                        
                        if let contactSAOTW = viewModel.extractedData["contactSAOTW"], !contactSAOTW.isEmpty {
                            ContactDetailRow(title: "SAO(TW)", value: contactSAOTW)
                        }
                        
                        if let contactAAOTW = viewModel.extractedData["contactAAOTW"], !contactAAOTW.isEmpty {
                            ContactDetailRow(title: "AAO(TW)", value: contactAAOTW)
                        }
                        
                        if let contactProCivil = viewModel.extractedData["contactProCivil"], !contactProCivil.isEmpty {
                            ContactDetailRow(title: "PRO CIVIL", value: contactProCivil)
                        }
                        
                        if let contactProArmy = viewModel.extractedData["contactProArmy"], !contactProArmy.isEmpty {
                            ContactDetailRow(title: "PRO ARMY", value: contactProArmy)
                        }
                        
                        if let contactHelpDesk = viewModel.extractedData["contactHelpDesk"], !contactHelpDesk.isEmpty {
                            ContactDetailRow(title: "Help Desk", value: contactHelpDesk)
                        }
                        
                        if let contactWebsite = viewModel.extractedData["contactWebsite"], !contactWebsite.isEmpty {
                            ContactDetailRow(title: "Website", value: contactWebsite, isWebsite: true)
                        }
                        
                        if let contactEmailTADA = viewModel.extractedData["contactEmailTADA"], !contactEmailTADA.isEmpty {
                            ContactDetailRow(title: "TA/DA Email", value: contactEmailTADA, isEmail: true)
                        }
                        
                        if let contactEmailLedger = viewModel.extractedData["contactEmailLedger"], !contactEmailLedger.isEmpty {
                            ContactDetailRow(title: "Ledger Email", value: contactEmailLedger, isEmail: true)
                        }
                        
                        if let contactEmailRankPay = viewModel.extractedData["contactEmailRankPay"], !contactEmailRankPay.isEmpty {
                            ContactDetailRow(title: "Rank Pay Email", value: contactEmailRankPay, isEmail: true)
                        }
                        
                        if let contactEmailGeneral = viewModel.extractedData["contactEmailGeneral"], !contactEmailGeneral.isEmpty {
                            ContactDetailRow(title: "General Query Email", value: contactEmailGeneral, isEmail: true)
                        }
                        
                        // Display any other contact details that don't match the predefined types
                        ForEach(viewModel.extractedData.keys.sorted(), id: \.self) { key in
                            if key.hasPrefix("contact") && 
                               key != "contactSAOLW" && 
                               key != "contactAAOLW" && 
                               key != "contactSAOTW" && 
                               key != "contactAAOTW" && 
                               key != "contactProCivil" && 
                               key != "contactProArmy" && 
                               key != "contactHelpDesk" && 
                               key != "contactWebsite" && 
                               key != "contactEmailTADA" && 
                               key != "contactEmailLedger" && 
                               key != "contactEmailRankPay" && 
                               key != "contactEmailGeneral" {
                                
                                let value = viewModel.extractedData[key]!
                                let title = key.replacingOccurrences(of: "contact", with: "")
                                    .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                if value.contains("@") {
                                    ContactDetailRow(title: title, value: value, isEmail: true)
                                } else if value.contains("http") || value.contains(".com") || value.contains(".gov") || value.contains(".in") {
                                    ContactDetailRow(title: title, value: value, isWebsite: true)
                                } else {
                                    ContactDetailRow(title: title, value: value, isPhone: value.contains(where: { $0.isNumber }))
                                }
                            }
                        }
                        
                        // Add a default message if no contact details are available
                        if !viewModel.extractedData.keys.contains(where: { $0.hasPrefix("contact") }) {
                            Text("No contact details available")
                                .foregroundColor(.secondary)
                                .italic()
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
        .sheet(isPresented: $viewModel.showDiagnostics) {
            NavigationView {
                if let payslipItem = viewModel.decryptedPayslip as? PayslipItem {
                    PayslipExtractionDiagnosticsView(payslip: payslipItem)
                } else {
                    Text("Diagnostics only available for PayslipItem objects")
                }
            }
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
        
        // Initialize Income Tax details
        editedIncomeTaxDetails = [:]
        for (key, value) in viewModel.extractedData {
            if key.starts(with: "incomeTax") || key == "statementPeriod" || key == "edCessDeducted" || 
               key == "totalTaxPayable" || key == "grossSalary" || key == "standardDeduction" || 
               key == "netTaxableIncome" {
                editedIncomeTaxDetails[key] = value
            }
        }
        
        // Initialize DSOP details
        editedDSOPDetails = [:]
        for (key, value) in viewModel.extractedData {
            if key.starts(with: "dsop") {
                editedDSOPDetails[key] = value
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
        
        // Update Income Tax details in extractedData
        for (key, value) in editedIncomeTaxDetails {
            viewModel.updateExtractedData(key: key, value: value)
        }
        
        // Update DSOP details in extractedData
        for (key, value) in editedDSOPDetails {
            viewModel.updateExtractedData(key: key, value: value)
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
        .padding(.horizontal, 0)
    }
}

struct ContactDetailRow: View {
    let title: String
    let value: String
    var isPhone: Bool = false
    var isEmail: Bool = false
    var isWebsite: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            if isPhone || isPhoneNumber(value) {
                Button(action: {
                    let cleanedNumber = value.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                    if let url = URL(string: "tel://\(cleanedNumber)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(value)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.trailing)
                }
            } else if isEmail {
                Button(action: {
                    if let url = URL(string: "mailto:\(value)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(value)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.trailing)
                }
            } else if isWebsite {
                Button(action: {
                    var urlString = value
                    if !urlString.lowercased().hasPrefix("http") {
                        urlString = "https://\(urlString)"
                    }
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text(value)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 0)
    }
    
    // Helper function to detect if a string is likely a phone number
    private func isPhoneNumber(_ string: String) -> Bool {
        // Simple check for phone number format
        let phoneRegex = "^[0-9+\\-\\(\\) ]{7,}$"
        return string.range(of: phoneRegex, options: .regularExpression) != nil
    }
}

// Add a helper method to format currency without decimal places
private func formatCurrencyWithoutDecimals(_ value: Double) -> String {
    // For year values, just return the integer without formatting
    if value >= 1000 && value <= 9999 && value.truncatingRemainder(dividingBy: 1) == 0 {
        return String(format: "%.0f", value)
    }
    
    // For currency values, use number formatter with grouping separator
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    
    if let formattedValue = formatter.string(from: NSNumber(value: value)) {
        return formattedValue
    }
    
    return String(format: "%.0f", value)
}
