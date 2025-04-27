import Foundation
import PDFKit

/// A specialized parser for corporate payslips that implements the CorporatePayslipParser protocol
class CorporatePayslipParserImpl: CorporatePayslipParser {
    // MARK: - Properties
    
    /// Name of the parser for identification
    var name: String {
        return "CorporatePayslipParser"
    }
    
    /// Text extractor for handling PDF text extraction
    private let textExtractor: PDFTextExtractor
    
    /// Pattern matching service for extracting data using regex patterns
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes a new CorporatePayslipParserImpl
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil,
         textExtractor: PDFTextExtractor? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
        self.textExtractor = textExtractor ?? PDFTextExtractor()
        setupCorporatePatterns()
    }
    
    // MARK: - Setup
    
    /// Sets up corporate-specific patterns for the pattern matching service
    private func setupCorporatePatterns() {
        // Personal details patterns
        let corporatePatterns: [String: String] = [
            "name": "(?:Employee Name|NAME|Name|Personnel)[\\s:]*([A-Za-z\\s.]+)",
            "employeeID": "(?:Employee ID|EMP ID|Employee Number|EMP NO)[\\s:]*([A-Za-z0-9-]+)",
            "department": "(?:Department|DEPT|DEP)[\\s:]*([A-Za-z\\s&]+)",
            "designation": "(?:Designation|DESG|Position)[\\s:]*([A-Za-z\\s&]+)",
            "month": "(?:Salary for the Month of|MONTH|PAY FOR|PAYSLIP FOR|MONTH OF|SALARY FOR)[\\s:]*(\\w+)\\s*([0-9]{4})?",
            "year": "(?:YEAR|FOR THE YEAR|FOR FINANCIAL YEAR|FY)[\\s:]*([0-9]{4})",
            "companyName": "(?:Company Name|COMPANY|Organisation)[\\s:]*([A-Za-z\\s.&]+)",
            "accountNumber": "(?:Bank A\\/C No|Account No|Bank Account)[\\s:]*([0-9\\-/]+)",
            "panNumber": "(?:PAN|PAN No|PAN Number)[\\s:]*([A-Za-z0-9]+)",
            "location": "(?:Location|LOC|PLACE|City)[\\s:]*([A-Za-z\\s.]+)"
        ]
        
        // Add all corporate patterns to the pattern manager
        for (key, pattern) in corporatePatterns {
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
        
        // Verify this is a corporate payslip
        if !canHandleCorporateFormat(text: fullText) {
            print("CorporatePayslipParserImpl: Not a corporate payslip format")
            return nil
        }
        
        // Extract employee details
        let employeeDetails = extractEmployeeDetails(from: fullText)
        
        // Extract company details - not directly used in this version
        _ = extractCompanyDetails(from: fullText)
        
        // Extract tax information - use the values directly from deductions
        _ = extractTaxInformation(from: fullText)
        
        // Extract earnings and deductions
        let (earnings, deductions) = extractFinancialData(from: fullText)
        
        // Calculate totals
        let totalCredits = earnings.values.reduce(0, +)
        let totalDebits = deductions.values.reduce(0, +)
        
        // Find specific values
        let incomeTax = deductions["INCOME TAX"] ?? deductions["TDS"] ?? deductions["TAX"] ?? 0.0
        let providentFund = deductions["PF"] ?? deductions["PROVIDENT FUND"] ?? deductions["EPF"] ?? 0.0
        
        // Extract PAN number separately
        var panNumber = ""
        if let extractedPAN = employeeDetails["panNumber"], !extractedPAN.isEmpty {
            panNumber = extractedPAN
        }
        
        // Create the payslip item
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: employeeDetails["month"] ?? getCurrentMonth(),
            year: Int(employeeDetails["year"] ?? String(getCurrentYear())) ?? getCurrentYear(),
            credits: totalCredits,
            debits: totalDebits,
            dsop: providentFund, // Using PF as DSOP equivalent for corporate
            tax: incomeTax,
            name: employeeDetails["name"] ?? "Corporate Employee",
            accountNumber: employeeDetails["accountNumber"] ?? "",
            panNumber: panNumber,
            pdfData: nil
        )
        
        // Set earnings and deductions
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions
        
        return payslipItem
    }
    
    // MARK: - CorporatePayslipParser Protocol Implementation
    
    /// Determines if the parser can handle a specific corporate format
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: True if the parser can handle this format, false otherwise
    func canHandleCorporateFormat(text: String) -> Bool {
        // Check for common corporate payslip terms
        let corporateTerms = [
            "Salary Slip", "Pay Slip", "Employee Name", "Employee ID", 
            "Department", "Designation", "Earnings", "Deductions",
            "Net Pay", "Gross Pay", "PF", "ESI", "TDS", "Professional Tax"
        ]
        
        // Count how many corporate terms appear in the text
        var count = 0
        for term in corporateTerms {
            if text.contains(term) {
                count += 1
            }
        }
        
        // If more than 3 corporate terms are found, consider it a corporate payslip
        return count > 3
    }
    
    /// Extracts employee details from the payslip
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: A dictionary of extracted employee details
    func extractEmployeeDetails(from text: String) -> [String: String] {
        // Use the pattern matching service to extract data
        var extractedData = patternMatchingService.extractData(from: text)
        
        // If month is not found, try to extract from text
        if extractedData["month"] == nil || extractedData["month"]?.isEmpty == true {
            let monthPattern = "(?:Salary for the Month of|MONTH OF|SALARY FOR)\\s*([A-Za-z]+)"
            if let range = text.range(of: monthPattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let captureRange = matchedText.range(of: "([A-Za-z]+)$", options: .regularExpression) {
                    let month = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    extractedData["month"] = month
                }
            }
        }
        
        // If year is not found, try to extract from text
        if extractedData["year"] == nil || extractedData["year"]?.isEmpty == true {
            let yearPattern = "(?:YEAR|FOR THE YEAR|FY|FOR FINANCIAL YEAR|DATED)\\s*(?:[A-Za-z]+\\s*)?([0-9]{4})"
            if let range = text.range(of: yearPattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let captureRange = matchedText.range(of: "([0-9]{4})", options: .regularExpression) {
                    let year = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    extractedData["year"] = year
                }
            }
        }
        
        // If still no month/year, use current date
        if extractedData["month"] == nil || extractedData["month"]?.isEmpty == true {
            extractedData["month"] = getCurrentMonth()
        }
        
        if extractedData["year"] == nil || extractedData["year"]?.isEmpty == true {
            extractedData["year"] = String(getCurrentYear())
        }
        
        return extractedData
    }
    
    /// Extracts company details from the payslip
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: A dictionary of extracted company details
    func extractCompanyDetails(from text: String) -> [String: String] {
        var companyDetails: [String: String] = [:]
        
        // Extract company name using direct pattern
        let companyNamePattern = "(?:Company Name|COMPANY|Organisation)[\\s:]*([A-Za-z\\s.&]+)"
        if let range = text.range(of: companyNamePattern, options: .regularExpression) {
            let matchedText = String(text[range])
            if let captureRange = matchedText.range(of: "([A-Za-z\\s.&]+)$", options: .regularExpression) {
                let companyName = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                companyDetails["companyName"] = companyName
            }
        }
        
        // Extract location using direct pattern
        let locationPattern = "(?:Location|LOC|PLACE|City)[\\s:]*([A-Za-z\\s.]+)"
        if let range = text.range(of: locationPattern, options: .regularExpression) {
            let matchedText = String(text[range])
            if let captureRange = matchedText.range(of: "([A-Za-z\\s.]+)$", options: .regularExpression) {
                let location = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                companyDetails["location"] = location
            }
        }
        
        return companyDetails
    }
    
    /// Extracts tax and deduction information
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: A dictionary of tax and deduction information
    func extractTaxInformation(from text: String) -> [String: Double] {
        var taxInfo: [String: Double] = [:]
        
        // Common tax and deduction patterns
        let patterns: [String: String] = [
            "incomeTax": "(?:Income Tax|TDS|Tax Deducted at Source)[\\s:]*([0-9,.]+)",
            "professionalTax": "(?:Professional Tax|PT)[\\s:]*([0-9,.]+)",
            "providentFund": "(?:Provident Fund|PF|EPF)[\\s:]*([0-9,.]+)",
            "esi": "(?:ESI|Employee State Insurance)[\\s:]*([0-9,.]+)"
        ]
        
        // Extract values using the patterns
        for (key, pattern) in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let captureRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueStr = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    // Convert the string to a double, handling commas in the number
                    let valueWithoutCommas = valueStr.replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueWithoutCommas) {
                        taxInfo[key] = value
                    }
                }
            }
        }
        
        return taxInfo
    }
    
    // MARK: - Helper Methods
    
    /// Extracts earnings and deductions from the corporate payslip text using predefined regex patterns.
    /// Also attempts to find total earnings, total deductions, and net pay.
    /// - Parameter text: The full text content extracted from the payslip.
    /// - Returns: A tuple containing two dictionaries: one for earnings and one for deductions, mapping item names to amounts.
    private func extractFinancialData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Common earnings patterns
        let earningsPatterns = [
            "BASIC": "(?:BASIC|BASIC PAY|BASIC SALARY)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "HRA": "(?:HRA|HOUSE RENT ALLOWANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "CONVEYANCE": "(?:CONVEYANCE|CONVEYANCE ALLOWANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "SPECIAL ALLOWANCE": "(?:SPECIAL ALLOWANCE|SP\\.ALLOWANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "MEDICAL ALLOWANCE": "(?:MEDICAL ALLOWANCE|MED\\.ALLOWANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "LTA": "(?:LTA|LEAVE TRAVEL ALLOWANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "BONUS": "(?:BONUS|PERFORMANCE BONUS)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)"
        ]
        
        // Common deduction patterns
        let deductionsPatterns = [
            "PF": "(?:PF|PROVIDENT FUND|EPF)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "ESI": "(?:ESI|EMPLOYEES STATE INSURANCE)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "PROFESSIONAL TAX": "(?:PT|PROFESSIONAL TAX|P TAX)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "INCOME TAX": "(?:TDS|TAX|INCOME TAX|I\\.TAX)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "LOAN": "(?:LOAN|LOAN REPAYMENT)[\\s:]*(?:Rs\\.?)?\\s*([0-9,.]+)"
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
        let totalEarningsPatterns = [
            "(?:TOTAL EARNINGS|GROSS PAY|GROSS SALARY|GROSS EARNINGS)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)",
            "(?:Total Earnings|Gross Earnings)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)"
        ]
        
        for pattern in totalEarningsPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let valueRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueString = String(matchedText[valueRange])
                                      .replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        earnings["TOTAL EARNINGS"] = value
                        break
                    }
                }
            }
        }
        
        // Try to find total deductions
        let totalDeductionsPatterns = [
            "(?:TOTAL DEDUCTION|TOTAL DEDUCTIONS)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)",
            "(?:Total Deduction|Total Deductions)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)"
        ]
        
        for pattern in totalDeductionsPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let valueRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueString = String(matchedText[valueRange])
                                      .replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        deductions["TOTAL DEDUCTIONS"] = value
                        break
                    }
                }
            }
        }
        
        // Try to find net pay
        let netPayPatterns = [
            "(?:NET PAY|NET SALARY|TAKE HOME|NET AMOUNT)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)",
            "(?:Net Pay|Net Salary|Take Home|Net Amount)[\\s:]*(?:Rs\\.)?\\s*([0-9,.]+)"
        ]
        
        for pattern in netPayPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[range])
                if let valueRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueString = String(matchedText[valueRange])
                                      .replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        // Store net pay info - not using it directly but good to have
                        earnings["NET PAY"] = value
                        break
                    }
                }
            }
        }
        
        return (earnings, deductions)
    }
    
    /// Gets the current month name (e.g., "July") as a fallback.
    /// - Returns: The full name of the current month.
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    /// Gets the current year as an integer (e.g., 2024) as a fallback.
    /// - Returns: The current calendar year.
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
} 