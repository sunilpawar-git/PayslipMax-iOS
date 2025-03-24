import SwiftUI
import PDFKit

/// View for displaying parsing results and collecting user feedback
struct PDFParsingFeedbackView: View {
    // MARK: - Properties
    
    /// The parsed payslip item
    @State private var payslipItem: PayslipItem
    
    /// The original PDF document
    private let pdfDocument: PDFDocument
    
    /// The parsing coordinator
    private let parsingCoordinator: PDFParsingCoordinator
    
    /// Flag indicating whether the view is in edit mode
    @State private var isEditing = false
    
    /// Flag indicating whether to show the parser selection
    @State private var showParserSelection = false
    
    /// The selected parser name
    @State private var selectedParser: String?
    
    /// Flag indicating whether to show the abbreviation management view
    @State private var showAbbreviationManagement = false
    
    /// Flag indicating whether to show the success alert
    @State private var showSuccessAlert = false
    
    /// Temporary storage for edited values
    @State private var editedEarnings: [String: Double] = [:]
    @State private var editedDeductions: [String: Double] = [:]
    @State private var editedName: String = ""
    @State private var editedMonth: String = ""
    @State private var editedYear: Int = 0
    
    /// Environment object for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Initialization
    
    init(payslipItem: PayslipItem, pdfDocument: PDFDocument, parsingCoordinator: PDFParsingCoordinator) {
        self._payslipItem = State(initialValue: payslipItem)
        self.pdfDocument = pdfDocument
        self.parsingCoordinator = parsingCoordinator
        
        // Initialize edited values with current values
        self._editedEarnings = State(initialValue: payslipItem.earnings)
        self._editedDeductions = State(initialValue: payslipItem.deductions)
        self._editedName = State(initialValue: payslipItem.name)
        self._editedMonth = State(initialValue: payslipItem.month)
        self._editedYear = State(initialValue: payslipItem.year)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Personal Details Section
                Section(header: Text("Personal Details")) {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        TextField("Month", text: $editedMonth)
                        TextField("Year", value: $editedYear, formatter: NumberFormatter())
                    } else {
                        LabeledContent("Name", value: payslipItem.name)
                        LabeledContent("Month", value: payslipItem.month)
                        LabeledContent("Year", value: String(payslipItem.year))
                        LabeledContent("Account Number", value: payslipItem.accountNumber)
                        LabeledContent("PAN Number", value: payslipItem.panNumber)
                        LabeledContent("Location", value: payslipItem.location)
                    }
                }
                
                // Earnings Section
                Section(header: Text("Earnings")) {
                    ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                        if isEditing {
                            HStack {
                                Text(key)
                                Spacer()
                                TextField("Amount", value: Binding(
                                    get: { self.editedEarnings[key] ?? 0 },
                                    set: { self.editedEarnings[key] = $0 }
                                ), formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            }
                        } else {
                            LabeledContent(key, value: formatCurrency(payslipItem.earnings[key] ?? 0))
                        }
                    }
                    
                    if isEditing {
                        Button("Add Earning") {
                            addNewEarning()
                        }
                    }
                    
                    LabeledContent("Total Credits", value: formatCurrency(payslipItem.credits))
                        .fontWeight(.bold)
                }
                
                // Deductions Section
                Section(header: Text("Deductions")) {
                    ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                        if isEditing {
                            HStack {
                                Text(key)
                                Spacer()
                                TextField("Amount", value: Binding(
                                    get: { self.editedDeductions[key] ?? 0 },
                                    set: { self.editedDeductions[key] = $0 }
                                ), formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            }
                        } else {
                            LabeledContent(key, value: formatCurrency(payslipItem.deductions[key] ?? 0))
                        }
                    }
                    
                    if isEditing {
                        Button("Add Deduction") {
                            addNewDeduction()
                        }
                    }
                    
                    LabeledContent("Total Debits", value: formatCurrency(payslipItem.debits))
                        .fontWeight(.bold)
                }
                
                // Net Pay Section
                Section(header: Text("Net Pay")) {
                    LabeledContent("Net Pay", value: formatCurrency(payslipItem.credits - payslipItem.debits))
                        .fontWeight(.bold)
                }
                
