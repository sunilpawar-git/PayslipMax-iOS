import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

@MainActor
final class PayslipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published private(set) var decryptedPayslip: (any PayslipItemProtocol)?
    @Published private(set) var netAmount: Double = 0.0
    @Published private(set) var formattedNetAmount: String = ""
    @Published var showShareSheet = false
    @Published private(set) var extractedData: [String: String] = [:]
    @Published private(set) var editedFields: Set<String> = []
    
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
        
        // Load previously edited fields from UserDefaults
        if let payslipItem = payslip as? PayslipItem,
           let savedFields = UserDefaults.standard.array(forKey: "editedFields_\(payslipItem.id.uuidString)") as? [String] {
            self.editedFields = Set(savedFields)
        }
        
        // Convert to PayslipItem if needed
        if let item = payslip as? PayslipItem {
            self.decryptedPayslip = item
            
            // Extract additional data if available
            if !item.earnings.isEmpty || !item.deductions.isEmpty {
                // Create a dictionary of extracted data from the payslip
                var extractedData: [String: String] = [:]
                
                // Add statement period if available
                if let month = Calendar.current.dateComponents([.month], from: item.timestamp).month {
                    extractedData["statementPeriod"] = String(format: "%02d/%d", month, item.year)
                }
                
                // Add DSOP details if available in the deductions
                if let dsopValue = item.deductions["DSOP"] {
                    extractedData["dsop"] = String(format: "%.0f", dsopValue)
                }
                
                // Add tax details if available in the deductions
                if let taxValue = item.deductions["ITAX"] {
                    extractedData["itax"] = String(format: "%.0f", taxValue)
                }
                
                self.extractedData = extractedData
            }
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
        loadExtractedData()
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
        
        // Remove trailing 'A' from name if present
        if payslip.name.hasSuffix(" A") {
            payslip.name = String(payslip.name.dropLast(2))
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
        // Format without decimal places
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }
        
        return String(format: "%.0f", value)
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
        
        // Track which fields were edited
        if name != payslipItem.name {
            editedFields.insert("name")
        }
        
        if accountNumber != payslipItem.accountNumber {
            editedFields.insert("accountNumber")
        }
        
        if panNumber != payslipItem.panNumber {
            editedFields.insert("panNumber")
        }
        
        // Update the payslip with corrected data
        payslipItem.name = name
        payslipItem.accountNumber = accountNumber
        payslipItem.panNumber = panNumber
        
        // Save the updated payslip
        updatePayslip(payslipItem)
        
        // Save edited fields to UserDefaults
        let payslipId = payslipItem.id.uuidString
        UserDefaults.standard.set(Array(editedFields), forKey: "editedFields_\(payslipId)")
    }
    
    /// Checks if a field was manually edited by the user.
    ///
    /// - Parameter field: The field name to check.
    /// - Returns: True if the field was manually edited, false otherwise.
    func wasFieldManuallyEdited(field: String) -> Bool {
        return editedFields.contains(field)
    }
    
    /// Tracks that a field was manually edited by the user.
    ///
    /// - Parameter field: The field name to track.
    func trackEditedField(_ field: String) {
        editedFields.insert(field)
        
        // Save to UserDefaults if we have a PayslipItem with an ID
        if let payslipItem = decryptedPayslip as? PayslipItem {
            let payslipId = payslipItem.id.uuidString
            UserDefaults.standard.set(Array(editedFields), forKey: "editedFields_\(payslipId)")
        }
    }
    
    /// Loads extracted data from the payslip.
    private func loadExtractedData() {
        guard let payslipItem = payslip as? PayslipItem else { return }
        
        // Create a dictionary of extracted data from the payslip
        var extractedData: [String: String] = [:]
        
        // Add statement period if available
        if let month = Calendar.current.dateComponents([.month], from: payslipItem.timestamp).month {
            extractedData["statementPeriod"] = String(format: "%02d/%d", month, payslipItem.year)
        }
        
        // Add earnings breakdown
        for (key, value) in payslipItem.earnings {
            if value > 0 {
                extractedData[key.lowercased().replacingOccurrences(of: "-", with: "")] = String(format: "%.0f", value)
            }
        }
        
        // Add deductions breakdown
        for (key, value) in payslipItem.deductions {
            if value > 0 {
                extractedData[key.lowercased()] = String(format: "%.0f", value)
            }
        }
        
        // Try to extract more data from PDF if available
        if let pdfData = payslipItem.pdfData {
            loadExtractedData(from: pdfData)
        } else {
            self.extractedData = extractedData
        }
    }
    
    /// Loads extracted data from PDF data.
    ///
    /// - Parameter pdfData: The PDF data to extract from.
    private func loadExtractedData(from pdfData: Data) {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("Failed to create PDF document from data")
            return
        }
        
        // Extract text from the PDF
        var extractedText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                extractedText += pageText
            }
        }
        
        // Use the PayslipPatternManager to extract data
        let extractedData = PayslipPatternManager.extractData(from: extractedText)
        
        // Extract tabular data (earnings and deductions)
        let (earnings, deductions) = PayslipPatternManager.extractTabularData(from: extractedText)
        
        // Create a mutable copy of the extracted data
        var updatedExtractedData = extractedData
        
        // Add earnings breakdown
        for (key, value) in earnings {
            if value > 0 {
                updatedExtractedData[key.lowercased().replacingOccurrences(of: "-", with: "")] = String(format: "%.0f", value)
            }
        }
        
        // Add deductions breakdown
        for (key, value) in deductions {
            if value > 0 {
                updatedExtractedData[key.lowercased()] = String(format: "%.0f", value)
            }
        }
        
        // Extract additional data for Income Tax Details
        // Try to find the Income Tax Details section
        if let taxSectionRange = extractedText.range(of: "INCOME TAX DETAILS", options: .caseInsensitive) {
            let taxSectionText = String(extractedText[taxSectionRange.lowerBound...])
            
            // Extract Assessment Year
            if let match = taxSectionText.range(of: "Assessment Year ([0-9\\-\\.]+)", options: .regularExpression) {
                let matchText = taxSectionText[match]
                if let yearRange = matchText.range(of: "[0-9\\-\\.]+", options: .regularExpression) {
                    updatedExtractedData["assessmentYear"] = String(matchText[yearRange])
                }
            }
            
            // Extract Gross Salary
            if let match = taxSectionText.range(of: "Gross Salary[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = taxSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["grossSalary"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract Standard Deduction
            if let match = taxSectionText.range(of: "Standard Deduction[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = taxSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["standardDeduction"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract Net Taxable Income
            if let match = taxSectionText.range(of: "Net Taxable Income[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = taxSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["netTaxableIncome"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
        }
        
        // Extract DSOP Fund Details
        if let dsopSectionRange = extractedText.range(of: "DSOP FUND", options: .caseInsensitive) {
            let dsopSectionText = String(extractedText[dsopSectionRange.lowerBound...])
            
            // Extract Opening Balance
            if let match = dsopSectionText.range(of: "Opening Balance[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = dsopSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["dsopOpeningBalance"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract Subscription
            if let match = dsopSectionText.range(of: "Subscription[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = dsopSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["dsopSubscription"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract Misc Adj
            if let match = dsopSectionText.range(of: "Misc Adj[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = dsopSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["dsopMiscAdj"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract Closing Balance
            if let match = dsopSectionText.range(of: "Closing Balance[^0-9]*([0-9,]+)", options: .regularExpression) {
                let matchText = dsopSectionText[match]
                if let valueRange = matchText.range(of: "[0-9,]+", options: .regularExpression) {
                    updatedExtractedData["dsopClosingBalance"] = String(matchText[valueRange]).replacingOccurrences(of: ",", with: "")
                }
            }
        }
        
        // Extract Contact Details
        if let contactSectionRange = extractedText.range(of: "YOUR CONTACT POINTS", options: .caseInsensitive) {
            let contactSectionText = String(extractedText[contactSectionRange.lowerBound...])
            
            // Extract SAO(LW)
            if let match = contactSectionText.range(of: "SAO\\(LW\\)[^\\(]*\\([0-9\\-]+\\)", options: .regularExpression) {
                updatedExtractedData["contactSAOLW"] = String(contactSectionText[match])
            }
            
            // Extract AAO(LW)
            if let match = contactSectionText.range(of: "AAO\\(LW\\)[^\\(]*\\([0-9\\-]+\\)", options: .regularExpression) {
                updatedExtractedData["contactAAOLW"] = String(contactSectionText[match])
            }
            
            // Extract Email addresses
            if let match = contactSectionText.range(of: "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", options: .regularExpression) {
                let email = String(contactSectionText[match])
                if email.contains("tada") {
                    updatedExtractedData["contactEmailTADA"] = email
                } else if email.contains("ledger") {
                    updatedExtractedData["contactEmailLedger"] = email
                } else if email.contains("rankpay") {
                    updatedExtractedData["contactEmailRankPay"] = email
                } else if email.contains("generalquery") {
                    updatedExtractedData["contactEmailGeneral"] = email
                }
            }
        }
        
        // Update the payslip item with the extracted data if needed
        if let payslipItem = decryptedPayslip as? PayslipItem {
            // Update earnings if empty
            if payslipItem.earnings.isEmpty && !earnings.isEmpty {
                payslipItem.earnings = earnings
            }
            
            // Update deductions if empty
            if payslipItem.deductions.isEmpty && !deductions.isEmpty {
                payslipItem.deductions = deductions
            }
            
            // Update the payslip
            Task {
                do {
                    // Initialize the data service if needed
                    if !dataService.isInitialized {
                        try await dataService.initialize()
                    }
                    
                    // Update the payslip
                    try await dataService.save(payslipItem)
                    
                    print("PayslipDetailViewModel: Updated payslip with extracted data")
                } catch {
                    handleError(error)
                }
            }
        }
        
        // Update the published extracted data
        self.extractedData = updatedExtractedData
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
    
    /// Updates a value in the extractedData dictionary
    ///
    /// - Parameters:
    ///   - key: The key to update
    ///   - value: The new value
    func updateExtractedData(key: String, value: String) {
        var updatedData = self.extractedData
        updatedData[key] = value
        self.extractedData = updatedData
    }
} 