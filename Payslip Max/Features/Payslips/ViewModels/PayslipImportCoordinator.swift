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
                // Create a temporary copy to avoid capturing a reference to result
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
                let payslipPdfData = result.pdfData
                let payslipEarnings = result.earnings
                let payslipDeductions = result.deductions
                
                await MainActor.run {
                    self.payslip = PayslipItem(
                        id: payslipID,
                        month: payslipMonth,
                        year: payslipYear,
                        credits: payslipCredits,
                        debits: payslipDebits,
                        dsop: payslipDsop,
                        tax: payslipTax,
                        name: payslipName,
                        accountNumber: payslipAccountNumber,
                        panNumber: payslipPanNumber,
                        timestamp: payslipTimestamp,
                        pdfData: payslipPdfData
                    )
                    // Copy over the dictionaries
                    self.payslip?.earnings = payslipEarnings
                    self.payslip?.deductions = payslipDeductions
                    
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