import Foundation
import PDFKit

/// Processor for military format payslips
class MilitaryPayslipProcessor: PayslipProcessorProtocol {
    // MARK: - Properties
    
    /// The format that this processor handles
    var handlesFormat: PayslipFormat {
        return .military
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    /// Processes a military payslip
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A PayslipItem if processing was successful
    /// - Throws: Error if processing fails
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[MilitaryPayslipProcessor] Processing military payslip from \(text.count) characters")
        
        // Attempt to extract data using regex patterns
        let extractedData = extractFinancialData(from: text)
        
        // Extract month and year from text or use current date as fallback
        var month = ""
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateInfo = extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[MilitaryPayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Use current month as fallback
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[MilitaryPayslipProcessor] Using current date: \(month) \(year)")
        }
        
        // Extract financial data
        let credits = extractedData["credits"] ?? 0.0
        let debits = extractedData["debits"] ?? 0.0
        let dsop = extractedData["DSOP"] ?? 0.0
        let tax = extractedData["ITAX"] ?? 0.0
        
        // Extract name and account information if available
        let name = extractName(from: text) ?? "Military Personnel"
        let accountNumber = extractAccountNumber(from: text) ?? ""
        let panNumber = extractPANNumber(from: text) ?? ""
        
        print("[MilitaryPayslipProcessor] Creating military payslip with credits: \(credits), debits: \(debits)")
        
        // Create the payslip item
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
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
        
        // Check for military-specific keywords
        let militaryKeywords = [
            "ARMY": 0.3,
            "NAVY": 0.3, 
            "AIR FORCE": 0.3,
            "DEFENCE": 0.2,
            "MILITARY": 0.3,
            "SERVICE NO & NAME": 0.4,
            "ARMY NO AND NAME": 0.4,
            "DSOP FUND": 0.3,
            "AGIF": 0.3,
            "MSP": 0.2
        ]
        
        // Calculate score based on keyword matches
        for (keyword, weight) in militaryKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }
        
        // Cap the score at 1.0
        score = min(score, 1.0)
        
        print("[MilitaryPayslipProcessor] Format confidence score: \(score)")
        return score
    }
    
    // MARK: - Private Methods
    
    /// Extracts financial data from text
    private func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Define patterns to look for in the PDF text
        let patterns: [(key: String, regex: String)] = [
            ("BPAY", "BASIC PAY\\s*[:=]\\s*([0-9,.]+)"),
            ("DA", "DA\\s*[:=]\\s*([0-9,.]+)"),
            ("MSP", "MSP\\s*[:=]\\s*([0-9,.]+)"),
            ("RH12", "RH12\\s*[:=]\\s*([0-9,.]+)"),
            ("TPTA", "TPTA(?!DA)\\s*[:=]\\s*([0-9,.]+)"),
            ("TPTADA", "TPTADA\\s*[:=]\\s*([0-9,.]+)"),
            ("DSOP", "DSOP\\s*[:=]\\s*([0-9,.]+)"),
            ("AGIF", "AGIF\\s*[:=]\\s*([0-9,.]+)"),
            ("ITAX", "ITAX\\s*[:=]\\s*([0-9,.]+)"),
            ("EHCESS", "EHCESS\\s*[:=]\\s*([0-9,.]+)"),
            ("credits", "GROSS PAY\\s*[:=]\\s*([0-9,.]+)"),
            ("debits", "TOTAL DEDUCTION\\s*[:=]\\s*([0-9,.]+)")
        ]
        
        // Extract each value using regex patterns
        for (key, pattern) in patterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[MilitaryPayslipProcessor] Extracted \(key): \(value)")
            }
        }
        
        // If we didn't get credits, try alternative patterns
        if extractedData["credits"] == nil {
            if let value = extractAmountWithPattern("(?:कुल आय|TOTAL CREDITS)\\s*[:=]\\s*([0-9,.]+)", from: text) {
                extractedData["credits"] = value
            }
        }
        
        // If we still don't have credits, calculate from the earnings
        if extractedData["credits"] == nil {
            let basicPay = extractedData["BPAY"] ?? 0
            let da = extractedData["DA"] ?? 0
            let msp = extractedData["MSP"] ?? 0
            let rh12 = extractedData["RH12"] ?? 0
            let tpta = extractedData["TPTA"] ?? 0
            let tptada = extractedData["TPTADA"] ?? 0
            
            let calculatedCredits = basicPay + da + msp + rh12 + tpta + tptada
            if calculatedCredits > 0 {
                extractedData["credits"] = calculatedCredits
                print("[MilitaryPayslipProcessor] Calculated credits: \(calculatedCredits)")
            }
        }
        
        // Calculate total debits if not found
        if extractedData["debits"] == nil {
            let dsop = extractedData["DSOP"] ?? 0
            let agif = extractedData["AGIF"] ?? 0
            let itax = extractedData["ITAX"] ?? 0
            let ehcess = extractedData["EHCESS"] ?? 0
            
            let calculatedDebits = dsop + agif + itax + ehcess
            if calculatedDebits > 0 {
                extractedData["debits"] = calculatedDebits
                print("[MilitaryPayslipProcessor] Calculated debits: \(calculatedDebits)")
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
            print("[MilitaryPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Extracts statement date from text
    private func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Look for "STATEMENT OF ACCOUNT FOR MM/YYYY" pattern
        if let dateValue = extractDateWithPattern("STATEMENT\\s+OF\\s+ACCOUNT\\s+FOR\\s+([0-9]{1,2})/([0-9]{4})", from: text) {
            return dateValue
        }
        
        // Alternative pattern: "Month Year" format
        if let dateValue = extractDateWithPattern("(January|February|March|April|May|June|July|August|September|October|November|December)\\s+([0-9]{4})", from: text) {
            return dateValue
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
            print("[MilitaryPayslipProcessor] Error extracting date with pattern \(pattern): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extracts name from text
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "Name:\\s*([A-Za-z\\s]+)",
            "(?:SERVICE|ARMY)\\s+NO\\s+&\\s+NAME[\\s:]*([A-Za-z\\s]+)"
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
            "A/C\\s+No\\s*[-:]\\s*([0-9/]+[A-Z]?)",
            "Account\\s+Number\\s*[-:]\\s*([0-9/]+[A-Z]?)"
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
            "PAN\\s+No\\s*[-:]\\s*([A-Z0-9*]+)",
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
            print("[MilitaryPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
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
        if let bpay = data["BPAY"] { earnings["BPAY"] = bpay }
        if let da = data["DA"] { earnings["DA"] = da }
        if let msp = data["MSP"] { earnings["MSP"] = msp }
        if let rh12 = data["RH12"] { earnings["RH12"] = rh12 }
        if let tpta = data["TPTA"] { earnings["TPTA"] = tpta }
        if let tptada = data["TPTADA"] { earnings["TPTADA"] = tptada }
        
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
        if let dsop = data["DSOP"] { deductions["DSOP"] = dsop }
        if let agif = data["AGIF"] { deductions["AGIF"] = agif }
        if let itax = data["ITAX"] { deductions["ITAX"] = itax }
        if let ehcess = data["EHCESS"] { deductions["EHCESS"] = ehcess }
        
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