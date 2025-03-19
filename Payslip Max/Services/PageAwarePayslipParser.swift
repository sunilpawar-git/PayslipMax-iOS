import Foundation
import PDFKit

/// Represents a section of a payslip document
enum PayslipSection: String, CaseIterable {
    case personalDetails = "Name:"
    case earningsDeductions = "EARNINGS"
    case netRemittance = "Net Remittance"
    case incomeTaxDetails = "INCOME TAX DETAILS"
    case dsopFundDetails = "DSOP FUND"
    case contactDetails = "CONTACT US"
    
    /// Alternative markers to help identify sections
    var alternativeMarkers: [String] {
        switch self {
        case .personalDetails:
            return ["A/C No", "PAN No"]
        case .earningsDeductions:
            return ["DEDUCTIONS", "Description", "Amount"]
        case .netRemittance:
            return ["Rs."]
        case .incomeTaxDetails:
            return ["Total Taxable Income", "Standard Deduction"]
        case .dsopFundDetails:
            return ["Opening Balance", "Closing Balance"]
        case .contactDetails:
            return ["Email", "Phone"]
        }
    }
}

/// Represents a page in the payslip document
struct PageInfo {
    let pageNumber: Int
    let pageText: String
    let detectedSections: [PayslipSection]
}

/// Represents all data extracted from a payslip
struct PagedPayslipData {
    var personalDetails = PersonalDetails()
    var earningsDeductions = EarningsDeductionsData()
    var netRemittance: Double = 0
    var incomeTaxDetails = IncomeTaxDetails()
    var dsopFundDetails = DSOPFundDetails()
    var contactDetails = ContactDetails()
}

/// A parser that is aware of the page structure of a payslip
class PageAwarePayslipParser {
    // MARK: - Properties
    
    /// The abbreviation manager for handling abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// The enhanced earnings and deductions parser
    private let earningsDeductionsParser: EnhancedEarningsDeductionsParser
    
    // MARK: - Initialization
    
