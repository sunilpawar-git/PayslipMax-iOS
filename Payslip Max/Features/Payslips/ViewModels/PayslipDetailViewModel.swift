import SwiftUI
import SwiftData
import Foundation
import Combine

@MainActor
final class PayslipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published private(set) var decryptedPayslip: (any PayslipItemProtocol)?
    @Published private(set) var netAmount: Double = 0.0
    @Published private(set) var formattedNetAmount: String = ""
    @Published var showShareSheet = false
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private(set) var payslip: any PayslipItemProtocol
    let dataService: DataServiceProtocol
    private let pdfFilename: String
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipDetailViewModel with the specified payslip and security service.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    init(payslip: any PayslipItemProtocol, securityService: SecurityServiceProtocol? = nil, dataService: DataServiceProtocol? = nil) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        
        // Convert to PayslipItem if needed
        if let item = payslip as? PayslipItem {
            self.decryptedPayslip = item
        } else {
            // Create a new PayslipItem with the same data
            self.decryptedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: payslip.credits,
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: (payslip as? PayslipItem)?.pdfData
            )
        }
        
        // Set the PDF filename
        self.pdfFilename = "payslip_\(payslip.month.lowercased())_\(payslip.year).pdf"
        
        calculateNetAmount()
    }
    
    // MARK: - Public Methods
    
    /// Loads and decrypts sensitive data in the payslip.
    ///
    /// This method decrypts the sensitive data in the payslip and updates the decryptedPayslip property.
    func loadDecryptedData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Since PayslipItemProtocol is a protocol, we need to create a copy differently
        // For now, we'll just use the original payslip and decrypt it
        do {
            // We need to handle this differently since we can't just copy a protocol
            // For PayslipItem, we can cast and use it directly
            if let concretePayslip = payslip as? PayslipItem {
                let decrypted = concretePayslip
                try decrypted.decryptSensitiveData()
                
                // Parse and separate name, account number, and PAN number
                parseAndSeparatePersonalInfo(for: decrypted)
                
                self.decryptedPayslip = decrypted
            } else {
                // For other implementations, we'll need to decrypt the original
                try payslip.decryptSensitiveData()
                self.decryptedPayslip = payslip
            }
        } catch {
            self.error = AppError.from(error)
        }
        calculateNetAmount()
    }
    
    /// Parses and separates the name, account number, and PAN number from combined fields.
    ///
    /// - Parameter payslip: The payslip to update.
    private func parseAndSeparatePersonalInfo(for payslip: PayslipItem) {
        // Check if name contains account number and PAN number
        let nameText = payslip.name
        
        // Common patterns in the data
        if nameText.contains("A/C No") || nameText.contains("PAN No") {
            // Extract name (assuming it's the first part before A/C No)
            if let nameRange = nameText.range(of: "A/C No", options: .caseInsensitive) {
                let name = nameText[..<nameRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                payslip.name = name
                
                // Extract account number
                let afterName = nameText[nameRange.lowerBound...]
                if let acNoRange = afterName.range(of: "A/C No - ", options: .caseInsensitive) {
                    let afterAcNo = afterName[acNoRange.upperBound...]
                    if let panRange = afterAcNo.range(of: "PAN No", options: .caseInsensitive) {
                        let acNo = afterAcNo[..<panRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                        payslip.accountNumber = acNo
                        
                        // Extract PAN number
                        let afterPanLabel = afterAcNo[panRange.lowerBound...]
                        if let colonRange = afterPanLabel.range(of: ":") {
                            let pan = afterPanLabel[colonRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                            payslip.panNumber = pan
                        }
                    } else {
                        // If no PAN No label, assume the rest is account number
                        payslip.accountNumber = String(afterAcNo).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        // Check if PAN Number field contains name and account number
        let panText = payslip.panNumber
        if panText.contains("Name:") || panText.contains("A/C No") {
            // Extract PAN number (assuming it's at the end)
            if let panRange = panText.range(of: "AR", options: .caseInsensitive) {
                let pan = panText[panRange.lowerBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                payslip.panNumber = pan
            }
        }
        
        // If account number is still empty but contains in name or PAN field, try to extract it
        if payslip.accountNumber.isEmpty {
            if let acNoRange = nameText.range(of: "\\d{2}/\\d{3}/\\d{6}", options: .regularExpression) {
                payslip.accountNumber = nameText[acNoRange].trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let acNoRange = panText.range(of: "\\d{2}/\\d{3}/\\d{6}", options: .regularExpression) {
                payslip.accountNumber = panText[acNoRange].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    /// Calculates and formats the net amount.
    ///
    /// This method calculates the net amount based on the payslip's credits, debits, DSOP, and tax,
    /// and formats it as a currency string.
    private func calculateNetAmount() {
        // Use the protocol's calculateNetAmount method
        netAmount = payslip.calculateNetAmount()
        formattedNetAmount = Formatters.formatCurrency(netAmount)
    }
    
    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double) -> String {
        return Formatters.formatCurrency(value)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        guard let payslip = decryptedPayslip else {
            return "Payslip details not available"
        }
        
        // Use the protocol's formattedDescription method
        return payslip.formattedDescription()
    }
    
    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedPayslip: The corrected payslip data.
    func updatePayslip(_ correctedPayslip: PayslipItem) {
        Task {
            do {
                // Initialize the data service if needed
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Update the payslip
                try await dataService.save(correctedPayslip)
                
                // Update the published payslip
                self.decryptedPayslip = correctedPayslip
                
                print("PayslipDetailViewModel: Updated payslip with corrected data")
            } catch {
                handleError(error)
            }
        }
    }
    
    func getPDFURL() async throws -> URL? {
        guard let payslipItem = payslip as? PayslipItem else { 
            throw AppError.message("Cannot share PDF: Invalid payslip type")
        }
        
        // Check if PDF is already stored
        if let url = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString) {
            print("PDF found at: \(url.path)")
            return url
        }
        
        // If not stored, get the PDF data and save it
        guard let pdfData = payslipItem.pdfData else { 
            throw AppError.message("Cannot share PDF: No PDF data available")
        }
        
        do {
            print("Saving PDF data of size: \(pdfData.count) bytes")
            let url = try PDFManager.shared.savePDF(
                data: pdfData,
                identifier: payslipItem.id.uuidString
            )
            print("PDF saved successfully at: \(url.path)")
            return url
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            throw AppError.message("Failed to save PDF: \(error.localizedDescription)")
        }
    }
    
    /// Manually corrects and updates the payslip data.
    ///
    /// - Parameters:
    ///   - name: The corrected name.
    ///   - accountNumber: The corrected account number.
    ///   - panNumber: The corrected PAN number.
    func correctPayslipData(name: String, accountNumber: String, panNumber: String) {
        guard let payslipItem = decryptedPayslip as? PayslipItem else {
            self.error = AppError.message("Cannot update payslip: Invalid payslip type")
            return
        }
        
        // Update the payslip with corrected data
        payslipItem.name = name
        payslipItem.accountNumber = accountNumber
        payslipItem.panNumber = panNumber
        
        // Save the updated payslip
        updatePayslip(payslipItem)
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
} 