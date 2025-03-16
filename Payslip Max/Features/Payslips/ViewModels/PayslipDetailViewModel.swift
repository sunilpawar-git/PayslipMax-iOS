import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

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
    @Published var showDiagnostics = false
    @Published var unknownComponents: [String: (amount: Double, category: String?)] = [:]
    
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
                if let dsopValue = item.deductions["DSOP"] ?? item.deductions["DSOP Fund"] {
                    extractedData["dsop"] = String(format: "%.0f", dsopValue)
                    extractedData["dsopSubscription"] = String(format: "%.0f", dsopValue)
                }
                
                // Add tax details if available in the deductions
                if let taxValue = item.deductions["ITAX"] ?? item.deductions["Income Tax"] {
                    extractedData["itax"] = String(format: "%.0f", taxValue)
                    extractedData["incomeTaxDeducted"] = String(format: "%.0f", taxValue)
                }
                
                // Check if we have PDF data and try to extract more details using the enhanced parser
                if let pdfData = item.pdfData, let pdfDocument = PDFDocument(data: pdfData) {
                    do {
                        let enhancedParser = EnhancedPDFParser()
                        let parsedData = try enhancedParser.parseDocument(pdfDocument)
                        
                        // Merge the additional extracted data
                        let additionalData = PayslipParsingUtility.extractAdditionalData(from: parsedData)
                        for (key, value) in additionalData {
                            extractedData[key] = value
                        }
                    } catch {
                        print("Error extracting additional data: \(error)")
                    }
                }
                
                self.extractedData = extractedData
            }
            
            // Decrypt sensitive data if needed
            if let payslipItem = payslip as? PayslipItem {
                do {
                    try payslipItem.decryptSensitiveData()
                } catch {
                    print("Error decrypting sensitive data: \(error)")
                }
            }
        } else {
            // Handle the case where payslip is not a PayslipItem
            self.decryptedPayslip = nil
            self.isLoading = false
            self.error = AppError.message("Unsupported payslip type")
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
                
                // Remove any HRA entries from earnings
                if let payslipItem = self.decryptedPayslip as? PayslipItem {
                    payslipItem.earnings.removeValue(forKey: "HRA")
                    print("Explicitly removed HRA from earnings")
                }
                
                // Parse and separate name, account number, and PAN number
                parseAndSeparatePersonalInfo(for: decrypted)
                
                self.decryptedPayslip = decrypted
            } else {
                // For other implementations, we'll need to decrypt the original
                try payslip.decryptSensitiveData()
                self.decryptedPayslip = payslip
            }
            
            // Remove any HRA entries from earnings
            if let payslipItem = self.decryptedPayslip as? PayslipItem {
                payslipItem.earnings.removeValue(forKey: "HRA")
                print("Explicitly removed HRA from earnings")
            }
            
            // Ensure contact details are populated
            populateContactDetails()
        } catch {
            self.error = AppError.from(error)
        }
        calculateNetAmount()
    }
    
    /// Populates contact details to ensure they're always displayed
    private func populateContactDetails() {
        // Check if contact details are already populated
        let hasContactDetails = extractedData.keys.contains { $0.hasPrefix("contact") }
        
        // If no contact details are found, try to extract them from the PDF
        if !hasContactDetails {
            if let payslipItem = payslip as? PayslipItem, let pdfData = payslipItem.pdfData, let pdfDocument = PDFDocument(data: pdfData) {
                do {
                    // Try to extract contact details using the enhanced parser
                    let enhancedParser = EnhancedPDFParser()
                    let parsedData = try enhancedParser.parseDocument(pdfDocument)
                    
                    // Add contact details to extractedData
                    for (key, value) in parsedData.contactDetails {
                        extractedData["contact\(key.capitalized)"] = value
                    }
                    
                    print("Extracted contact details: \(parsedData.contactDetails)")
                    
                    // If still no contact details, try direct extraction from PDF text
                    if !extractedData.keys.contains(where: { $0.hasPrefix("contact") }) {
                        extractContactDetailsDirectly(from: pdfDocument)
                    }
                    
                    // If still no contact details, add sample data
                    if !extractedData.keys.contains(where: { $0.hasPrefix("contact") }) {
                        addSampleContactData()
                    }
                } catch {
                    print("Error extracting contact details: \(error)")
                    // Try direct extraction as fallback
                    extractContactDetailsDirectly(from: pdfDocument)
                    
                    // If still no contact details, add sample data
                    if !extractedData.keys.contains(where: { $0.hasPrefix("contact") }) {
                        addSampleContactData()
                    }
                }
            } else {
                // No PDF data available, add sample data
                addSampleContactData()
            }
        }
    }
    
    /// Extracts contact details directly from PDF text
    private func extractContactDetailsDirectly(from pdfDocument: PDFDocument) {
        // Extract all text from the PDF
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        // Look for contact section
        let contactSectionPatterns = [
            "CONTACT US",
            "CONTACT DETAILS",
            "FOR QUERIES",
            "HELP DESK",
            "CONTACT INFORMATION"
        ]
        
        var contactSectionText = fullText
        for pattern in contactSectionPatterns {
            if let range = fullText.range(of: pattern, options: .caseInsensitive) {
                // Extract text from the contact section to the end
                contactSectionText = String(fullText[range.lowerBound...])
                break
            }
        }
        
        // Extract phone numbers with roles
        let rolePhonePattern = "(SAO\\s*\\(?LW\\)?|AAO\\s*\\(?LW\\)?|SAO\\s*\\(?TW\\)?|AAO\\s*\\(?TW\\)?|PRO\\s*CIVIL|PRO\\s*ARMY|HELP\\s*DESK)[^0-9]*([0-9][0-9\\-\\s]+)"
        if let regex = try? NSRegularExpression(pattern: rolePhonePattern, options: .caseInsensitive) {
            let nsString = contactSectionText as NSString
            let matches = regex.matches(in: contactSectionText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let roleRange = match.range(at: 1)
                    let phoneRange = match.range(at: 2)
                    
                    let role = nsString.substring(with: roleRange)
                    let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Map the role to the appropriate key
                    let roleUpper = role.uppercased().replacingOccurrences(of: " ", with: "")
                    let key: String
                    switch roleUpper {
                    case "SAO(LW)", "SAOLW": key = "SAOLW"
                    case "AAO(LW)", "AAOLW": key = "AAOLW"
                    case "SAO(TW)", "SAOTW": key = "SAOTW"
                    case "AAO(TW)", "AAOTW": key = "AAOTW"
                    case "PROCIVIL": key = "ProCivil"
                    case "PROARMY": key = "ProArmy"
                    case "HELPDESK": key = "HelpDesk"
                    default: key = roleUpper
                    }
                    
                    extractedData["contact\(key)"] = "\(role): \(phone)"
                }
            }
        }
        
        // Extract email addresses
        let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        if let regex = try? NSRegularExpression(pattern: emailPattern, options: []) {
            let nsString = contactSectionText as NSString
            let matches = regex.matches(in: contactSectionText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for (index, match) in matches.enumerated() {
                let emailRange = match.range(at: 0)
                let email = nsString.substring(with: emailRange)
                
                // Categorize emails if possible
                if email.contains("tada") {
                    extractedData["contactEmailTADA"] = email
                } else if email.contains("ledger") {
                    extractedData["contactEmailLedger"] = email
                } else if email.contains("rankpay") {
                    extractedData["contactEmailRankPay"] = email
                } else if email.contains("general") {
                    extractedData["contactEmailGeneral"] = email
                } else {
                    extractedData["contactEmail\(index + 1)"] = email
                }
            }
        }
        
        // Extract website
        let websitePattern = "(?:https?://)?(?:www\\.)?[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        if let regex = try? NSRegularExpression(pattern: websitePattern, options: []) {
            let nsString = contactSectionText as NSString
            let matches = regex.matches(in: contactSectionText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let websiteRange = match.range(at: 0)
                let website = nsString.substring(with: websiteRange)
                extractedData["contactWebsite"] = website
            }
        }
        
        print("Direct extraction found contact details: \(extractedData.filter { $0.key.hasPrefix("contact") })")
    }
    
    /// Adds sample contact data when real data is not available
    private func addSampleContactData() {
        print("Adding sample contact data")
        extractedData["contactSAOLW"] = "SAO(LW) Office: +91-123-4567890"
        extractedData["contactAAOLW"] = "AAO(LW) Office: +91-123-4567891"
        extractedData["contactWebsite"] = "https://pcda.gov.in"
        extractedData["contactEmailGeneral"] = "contact@pcda.gov.in"
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
                
                // Post a notification that a payslip was updated
                NotificationCenter.default.post(name: .payslipUpdated, object: nil)
                
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
        
        // Explicitly remove HRA from earnings
        payslipItem.earnings.removeValue(forKey: "HRA")
        print("loadExtractedData: Removed HRA from earnings")
        
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
        
        #if canImport(Vision)
        if #available(iOS 16.0, *) {
            // Use Vision-based extraction for better accuracy
            extractDataUsingVision(from: pdfData)
            return
        }
        #endif
        
        // Fall back to traditional text extraction for older iOS versions
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
        
        // Get standard components and thresholds
        let standardEarningsComponents = PayslipPatternManager.standardEarningsComponents
        let standardDeductionsComponents = PayslipPatternManager.standardDeductionsComponents
        let minimumEarningsAmount = PayslipPatternManager.minimumEarningsAmount
        let minimumDeductionsAmount = PayslipPatternManager.minimumDeductionsAmount
        
        // Add earnings breakdown
        for (key, value) in earnings {
            if value >= minimumEarningsAmount {
                updatedExtractedData[key.lowercased().replacingOccurrences(of: "-", with: "")] = String(format: "%.0f", value)
            }
        }
        
        // Add deductions breakdown
        for (key, value) in deductions {
            if value >= minimumDeductionsAmount {
                updatedExtractedData[key.lowercased()] = String(format: "%.0f", value)
            }
        }
        
        // Update the payslip with the correct categorization
        if let payslipItem = payslip as? PayslipItem {
            // Clear existing earnings and deductions to avoid duplicates
            payslipItem.earnings = [:]
            payslipItem.deductions = [:]
            
            // Add earnings
            for (key, value) in earnings {
                if value >= minimumEarningsAmount && !PayslipPatternManager.blacklistedTerms.contains(key) {
                    payslipItem.earnings[key] = value
                    print("PayslipDetailViewModel: Added earnings \(key) with amount \(value)")
                }
            }
            
            // Add deductions
            for (key, value) in deductions {
                if value >= minimumDeductionsAmount && !PayslipPatternManager.blacklistedTerms.contains(key) {
                    payslipItem.deductions[key] = value
                    print("PayslipDetailViewModel: Added deduction \(key) with amount \(value)")
                }
            }
            
            // Final validation: ensure standard components are in the correct category
            for component in standardEarningsComponents {
                if component != "HRA" && payslipItem.deductions[component] != nil && payslipItem.deductions[component]! > 1 {
                    // Move from deductions to earnings
                    payslipItem.earnings[component] = payslipItem.deductions[component]!
                    payslipItem.deductions.removeValue(forKey: component)
                    print("PayslipDetailViewModel: Moved standard earnings component \(component) from deductions to earnings")
                }
            }
            
            for component in standardDeductionsComponents {
                if let value = payslipItem.earnings[component], value >= minimumDeductionsAmount {
                    // Move from earnings to deductions
                    payslipItem.deductions[component] = value
                    payslipItem.earnings.removeValue(forKey: component)
                    print("PayslipDetailViewModel: Moved standard deductions component \(component) from earnings to deductions")
                }
            }
            
            // Extract and set credits, debits, DSOP, and tax from the PDF
            // Look for "Gross Pay", "Total Deductions", "DSOP", and "ITAX" or "Income Tax"
            let grossPayPattern = "(?:Gross Pay|कुल आय|Total Earnings|TOTAL EARNINGS|कुल आय)[^0-9]*([0-9,.]+)"
            let totalDeductionsPattern = "(?:Total Deductions|कुल कटौती|TOTAL DEDUCTIONS|कुल कटौती)[^0-9]*([0-9,.]+)"
            let dsopPattern = "(?:DSOP|DSOP Fund|Provident Fund)[^0-9]*([0-9,.]+)"
            let taxPattern = "(?:ITAX|Income Tax|I\\.Tax)[^0-9]*([0-9,.]+)"
            
            // Try to extract Gross Pay (Credits)
            if let grossPayMatch = extractedText.range(of: grossPayPattern, options: .regularExpression),
               let grossPayValueMatch = extractedText[grossPayMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                let grossPayValue = extractedText[grossPayMatch][grossPayValueMatch]
                    .replacingOccurrences(of: ",", with: "")
                if let credits = Double(grossPayValue), credits > 1000 {  // Add minimum threshold
                    payslipItem.credits = credits
                    print("PayslipDetailViewModel: Set credits to \(credits)")
                }
            }
            
            // Try to extract Total Deductions (Debits)
            if let totalDeductionsMatch = extractedText.range(of: totalDeductionsPattern, options: .regularExpression),
               let totalDeductionsValueMatch = extractedText[totalDeductionsMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                let totalDeductionsValue = extractedText[totalDeductionsMatch][totalDeductionsValueMatch]
                    .replacingOccurrences(of: ",", with: "")
                if let debits = Double(totalDeductionsValue), debits > 1000 {  // Add minimum threshold
                    payslipItem.debits = debits
                    print("PayslipDetailViewModel: Set debits to \(debits)")
                }
            }
            
            // Try to extract DSOP
            var foundDSOP = false
            // First look for DSOP in deductions
            for (key, value) in deductions {
                if key == "DSOP" && value >= 1000 {  // Add minimum threshold
                    payslipItem.dsop = value
                    foundDSOP = true
                    print("PayslipDetailViewModel: Set DSOP to \(value) from deductions")
                    break
                }
            }
            
            // If not found in deductions, try regex pattern
            if !foundDSOP {
                if let dsopMatch = extractedText.range(of: dsopPattern, options: .regularExpression),
                   let dsopValueMatch = extractedText[dsopMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let dsopValue = extractedText[dsopMatch][dsopValueMatch]
                        .replacingOccurrences(of: ",", with: "")
                    if let dsop = Double(dsopValue), dsop >= 1000 {  // Add minimum threshold
                        payslipItem.dsop = dsop
                        print("PayslipDetailViewModel: Set DSOP to \(dsop) from regex")
                        foundDSOP = true
                    }
                }
            }
            
            // If still not found, look for specific DSOP patterns in the text
            if !foundDSOP {
                let dsopSpecificPattern = "DSOP\\s*(?:Fund|Subscription)?\\s*[^0-9]*([0-9,.]+)"
                if let dsopMatch = extractedText.range(of: dsopSpecificPattern, options: .regularExpression),
                   let dsopValueMatch = extractedText[dsopMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let dsopValue = extractedText[dsopMatch][dsopValueMatch]
                        .replacingOccurrences(of: ",", with: "")
                    if let dsop = Double(dsopValue), dsop >= 1000 {  // Add minimum threshold
                        payslipItem.dsop = dsop
                        print("PayslipDetailViewModel: Set DSOP to \(dsop) from specific pattern")
                    }
                }
            }
            
            // Try to extract Income Tax
            var foundTax = false
            // First look for ITAX in deductions
            for (key, value) in deductions {
                if (key == "ITAX" || key == "Income Tax") && value > 1000 {  // Add minimum threshold
                    payslipItem.tax = value
                    foundTax = true
                    print("PayslipDetailViewModel: Set tax to \(value) from deductions")
                    break
                }
            }
            
            // If not found in deductions, try regex pattern
            if !foundTax {
                if let taxMatch = extractedText.range(of: taxPattern, options: .regularExpression),
                   let taxValueMatch = extractedText[taxMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let taxValue = extractedText[taxMatch][taxValueMatch]
                        .replacingOccurrences(of: ",", with: "")
                    if let tax = Double(taxValue), tax > 1000 {  // Add minimum threshold
                        payslipItem.tax = tax
                        print("PayslipDetailViewModel: Set tax to \(tax) from regex")
                    }
                }
            }
            
            // Validate that credits and debits are not the same value (which would result in zero net remittance)
            if payslipItem.credits == payslipItem.debits && payslipItem.credits > 0 {
                print("PayslipDetailViewModel: Credits and debits are the same value, attempting to fix...")
                
                // Look for a different pattern for credits
                let alternativeCreditsPattern = "(?:Gross\\s*Pay|Total\\s*Earnings|कुल\\s*आय)[^0-9]*([0-9,.]+)"
                if let creditsMatch = extractedText.range(of: alternativeCreditsPattern, options: .regularExpression),
                   let creditsValueMatch = extractedText[creditsMatch].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let creditsValue = extractedText[creditsMatch][creditsValueMatch]
                        .replacingOccurrences(of: ",", with: "")
                    if let credits = Double(creditsValue), credits > 1000 && credits != payslipItem.debits {
                        payslipItem.credits = credits
                        print("PayslipDetailViewModel: Fixed credits to \(credits) using alternative pattern")
                    }
                }
                
                // If still the same, try to calculate credits from earnings
                if payslipItem.credits == payslipItem.debits {
                    let totalEarnings = payslipItem.earnings.values.reduce(0, +)
                    if totalEarnings > 1000 && totalEarnings != payslipItem.debits {
                        payslipItem.credits = totalEarnings
                        print("PayslipDetailViewModel: Fixed credits to \(totalEarnings) using earnings sum")
                    }
                }
            }
            
            // Save the updated payslip
            Task {
                do {
                    // Ensure HRA is removed from earnings
                    payslipItem.earnings.removeValue(forKey: "HRA")
                    print("Vision: Explicitly removed HRA from earnings")
                    
                    if !dataService.isInitialized {
                        try await dataService.initialize()
                    }
                    try await dataService.save(payslipItem)
                    print("PayslipDetailViewModel: Updated payslip with extracted data")
                } catch {
                    handleError(error)
                }
            }
        }
        
        // Update the published extracted data
        self.extractedData = updatedExtractedData
        
        // After processing the extracted data, identify unknown components
        identifyUnknownComponents()
    }
    
    /// Identifies unknown components in the payslip
    private func identifyUnknownComponents() {
        guard let payslipItem = payslip as? PayslipItem else { return }
        
        // Clear previous unknown components
        unknownComponents = [:]
        
        // Check earnings for unknown components
        for (code, amount) in payslipItem.earnings {
            if !PayslipPatternManager.standardEarningsComponents.contains(code) &&
               !PayslipPatternManager.standardDeductionsComponents.contains(code) {
                // Check if user has previously categorized this
                if let savedCategory = UserDefaults.standard.string(forKey: "userCategory_\(code)") {
                    unknownComponents[code] = (amount, savedCategory)
                } else {
                    unknownComponents[code] = (amount, "earnings")
                }
            }
        }
        
        // Check deductions for unknown components
        for (code, amount) in payslipItem.deductions {
            if !PayslipPatternManager.standardEarningsComponents.contains(code) &&
               !PayslipPatternManager.standardDeductionsComponents.contains(code) {
                // Check if user has previously categorized this
                if let savedCategory = UserDefaults.standard.string(forKey: "userCategory_\(code)") {
                    unknownComponents[code] = (amount, savedCategory)
                } else {
                    unknownComponents[code] = (amount, "deductions")
                }
            }
        }
    }
    
    /// Handles user categorization of an unknown component
    ///
    /// - Parameters:
    ///   - code: The component code
    ///   - category: The category assigned by the user ("earnings" or "deductions")
    func userCategorizedComponent(code: String, asCategory category: String) {
        guard let payslipItem = payslip as? PayslipItem else { return }
        
        // Update the current payslip
        if category == "earnings" {
            if let amount = payslipItem.deductions[code] {
                payslipItem.earnings[code] = amount
                payslipItem.deductions.removeValue(forKey: code)
            }
        } else if category == "deductions" {
            if let amount = payslipItem.earnings[code] {
                payslipItem.deductions[code] = amount
                payslipItem.earnings.removeValue(forKey: code)
            }
        }
        
        // Save the user's preference for future payslips
        UserDefaults.standard.set(category, forKey: "userCategory_\(code)")
        
        // Update the learning system
        PayslipLearningSystem.shared.learnUserCategorization(code: code, category: category)
        
        // Update the unknown components list
        unknownComponents[code] = (unknownComponents[code]?.amount ?? 0, category)
        
        // Save the payslip
        savePayslip()
    }
    
    /// Saves the current payslip
    private func savePayslip() {
        guard let payslipItem = payslip as? PayslipItem else { return }
        
        Task {
            do {
                try await dataService.save(payslipItem)
            } catch {
                print("Error saving payslip: \(error)")
            }
        }
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

#if canImport(Vision)
extension PayslipDetailViewModel {
    /// Extracts data from PDF using Vision framework for better table recognition
    /// - Parameter pdfData: The PDF data to process
    func extractDataUsingVision(from pdfData: Data) {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("Failed to create PDF document from data")
            return
        }
        
        // Process all pages of the PDF
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                print("Failed to get page \(pageIndex) from PDF")
                continue
            }
            
            // Convert PDF page to image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: pageRect.size))
                
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            // Create a text recognition request
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                guard error == nil else {
                    print("Text recognition error: \(error!.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                // Process the recognized text
                var recognizedText: [String] = []
                var tableData: [(String, CGRect)] = []
                
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        recognizedText.append(topCandidate.string)
                        
                        // Store the text and its bounding box for table analysis
                        let boundingBox = observation.boundingBox
                        tableData.append((topCandidate.string, boundingBox))
                    }
                }
                
                // Process the table data to extract earnings and deductions
                self.processTableData(tableData, pageIndex: pageIndex)
            }
            
            // Configure the text recognition request
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]
            
            // Create a request handler and perform the request
            let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error.localizedDescription)")
            }
        }
    }
    
    /// Process table data extracted using Vision
    /// - Parameters:
    ///   - tableData: Array of text and bounding boxes
    ///   - pageIndex: The index of the page being processed
    private func processTableData(_ tableData: [(String, CGRect)], pageIndex: Int) {
        // Get the standard components and blacklist from PayslipPatternManager
        let standardEarningsComponents = PayslipPatternManager.standardEarningsComponents
        let standardDeductionsComponents = PayslipPatternManager.standardDeductionsComponents
        let blacklistedTerms = PayslipPatternManager.blacklistedTerms
        let minimumEarningsAmount = PayslipPatternManager.minimumEarningsAmount
        let minimumDeductionsAmount = PayslipPatternManager.minimumDeductionsAmount
        
        // Sort table data by Y position (top to bottom)
        let sortedByRow = tableData.sorted { $0.1.midY > $1.1.midY }
        
        // Group items by row
        var rows: [[String]] = []
        var currentRowY: CGFloat = -1
        var currentRow: [String] = []
        
        for (text, rect) in sortedByRow {
            // If this is a new row
            if abs(rect.midY - currentRowY) > 0.02 {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [text]
                currentRowY = rect.midY
            } else {
                currentRow.append(text)
            }
        }
        
        // Add the last row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        // Process rows to find earnings and deductions
        var inEarningsSection = false
        var inDeductionsSection = false
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Variables to capture financial summary
        var grossPay: Double?
        var totalDeductions: Double?
        var dsopValue: Double?
        var taxValue: Double?
        
        for row in rows {
            let rowText = row.joined(separator: " ")
            
            // Detect section headers
            if rowText.contains("EARNINGS") || rowText.contains("PAY AND ALLOWANCES") {
                inEarningsSection = true
                inDeductionsSection = false
                print("Vision: Found EARNINGS section on page \(pageIndex)")
                continue
            } else if rowText.contains("DEDUCTIONS") || rowText.contains("RECOVERIES") {
                inEarningsSection = false
                inDeductionsSection = true
                print("Vision: Found DEDUCTIONS section on page \(pageIndex)")
                continue
            }
            
            // Look for financial summary data
            if rowText.contains("Gross Pay") || rowText.contains("कुल आय") || rowText.contains("Total Earnings") {
                // Try to extract the gross pay amount
                let pattern = "([0-9,.]+)"
                if let match = rowText.range(of: pattern, options: .regularExpression) {
                    let amountStr = rowText[match].replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountStr) {
                        grossPay = amount
                        print("Vision: Found Gross Pay: \(amount)")
                    }
                }
            } else if rowText.contains("Total Deductions") || rowText.contains("कुल कटौती") {
                // Try to extract the total deductions amount
                let pattern = "([0-9,.]+)"
                if let match = rowText.range(of: pattern, options: .regularExpression) {
                    let amountStr = rowText[match].replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountStr) {
                        totalDeductions = amount
                        print("Vision: Found Total Deductions: \(amount)")
                    }
                }
            } else if rowText.contains("DSOP") {
                // Try to extract the DSOP amount
                let pattern = "([0-9,.]+)"
                if let match = rowText.range(of: pattern, options: .regularExpression) {
                    let amountStr = rowText[match].replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountStr) {
                        dsopValue = amount
                        print("Vision: Found DSOP: \(amount)")
                    }
                }
            } else if rowText.contains("ITAX") || rowText.contains("Income Tax") {
                // Try to extract the tax amount
                let pattern = "([0-9,.]+)"
                if let match = rowText.range(of: pattern, options: .regularExpression) {
                    let amountStr = rowText[match].replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountStr) {
                        taxValue = amount
                        print("Vision: Found Income Tax: \(amount)")
                    }
                }
            }
            
            // Process row data
            if row.count >= 2 {
                // Try to identify code and amount in the row
                var code: String?
                var amount: Double?
                
                // Check if the last element is a number (amount)
                if let lastElement = row.last, let parsedAmount = Double(lastElement.replacingOccurrences(of: ",", with: "")) {
                    amount = parsedAmount
                    
                    // First element is likely the code
                    if let firstElement = row.first {
                        // Clean up the code - remove any non-alphanumeric characters except hyphen
                        let cleanedCode = firstElement.replacingOccurrences(of: "[^A-Z0-9\\-]", with: "", options: .regularExpression)
                        code = cleanedCode
                    }
                } else {
                    // Try to find a pattern like "CODE 12,345" in the row text
                    let codeAmountPattern = "([A-Z][A-Z\\-]+)\\s+([0-9,.]+)"
                    if let match = rowText.range(of: codeAmountPattern, options: .regularExpression) {
                        let matchedText = String(rowText[match])
                        let components = matchedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        
                        if components.count >= 2 {
                            code = components[0]
                            if let parsedAmount = Double(components[1].replacingOccurrences(of: ",", with: "")) {
                                amount = parsedAmount
                            }
                        }
                    }
                }
                
                // If we found both code and amount
                if let code = code, let amount = amount {
                    // Skip blacklisted terms
                    if blacklistedTerms.contains(code) {
                        print("Vision: Skipping blacklisted term \(code)")
                        continue
                    }
                    
                    // Skip HRA explicitly
                    if code == "HRA" {
                        print("Vision: Skipping HRA as it's blacklisted")
                        continue
                    }
                    
                    // Categorize based on section and standard components
                    if inEarningsSection || standardEarningsComponents.contains(code) {
                        if amount >= minimumEarningsAmount {
                            earnings[code] = amount
                            print("Vision: Categorized \(code) as earnings with amount \(amount)")
                        } else {
                            print("Vision: Skipping earnings \(code) with amount \(amount) below threshold")
                        }
                    } else if inDeductionsSection || standardDeductionsComponents.contains(code) {
                        if amount >= minimumDeductionsAmount {
                            deductions[code] = amount
                            print("Vision: Categorized \(code) as deductions with amount \(amount)")
                        } else {
                            print("Vision: Skipping deduction \(code) with amount \(amount) below threshold")
                        }
                    } else {
                        print("Vision: Ignoring unknown code \(code) with amount \(amount)")
                    }
                }
            }
        }
        
        // Update the payslip with the extracted data
        if let payslipItem = payslip as? PayslipItem {
            // Merge with existing data rather than replacing
            for (code, amount) in earnings {
                if !blacklistedTerms.contains(code) && code != "HRA" {
                    payslipItem.earnings[code] = amount
                }
            }
            
            for (code, amount) in deductions {
                if !blacklistedTerms.contains(code) {
                    payslipItem.deductions[code] = amount
                }
            }
            
            // Final validation: ensure standard components are in the correct category
            for component in standardEarningsComponents {
                if component != "HRA" && payslipItem.deductions[component] != nil && payslipItem.deductions[component]! > 1 {
                    // Move from deductions to earnings
                    payslipItem.earnings[component] = payslipItem.deductions[component]!
                    payslipItem.deductions.removeValue(forKey: component)
                    print("Vision: Moved standard earnings component \(component) from deductions to earnings")
                }
            }
            
            for component in standardDeductionsComponents {
                if let value = payslipItem.earnings[component], value > 1 {
                    // Move from earnings to deductions
                    payslipItem.deductions[component] = value
                    payslipItem.earnings.removeValue(forKey: component)
                    print("Vision: Moved standard deductions component \(component) from earnings to deductions")
                }
            }
            
            // Update financial summary data if found
            if let grossPay = grossPay {
                payslipItem.credits = grossPay
                print("Vision: Set credits to \(grossPay)")
            }
            
            if let totalDeductions = totalDeductions {
                payslipItem.debits = totalDeductions
                print("Vision: Set debits to \(totalDeductions)")
            }
            
            // For DSOP, first check if we found it in the rows
            var foundDSOP = false
            if let dsopValue = dsopValue, dsopValue >= 1000 {
                payslipItem.dsop = dsopValue
                foundDSOP = true
                print("Vision: Set DSOP to \(dsopValue) from rows")
            }
            
            // If not found in rows, check deductions
            if !foundDSOP {
                for (key, value) in deductions {
                    if key == "DSOP" && value >= 1000 {
                        payslipItem.dsop = value
                        foundDSOP = true
                        print("Vision: Set DSOP to \(value) from deductions")
                        break
                    }
                }
            }
            
            // For tax, first check if we found it in the rows
            var foundTax = false
            if let taxValue = taxValue, taxValue > 1000 {
                payslipItem.tax = taxValue
                foundTax = true
                print("Vision: Set tax to \(taxValue) from rows")
            }
            
            // If not found in rows, check deductions
            if !foundTax {
                for (key, value) in deductions {
                    if (key == "ITAX" || key == "Income Tax") && value > 1000 {
                        payslipItem.tax = value
                        foundTax = true
                        print("Vision: Set tax to \(value) from deductions")
                        break
                    }
                }
            }
            
            // Validate that credits and debits are not the same value (which would result in zero net remittance)
            if payslipItem.credits == payslipItem.debits && payslipItem.credits > 0 {
                print("Vision: Credits and debits are the same value, attempting to fix...")
                
                // Try to calculate credits from earnings
                let totalEarnings = payslipItem.earnings.values.reduce(0, +)
                if totalEarnings > 1000 && totalEarnings != payslipItem.debits {
                    payslipItem.credits = totalEarnings
                    print("Vision: Fixed credits to \(totalEarnings) using earnings sum")
                }
            }
            
            // Save the updated payslip
            Task {
                do {
                    // Ensure HRA is removed from earnings
                    payslipItem.earnings.removeValue(forKey: "HRA")
                    print("Vision: Explicitly removed HRA from earnings")
                    
                    if !dataService.isInitialized {
                        try await dataService.initialize()
                    }
                    try await dataService.save(payslipItem)
                    print("Vision: Updated payslip with extracted data")
                } catch {
                    print("Vision: Failed to save payslip: \(error.localizedDescription)")
                }
            }
        }
    }
}
#endif 