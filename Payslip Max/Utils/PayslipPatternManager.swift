import Foundation

/// A utility class for extracting data from payslips using regex patterns.
///
/// This class provides methods for extracting various data points from payslip text
/// using regular expressions tailored to specific payslip formats.
class PayslipPatternManager {
    // MARK: - Main Patterns Dictionary
    
    /// Dictionary of regex patterns for extracting data from payslips.
    static var patterns: [String: String] = [
        // Personal Information
        "name": "Name:\\s*([A-Za-z\\s.]+?)\\s*(?:A\\s*)?$",
        "accountNumber": "(?:A\\/C\\s*No\\s*-\\s*|PCDA\\s*Account\\s*Number\\s*:?\\s*)([0-9\\-\\/A-Z]+)",
        "panNumber": "(?:PAN\\s*No:\\s*|PAN\\s*Number\\s*:?\\s*)([A-Z0-9\\*]+)",
        "statementPeriod": "(?:STATEMENT\\s*OF\\s*ACCOUNT\\s*FOR\\s*|Statement\\s*Period\\s*:?\\s*)([0-9\\/]+)",
        
        // Financial Information
        "grossPay": "(?:Gross\\s*Pay|कुल आय|Total\\s*Earnings)\\s*([0-9,]+)",
        "totalDeductions": "(?:Total\\s*Deductions|कुल कटौती)\\s*([0-9,]+)",
        "netRemittance": "(?:Net\\s*Remittance|Net\\s*Amount)\\s*:?\\s*(?:Rs\\.)?\\s*([\\-0-9,]+)",
        
        // Earnings
        "basicPay": "BPAY\\s*([0-9,]+)",
        "da": "DA\\s*([0-9,]+)",
        "msp": "MSP\\s*([0-9,]+)",
        "tpta": "TPTA\\s*([0-9,]+)",
        "tptada": "TPTADA\\s*([0-9,]+)",
        "arrDa": "ARR-DA\\s*([0-9,]+)",
        "arrSpcdo": "ARR-SPCDO\\s*([0-9,]+)",
        "arrTptada": "ARR-TPTADA\\s*([0-9,]+)",
        
        // Deductions
        "etkt": "ETKT\\s*([0-9,]+)",
        "fur": "FUR\\s*([0-9,]+)",
        "lf": "LF\\s*([0-9,]+)",
        "dsop": "DSOP\\s*([0-9,]+)",
        "agif": "AGIF\\s*([0-9,]+)",
        "itax": "ITAX\\s*([0-9,]+)",
        "ehcess": "EHCESS\\s*([0-9,]+)",
        
        // Income Tax Details
        "incomeTaxDeducted": "Income\\s*Tax\\s*Deducted\\s*([0-9,]+)",
        "edCessDeducted": "Ed\\.\\s*Cess\\s*Deducted\\s*([0-9,]+)",
        "totalTaxPayable": "Total\\s*Tax\\s*Payable\\s*([0-9,]+)",
        "grossSalary": "Gross\\s*Salary\\s*(?:upto|excluding)\\s*[0-9\\/]+\\s*(?:excluding\\s*HRA)?\\s*([0-9,]+)",
        "standardDeduction": "Standard\\s*Deduction\\s*([0-9,]+)",
        "netTaxableIncome": "Net\\s*Taxable\\s*Income\\s*\\([0-9]\\s*-\\s*[0-9]\\s*-\\s*[0-9]\\)\\s*([0-9,]+)",
        "assessmentYear": "Assessment\\s*Year\\s*([0-9\\-\\.]+)",
        "estimatedFutureSalary": "Estimated\\s*future\\s*Salary\\s*upto\\s*[0-9\\/]+\\s*([0-9,]+)",
        
        // DSOP Fund Details
        "dsopOpeningBalance": "Opening\\s*Balance\\s*([0-9,]+)",
        "dsopSubscription": "Subscription\\s*([0-9,]+)",
        "dsopMiscAdj": "Misc\\s*Adj\\s*([0-9,]+)",
        "dsopWithdrawal": "Withdrawal\\s*([0-9,]+)",
        "dsopRefund": "Refund\\s*([0-9,]+)",
        "dsopClosingBalance": "Closing\\s*Balance\\s*([0-9,]+)",
        
        // Contact Details
        "contactSAOLW": "SAO\\(LW\\)\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOLW": "AAO\\(LW\\)\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactSAOTW": "SAO\\(TW\\)\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOTW": "AAO\\(TW\\)\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactProCivil": "PRO\\s*CIVIL\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactProArmy": "PRO\\s*ARMY\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactWebsite": "Visit\\s*us\\s*:?\\s*(https?:\\/\\/[\\w\\.-]+\\.[a-z]{2,}(?:\\/[\\w\\.-]*)*)",
        "contactEmailTADA": "For\\s*TA\\/DA\\s*related\\s*matter\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailLedger": "For\\s*Ledger\\s*Section\\s*matter\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailRankPay": "For\\s*rank\\s*pay\\s*related\\s*matter\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailGeneral": "For\\s*other\\s*grievances\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})"
    ]
    
