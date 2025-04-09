import Foundation
import PDFKit

/// A specialized parser for military payslips that implements the MilitaryPayslipParser protocol
class MilitaryPayslipParserImpl: MilitaryPayslipParser {
    // MARK: - Properties
    
    /// Name of the parser for identification
    var name: String {
        return "MilitaryPayslipParser"
    }
    
    /// The abbreviation manager for handling military abbreviations
    let abbreviationManager: AbbreviationManager
    
    /// Text extractor for handling PDF text extraction
    private let textExtractor: PDFTextExtractor
    
    /// Pattern matching service for extracting data using regex patterns
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes a new MilitaryPayslipParserImpl
    /// - Parameter abbreviationManager: The abbreviation manager to use
    init(abbreviationManager: AbbreviationManager, 
         patternMatchingService: PatternMatchingServiceProtocol? = nil,
         textExtractor: PDFTextExtractor? = nil) {
        self.abbreviationManager = abbreviationManager
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
        self.textExtractor = textExtractor ?? PDFTextExtractor()
        setupMilitaryPatterns()
    }
    
    // MARK: - Setup
    
    /// Sets up military-specific patterns for the pattern matching service
    private func setupMilitaryPatterns() {
        // Personal details patterns
        let militaryPatterns: [String: String] = [
            "name": "(?:SERVICE NO & NAME|ARMY NO AND NAME|NAME|Name|Personnel|Employee Name)[\\s:]*(?:[A-Z0-9]+\\s*)?([A-Za-z\\s.]+?)(?:\\s*UNIT|\\s*$)",
            "month": "(?:FOR THE MONTH OF|MONTH|PAY FOR|PAYSLIP FOR|STATEMENT OF ACCOUNT FOR|MONTH OF|SALARY FOR)\\s*(?:THE MONTH OF)?\\s*([A-Za-z]+)\\s*([0-9]{4})?",
            "year": "(?:YEAR|FOR THE YEAR|FOR FINANCIAL YEAR|FY|FOR THE MONTH OF|DATED)\\s*(?:[A-Za-z]+\\s*)?([0-9]{4})",
            "accountNumber": "(?:BANK A\\/C NO|A\\/C NO|Account No|Bank Account)\\s*[:.]?\\s*([0-9\\-/]+)",
            "panNumber": "(?:PAN|PAN No|PAN Number)[\\s:]*([A-Za-z0-9]+)",
            "serviceNumber": "(?:SERVICE NO|ARMY NO|SERVICE NUMBER)[\\s:]*([A-Za-z0-9]+)"
        ]
        
        // Add all military patterns to the pattern manager
        for (key, pattern) in militaryPatterns {
            patternMatchingService.addPattern(key: key, pattern: pattern)
        }
    }
    
    // MARK: - PayslipParser Protocol Implementation
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // Extract text from the PDF
        let fullText = textExtractor.extractText(from: pdfDocument)
        
        // Verify this is a military payslip
        if !canHandleMilitaryFormat(text: fullText) {
            print("MilitaryPayslipParserImpl: Not a military payslip format")
            return nil
        }
        
        // Extract military-specific details
        let militaryDetails = extractMilitaryDetails(from: fullText)
        
        // Extract earnings and deductions
        let (earnings, deductions) = extractFinancialData(from: fullText)
        
        // Calculate totals
        let totalCredits = earnings.values.reduce(0, +)
        let totalDebits = deductions.values.reduce(0, +)
        
        // Extract DSOP and tax values
        let dsop = deductions["DSOP"] ?? 0.0
        let tax = deductions["ITAX"] ?? deductions["INCOME TAX"] ?? 0.0
        
        // Create the payslip item
        let payslipItem = PayslipItem(
            month: militaryDetails["month"] ?? getCurrentMonth(),
            year: Int(militaryDetails["year"] ?? String(getCurrentYear())) ?? getCurrentYear(),
            credits: totalCredits,
            debits: totalDebits,
            dsop: dsop,
            tax: tax,
            name: militaryDetails["name"] ?? "Military Personnel",
            accountNumber: militaryDetails["accountNumber"] ?? "",
            panNumber: militaryDetails["panNumber"] ?? "",
            timestamp: Date(),
            pdfData: nil
        )
        
