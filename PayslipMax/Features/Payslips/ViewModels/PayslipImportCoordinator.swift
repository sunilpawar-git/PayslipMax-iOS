import SwiftUI
import PDFKit
import Combine

class PayslipImportCoordinator: ObservableObject {
    // MARK: - Properties
    
    @Published var payslip: PayslipItem?
    @Published var isLoading = false
    @Published var showManualEntry = false
    @Published var showParsingFeedback = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    @Published var parsedPayslipItem: PayslipItem?
    @Published var sourcePdfDocument: PDFDocument?
    
    private let parsingCoordinator: PDFParsingCoordinator
    private let abbreviationManager: AbbreviationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(parsingCoordinator: PDFParsingCoordinator, abbreviationManager: AbbreviationManager) {
        self.parsingCoordinator = parsingCoordinator
        self.abbreviationManager = abbreviationManager
    }
    
    // MARK: - Methods
    
    /// Processes a PDF document
    /// - Parameter pdfDocument: The PDF document to process
    func processPDF(_ pdfDocument: PDFDocument) {
        isLoading = true
        errorMessage = nil
        parsedPayslipItem = nil
        sourcePdfDocument = nil
        showParsingFeedback = false
        
        Task {
            do {
                // Try to parse the PDF
                if let result = try await parsingCoordinator.parsePayslip(pdfDocument: pdfDocument) {
                    
                    // Extract Sendable data BEFORE the MainActor block
                    let payslipID = result.id
                    let payslipMonth = result.month
                    let payslipYear = result.year
                    let payslipCredits = result.credits
                    let payslipDebits = result.debits
                    let payslipDsop = result.dsop
                    let payslipTax = result.tax
                    let payslipName = result.name
                    let payslipAccountNumber = result.accountNumber
                    let payslipPanNumber = result.panNumber
                    let payslipTimestamp = result.timestamp
                    let payslipPdfData = result.pdfData // Data? is Sendable
                    let payslipEarnings = result.earnings // [String: Double] is Sendable
                    let payslipDeductions = result.deductions // [String: Double] is Sendable
                    
                    // Pass only Sendable values into MainActor context
                    await MainActor.run {
                        // Reconstruct the item on the MainActor
                        let newItem = PayslipItem(
                            id: payslipID,
                            timestamp: payslipTimestamp,
                            month: payslipMonth,
                            year: payslipYear,
                            credits: payslipCredits,
                            debits: payslipDebits,
                            dsop: payslipDsop,
                            tax: payslipTax,
                            name: payslipName,
                            accountNumber: payslipAccountNumber,
                            panNumber: payslipPanNumber,
                            pdfData: payslipPdfData
                        )
                        newItem.earnings = payslipEarnings // Assign dictionaries
                        newItem.deductions = payslipDeductions
                        
                        self.parsedPayslipItem = newItem // Store the reconstructed item
                        self.sourcePdfDocument = pdfDocument // Store the source document
                        self.isLoading = false
                        self.showParsingFeedback = true // Trigger feedback view
                    }
                } else {
                    // Handle case where parsing succeeded but returned nil (e.g., not a payslip)
                    await MainActor.run {
                        self.errorMessage = "Document processed, but does not appear to be a valid payslip."
                        self.showError = true
                        self.isLoading = false
                    }
                }
            } catch {
                // Handle errors thrown by parsePayslip
                await MainActor.run {
                    self.errorMessage = "Error parsing payslip: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Creates a new empty payslip for manual entry
    func createEmptyPayslip() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Use parsedPayslipItem to avoid conflict if user navigates back
        let manualEntryItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: calendar.monthSymbols[calendar.component(.month, from: currentDate) - 1],
            year: calendar.component(.year, from: currentDate),
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: "",
            pdfData: nil
        )
        
        self.parsedPayslipItem = manualEntryItem // Set item for manual entry sheet
        self.sourcePdfDocument = nil // No source PDF for manual entry
        self.showManualEntry = true // Use the separate flag for manual entry
        self.showParsingFeedback = false // Ensure feedback flag is false
    }
    
    var abbreviationManagerForFeedback: AbbreviationManager {
        self.abbreviationManager
    }
    
    // Add accessor for parsingCoordinator
    var parsingCoordinatorForFeedback: PDFParsingCoordinator {
        self.parsingCoordinator
    }
} 