    // MARK: - Public Methods
    
    /// Adds a new pattern to the patterns dictionary.
    ///
    /// - Parameters:
    ///   - key: The key for the pattern.
    ///   - pattern: The regex pattern.
    static func addPattern(key: String, pattern: String) {
        patterns[key] = pattern
    }
    
    /// Extracts data from text using the patterns dictionary.
    ///
    /// - Parameter text: The text to extract data from.
    /// - Returns: A dictionary of extracted data.
    static func extractData(from text: String) -> [String: String] {
        var extractedData: [String: String] = [:]
        
        for (key, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    let value = nsString.substring(with: valueRange)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")
                    extractedData[key] = value
                    
                    // Debug print for name extraction
                    if key == "name" {
                        print("PayslipPatternManager: Extracted name: '\(value)' using pattern: '\(pattern)'")
                    }
                } else if key == "name" {
                    print("PayslipPatternManager: No match found for name using pattern: '\(pattern)'")
                }
            }
        }
        
        return extractedData
    }
    
    /// Extracts tabular data from text.
    ///
    /// - Parameter text: The text to extract data from.
    /// - Returns: A tuple containing earnings and deductions dictionaries.
    static func extractTabularData(from text: String) -> (earnings: [String: Double], deductions: [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Find the EARNINGS section
        if let earningsSectionRange = text.range(of: "(?:EARNINGS|आय|EARNINGS \\(₹\\))", options: .regularExpression) {
            let earningsText = String(text[earningsSectionRange.lowerBound...])
            
            // Pattern to match earnings table rows - more flexible to handle different formats
            let earningsPattern = "([A-Z\\-]+)\\s+([0-9,]+)"
            if let earningsRegex = try? NSRegularExpression(pattern: earningsPattern, options: []) {
                let nsString = earningsText as NSString
                let matches = earningsRegex.matches(in: earningsText, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 2 {
                        let keyRange = match.range(at: 1)
                        let valueRange = match.range(at: 2)
                        
                        let key = nsString.substring(with: keyRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        let valueString = nsString.substring(with: valueRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: ",", with: "")
                        
                        if let value = Double(valueString) {
                            earnings[key] = value
                        }
                    }
                }
            }
        }
        
        // Find the DEDUCTIONS section
        if let deductionsSectionRange = text.range(of: "(?:DEDUCTIONS|कटौती|DEDUCTIONS \\(₹\\))", options: .regularExpression) {
            let deductionsText = String(text[deductionsSectionRange.lowerBound...])
            
            // Pattern to match deductions table rows - more flexible to handle different formats
            let deductionsPattern = "([A-Z\\-]+)\\s+([0-9,]+)"
            if let deductionsRegex = try? NSRegularExpression(pattern: deductionsPattern, options: []) {
                let nsString = deductionsText as NSString
                let matches = deductionsRegex.matches(in: deductionsText, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 2 {
                        let keyRange = match.range(at: 1)
                        let valueRange = match.range(at: 2)
                        
                        let key = nsString.substring(with: keyRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        let valueString = nsString.substring(with: valueRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: ",", with: "")
                        
                        if let value = Double(valueString) {
                            deductions[key] = value
                        }
                    }
                }
            }
        }
        
        return (earnings, deductions)
    }
    
    /// Calculates total earnings from a dictionary of earnings.
    ///
    /// - Parameter earnings: The earnings dictionary.
    /// - Returns: The total earnings.
    static func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return earnings.values.reduce(0, +)
    }
    
    /// Calculates total deductions from a dictionary of deductions.
    ///
    /// - Parameter deductions: The deductions dictionary.
    /// - Returns: The total deductions.
    static func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return deductions.values.reduce(0, +)
    }
    
    /// Extracts the month name from a statement period.
    ///
    /// - Parameter statementPeriod: The statement period (e.g., "03/2024").
    /// - Returns: The month name.
    static func getMonthName(from statementPeriod: String) -> String {
        let months = ["January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December"]
        
        // Format is typically MM/YYYY
        let components = statementPeriod.components(separatedBy: "/")
        if components.count >= 1, let monthNumber = Int(components[0]), 
           monthNumber >= 1 && monthNumber <= 12 {
            return months[monthNumber - 1]
        }
        
        return "Unknown"
    }
    
    /// Extracts the year from a statement period.
    ///
    /// - Parameter statementPeriod: The statement period (e.g., "03/2024").
    /// - Returns: The year as a string.
    static func getYear(from statementPeriod: String) -> String {
        // Format is typically MM/YYYY
        let components = statementPeriod.components(separatedBy: "/")
        if components.count >= 2 {
            return components[1]
        }
        
        return String(Calendar.current.component(.year, from: Date()))
    }
    
    /// Creates a PayslipItem from extracted data.
    ///
    /// - Parameters:
    ///   - extractedData: The extracted data dictionary.
    ///   - earnings: The earnings dictionary.
    ///   - deductions: The deductions dictionary.
    ///   - pdfData: The PDF data.
    /// - Returns: A PayslipItem.
    static func createPayslipItem(from extractedData: [String: String], 
                                 earnings: [String: Double], 
                                 deductions: [String: Double],
                                 pdfData: Data?) -> PayslipItem {
        // Extract statement period
        let statementPeriod = extractedData["statementPeriod"] ?? ""
        let month = getMonthName(from: statementPeriod)
        let yearString = getYear(from: statementPeriod)
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Get name (no fallback to specific name)
        let name = extractedData["name"] ?? ""
        
        // Get credits (gross pay)
        var credits = Double(extractedData["grossPay"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
        
        // If no gross pay, calculate from individual earnings
        if credits == 0 {
            credits = calculateTotalEarnings(from: earnings)
            
            // If still 0, try to calculate from the earnings patterns
            if credits == 0 {
                credits = [
                    "basicPay", "da", "msp", "tpta", "tptada",
                    "arrDa", "arrSpcdo", "arrTptada"
                ].reduce(0.0) { total, key in
                    total + (Double(extractedData[key]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0)
                }
            }
        }
        
        // Get debits (total deductions)
        var debits = Double(extractedData["totalDeductions"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
        
        // If no total deductions, calculate from individual deductions
        if debits == 0 {
            debits = calculateTotalDeductions(from: deductions)
            
            // If still 0, try to calculate from the deductions patterns
            if debits == 0 {
                debits = [
                    "etkt", "fur", "lf", "agif", "ehcess"
                ].reduce(0.0) { total, key in
                    total + (Double(extractedData[key]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0)
                }
            }
        }
        
        // Get DSOP
        let dsop = Double(extractedData["dsop"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
        
        // Get tax
        let tax = Double(extractedData["itax"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
        
        // Create PayslipItem
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            location: "Pune",
            name: name,
            accountNumber: extractedData["accountNumber"] ?? "",
            panNumber: extractedData["panNumber"] ?? "",
            timestamp: Date(),
            pdfData: pdfData
        )
        
        // Add individual earnings
        if !earnings.isEmpty {
            payslip.earnings = earnings
        } else {
            // Use the extracted data if no tabular data was found
            payslip.earnings = [
                "Basic Pay": Double(extractedData["basicPay"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "DA": Double(extractedData["da"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "MSP": Double(extractedData["msp"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "TPTA": Double(extractedData["tpta"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "TPTADA": Double(extractedData["tptada"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "ARR-DA": Double(extractedData["arrDa"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "ARR-SPCDO": Double(extractedData["arrSpcdo"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "ARR-TPTADA": Double(extractedData["arrTptada"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
            ]
        }
        
        // Add individual deductions
        if !deductions.isEmpty {
            payslip.deductions = deductions
        } else {
            // Use the extracted data if no tabular data was found
            payslip.deductions = [
                "ETKT": Double(extractedData["etkt"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "FUR": Double(extractedData["fur"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "LF": Double(extractedData["lf"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "DSOP": dsop,
                "AGIF": Double(extractedData["agif"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0,
                "ITAX": tax,
                "EHCESS": Double(extractedData["ehcess"]?.replacingOccurrences(of: ",", with: "") ?? "0") ?? 0.0
            ]
        }
        
        return payslip
    }
} 