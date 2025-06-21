import Foundation
import PDFKit

/// Processes payslips conforming to a common corporate format.
/// This processor uses regex patterns to extract financial data, employee details,
/// and the payslip period from the document's text content.
class CorporatePayslipProcessor: PayslipProcessorProtocol {
    // MARK: - Properties
    
    /// The format handled by this processor, which is `.corporate`.
    var handlesFormat: PayslipFormat {
        return .corporate
    }
    
    // MARK: - Initialization
    
    /// Initializes a new `CorporatePayslipProcessor`.
    init() {}
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    /// Processes the text extracted from a corporate payslip PDF.
    /// Extracts financial data, identifies the payslip period, and constructs a `PayslipItem`.
    /// Uses fallback logic to calculate totals if specific fields are missing.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` representing the processed corporate payslip.
    /// - Throws: An error if essential data (like month/year or financial figures) cannot be determined.
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[CorporatePayslipProcessor] Processing corporate payslip from \(text.count) characters")
        
        // Attempt to extract data using regex patterns
        let extractedData = extractFinancialData(from: text)
        
        // Extract month and year from text or use current date as fallback
        var month = ""
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateInfo = extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[CorporatePayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Use current month as fallback
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[CorporatePayslipProcessor] Using current date: \(month) \(year)")
        }
        
        // Extract financial data
        let credits = extractedData["credits"] ?? 0.0
        let debits = extractedData["debits"] ?? 0.0
        let tax = extractedData["TDS"] ?? 0.0
        
        // Extract name and account information if available
        let name = extractName(from: text) ?? "Corporate Employee"
        let accountNumber = extractAccountNumber(from: text) ?? ""
        let panNumber = extractPANNumber(from: text) ?? ""
        
        print("[CorporatePayslipProcessor] Creating corporate payslip with credits: \(credits), debits: \(debits)")
        
