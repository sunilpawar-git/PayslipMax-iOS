import Foundation
import PDFKit

/// Processor for PSU (Public Sector Unit) format payslips
class PSUPayslipProcessor: PayslipProcessorProtocol {
    // MARK: - Properties
    
    /// The format that this processor handles
    var handlesFormat: PayslipFormat {
        return .psu
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    /// Processes a PSU payslip
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A PayslipItem if processing was successful
    /// - Throws: Error if processing fails
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[PSUPayslipProcessor] Processing PSU payslip from \(text.count) characters")
        
        // Attempt to extract data using regex patterns
        let extractedData = extractFinancialData(from: text)
        
        // Extract month and year from text or use current date as fallback
        var month = ""
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateInfo = extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[PSUPayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Use current month as fallback
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[PSUPayslipProcessor] Using current date: \(month) \(year)")
        }
        
        // Extract financial data
        let credits = extractedData["credits"] ?? 0.0
        let debits = extractedData["debits"] ?? 0.0
        let tax = extractedData["TaxDeducted"] ?? 0.0
        
        // Extract name and account information if available
        let name = extractName(from: text) ?? "PSU Employee"
        let accountNumber = extractAccountNumber(from: text) ?? ""
        let panNumber = extractPANNumber(from: text) ?? ""
        
        print("[PSUPayslipProcessor] Creating PSU payslip with credits: \(credits), debits: \(debits)")
        
        // Create the payslip item
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: 0.0, // Not applicable for PSU
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: Data() // Empty data since we only have text at this point
        )
        
        // Set earnings and deductions
        payslipItem.earnings = createEarningsDictionary(from: extractedData)
        payslipItem.deductions = createDeductionsDictionary(from: extractedData)
        
