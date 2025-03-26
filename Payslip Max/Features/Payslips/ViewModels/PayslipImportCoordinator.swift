import SwiftUI
import PDFKit

class PayslipImportCoordinator: ObservableObject {
    // MARK: - Properties
    
    @Published var payslip: PayslipItem?
    @Published var isLoading = false
    @Published var showManualEntry = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let parsingCoordinator: PDFParsingCoordinator
    
    // MARK: - Initialization
    
    init(parsingCoordinator: PDFParsingCoordinator) {
        self.parsingCoordinator = parsingCoordinator
    }
    
    // MARK: - Methods
    
    /// Processes a PDF document
    /// - Parameter pdfDocument: The PDF document to process
    func processPDF(_ pdfDocument: PDFDocument) {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Try to parse the PDF
            if let result = parsingCoordinator.parsePayslip(pdfDocument: pdfDocument) {
                await MainActor.run {
                    self.payslip = result
                    self.isLoading = false
                    self.showManualEntry = true
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Could not parse the payslip. Please try again or enter details manually."
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
        
        payslip = PayslipItem(
            month: calendar.monthSymbols[calendar.component(.month, from: currentDate) - 1],
            year: calendar.component(.year, from: currentDate),
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: "",
            timestamp: Date(),
            pdfData: nil
        )
        
        showManualEntry = true
    }
} 