import SwiftUI
import PDFKit

/// View for displaying parsing results and collecting user feedback
struct PDFParsingFeedbackView: View {
    // MARK: - Properties

    /// The ViewModel managing the state and logic for this view
    @StateObject private var viewModel: PDFParsingFeedbackViewModel

    /// Environment object for dismissing the view
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Initialization

    init(viewModel: PDFParsingFeedbackViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                personalDetailsSection
                earningsSection
                deductionsSection
                netPaySection
                actionsSection
            }
            .navigationTitle("Parsing Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        Button("Cancel") {
                            viewModel.cancelEditing()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showParserSelection) {
                ParserSelectionView(
                    pdfDocument: viewModel.documentForSelection,
                    parsingCoordinator: viewModel.coordinatorForSelection,
                    onParserSelected: { newPayslipItem in
                        viewModel.handleNewParsingResult(newPayslipItem)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showAbbreviationManagement) {
                AbbreviationManagementView()
                    .environmentObject(viewModel.managerForAbbreviations)
            }
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Payslip has been saved successfully.")
            }
        }
    }

    // MARK: - Extracted View Components

    private var personalDetailsSection: some View {
        Section(header: Text("Personal Details")) {
            if viewModel.isEditing {
                TextField("Name", text: $viewModel.editedName)
                TextField("Month", text: $viewModel.editedMonth)
                TextField("Year", value: $viewModel.editedYear, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
            } else {
                LabeledContent("Name", value: viewModel.payslipItem.name)
                LabeledContent("Month", value: viewModel.payslipItem.month)
                LabeledContent("Year", value: String(viewModel.payslipItem.year))
                LabeledContent("Account Number", value: viewModel.payslipItem.accountNumber)
                LabeledContent("PAN Number", value: viewModel.payslipItem.panNumber)
            }
        }
    }

    private var earningsSection: some View {
        Section(header: Text("Earnings")) {
            // Use display name service for clean presentation
            let displayNameService = DIContainer.shared.makePayslipDisplayNameService()
            let displayEarnings = displayNameService.getDisplayEarnings(from: viewModel.isEditing ? viewModel.editedEarnings : viewModel.payslipItem.earnings)

            ForEach(displayEarnings, id: \.displayName) { item in
                if viewModel.isEditing {
                    // Find original key for editing
                    let originalKey = viewModel.editedEarnings.first { $0.value == item.value }?.key ?? item.displayName
                    HStack {
                        Text(item.displayName)
                        Spacer()
                        TextField("Amount", value: Binding<Double>(
                            get: { viewModel.editedEarnings[originalKey] ?? 0 },
                            set: { viewModel.editedEarnings[originalKey] = $0 }
                        ), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    LabeledContent(item.displayName, value: viewModel.formatCurrency(item.value))
                }
            }

            if viewModel.isEditing {
                Button("Add Earning") {
                    viewModel.addNewEarning()
                }
            }

            LabeledContent("Total Credits", value: viewModel.formatCurrency(viewModel.payslipItem.credits))
                .fontWeight(.bold)
        }
    }

    private var deductionsSection: some View {
        Section(header: Text("Deductions")) {
            ForEach(Array(viewModel.editedDeductions.keys.sorted()), id: \.self) { key in
                if viewModel.isEditing {
                    HStack {
                        Text(key)
                        Spacer()
                        TextField("Amount", value: Binding<Double>(
                            get: { viewModel.editedDeductions[key] ?? 0 },
                            set: { viewModel.editedDeductions[key] = $0 }
                        ), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    LabeledContent(key, value: viewModel.formatCurrency(viewModel.payslipItem.deductions[key] ?? 0))
                }
            }

            if viewModel.isEditing {
                Button("Add Deduction") {
                    viewModel.addNewDeduction()
                }
            }

            LabeledContent("Total Debits", value: viewModel.formatCurrency(viewModel.payslipItem.debits))
                .fontWeight(.bold)
        }
    }

    private var netPaySection: some View {
        Section(header: Text("Net Pay")) {
            LabeledContent("Net Pay", value: viewModel.formatCurrency(viewModel.payslipItem.credits - viewModel.payslipItem.debits))
                 .fontWeight(.bold)
        }
    }

    private var actionsSection: some View {
        Section {
            Button(viewModel.isEditing ? "Save Changes" : "Edit") {
                viewModel.toggleEdit()
            }

            if !viewModel.isEditing {
                Button("Try Different Parser") {
                    viewModel.triggerParserSelection()
                }

                Button("Manage Abbreviations") {
                    viewModel.triggerAbbreviationManagement()
                }

                Button("Accept and Save") {
                    viewModel.acceptAndSavePayslip()
                }
                .foregroundColor(.green)
            }
        }
    }
}

/// View for selecting a parser
struct ParserSelectionView: View {
    // MARK: - Properties

    /// The PDF document to parse
    private let pdfDocument: PDFDocument

    /// The parsing coordinator
    private let parsingCoordinator: PDFParsingCoordinatorProtocol

    /// Callback for when a parser is selected
    private let onParserSelected: (PayslipItem?) -> Void

    /// Available parsers
    @State private var availableParsers: [String] = []

    /// Environment object for dismissing the view
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Initialization

    init(pdfDocument: PDFDocument, parsingCoordinator: PDFParsingCoordinatorProtocol, onParserSelected: @escaping (PayslipItem?) -> Void) {
        self.pdfDocument = pdfDocument
        self.parsingCoordinator = parsingCoordinator
        self.onParserSelected = onParserSelected
        self._availableParsers = State(initialValue: parsingCoordinator.getAvailableParsers().map { $0.name })
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                ForEach(availableParsers, id: \.self) { parser in
                    Button(parser) {
                        Task {
                            await selectParser(parser)
                        }
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
    private func selectParser(_ parser: String) async {
        do {
            let payslipDTO = try await parsingCoordinator.parsePayslip(pdfDocument: pdfDocument, using: parser)
            let payslipItem = payslipDTO.map { PayslipItem(from: $0) }
            onParserSelected(payslipItem)
        } catch {
            print("Error parsing with selected parser '\(parser)': \(error)")
            onParserSelected(nil)
        }
        await MainActor.run {
             presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview Provider (Needs Update)

// struct PDFParsingFeedbackView_Previews: PreviewProvider {
//     static var previews: some View {
//         // TODO: Update PreviewProvider to instantiate ViewModel with mock dependencies
//         // Need mock PayslipItem, mock PDFDocument, mock ParsingCoordinator, mock AbbreviationManager
//         let mockItem = PayslipItem(/* ... */)
//         let mockViewModel = PDFParsingFeedbackViewModel(
//             payslipItem: mockItem,
//             parsingCoordinator: MockParsingCoordinator(), // Create mock
//             abbreviationManager: MockAbbreviationManager() // Create mock
//         )
//         PDFParsingFeedbackView(viewModel: mockViewModel)
//     }
// }