        return payslipItem
    }
    
    /// Checks if this processor can handle the given text
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A confidence score between 0 and 1
    func canProcess(text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0
        
        // Check for PSU-specific keywords
        let psuKeywords = [
            "PSU": 0.3,
            "PUBLIC SECTOR": 0.3,
            "BHARAT": 0.1,
            "EMPLOYEE NO": 0.2,
            "EMPLOYEE CODE": 0.2,
            "DESIGNATION": 0.1,
            "GRADE": 0.1,
            "BASIC PAY": 0.2,
            "DEARNESS ALLOWANCE": 0.2,
            "HOUSE RENT ALLOWANCE": 0.2,
            "HRA": 0.1,
            "PF CONTRIBUTION": 0.2,
            "PROFESSIONAL TAX": 0.2
        ]
        
        // Calculate score based on keyword matches
        for (keyword, weight) in psuKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }
        
        // Cap the score at 1.0
        score = min(score, 1.0)
        
        print("[PSUPayslipProcessor] Format confidence score: \(score)")
        return score
    }
    
    // MARK: - Private Methods
    
    /// Extracts financial data from text
    private func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Define patterns to look for in the PDF text
        let patterns: [(key: String, regex: String)] = [
            ("BasicPay", "BASIC(?:\\s+PAY)?\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("DA", "(?:DA|DEARNESS\\s+ALLOWANCE)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("HRA", "(?:HRA|HOUSE\\s+RENT\\s+ALLOWANCE)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("TA", "(?:TA|TRANSPORT\\s+ALLOWANCE)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("Special", "(?:SPECIAL\\s+ALLOWANCE)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("PF", "(?:PF|PROVIDENT\\s+FUND)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("TaxDeducted", "(?:INCOME\\s+TAX|TAX\\s+DEDUCTED|TDS)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("ProfTax", "(?:PROFESSIONAL\\s+TAX|PROF\\s+TAX)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("credits", "(?:GROSS\\s+EARNINGS|TOTAL\\s+EARNINGS|GROSS\\s+SALARY)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"),
            ("debits", "(?:GROSS\\s+DEDUCTIONS|TOTAL\\s+DEDUCTIONS)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)")
        ]
        
        // Extract each value using regex patterns
        for (key, pattern) in patterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[PSUPayslipProcessor] Extracted \(key): \(value)")
            }
        }
        
        // If we didn't get credits, try alternative patterns
        if extractedData["credits"] == nil {
            if let value = extractAmountWithPattern("(?:NET\\s+SALARY|NET\\s+PAY)\\s*[:-]\\s*(?:Rs\\.?)?\\s*([0-9,.]+)", from: text) {
                // If we have net salary and total deductions, we can calculate gross
                if let deductions = extractedData["debits"] {
                    extractedData["credits"] = value + deductions
                    print("[PSUPayslipProcessor] Calculated credits from net: \(extractedData["credits"]!)")
                } else {
                    extractedData["credits"] = value
                }
            }
        }
        
        // If we still don't have credits, calculate from the earnings
        if extractedData["credits"] == nil {
            let basicPay = extractedData["BasicPay"] ?? 0
            let da = extractedData["DA"] ?? 0
            let hra = extractedData["HRA"] ?? 0
            let ta = extractedData["TA"] ?? 0
            let special = extractedData["Special"] ?? 0
            
            let calculatedCredits = basicPay + da + hra + ta + special
            if calculatedCredits > 0 {
                extractedData["credits"] = calculatedCredits
                print("[PSUPayslipProcessor] Calculated credits: \(calculatedCredits)")
            }
        }
        
        // Calculate total debits if not found
        if extractedData["debits"] == nil {
            let pf = extractedData["PF"] ?? 0
            let tax = extractedData["TaxDeducted"] ?? 0
            let profTax = extractedData["ProfTax"] ?? 0
            
            let calculatedDebits = pf + tax + profTax
            if calculatedDebits > 0 {
                extractedData["debits"] = calculatedDebits
                print("[PSUPayslipProcessor] Calculated debits: \(calculatedDebits)")
            }
        }
        
        return extractedData
    }
    
    /// Helper to extract amount with a specific pattern
    private func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanValue) {
                    return doubleValue
                }
            }
        } catch {
            print("[PSUPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Extracts statement date from text
    private func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Look for common date formats in payslips
        
        // Pattern: "Month YYYY" or "For the month of Month YYYY"
        let monthYearPatterns = [
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})",
            "(?:SALARY\\s+FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})"
        ]
        
        for pattern in monthYearPatterns {
            if let dateValue = extractDateWithPattern(pattern, from: text) {
                return dateValue
            }
        }
        
        // Pattern: "MM/YYYY" or "MM-YYYY"
        let numericDatePatterns = [
            "(?:SALARY\\s+FOR\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})",
            "(?:FOR\\s+MONTH\\s+OF\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})"
        ]
        
        for pattern in numericDatePatterns {
            if let dateValue = extractDateWithPattern(pattern, from: text) {
                return dateValue
            }
        }
        
        return nil
    }
    
    /// Helper to extract date with a specific pattern
    private func extractDateWithPattern(_ pattern: String, from text: String) -> (month: String, year: Int)? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 2 {
                let monthRange = match.range(at: 1)
                let yearRange = match.range(at: 2)
                
                let monthText = nsString.substring(with: monthRange)
                let yearString = nsString.substring(with: yearRange)
                
                if let year = Int(yearString) {
                    // If month is numeric, convert it to name
                    if let monthNumber = Int(monthText), monthNumber >= 1 && monthNumber <= 12 {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMMM"
                        
                        var dateComponents = DateComponents()
                        dateComponents.month = monthNumber
                        dateComponents.year = 2000  // Any year would work for getting month name
                        
                        if let date = Calendar.current.date(from: dateComponents) {
                            let monthName = dateFormatter.string(from: date)
                            return (monthName, year)
                        }
                    } else {
                        // Month is already a name
                        return (capitalizeMonth(monthText), year)
                    }
                }
            }
        } catch {
            print("[PSUPayslipProcessor] Error extracting date with pattern \(pattern): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extracts name from text
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "EMPLOYEE\\s+NAME\\s*[-:]\\s*([A-Za-z\\s.]+)",
            "NAME\\s*[-:]\\s*([A-Za-z\\s.]+)"
        ]
        
        for pattern in namePatterns {
            if let name = extractStringWithPattern(pattern, from: text) {
                return name
            }
        }
        
        return nil
    }
    
    /// Extracts account number from text
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "ACCOUNT\\s+(?:NO|NUMBER)\\s*[-:]\\s*([0-9/]+[A-Z]*)",
            "BANK\\s+A/C\\s+(?:NO|NUMBER)\\s*[-:]\\s*([0-9/]+[A-Z]*)"
        ]
        
        for pattern in accountPatterns {
            if let account = extractStringWithPattern(pattern, from: text) {
                return account
            }
        }
        
        return nil
    }
    
    /// Extracts PAN number from text
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "PAN\\s+(?:NO|NUMBER)\\s*[-:]\\s*([A-Z0-9*]+)",
            "PAN\\s*[-:]\\s*([A-Z0-9*]+)"
        ]
        
        for pattern in panPatterns {
            if let pan = extractStringWithPattern(pattern, from: text) {
                return pan
            }
        }
        
        return nil
    }
    
    /// Helper to extract string with a specific pattern
    private func extractStringWithPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                return value
            }
        } catch {
            print("[PSUPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Capitalizes the first letter of the month name
    private func capitalizeMonth(_ month: String) -> String {
        let lowercaseMonth = month.lowercased()
        if let firstChar = lowercaseMonth.first {
            return String(firstChar).uppercased() + lowercaseMonth.dropFirst()
        }
        return month
    }
    
    /// Creates an earnings dictionary from extracted data
    private func createEarningsDictionary(from data: [String: Double]) -> [String: Double] {
        var earnings = [String: Double]()
        
        // Add standard earnings components
        if let basicPay = data["BasicPay"] { earnings["Basic Pay"] = basicPay }
        if let da = data["DA"] { earnings["Dearness Allowance"] = da }
        if let hra = data["HRA"] { earnings["House Rent Allowance"] = hra }
        if let ta = data["TA"] { earnings["Transport Allowance"] = ta }
        if let special = data["Special"] { earnings["Special Allowance"] = special }
        
        // Calculate total credits from components if needed
        let totalComponentCredits = earnings.values.reduce(0, +)
        let reportedCredits = data["credits"] ?? 0
        
        // If there's a difference between reported and calculated, add as "Other Allowances"
        if reportedCredits > totalComponentCredits && totalComponentCredits > 0 {
            let otherAllowances = reportedCredits - totalComponentCredits
            earnings["Other Allowances"] = otherAllowances
        }
        
        return earnings
    }
    
    /// Creates a deductions dictionary from extracted data
    private func createDeductionsDictionary(from data: [String: Double]) -> [String: Double] {
        var deductions = [String: Double]()
        
        // Add standard deduction components
        if let pf = data["PF"] { deductions["Provident Fund"] = pf }
        if let tax = data["TaxDeducted"] { deductions["Income Tax"] = tax }
        if let profTax = data["ProfTax"] { deductions["Professional Tax"] = profTax }
        
        // Calculate total debits from components if needed
        let totalComponentDebits = deductions.values.reduce(0, +)
        let reportedDebits = data["debits"] ?? 0
        
        // If there's a difference between reported and calculated, add as "Other Deductions"
        if reportedDebits > totalComponentDebits && totalComponentDebits > 0 {
            let otherDeductions = reportedDebits - totalComponentDebits
            deductions["Other Deductions"] = otherDeductions
        }
        
        return deductions
    }
} 