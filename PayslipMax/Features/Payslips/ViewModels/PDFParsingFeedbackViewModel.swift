import SwiftUI
import Combine
import PDFKit

@MainActor
final class PDFParsingFeedbackViewModel: ObservableObject {
    // MARK: - Published Properties (State)

    @Published var payslipItem: PayslipItem
    @Published var isEditing: Bool = false
    @Published var showParserSelection: Bool = false
    @Published var showAbbreviationManagement: Bool = false
    @Published var showSuccessAlert: Bool = false

    // Temporary storage for edits (Consider a dedicated struct if complex)
    @Published var editedName: String
    @Published var editedMonth: String
    @Published var editedYear: Int
    @Published var editedEarnings: [String: Double]
    @Published var editedDeductions: [String: Double]

    // MARK: - Dependencies (Inject these)

    private let parsingCoordinator: PDFParsingCoordinatorProtocol // Or a dedicated service
    private let abbreviationManager: AbbreviationManager // Needs DI
    private let pdfDocument: PDFDocument // Needed for ParserSelectionView
    // Add other services if needed (e.g., DataService for saving)

    // MARK: - Initialization

    init(payslipItem: PayslipItem, pdfDocument: PDFDocument, parsingCoordinator: PDFParsingCoordinatorProtocol, abbreviationManager: AbbreviationManager) {
        self.payslipItem = payslipItem
        self.pdfDocument = pdfDocument // Store pdfDocument
        self.parsingCoordinator = parsingCoordinator
        self.abbreviationManager = abbreviationManager

        // Initialize editable state from the initial item
        self.editedName = payslipItem.name
        self.editedMonth = payslipItem.month
        self.editedYear = payslipItem.year
        self.editedEarnings = payslipItem.earnings
        self.editedDeductions = payslipItem.deductions
        
        print("PDFParsingFeedbackViewModel Initialized for payslip: \(payslipItem.id)")
    }

    // MARK: - Public Accessors for Dependencies (if needed by View)
    
    // Provide access if sheets need direct access, though ideally ViewModels are passed
    var documentForSelection: PDFDocument { pdfDocument }
    var coordinatorForSelection: PDFParsingCoordinatorProtocol { parsingCoordinator }
    var managerForAbbreviations: AbbreviationManager { abbreviationManager }

    // MARK: - Actions / Methods (Implement Logic Here)

    func toggleEdit() {
        isEditing.toggle()
        if !isEditing {
            // Reset edits if cancelled
            resetEditedValues()
        }
        print("Toggle Edit: isEditing = \(isEditing)")
    }

    func saveChanges() {
        // TODO: Implement logic to update payslipItem from edited values
        print("Save Changes called")
        // Update the main payslipItem with edited values
        payslipItem.name = editedName
        payslipItem.month = editedMonth
        payslipItem.year = editedYear
        payslipItem.earnings = editedEarnings
        payslipItem.deductions = editedDeductions
        // Recalculate totals if necessary (or ensure model does it)
        payslipItem.credits = editedEarnings.values.reduce(0, +)
        payslipItem.debits = editedDeductions.values.reduce(0, +)
        
        isEditing = false
    }

    func cancelEditing() {
        resetEditedValues()
        isEditing = false
        print("Cancel Editing called")
    }

    func addNewEarning() {
        // TODO: Implement logic to add a new placeholder earning entry
        print("Add New Earning called")
         // Example: Add a default new entry
        let newKey = "New Earning \(editedEarnings.count + 1)"
        editedEarnings[newKey] = 0
    }

    func addNewDeduction() {
        // TODO: Implement logic to add a new placeholder deduction entry
        print("Add New Deduction called")
        // Example: Add a default new entry
        let newKey = "New Deduction \(editedDeductions.count + 1)"
        editedDeductions[newKey] = 0
    }

    func triggerParserSelection() {
        showParserSelection = true
        print("Trigger Parser Selection called")
    }

    func triggerAbbreviationManagement() {
        showAbbreviationManagement = true
        print("Trigger Abbreviation Management called")
    }

    func acceptAndSavePayslip() {
        // TODO: Implement logic to save the (potentially edited) payslipItem
        // This might involve calling a DataService or Repository
        print("Accept and Save Payslip called for ID: \(payslipItem.id)")
        // Example placeholder for success
        showSuccessAlert = true 
    }
    
    func handleNewParsingResult(_ newPayslipItem: PayslipItem?) {
         if let newItem = newPayslipItem {
             self.payslipItem = newItem
             resetEditedValues() // Reset edits to reflect new item
             print("Updated payslipItem from parser selection: \(newItem.id)")
         } else {
             print("Parser selection resulted in nil item.")
         }
     }

    // MARK: - Private Helpers

    private func resetEditedValues() {
        editedName = payslipItem.name
        editedMonth = payslipItem.month
        editedYear = payslipItem.year
        editedEarnings = payslipItem.earnings
        editedDeductions = payslipItem.deductions
        print("Reset edited values to match payslipItem: \(payslipItem.id)")
    }
    
    // MARK: - Formatting (Consider moving to a dedicated Formatter)
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Or specify a locale
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
} 