        // Create the payslip item (PDF data will be set by the processing pipeline)
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: 0.0, // Not applicable for corporate
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: nil // Will be set by the processing pipeline
        )
        
        // Set earnings and deductions
        payslipItem.earnings = createEarningsDictionary(from: extractedData)
        payslipItem.deductions = createDeductionsDictionary(from: extractedData)
        
        return payslipItem
    }
    
    /// Determines if the provided text likely represents a corporate payslip.
    /// Calculates a confidence score based on the presence of common corporate payslip keywords.
    /// - Parameter text: The extracted text from the PDF.
    /// - Returns: A confidence score between 0.0 (unlikely) and 1.0 (likely).
    func canProcess(text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0
        
        // Check for corporate-specific keywords
        let corporateKeywords = [
            "SALARY SLIP": 0.3,
            "PAY SLIP": 0.3,
            "EMPLOYEE ID": 0.2,
            "EARNINGS": 0.1,
            "DEDUCTIONS": 0.1,
            "BASIC SALARY": 0.2,
            "PROVIDENT FUND": 0.1,
            "ESI": 0.2,
            "PROFESSIONAL TAX": 0.1,
            "LTA": 0.2,
            "MEDICAL ALLOWANCE": 0.2,
            "PERFORMANCE BONUS": 0.2,
            "TDS": 0.1
        ]
        
        // Calculate score based on keyword matches
        for (keyword, weight) in corporateKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }
        
        // Cap the score at 1.0
        score = min(score, 1.0)
        
        print("[CorporatePayslipProcessor] Format confidence score: \(score)")
        return score
    }
    
    // MARK: - Private Methods
    
    /// Extracts various financial figures (earnings, deductions, totals) from the text using predefined regex patterns.
    /// Includes logic to calculate totals if specific fields like Gross Earnings or Total Deductions are missing.
    /// - Parameter text: The payslip text.
    /// - Returns: A dictionary where keys are field names (e.g., "BasicSalary", "credits") and values are the extracted amounts.
    private func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Define patterns to look for in the PDF text
        let patterns: [(key: String, regex: String)] = [
            ("BasicSalary", "BASIC(?:\\s+SALARY)?\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("HRA", "(?:HRA|HOUSE\\s+RENT\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ConveyanceAllowance", "(?:CONVEYANCE|CONVEYANCE\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("MedicalAllowance", "(?:MEDICAL|MEDICAL\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("SpecialAllowance", "(?:SPECIAL|SPECIAL\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("Bonus", "(?:BONUS|PERFORMANCE\\s+BONUS)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("LTA", "(?:LTA|LEAVE\\s+TRAVEL\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("PF", "(?:PF|PROVIDENT\\s+FUND)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ESI", "(?:ESI|EMPLOYEE\\s+STATE\\s+INSURANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("TDS", "(?:TDS|TAX\\s+DEDUCTED\\s+AT\\s+SOURCE|INCOME\\s+TAX)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ProfTax", "(?:PROF\\s+TAX|PROFESSIONAL\\s+TAX)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("credits", "(?:GROSS(?:\\s+EARNINGS|\\s+SALARY)|TOTAL\\s+EARNINGS)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("debits", "(?:TOTAL\\s+DEDUCTIONS)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)")
        ]
        
        // Extract each value using regex patterns
        for (key, pattern) in patterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[CorporatePayslipProcessor] Extracted \(key): \(value)")
            }
        }
        
        // If we didn't get credits, try alternative patterns
        if extractedData["credits"] == nil {
            if let value = extractAmountWithPattern("(?:TOTAL\\s+GROSS|GROSS\\s+AMOUNT)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)", from: text) {
                extractedData["credits"] = value
            }
        }
        
        // Check for net pay - can use to calculate if we have deductions
        if let netPay = extractAmountWithPattern("(?:NET\\s+PAY|NET\\s+SALARY|NET\\s+AMOUNT\\s+PAYABLE|TAKE\\s+HOME)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)", from: text) {
            extractedData["netPay"] = netPay
            
            // If we have net pay but no credits, and we have deductions, we can calculate credits
            if extractedData["credits"] == nil && extractedData["debits"] != nil {
                let debits = extractedData["debits"]!
                extractedData["credits"] = netPay + debits
                print("[CorporatePayslipProcessor] Calculated credits from net pay: \(extractedData["credits"]!)")
            }
            
            // If we have net pay and credits but no debits, we can calculate debits
            if extractedData["debits"] == nil && extractedData["credits"] != nil {
                let credits = extractedData["credits"]!
                extractedData["debits"] = credits - netPay
                print("[CorporatePayslipProcessor] Calculated debits from net pay: \(extractedData["debits"]!)")
            }
        }
        
        // If we still don't have credits, calculate from the earnings
        if extractedData["credits"] == nil {
            let basicSalary = extractedData["BasicSalary"] ?? 0
            let hra = extractedData["HRA"] ?? 0
            let conveyance = extractedData["ConveyanceAllowance"] ?? 0
            let medical = extractedData["MedicalAllowance"] ?? 0
            let special = extractedData["SpecialAllowance"] ?? 0
            let bonus = extractedData["Bonus"] ?? 0
            let lta = extractedData["LTA"] ?? 0
            
            let calculatedCredits = basicSalary + hra + conveyance + medical + special + bonus + lta
            if calculatedCredits > 0 {
                extractedData["credits"] = calculatedCredits
                print("[CorporatePayslipProcessor] Calculated credits: \(calculatedCredits)")
            }
        }
        
        // Calculate total debits if not found
        if extractedData["debits"] == nil {
            let pf = extractedData["PF"] ?? 0
            let esi = extractedData["ESI"] ?? 0
            let tds = extractedData["TDS"] ?? 0
            let profTax = extractedData["ProfTax"] ?? 0
            
            let calculatedDebits = pf + esi + tds + profTax
            if calculatedDebits > 0 {
                extractedData["debits"] = calculatedDebits
                print("[CorporatePayslipProcessor] Calculated debits: \(calculatedDebits)")
            }
        }
        
        return extractedData
    }
    
    /// Helper function to extract a numerical amount using a specific regex pattern.
    /// Handles comma removal and conversion to Double.
    /// - Parameters:
    ///   - pattern: The regex pattern string. Must contain a capture group for the numerical value.
    ///   - text: The text to search within.
    /// - Returns: The extracted `Double` value, or `nil` if the pattern doesn't match or conversion fails.
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
            print("[CorporatePayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Extracts the payslip statement month and year from the text.
    /// Tries multiple common date patterns (e.g., "Month YYYY", "MM/YYYY").
    /// - Parameter text: The payslip text.
    /// - Returns: A tuple containing the month name (String) and year (Int), or `nil` if no date is found.
    private func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Look for common date formats in payslips
        
        // Pattern: "Month YYYY" or "For the month of Month YYYY"
        let monthYearPatterns = [
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(?:OF\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})",
            "(?:SALARY\\s+FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(?:OF\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})",
            "(?:PAYSLIP\\s+FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(?:OF\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})"
        ]
        
        for pattern in monthYearPatterns {
            if let dateValue = extractDateWithPattern(pattern, from: text) {
                return dateValue
            }
        }
        
        // Pattern: "MM/YYYY" or "MM-YYYY"
        let numericDatePatterns = [
            "(?:SALARY\\s+FOR\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})",
            "(?:FOR\\s+MONTH\\s+OF\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})",
            "(?:PAY\\s+PERIOD\\s*:?\\s*)([0-9]{1,2})[/\\-]([0-9]{4})"
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
            print("[CorporatePayslipProcessor] Error extracting date with pattern \(pattern): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extracts the employee's name from the text using common patterns.
    /// - Parameter text: The payslip text.
    /// - Returns: The extracted name as a `String`, or `nil` if not found.
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "EMPLOYEE\\s+NAME\\s*[:-]\\s*([A-Za-z\\s.]+)",
            "NAME\\s*[:-]\\s*([A-Za-z\\s.]+)"
        ]
        
        for pattern in namePatterns {
            if let name = extractStringWithPattern(pattern, from: text) {
                return name
            }
        }
        
        return nil
    }
    
    /// Extracts the bank account number from the text using common patterns.
    /// - Parameter text: The payslip text.
    /// - Returns: The extracted account number as a `String`, or `nil` if not found.
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "BANK\\s+A/C\\s+(?:NO|NUMBER)\\s*[:-]\\s*([0-9]+)",
            "ACCOUNT\\s+(?:NO|NUMBER)\\s*[:-]\\s*([0-9]+)"
        ]
        
        for pattern in accountPatterns {
            if let account = extractStringWithPattern(pattern, from: text) {
                return account
            }
        }
        
        return nil
    }
    
    /// Extracts the PAN (Permanent Account Number) from the text using common patterns.
    /// - Parameter text: The payslip text.
    /// - Returns: The extracted PAN number as a `String`, or `nil` if not found.
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "PAN\\s+(?:NO|NUMBER)\\s*[:-]\\s*([A-Z0-9]+)",
            "PAN\\s*[:-]\\s*([A-Z0-9]+)"
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
            print("[CorporatePayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
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
    
    /// Creates a dictionary representing earnings based on extracted financial data.
    /// Maps specific extracted keys (e.g., "BasicSalary") to standardized earning item names.
    /// - Parameter extractedData: The dictionary of financially extracted data.
    /// - Returns: A `[String: Double]` dictionary representing earnings.
    private func createEarningsDictionary(from data: [String: Double]) -> [String: Double] {
        var earnings = [String: Double]()
        
        // Add standard earnings components
        if let basicSalary = data["BasicSalary"] { earnings["Basic Salary"] = basicSalary }
        if let hra = data["HRA"] { earnings["HRA"] = hra }
        if let conveyance = data["ConveyanceAllowance"] { earnings["Conveyance Allowance"] = conveyance }
        if let medical = data["MedicalAllowance"] { earnings["Medical Allowance"] = medical }
        if let special = data["SpecialAllowance"] { earnings["Special Allowance"] = special }
        if let bonus = data["Bonus"] { earnings["Bonus"] = bonus }
        if let lta = data["LTA"] { earnings["LTA"] = lta }
        
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
    
    /// Creates a dictionary representing deductions based on extracted financial data.
    /// Maps specific extracted keys (e.g., "PF", "TDS") to standardized deduction item names.
    /// - Parameter extractedData: The dictionary of financially extracted data.
    /// - Returns: A `[String: Double]` dictionary representing deductions.
    private func createDeductionsDictionary(from data: [String: Double]) -> [String: Double] {
        var deductions = [String: Double]()
        
        // Add standard deduction components
        if let pf = data["PF"] { deductions["PF"] = pf }
        if let esi = data["ESI"] { deductions["ESI"] = esi }
        if let tds = data["TDS"] { deductions["TDS"] = tds }
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