                // Actions Section
                Section {
                    Button(isEditing ? "Save Changes" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    }
                    
                    if !isEditing {
                        Button("Try Different Parser") {
                            showParserSelection = true
                        }
                        
                        Button("Manage Abbreviations") {
                            showAbbreviationManagement = true
                        }
                        
                        Button("Accept and Save") {
                            savePayslip()
                            showSuccessAlert = true
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Parsing Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    }
                }
            }
            .sheet(isPresented: $showParserSelection) {
                ParserSelectionView(
                    pdfDocument: pdfDocument,
                    parsingCoordinator: parsingCoordinator,
                    onParserSelected: { newPayslipItem in
                        if let newItem = newPayslipItem {
                            payslipItem = newItem
                            editedEarnings = newItem.earnings
                            editedDeductions = newItem.deductions
                            editedName = newItem.name
                            editedMonth = newItem.month
                            editedYear = newItem.year
                        }
                    }
                )
            }
            .sheet(isPresented: $showAbbreviationManagement) {
                AbbreviationManagementView()
                    .environmentObject(AbbreviationManager())
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Payslip has been saved successfully."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats a currency value
    /// - Parameter value: The value to format
    /// - Returns: A formatted currency string
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
    
    /// Adds a new earning
    private func addNewEarning() {
        let alert = UIAlertController(title: "Add Earning", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Description"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let description = alert.textFields?[0].text, !description.isEmpty,
                  let amountText = alert.textFields?[1].text,
                  let amount = Double(amountText) else {
                return
            }
            
            editedEarnings[description] = amount
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    /// Adds a new deduction
    private func addNewDeduction() {
        let alert = UIAlertController(title: "Add Deduction", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Description"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let description = alert.textFields?[0].text, !description.isEmpty,
                  let amountText = alert.textFields?[1].text,
                  let amount = Double(amountText) else {
                return
            }
            
            editedDeductions[description] = amount
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    /// Saves the changes made in edit mode
    private func saveChanges() {
        // Update payslip item with edited values
        payslipItem.name = editedName
        payslipItem.month = editedMonth
        payslipItem.year = editedYear
        payslipItem.earnings = editedEarnings
        payslipItem.deductions = editedDeductions
        
        // Recalculate totals
        payslipItem.credits = editedEarnings.values.reduce(0, +)
        payslipItem.debits = editedDeductions.values.reduce(0, +)
        
        // Update specific fields
        payslipItem.dsop = editedDeductions["DSOP"] ?? 0
        payslipItem.tax = editedDeductions["ITAX"] ?? 0
        
        // Exit edit mode
        isEditing = false
    }
    
    /// Cancels editing and reverts changes
    private func cancelEditing() {
        // Reset edited values to current values
        editedEarnings = payslipItem.earnings
        editedDeductions = payslipItem.deductions
        editedName = payslipItem.name
        editedMonth = payslipItem.month
        editedYear = payslipItem.year
        
        // Exit edit mode
        isEditing = false
    }
    
    /// Saves the payslip to the database
    private func savePayslip() {
        // This is a placeholder for saving the payslip to your database
        // Implement this based on your existing data persistence mechanism
    }
}

/// View for selecting a parser
struct ParserSelectionView: View {
    // MARK: - Properties
    
    /// The PDF document to parse
    private let pdfDocument: PDFDocument
    
    /// The parsing coordinator
    private let parsingCoordinator: PDFParsingCoordinator
    
    /// Callback for when a parser is selected
    private let onParserSelected: (PayslipItem?) -> Void
    
    /// Available parsers
    @State private var availableParsers: [String] = []
    
    /// Environment object for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Initialization
    
    init(pdfDocument: PDFDocument, parsingCoordinator: PDFParsingCoordinator, onParserSelected: @escaping (PayslipItem?) -> Void) {
        self.pdfDocument = pdfDocument
        self.parsingCoordinator = parsingCoordinator
        self.onParserSelected = onParserSelected
        self._availableParsers = State(initialValue: parsingCoordinator.getAvailableParsers())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableParsers, id: \.self) { parser in
                    Button(parser) {
                        selectParser(parser)
                    }
                }
            }
            .navigationTitle("Select Parser")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Selects a parser and parses the document
    /// - Parameter parser: The name of the parser to use
    private func selectParser(_ parser: String) {
        let payslipItem = parsingCoordinator.parsePayslip(pdfDocument: pdfDocument, using: parser)
        onParserSelected(payslipItem)
        presentationMode.wrappedValue.dismiss()
    }
} 