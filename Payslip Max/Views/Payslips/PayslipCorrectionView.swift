import SwiftUI

/// A view for correcting extracted payslip data.
struct PayslipCorrectionView: View {
    // MARK: - Properties
    
    /// The payslip to correct.
    @State private var payslip: any PayslipItemProtocol
    
    /// The filename of the PDF.
    let pdfFilename: String
    
    /// The action to perform when corrections are saved.
    let onSave: (PayslipItem) -> Void
    
    /// The corrected name.
    @State private var name: String
    
    /// The corrected month.
    @State private var month: String
    
    /// The corrected year.
    @State private var year: Int
    
    /// The corrected credits.
    @State private var credits: String
    
    /// The corrected debits.
    @State private var debits: String
    
    /// The corrected DSPOF.
    @State private var dspof: String
    
    /// The corrected tax.
    @State private var tax: String
    
    /// The corrected location.
    @State private var location: String
    
    /// The corrected account number.
    @State private var accountNumber: String
    
    /// The corrected PAN number.
    @State private var panNumber: String
    
    /// Whether to dismiss the view.
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipCorrectionView.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to correct.
    ///   - pdfFilename: The filename of the PDF.
    ///   - onSave: The action to perform when corrections are saved.
    init(payslip: any PayslipItemProtocol, pdfFilename: String, onSave: @escaping (PayslipItem) -> Void) {
        self._payslip = State(initialValue: payslip)
        self.pdfFilename = pdfFilename
        self.onSave = onSave
        
        // Initialize state variables with original values
        _name = State(initialValue: payslip.name)
        _month = State(initialValue: payslip.month)
        _year = State(initialValue: payslip.year)
        _credits = State(initialValue: String(format: "%.2f", payslip.credits))
        _debits = State(initialValue: String(format: "%.2f", payslip.debits))
        _dspof = State(initialValue: String(format: "%.2f", payslip.dspof))
        _tax = State(initialValue: String(format: "%.2f", payslip.tax))
        _location = State(initialValue: payslip.location)
        _accountNumber = State(initialValue: payslip.accountNumber)
        _panNumber = State(initialValue: payslip.panNumber)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Personal details section
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                    
                    TextField("Month", text: $month)
                    
                    Stepper(value: $year, in: 2000...2100) {
                        HStack {
                            Text("Year")
                            Spacer()
                            Text("\(year)")
                        }
                    }
                    
                    TextField("Location", text: $location)
                    
                    TextField("Account Number", text: $accountNumber)
                    
                    TextField("PAN Number", text: $panNumber)
                }
                
                // Financial details section
                Section(header: Text("Financial Details")) {
                    HStack {
                        Text("Credits")
                        Spacer()
                        TextField("Credits", text: $credits)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Debits")
                        Spacer()
                        TextField("Debits", text: $debits)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("DSPOF")
                        Spacer()
                        TextField("DSPOF", text: $dspof)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        TextField("Tax", text: $tax)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Changes section
                Section(header: Text("Changes")) {
                    ForEach(getChanges(), id: \.field) { change in
                        HStack {
                            Text(change.field)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(change.from) → \(change.to)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Save button
                Section {
                    Button("Save Corrections") {
                        saveCorrections()
                    }
                    .disabled(getChanges().isEmpty)
                }
            }
            .navigationTitle("Correct Extraction")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // MARK: - Methods
    
    /// Gets the changes made to the payslip.
    ///
    /// - Returns: The changes made to the payslip.
    private func getChanges() -> [PayslipChange] {
        var changes: [PayslipChange] = []
        
        // Check each field for changes
        if name != payslip.name {
            changes.append(PayslipChange(field: "Name", from: payslip.name, to: name))
        }
        
        if month != payslip.month {
            changes.append(PayslipChange(field: "Month", from: payslip.month, to: month))
        }
        
        if year != payslip.year {
            changes.append(PayslipChange(field: "Year", from: "\(payslip.year)", to: "\(year)"))
        }
        
        let creditsValue = Double(credits) ?? 0
        if abs(creditsValue - payslip.credits) > 0.01 {
            changes.append(PayslipChange(
                field: "Credits",
                from: String(format: "%.2f", payslip.credits),
                to: String(format: "%.2f", creditsValue)
            ))
        }
        
        let debitsValue = Double(debits) ?? 0
        if abs(debitsValue - payslip.debits) > 0.01 {
            changes.append(PayslipChange(
                field: "Debits",
                from: String(format: "%.2f", payslip.debits),
                to: String(format: "%.2f", debitsValue)
            ))
        }
        
        let dspofValue = Double(dspof) ?? 0
        if abs(dspofValue - payslip.dspof) > 0.01 {
            changes.append(PayslipChange(
                field: "DSPOF",
                from: String(format: "%.2f", payslip.dspof),
                to: String(format: "%.2f", dspofValue)
            ))
        }
        
        let taxValue = Double(tax) ?? 0
        if abs(taxValue - payslip.tax) > 0.01 {
            changes.append(PayslipChange(
                field: "Tax",
                from: String(format: "%.2f", payslip.tax),
                to: String(format: "%.2f", taxValue)
            ))
        }
        
        if location != payslip.location {
            changes.append(PayslipChange(field: "Location", from: payslip.location, to: location))
        }
        
        if accountNumber != payslip.accountNumber {
            changes.append(PayslipChange(field: "Account Number", from: payslip.accountNumber, to: accountNumber))
        }
        
        if panNumber != payslip.panNumber {
            changes.append(PayslipChange(field: "PAN Number", from: payslip.panNumber, to: panNumber))
        }
        
        return changes
    }
    
    /// Saves the corrections to the payslip.
    private func saveCorrections() {
        // Create a new payslip with the corrected values
        let correctedPayslip = PayslipItem(
            month: month,
            year: year,
            credits: Double(credits) ?? 0,
            debits: Double(debits) ?? 0,
            dspof: Double(dspof) ?? 0,
            tax: Double(tax) ?? 0,
            location: location,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: payslip.timestamp
        )
        
        // Record the corrections for training
        PDFExtractionTrainer.shared.recordCorrections(
            pdfFilename: pdfFilename,
            corrections: correctedPayslip
        )
        
        // Call the onSave callback
        onSave(correctedPayslip)
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Types

/// A change made to a payslip field.
struct PayslipChange {
    /// The field that was changed.
    let field: String
    
    /// The original value.
    let from: String
    
    /// The new value.
    let to: String
} 