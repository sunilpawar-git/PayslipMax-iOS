import Foundation
import PDFKit

/// Represents the type of a payslip page
enum PageType {
    case mainSummary
    case incomeTaxDetails
    case dsopFundDetails
    case contactDetails
    case other
}

/// A comprehensive parser for PCDA (Principal Controller of Defence Accounts) payslips
class PCDAPayslipParser: PayslipParser {
    // MARK: - Properties
    
    /// Name of the parser for identification
    var name: String {
        return "PCDAPayslipParser"
    }
    
    /// The abbreviation manager for handling abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// The abbreviation learning system for tracking unknown abbreviations
    private let learningSystem: AbbreviationLearningSystem
    
    /// The enhanced earnings and deductions parser
    private let earningsDeductionsParser: EnhancedEarningsDeductionsParser
    
    // MARK: - Initialization
    
    /// Initializes a new PCDAPayslipParser
    /// - Parameter abbreviationManager: The abbreviation manager to use
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        self.earningsDeductionsParser = EnhancedEarningsDeductionsParser(abbreviationManager: abbreviationManager)
        self.learningSystem = self.earningsDeductionsParser.getLearningSystem()
    }
    
    // MARK: - PayslipParser Protocol
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // 1. Extract text from all pages
        var pageTexts: [String] = []
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let text = page.string {
                pageTexts.append(text)
            }
        }
        
        // 2. Identify page types
        let pageTypes = identifyPageTypes(pageTexts)
        
        // 3. Extract data from each page type
        let personalDetails = extractPersonalDetails(from: pageTexts, pageTypes: pageTypes)
        let earningsDeductions = extractEarningsDeductions(from: pageTexts, pageTypes: pageTypes)
        
        // These values are extracted but not used in createPayslipItem, so replace with '_'
        _ = extractNetRemittance(from: pageTexts, pageTypes: pageTypes)
        _ = extractIncomeTaxDetails(from: pageTexts, pageTypes: pageTypes)
        _ = extractDSOPFundDetails(from: pageTexts, pageTypes: pageTypes)
        _ = extractContactDetails(from: pageTexts, pageTypes: pageTypes)
        
        // 4. Create PayslipItem
        let payslipItem = createPayslipItem(
            personalDetails: personalDetails,
            earningsDeductions: earningsDeductions
        )
        
        // 5. Validate the extracted data
        if validatePayslipData(payslipItem) {
            return payslipItem
        } else {
            print("Validation failed for payslip")
            return nil
        }
    }
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        var score = 0
        
        // Check personal details
        if !payslipItem.name.isEmpty && !payslipItem.accountNumber.isEmpty {
            score += 1
        }
        
        // Check earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if payslipItem.earnings["BPAY"] != nil && 
           payslipItem.deductions["DSOP"] != nil {
            score += 1
        }
        
        // Check if we have a reasonable number of items
        if payslipItem.earnings.count >= 3 && payslipItem.deductions.count >= 3 {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 4 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Private Methods
    
    /// Identifies the type of each page
    /// - Parameter pageTexts: Array of page texts
    /// - Returns: Array of page types
    private func identifyPageTypes(_ pageTexts: [String]) -> [PageType] {
        var pageTypes: [PageType] = []
        
        for pageText in pageTexts {
            if pageText.contains("STATEMENT OF ACCOUNT FOR") {
                pageTypes.append(.mainSummary)
            } else if pageText.contains("INCOME TAX DETAILS") {
                pageTypes.append(.incomeTaxDetails)
            } else if pageText.contains("DSOP FUND FOR THE CURRENT YEAR") {
                pageTypes.append(.dsopFundDetails)
            } else if pageText.contains("CONTACT US") {
                pageTypes.append(.contactDetails)
            } else {
                pageTypes.append(.other)
            }
        }
        
        return pageTypes
    }
    
    /// Extracts personal details from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Personal details structure
    private func extractPersonalDetails(from pageTexts: [String], pageTypes: [PageType]) -> PersonalDetails {
        var details = PersonalDetails()
        
        // Find the main summary page
        if let mainSummaryIndex = pageTypes.firstIndex(of: .mainSummary), mainSummaryIndex < pageTexts.count {
            let pageText = pageTexts[mainSummaryIndex]
            
            // Extract Name
            if let nameRange = pageText.range(of: "Name:\\s*([^\\n]+)", options: .regularExpression) {
                let nameMatch = pageText[nameRange]
                let nameComponents = nameMatch.components(separatedBy: ":")
                if nameComponents.count > 1 {
                    details.name = nameComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Extract Account Number
            if let accountRange = pageText.range(of: "A/C No\\s*-\\s*([^\\s]+)", options: .regularExpression) {
                let accountMatch = pageText[accountRange]
                let accountComponents = accountMatch.components(separatedBy: "-")
                if accountComponents.count > 1 {
                    details.accountNumber = accountComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Extract PAN
            if let panRange = pageText.range(of: "PAN No:\\s*([^\\s\\n]+)", options: .regularExpression) {
                let panMatch = pageText[panRange]
                let panComponents = panMatch.components(separatedBy: ":")
                if panComponents.count > 1 {
                    details.panNumber = panComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Extract Month/Year from statement heading
            if let statementRange = pageText.range(of: "STATEMENT OF ACCOUNT FOR (\\d+/\\d+)", options: .regularExpression) {
                let statementMatch = pageText[statementRange]
                if let periodRange = statementMatch.range(of: "\\d+/\\d+", options: .regularExpression) {
                    let period = statementMatch[periodRange]
                    let components = period.components(separatedBy: "/")
                    if components.count == 2 {
                        details.month = mapMonthNumber(components[0])
                        if let yearComponent = Int(components[1]) {
                            if yearComponent < 100 {
                                details.year = String(2000 + yearComponent)
                            } else {
                                details.year = String(yearComponent)
                            }
                        } else {
                            details.year = String(Calendar.current.component(.year, from: Date()))
                        }
                    }
                }
            }
            
            // Extract Location
            if let locationRange = pageText.range(of: "Location:\\s*([^\\n]+)", options: .regularExpression) {
                let locationMatch = pageText[locationRange]
                let locationComponents = locationMatch.components(separatedBy: ":")
                if locationComponents.count > 1 {
                    details.location = locationComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return details
    }
    
    /// Extracts earnings and deductions data from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Earnings and deductions data
    private func extractEarningsDeductions(from pageTexts: [String], pageTypes: [PageType]) -> EarningsDeductionsData {
        // Find the main summary page
        if let mainSummaryIndex = pageTypes.firstIndex(of: .mainSummary), mainSummaryIndex < pageTexts.count {
            let pageText = pageTexts[mainSummaryIndex]
            
            // Use the enhanced earnings and deductions parser
            return earningsDeductionsParser.extractEarningsDeductions(from: pageText)
        }
        
        return EarningsDeductionsData()
    }
    
    /// Extracts net remittance from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Net remittance amount
    private func extractNetRemittance(from pageTexts: [String], pageTypes: [PageType]) -> Double {
        // Find the main summary page
        if let mainSummaryIndex = pageTypes.firstIndex(of: .mainSummary), mainSummaryIndex < pageTexts.count {
            let pageText = pageTexts[mainSummaryIndex]
            
            // Pattern to match "Net Remittance : Rs.XX,XXX"
            if let remittanceRange = pageText.range(of: "Net Remittance\\s*:\\s*Rs\\.([\\d,]+)", options: .regularExpression) {
                let remittanceMatch = pageText[remittanceRange]
                if let valueRange = remittanceMatch.range(of: "[\\d,]+", options: .regularExpression) {
                    let valueString = remittanceMatch[valueRange]
                    // Remove commas and convert to Double
                    let cleanValue = valueString.replacingOccurrences(of: ",", with: "")
                    return Double(cleanValue) ?? 0
                }
            }
        }
        
        return 0
    }
    
    /// Extracts income tax details from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Income tax details
    private func extractIncomeTaxDetails(from pageTexts: [String], pageTypes: [PageType]) -> IncomeTaxDetails {
        var taxDetails = IncomeTaxDetails()
        
        // Find the income tax details page
        if let taxPageIndex = pageTypes.firstIndex(of: .incomeTaxDetails), taxPageIndex < pageTexts.count {
            let pageText = pageTexts[taxPageIndex]
            
            // Extract key tax information using line-by-line approach
            let lines = pageText.components(separatedBy: .newlines)
            
            for (index, line) in lines.enumerated() {
                if line.contains("Total Taxable Income") && index + 1 < lines.count {
                    taxDetails.totalTaxableIncome = extractNumberFromLine(lines[index])
                }
                else if line.contains("Standard Deduction") && index + 1 < lines.count {
                    taxDetails.standardDeduction = extractNumberFromLine(lines[index])
                }
                else if line.contains("Net Taxable Income") && index + 1 < lines.count {
                    taxDetails.netTaxableIncome = extractNumberFromLine(lines[index])
                }
                else if line.contains("Total Tax Payable") && index + 1 < lines.count {
                    taxDetails.totalTaxPayable = extractNumberFromLine(lines[index])
                }
                else if line.contains("Income Tax Deducted") && index + 1 < lines.count {
                    taxDetails.incomeTaxDeducted = extractNumberFromLine(lines[index])
                }
                else if line.contains("Ed. Cess Deducted") && index + 1 < lines.count {
                    taxDetails.educationCessDeducted = extractNumberFromLine(lines[index])
                }
            }
        }
        
        return taxDetails
    }
    
    /// Extracts DSOP fund details from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: DSOP fund details
    private func extractDSOPFundDetails(from pageTexts: [String], pageTypes: [PageType]) -> DSOPFundDetails {
        var dsopDetails = DSOPFundDetails()
        
        // Find the DSOP fund details page
        if let dsopPageIndex = pageTypes.firstIndex(of: .dsopFundDetails), dsopPageIndex < pageTexts.count {
            let pageText = pageTexts[dsopPageIndex]
            
            // Extract Opening Balance
            if let openingBalanceRange = pageText.range(of: "Opening Balance\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[openingBalanceRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.openingBalance = Double(valueString) ?? 0
                }
            }
            
            // Extract Subscription
            if let subscriptionRange = pageText.range(of: "Subscription\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[subscriptionRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.subscription = Double(valueString) ?? 0
                }
            }
            
            // Extract Misc Adjustment
            if let miscAdjRange = pageText.range(of: "Misc Adj\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[miscAdjRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.miscAdjustment = Double(valueString) ?? 0
                }
            }
            
            // Extract Withdrawal
            if let withdrawalRange = pageText.range(of: "Withdrawal\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[withdrawalRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.withdrawal = Double(valueString) ?? 0
                }
            }
            
            // Extract Refund
            if let refundRange = pageText.range(of: "Refund\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[refundRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.refund = Double(valueString) ?? 0
                }
            }
            
            // Extract Closing Balance
            if let closingBalanceRange = pageText.range(of: "Closing Balance\\s+(\\d+)", options: .regularExpression) {
                let match = pageText[closingBalanceRange]
                if let valueRange = match.range(of: "\\d+", options: .regularExpression) {
                    let valueString = match[valueRange]
                    dsopDetails.closingBalance = Double(valueString) ?? 0
                }
            }
        }
        
        return dsopDetails
    }
    
    /// Extracts contact details from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Contact details
    private func extractContactDetails(from pageTexts: [String], pageTypes: [PageType]) -> ContactDetails {
        var contactDetails = ContactDetails()
        
        // Find the contact details page
        if let contactPageIndex = pageTypes.firstIndex(of: .contactDetails), contactPageIndex < pageTexts.count {
            let pageText = pageTexts[contactPageIndex]
            
            // Extract contact persons with phone numbers
            let contactPersonPattern = "([A-Z]+\\([A-Z]+\\))\\s+([A-Za-z\\s]+)\\s*\\((\\d{3,}-\\d{7,})\\)"
            let contactRegex = try? NSRegularExpression(pattern: contactPersonPattern, options: [])
            let nsString = pageText as NSString
            let contactMatches = contactRegex?.matches(in: pageText, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
            
            for match in contactMatches {
                if match.numberOfRanges == 4 {
                    let designationRange = match.range(at: 1)
                    let nameRange = match.range(at: 2)
                    let phoneRange = match.range(at: 3)
                    
                    let designation = nsString.substring(with: designationRange)
                    let name = nsString.substring(with: nameRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    let phone = nsString.substring(with: phoneRange)
                    
                    let contact = ContactPerson(
                        designation: designation,
                        name: name,
                        phoneNumber: phone
                    )
                    contactDetails.contactPersons.append(contact)
                }
            }
            
            // Extract email addresses
            let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailRegex = try? NSRegularExpression(pattern: emailPattern, options: [])
            let emailMatches = emailRegex?.matches(in: pageText, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
            
            for match in emailMatches {
                let emailRange = match.range(at: 0)
                let email = nsString.substring(with: emailRange)
                contactDetails.emails.append(email)
            }
            
            // Extract website
            let websitePattern = "https?://[A-Za-z0-9.-]+\\.[A-Za-z]{2,}(?:/[A-Za-z0-9./-]*)?"
            let websiteRegex = try? NSRegularExpression(pattern: websitePattern, options: [])
            let websiteMatches = websiteRegex?.matches(in: pageText, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
            
            if let firstWebsiteMatch = websiteMatches.first {
                let websiteRange = firstWebsiteMatch.range(at: 0)
                contactDetails.website = nsString.substring(with: websiteRange)
            }
        }
        
        return contactDetails
    }
    
    /// Creates a PayslipItem from the extracted data
    /// - Parameters:
    ///   - personalDetails: The personal details extracted from the payslip
    ///   - earningsDeductions: The earnings and deductions data extracted from the payslip
    /// - Returns: A PayslipItem
    private func createPayslipItem(
        personalDetails: PersonalDetails,
        earningsDeductions: EarningsDeductionsData
    ) -> PayslipItem {
        // Create a PayslipItem from the extracted data
        let payslipItem = PayslipItem(
            id: UUID(),
            month: personalDetails.month,
            year: Int(personalDetails.year) ?? 0,
            credits: earningsDeductions.grossPay,
            debits: earningsDeductions.totalDeductions,
            dsop: earningsDeductions.dsop,
            tax: earningsDeductions.itax,
            location: personalDetails.location.isEmpty ? "PCDA(O) Pune" : personalDetails.location,
            name: personalDetails.name,
            accountNumber: personalDetails.accountNumber,
            panNumber: personalDetails.panNumber
        )
        
        // Clear any existing entries to avoid duplicates
        payslipItem.earnings = [:]
        payslipItem.deductions = [:]
        
        // Add standard earnings (only if they have values)
        if earningsDeductions.bpay > 0 {
            payslipItem.earnings["BPAY"] = earningsDeductions.bpay
        }
        
        if earningsDeductions.da > 0 {
            payslipItem.earnings["DA"] = earningsDeductions.da
        }
        
        if earningsDeductions.msp > 0 {
            payslipItem.earnings["MSP"] = earningsDeductions.msp
        }
        
        // Add known non-standard earnings
        for (key, value) in earningsDeductions.knownEarnings {
            if value > 0 {
                payslipItem.earnings[key] = value
            }
        }
        
        // Add misc credits if any
        if earningsDeductions.miscCredits > 0 {
            payslipItem.earnings["Misc Credits"] = earningsDeductions.miscCredits
        }
        
        // Add standard deductions (only if they have values)
        if earningsDeductions.dsop > 0 {
            payslipItem.deductions["DSOP"] = earningsDeductions.dsop
        }
        
        if earningsDeductions.agif > 0 {
            payslipItem.deductions["AGIF"] = earningsDeductions.agif
        }
        
        if earningsDeductions.itax > 0 {
            payslipItem.deductions["ITAX"] = earningsDeductions.itax
        }
        
        // Add known non-standard deductions
        for (key, value) in earningsDeductions.knownDeductions {
            if value > 0 {
                payslipItem.deductions[key] = value
            }
        }
        
        // Add misc debits if any
        if earningsDeductions.miscDebits > 0 {
            payslipItem.deductions["Misc Debits"] = earningsDeductions.miscDebits
        }
        
        return payslipItem
    }
    
    /// Validates the extracted payslip data
    /// - Parameter payslipItem: The payslip item to validate
    /// - Returns: True if the data is valid, false otherwise
    private func validatePayslipData(_ payslipItem: PayslipItem) -> Bool {
        // Check if we have the minimum required data
        if payslipItem.month.isEmpty || payslipItem.year == 0 {
            print("Missing month or year")
            return false
        }
        
        // Check if we have at least some earnings and deductions
        if payslipItem.earnings.isEmpty || payslipItem.deductions.isEmpty {
            print("Missing earnings or deductions")
            return false
        }
        
        // Check if the credits and debits are reasonable
        if payslipItem.credits <= 0 || payslipItem.debits <= 0 {
            print("Invalid credits or debits")
            return false
        }
        
        // Check if the net pay is reasonable
        let netPay = payslipItem.credits - payslipItem.debits
        if netPay <= 0 {
            print("Invalid net pay")
            return false
        }
        
        return true
    }
    
    /// Helper to extract a number from a line of text
    /// - Parameter line: The line of text
    /// - Returns: The extracted number
    private func extractNumberFromLine(_ line: String) -> Double {
        // Pattern to match the last number in a line
        if let range = line.range(of: "\\d+$", options: .regularExpression) {
            let numberString = line[range]
            return Double(numberString) ?? 0
        }
        return 0
    }
    
    /// Helper to convert a month number to a month name
    /// - Parameter monthNum: The month number as a string
    /// - Returns: The month name
    private func mapMonthNumber(_ monthNum: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        
        if let date = formatter.date(from: monthNum) {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date)
        }
        return monthNum
    }
} 