        // Set earnings and deductions
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions
        
        return payslipItem
    }
    
    // MARK: - MilitaryPayslipParser Protocol Implementation
    
    /// Determines if the parser can handle a specific military format
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: True if the parser can handle this format, false otherwise
    func canHandleMilitaryFormat(text: String) -> Bool {
        // Check for common military terms that indicate a military payslip
        let militaryTerms = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", 
            "PCDA", "CDA", "Defence", "DSOP FUND", "Military",
            "SERVICE NO", "ARMY NO", "UNIT", "Principal Controller of Defence Accounts"
        ]
        
        // Check if any military term appears in the text
        for term in militaryTerms {
            if text.contains(term) {
                return true
            }
        }
        
        return false
    }
    
    /// Extracts military-specific details from the payslip
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: A dictionary of extracted military-specific details
    func extractMilitaryDetails(from text: String) -> [String: String] {
        // Use the pattern matching service to extract data
        let extractedData = patternMatchingService.extractData(from: text)
        
        // Process month and year if needed
        var updatedData = extractedData
        
        // If month is not found, try to extract from text
        if updatedData["month"] == nil || updatedData["month"]?.isEmpty == true {
            let monthPattern = "(?:FOR THE MONTH OF|MONTH OF|STATEMENT OF ACCOUNT FOR|PAY FOR)\\s*([A-Za-z]+)"
            if let range = text.range(of: monthPattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let captureRange = matchedText.range(of: "([A-Za-z]+)$", options: .regularExpression) {
                    let month = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedData["month"] = month
                }
            }
        }
        
        // If year is not found, try to extract from text
        if updatedData["year"] == nil || updatedData["year"]?.isEmpty == true {
            let yearPattern = "(?:YEAR|FOR THE YEAR|FOR FINANCIAL YEAR|FY|FOR THE MONTH OF|DATED)\\s*(?:[A-Za-z]+\\s*)?([0-9]{4})"
            if let range = text.range(of: yearPattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let captureRange = matchedText.range(of: "([0-9]{4})", options: .regularExpression) {
                    let year = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedData["year"] = year
                }
            }
        }
        
        // If still no month/year, use current date
        if updatedData["month"] == nil || updatedData["month"]?.isEmpty == true {
            updatedData["month"] = getCurrentMonth()
        }
        
        if updatedData["year"] == nil || updatedData["year"]?.isEmpty == true {
            updatedData["year"] = String(getCurrentYear())
        }
        
        // Clean up name - remove UNIT and service number
        if let name = updatedData["name"] {
            let cleanedName = name.replacingOccurrences(of: "UNIT", with: "")
                               .replacingOccurrences(of: "\n", with: " ")
                               .trimmingCharacters(in: .whitespacesAndNewlines)
            updatedData["name"] = cleanedName
        }
        
        return updatedData
    }
    
    /// Parse military abbreviations in the payslip
    /// - Parameter text: The text containing abbreviations
    /// - Returns: A dictionary mapping abbreviations to their full meanings
    func parseMilitaryAbbreviations(in text: String) -> [String: String] {
        var result = [String: String]()
        
        // Regular expression to find potential abbreviations (uppercase words)
        let pattern = "\\b[A-Z][A-Z0-9]{1,}\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let abbreviation = nsString.substring(with: match.range)
                if let fullName = abbreviationManager.getFullName(for: abbreviation) {
                    result[abbreviation] = fullName
                }
            }
        } catch {
            print("Error parsing military abbreviations: \(error)")
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    /// Extracts financial data (earnings and deductions) from the payslip text
    /// - Parameter text: The text to extract from
    /// - Returns: A tuple containing earnings and deductions dictionaries
    private func extractFinancialData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Earnings patterns
        let earningsPatterns = [
            "BASIC PAY": "BASIC\\s*PAY\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "PAY": "PAY\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "DA": "(?:DA|DEARNESS ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "TA": "(?:TA|TRANSPORT ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "MSP": "(?:MSP|MILITARY SERVICE PAY)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "HRA": "(?:HRA|HOUSE RENT ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"
        ]
        
        // Deduction patterns
        let deductionsPatterns = [
            "DSOP": "(?:DSOP|DSOP FUND)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "AGIF": "(?:AGIF|ARMY GROUP INSURANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "INCOME TAX": "(?:INCOME TAX|I\\.TAX|IT)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "CGEIS": "CGEIS\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "AFPP": "AFPP\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"
        ]
        
        // Extract earnings using the patterns
        for (key, pattern) in earningsPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let valueRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueString = String(matchedText[valueRange])
                                      .replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        earnings[key] = value
                    }
                }
            }
        }
        
        // Extract deductions using the patterns
        for (key, pattern) in deductionsPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let valueRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueString = String(matchedText[valueRange])
                                      .replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        deductions[key] = value
                    }
                }
            }
        }
        
        // Try to find total earnings
        if let totalEarningsRange = text.range(of: "(?:TOTAL EARNINGS|GROSS PAY|GROSS SALARY)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)", options: .regularExpression) {
            let totalEarningsText = String(text[totalEarningsRange])
            if let valueRange = totalEarningsText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                let valueString = String(totalEarningsText[valueRange])
                                  .replacingOccurrences(of: ",", with: "")
                if let value = Double(valueString) {
                    earnings["TOTAL EARNINGS"] = value
                }
            }
        }
        
        // Try to find total deductions
        if let totalDeductionsRange = text.range(of: "(?:TOTAL DEDUCTION|TOTAL DEDUCTIONS)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)", options: .regularExpression) {
            let totalDeductionsText = String(text[totalDeductionsRange])
            if let valueRange = totalDeductionsText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                let valueString = String(totalDeductionsText[valueRange])
                                  .replacingOccurrences(of: ",", with: "")
                if let value = Double(valueString) {
                    deductions["TOTAL DEDUCTIONS"] = value
                }
            }
        }
        
        // Parse any unknown abbreviations and add them to the learning system
        let unknownAbbreviations = parseMilitaryAbbreviations(in: text)
        for (abbr, _) in unknownAbbreviations {
            if !earnings.keys.contains(abbr) && !deductions.keys.contains(abbr) {
                abbreviationManager.trackUnknownAbbreviation(abbr, value: 0.0)
            }
        }
        
        return (earnings, deductions)
    }
    
    /// Gets the current month name
    /// - Returns: The current month name
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    /// Gets the current year
    /// - Returns: The current year
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
}

// MARK: - Protocol Extensions

extension MilitaryPayslipParser {
    /// Default implementation for checking if a parser can handle military format
    static func defaultCanHandleMilitaryFormat(text: String) -> Bool {
        // Common military terms that indicate a military payslip
        let militaryTerms = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", 
            "PCDA", "CDA", "Defence", "DSOP FUND", "Military",
            "SERVICE NO", "ARMY NO", "UNIT"
        ]
        
        // Check if any military term appears in the text
        for term in militaryTerms {
            if text.contains(term) {
                return true
            }
        }
        
        return false
    }
    
    /// Default implementation for parsing military abbreviations
    static func defaultParseMilitaryAbbreviations(in text: String, with abbreviationManager: AbbreviationManager) -> [String: String] {
        var result = [String: String]()
        
        // Regular expression to find potential abbreviations (uppercase words)
        let pattern = "\\b[A-Z][A-Z0-9]{1,}\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let abbreviation = nsString.substring(with: match.range)
                if let fullName = abbreviationManager.getFullName(for: abbreviation) {
                    result[abbreviation] = fullName
                }
            }
        } catch {
            print("Error parsing military abbreviations: \(error)")
        }
        
        return result
    }
} 