    /// Initializes a new PageAwarePayslipParser
    /// - Parameter abbreviationManager: The abbreviation manager to use
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        self.earningsDeductionsParser = EnhancedEarningsDeductionsParser(abbreviationManager: abbreviationManager)
    }
    
    // MARK: - Parsing Methods
    
    /// Analyzes the pages of a PDF document to identify sections
    /// - Parameter pdfDocument: The PDF document to analyze
    /// - Returns: Array of page information
    func analyzePages(pdfDocument: PDFDocument) -> [PageInfo] {
        var pagesInfo: [PageInfo] = []
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let pageText = page.string ?? ""
            
            // Detect which sections are present on this page
            var detectedSections: [PayslipSection] = []
            for section in PayslipSection.allCases {
                if pageText.contains(section.rawValue) || 
                   section.alternativeMarkers.contains(where: { pageText.contains($0) }) {
                    detectedSections.append(section)
                }
            }
            
            pagesInfo.append(PageInfo(
                pageNumber: i + 1,
                pageText: pageText,
                detectedSections: detectedSections
            ))
        }
        
        return pagesInfo
    }
    
    /// Extracts payslip data from the analyzed pages
    /// - Parameter pagesInfo: Array of page information
    /// - Returns: Structured payslip data
    func extractPayslipData(from pagesInfo: [PageInfo]) -> PagedPayslipData {
        var payslipData = PagedPayslipData()
        
        // Find pages containing each section
        let personalDetailsPage = findPageForSection(.personalDetails, in: pagesInfo)
        let earningsDeductionsPage = findPageForSection(.earningsDeductions, in: pagesInfo)
        let netRemittancePage = findPageForSection(.netRemittance, in: pagesInfo)
        let incomeTaxPage = findPageForSection(.incomeTaxDetails, in: pagesInfo)
        let dsopFundPage = findPageForSection(.dsopFundDetails, in: pagesInfo)
        let contactDetailsPage = findPageForSection(.contactDetails, in: pagesInfo)
        
        // Extract data from each section using the appropriate page
        if let page = personalDetailsPage {
            payslipData.personalDetails = extractPersonalDetails(from: page.pageText)
        }
        
        if let page = earningsDeductionsPage {
            payslipData.earningsDeductions = earningsDeductionsParser.extractEarningsDeductions(from: page.pageText)
        }
        
        if let page = netRemittancePage {
            payslipData.netRemittance = extractNetRemittance(from: page.pageText)
        }
        
        if let page = incomeTaxPage {
            payslipData.incomeTaxDetails = extractIncomeTaxDetails(from: page.pageText)
        }
        
        if let page = dsopFundPage {
            payslipData.dsopFundDetails = extractDSOPFundDetails(from: page.pageText)
        }
        
        if let page = contactDetailsPage {
            payslipData.contactDetails = extractContactDetails(from: page.pageText)
        }
        
        return payslipData
    }
    
    /// Helper method to find the page containing a specific section
    /// - Parameters:
    ///   - section: The section to find
    ///   - pagesInfo: Array of page information
    /// - Returns: The page containing the section, or nil if not found
    private func findPageForSection(_ section: PayslipSection, in pagesInfo: [PageInfo]) -> PageInfo? {
        return pagesInfo.first { $0.detectedSections.contains(section) }
    }
    
    /// Extracts personal details from the page text
    /// - Parameter pageText: The text of the page
    /// - Returns: Structured personal details
    private func extractPersonalDetails(from pageText: String) -> PersonalDetails {
        var details = PersonalDetails()
        
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
        
        return details
    }
    
    /// Extracts net remittance from the page text
    /// - Parameter pageText: The text of the page
    /// - Returns: Net remittance amount
    private func extractNetRemittance(from pageText: String) -> Double {
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
        return 0
    }
    
    /// Extracts income tax details from the page text
    /// - Parameter pageText: The text of the page
    /// - Returns: Structured income tax details
    private func extractIncomeTaxDetails(from pageText: String) -> IncomeTaxDetails {
        var taxDetails = IncomeTaxDetails()
        
        // Check if we're in the income tax section
        guard pageText.contains("INCOME TAX DETAILS") else {
            return taxDetails
        }
        
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
        
        return taxDetails
    }
    
    /// Extracts DSOP fund details from the page text
    /// - Parameter pageText: The text of the page
    /// - Returns: Structured DSOP fund details
    private func extractDSOPFundDetails(from pageText: String) -> DSOPFundDetails {
        var dsopDetails = DSOPFundDetails()
        
        // Check if we're in the DSOP section
        guard pageText.contains("DSOP FUND FOR THE CURRENT YEAR") else {
            return dsopDetails
        }
        
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
        
        return dsopDetails
    }
    
    /// Extracts contact details from the page text
    /// - Parameter pageText: The text of the page
    /// - Returns: Structured contact details
    private func extractContactDetails(from pageText: String) -> ContactDetails {
        var contactDetails = ContactDetails()
        
        // Check if we're in the contact section
        guard pageText.contains("CONTACT US") else {
            return contactDetails
        }
        
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
        
        return contactDetails
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
    
    /// Creates a PayslipItem from the extracted data
    /// - Parameter data: The extracted payslip data
    /// - Returns: A PayslipItem
    func createPayslipItem(from data: PagedPayslipData) -> PayslipItem {
        // Create a PayslipItem from the extracted data
        let payslipItem = PayslipItem(
            id: UUID(),
            month: data.personalDetails.month,
            year: Int(data.personalDetails.year) ?? 0,
            credits: data.earningsDeductions.grossPay,
            debits: data.earningsDeductions.totalDeductions,
            dsop: data.earningsDeductions.dsop,
            tax: data.earningsDeductions.itax,
            location: data.personalDetails.location,
            name: data.personalDetails.name,
            accountNumber: data.personalDetails.accountNumber,
            panNumber: data.personalDetails.panNumber
        )
        
        // Clear any existing entries to avoid duplicates
        payslipItem.earnings = [:]
        payslipItem.deductions = [:]
        
        // Add standard earnings (only if they have values)
        if data.earningsDeductions.bpay > 0 {
            payslipItem.earnings["BPAY"] = data.earningsDeductions.bpay
        }
        
        if data.earningsDeductions.da > 0 {
            payslipItem.earnings["DA"] = data.earningsDeductions.da
        }
        
        if data.earningsDeductions.msp > 0 {
            payslipItem.earnings["MSP"] = data.earningsDeductions.msp
        }
        
        // Add known non-standard earnings
        for (key, value) in data.earningsDeductions.knownEarnings {
            if value > 0 {
                payslipItem.earnings[key] = value
            }
        }
        
        // Add misc credits if any
        if data.earningsDeductions.miscCredits > 0 {
            payslipItem.earnings["Misc Credits"] = data.earningsDeductions.miscCredits
        }
        
        // Add standard deductions (only if they have values)
        if data.earningsDeductions.dsop > 0 {
            payslipItem.deductions["DSOP"] = data.earningsDeductions.dsop
        }
        
        if data.earningsDeductions.agif > 0 {
            payslipItem.deductions["AGIF"] = data.earningsDeductions.agif
        }
        
        if data.earningsDeductions.itax > 0 {
            payslipItem.deductions["ITAX"] = data.earningsDeductions.itax
        }
        
        // Add known non-standard deductions
        for (key, value) in data.earningsDeductions.knownDeductions {
            if value > 0 {
                payslipItem.deductions[key] = value
            }
        }
        
        // Add misc debits if any
        if data.earningsDeductions.miscDebits > 0 {
            payslipItem.deductions["Misc Debits"] = data.earningsDeductions.miscDebits
        }
        
        return payslipItem
    }
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // 1. Analyze pages to identify sections
        let pagesInfo = analyzePages(pdfDocument: pdfDocument)
        
        // 2. Extract data using page-aware parsing
        let payslipData = extractPayslipData(from: pagesInfo)
        
        // 3. Create and return a PayslipItem
        return createPayslipItem(from: payslipData)
    }
} 