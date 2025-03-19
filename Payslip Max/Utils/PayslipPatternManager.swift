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
        "name": "(?:Name|Employee\\s*Name|Name\\s*of\\s*Employee)\\s*:?\\s*([A-Za-z\\s.]+?)\\s*(?:A\\s*)?$",
        "accountNumber": "(?:A\\/C\\s*No\\s*-\\s*|PCDA\\s*Account\\s*Number\\s*:?\\s*|A\\/C\\s*No\\s*:?\\s*|Account\\s*Number\\s*:?\\s*)([0-9\\-\\/A-Z]+)",
        "panNumber": "(?:PAN\\s*No:\\s*|PAN\\s*Number\\s*:?\\s*|PAN\\s*:?\\s*)([A-Z0-9\\*]+)",
        "statementPeriod": "(?:STATEMENT\\s*OF\\s*ACCOUNT\\s*FOR\\s*|Statement\\s*Period\\s*:?\\s*|For\\s*the\\s*month\\s*of\\s*|Month\\s*of\\s*)([0-9\\/]+|[A-Za-z]+\\s*[0-9]{4})",
        
        // Financial Information
        "grossPay": "(?:Gross\\s*Pay|कुल आय|Total\\s*Earnings|TOTAL\\s*EARNINGS)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "totalDeductions": "(?:Total\\s*Deductions|कुल कटौती|TOTAL\\s*DEDUCTIONS)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "netRemittance": "(?:Net\\s*Remittance|Net\\s*Amount|NET\\s*AMOUNT)\\s*:?\\s*(?:Rs\\.)?\\s*([\\-0-9,]+)",
        
        // Earnings
        "basicPay": "(?:BPAY|Basic\\s*Pay|BASIC\\s*PAY)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "da": "(?:DA|Dearness\\s*Allowance|D\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "msp": "(?:MSP|Military\\s*Service\\s*Pay)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "tpta": "(?:TPTA|Transport\\s*Allowance|T\\.P\\.T\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "tptada": "(?:TPTADA|Transport\\s*DA|T\\.P\\.T\\.A\\.\\s*DA)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "arrDa": "(?:ARR-DA|DA\\s*Arrears)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "arrSpcdo": "(?:ARR-SPCDO|SPCDO\\s*Arrears)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "arrTptada": "(?:ARR-TPTADA|TPTADA\\s*Arrears)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "hra": "(?:HRA|House\\s*Rent\\s*Allowance|H\\.R\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        
        // Deductions
        "etkt": "(?:ETKT|E-Ticket\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "fur": "(?:FUR|Furniture\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "lf": "(?:LF|License\\s*Fee)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsop": "(?:DSOP|DSOP\\s*Fund|Provident\\s*Fund|PF)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "agif": "(?:AGIF|Army\\s*Group\\s*Insurance\\s*Fund)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "itax": "(?:ITAX|Income\\s*Tax|I\\.Tax)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "ehcess": "(?:EHCESS|Education\\s*Health\\s*Cess)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        
        // Income Tax Details
        "incomeTaxDeducted": "(?:Income\\s*Tax\\s*Deducted|TDS)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "edCessDeducted": "(?:Ed\\.\\s*Cess\\s*Deducted|Education\\s*Cess)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "totalTaxPayable": "(?:Total\\s*Tax\\s*Payable|Tax\\s*Payable)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "grossSalary": "(?:Gross\\s*Salary|Gross\\s*Income)\\s*(?:upto|excluding)\\s*[0-9\\/]+\\s*(?:excluding\\s*HRA)?\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "standardDeduction": "(?:Standard\\s*Deduction)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "netTaxableIncome": "(?:Net\\s*Taxable\\s*Income|Taxable\\s*Income)\\s*\\([0-9]\\s*-\\s*[0-9]\\s*-\\s*[0-9]\\)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "assessmentYear": "(?:Assessment\\s*Year)\\s*([0-9\\-\\.]+)",
        "estimatedFutureSalary": "(?:Estimated\\s*future\\s*Salary)\\s*upto\\s*[0-9\\/]+\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        
        // DSOP Fund Details
        "dsopOpeningBalance": "(?:Opening\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopSubscription": "(?:Subscription|Monthly\\s*Contribution)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopMiscAdj": "(?:Misc\\s*Adj|Miscellaneous\\s*Adjustment)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopWithdrawal": "(?:Withdrawal)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopRefund": "(?:Refund)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopClosingBalance": "(?:Closing\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        
        // Location
        "location": "(?:Location|Place|Office|Branch|Work\\s*Location)\\s*:?\\s*([A-Za-z\\s]+)",
        
        // Contact Details
        "contactSAOLW": "(?:SAO\\(LW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOLW": "(?:AAO\\(LW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactSAOTW": "(?:SAO\\(TW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOTW": "(?:AAO\\(TW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactProCivil": "(?:PRO\\s*CIVIL)\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactProArmy": "(?:PRO\\s*ARMY)\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactWebsite": "(?:Visit\\s*us)\\s*:?\\s*(https?:\\/\\/[\\w\\.-]+\\.[a-z]{2,}(?:\\/[\\w\\.-]*)*)",
        "contactEmailTADA": "(?:For\\s*TA\\/DA\\s*related\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailLedger": "(?:For\\s*Ledger\\s*Section\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailRankPay": "(?:For\\s*rank\\s*pay\\s*related\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailGeneral": "(?:For\\s*other\\s*grievances)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})"
    ]
    
    // MARK: - Standard Components and Thresholds
    
    /// Standard earnings components for categorization
    static let standardEarningsComponents = [
        // Basic Pay and Allowances
        "BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA",
        // Special Allowances
        "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA", "HADA", 
        "HAUTA", "MISC", "NPA", "OTA", "PMA", "SDA", "SPLAL", "SPLDA",
        // Arrears
        "ARR-BPAY", "ARR-DA", "ARR-HRA", "ARR-MSP", "ARR-TA", "ARR-TPTA", "ARR-TPTADA",
        // Risk & Hardship Allowances
        "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
        // Dress Allowances
        "DRESALW", "SPCDO"
    ]
    
    /// Standard deductions components for categorization
    static let standardDeductionsComponents = [
        // Mandatory Deductions
        "DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS",
        // Housing and Utilities
        "FUR", "LF", "WATER", "ELEC", "EHCESS", "RENT", "ACCM", "QTRS",
        // Loans and Advances
        "ADVHBA", "ADVCP", "ADVFES", "ADVMCA", "ADVPF", "ADVSCTR", "LOAN", "LOANS",
        // Insurance and Funds
        "AFMSD", "AOBF", "AOCBF", "AOCSF", "AWHO", "AWWA", "DESA", "ECHS", "NGIF",
        // Recoveries and Miscellaneous
        "SPCDO", "ARR-RSHNA", "RSHNA", "TR", "UPTO", "MP", "MESS", "CLUB", "AFTI",
        // Specific Deductions
        "AAO", "AFPP", "AFWWA", "ARMY", "CSD", "CST", "IAFBA", "IAFCL", "IAFF", "IAFWWA",
        "NAVY", "NWWA", "PBOR", "PNBHFL", "POSB", "RSHNA", "SAO", "SBICC", "SBIL", "SBIPL",
        // E-Ticket
        "ETKT"
    ]
    
    /// Terms that should never be considered as pay items (blacklist)
    static let blacklistedTerms = [
        // Headers and Sections
        "STATEMENT", "CONTACT", "DEDUCTIONS", "EARNINGS", "TOTAL", "DETAILS", "SECTION", "PAGE",
        "SUMMARY", "BREAKDOWN", "ACCOUNT", "PERIOD", "MONTH", "YEAR", "DATE", "PAYSLIP",
        // Roman Numerals and Numbering
        "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
        // Contact and Administrative Terms
        "PAN", "SAO", "AAO", "PRO", "DI", "RL", "IT", "PCDA", "CDA", "OFFICE", "BRANCH",
        "DAK", "UPTO", "LOANS", "WATER", "INCOME", "HRA",
        // Miscellaneous Non-Financial Terms
        "NAME", "RANK", "UNIT", "LOCATION", "ADDRESS", "PHONE", "EMAIL", "WEBSITE", "CONTACT",
        // Table Headers
        "SI", "NO", "FROM", "TO", "BILL", "PAY", "CODE", "TYPE", "AMT", "PRINCIPAL",
        "INT", "BALANCE", "CUR", "INST", "DESCRIPTION", "AMOUNT",
        // Additional terms that might cause confusion
        "GROSS", "NET", "RECOVERY", "ARREAR", "ARREARS", "CLOSING", "OPENING", "SUBSCRIPTION",
        "WITHDRAWAL", "REFUND", "MISC", "ADJ", "ADJUSTMENT", "CURRENT", "PREVIOUS", "NEXT",
        "ASSESSMENT", "TAXABLE", "STANDARD", "FUTURE", "SALARY", "PROPERTY", "SOURCE", "HOUSE",
        "SURCHARGE", "CESS", "DEDUCTED", "PAYABLE", "EXCLUDING", "INCLUDING", "ESTIMATED"
    ]
    
    /// Context-specific blacklisted terms (terms that should be blacklisted only in specific contexts)
    static let contextSpecificBlacklist: [String: [String]] = [
        "earnings": ["DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS", "EHCESS", "RSHNA", "FUR", "LF"],
        "deductions": ["BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA", "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA"]
    ]
    
    /// Patterns to identify merged codes (e.g., "3600DSOP")
    static let mergedCodePatterns: [String: String] = [
        "numericPrefix": "^(\\d+)(\\D+)$",  // e.g., "3600DSOP"
        "abbreviationPrefix": "^([A-Z]{2,4})-(\\d+)$"  // e.g., "ARR-RSHNA"
    ]
    
    /// Minimum valid earnings amount
    static let minimumEarningsAmount: Double = 100.0
    
    /// Minimum valid deductions amount (lower to catch small deductions)
    static let minimumDeductionsAmount: Double = 10.0
    
    /// Minimum valid DSOP amount (to filter out small values that might be confused with DSOP)
    static let minimumDSOPAmount: Double = 1000.0
    
    /// Minimum valid tax amount
    static let minimumTaxAmount: Double = 1000.0
    
    // MARK: - Public Methods
    
    /// Adds a new pattern to the patterns dictionary.
    ///
    /// - Parameters:
    ///   - key: The key for the pattern.
    ///   - pattern: The regex pattern.
    static func addPattern(key: String, pattern: String) {
        patterns[key] = pattern
    }
    
    /// Checks if a term is blacklisted in a specific context
    ///
    /// - Parameters:
    ///   - term: The term to check
    ///   - context: The context (e.g., "earnings" or "deductions")
    /// - Returns: True if the term is blacklisted in the given context
    static func isBlacklisted(_ term: String, in context: String) -> Bool {
        // Check global blacklist
        if blacklistedTerms.contains(term) {
            return true
        }
        
        // Check context-specific blacklist
        if let contextBlacklist = contextSpecificBlacklist[context], contextBlacklist.contains(term) {
            return true
        }
        
        return false
    }
    
    /// Attempts to extract a clean code from a potentially merged code
    ///
    /// - Parameter code: The code to clean
    /// - Returns: A tuple containing the cleaned code and any extracted value
    static func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        // Check for numeric prefix pattern (e.g., "3600DSOP")
        if let regex = try? NSRegularExpression(pattern: mergedCodePatterns["numericPrefix"]!, options: []),
           let match = regex.firstMatch(in: code, options: [], range: NSRange(code.startIndex..., in: code)),
           match.numberOfRanges == 3,
           let valueRange = Range(match.range(at: 1), in: code),
           let codeRange = Range(match.range(at: 2), in: code) {
            
            let valueStr = String(code[valueRange])
            let cleanedCode = String(code[codeRange])
            
            if let value = Double(valueStr) {
                return (cleanedCode, value)
            }
        }
        
        // Check for abbreviation prefix pattern (e.g., "ARR-RSHNA")
        if let regex = try? NSRegularExpression(pattern: mergedCodePatterns["abbreviationPrefix"]!, options: []),
           let match = regex.firstMatch(in: code, options: [], range: NSRange(code.startIndex..., in: code)),
           match.numberOfRanges == 3,
           let prefixRange = Range(match.range(at: 1), in: code),
           let valueRange = Range(match.range(at: 2), in: code) {
            
            let prefix = String(code[prefixRange])
            let valueStr = String(code[valueRange])
            
            if let value = Double(valueStr) {
                return (prefix, value)
            }
        }
        
        // If no pattern matches, return the original code
        return (code, nil)
    }
    
    /// Extracts data from text using the patterns dictionary.
    ///
    /// - Parameter text: The text to extract data from.
    /// - Returns: A dictionary of extracted data.
    static func extractData(from text: String) -> [String: String] {
        var extractedData: [String: String] = [:]
        
        // Normalize the text by removing excessive whitespace
        let normalizedText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        for (key, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsString = normalizedText as NSString
                let matches = regex.matches(in: normalizedText, options: [], range: NSRange(location: 0, length: nsString.length))
                
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
        
        // Special handling for PAN number - direct pattern match
        if extractedData["panNumber"] == nil {
            if let panMatch = normalizedText.range(of: "[A-Z]{5}[0-9]{4}[A-Z]{1}", options: .regularExpression) {
                let pan = String(normalizedText[panMatch])
                extractedData["panNumber"] = pan
                print("PayslipPatternManager: Extracted PAN using direct pattern: \(pan)")
            }
        }
        
        // Special handling for statement period - try to extract month and year
        if extractedData["statementPeriod"] == nil {
            // Try to find month names
            let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            
            // Check for month name followed by year
            for monthName in monthNames {
                if let monthYearMatch = normalizedText.range(of: "\(monthName)\\s+\\d{4}", options: [.regularExpression, .caseInsensitive]) {
                    extractedData["statementPeriod"] = String(normalizedText[monthYearMatch])
                    print("PayslipPatternManager: Extracted statement period using month name: \(extractedData["statementPeriod"]!)")
                    break
                }
            }
            
            // Check for short month name followed by year
            if extractedData["statementPeriod"] == nil {
                for shortName in shortMonthNames {
                    if let monthYearMatch = normalizedText.range(of: "\(shortName)\\s+\\d{4}", options: [.regularExpression, .caseInsensitive]) {
                        extractedData["statementPeriod"] = String(normalizedText[monthYearMatch])
                        print("PayslipPatternManager: Extracted statement period using short month name: \(extractedData["statementPeriod"]!)")
                        break
                    }
                }
            }
            
            // Check for MM/YYYY format
            if extractedData["statementPeriod"] == nil {
                if let dateMatch = normalizedText.range(of: "\\b(0?[1-9]|1[0-2])[/\\-](20\\d{2})\\b", options: .regularExpression) {
                    extractedData["statementPeriod"] = String(normalizedText[dateMatch])
                    print("PayslipPatternManager: Extracted statement period using MM/YYYY format: \(extractedData["statementPeriod"]!)")
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
        
        // Normalize the text by removing excessive whitespace
        let normalizedText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Find the EARNINGS and DEDUCTIONS sections
        let earningsSectionPatterns = ["EARNINGS", "आय", "EARNINGS \\(₹\\)", "PAY AND ALLOWANCES", "Description\\s+Amount"]
        let deductionsSectionPatterns = ["DEDUCTIONS", "कटौती", "DEDUCTIONS \\(₹\\)", "RECOVERIES", "Description\\s+Amount"]
        
        // Extract earnings
        var earningsText = ""
        for pattern in earningsSectionPatterns {
            if let range = normalizedText.range(of: pattern, options: .regularExpression) {
                earningsText = String(normalizedText[range.lowerBound...])
                break
            }
        }
        
        // Extract deductions
        var deductionsText = ""
        for pattern in deductionsSectionPatterns {
            if let range = normalizedText.range(of: pattern, options: .regularExpression) {
                deductionsText = String(normalizedText[range.lowerBound...])
                break
            }
        }
        
        // If we found both sections, limit earnings text to end before deductions
        if !earningsText.isEmpty && !deductionsText.isEmpty {
            if let deductionsRange = earningsText.range(of: "DEDUCTIONS|कटौती|DEDUCTIONS \\(₹\\)|RECOVERIES", options: .regularExpression) {
                earningsText = String(earningsText[..<deductionsRange.lowerBound])
            }
        }
        
        // More robust pattern to match table rows with code and amount
        // This pattern looks for a code (uppercase letters with possible hyphens) 
        // followed by a numeric value, with possible whitespace or other characters in between
        let tableRowPattern = "([A-Z][A-Z\\-]+)\\s*[^0-9]*\\s*([0-9,.]+)"
        
        // Temporary dictionary to collect all extracted values
        var allExtractedValues: [String: Double] = [:]
        
        // Process earnings section
        if !earningsText.isEmpty {
            let earningsMatches = earningsText.matches(for: tableRowPattern)
            for match in earningsMatches {
                if match.count >= 3 {
                    let code = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let amountStr = match[2].replacingOccurrences(of: ",", with: "")
                    
                    if let amount = Double(amountStr), amount > 1 {
                        allExtractedValues[code] = amount
                    }
                }
            }
        }
        
        // Process deductions section
        if !deductionsText.isEmpty {
            let deductionsMatches = deductionsText.matches(for: tableRowPattern)
            for match in deductionsMatches {
                if match.count >= 3 {
                    let code = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let amountStr = match[2].replacingOccurrences(of: ",", with: "")
                    
                    if let amount = Double(amountStr), amount > 1 {
                        allExtractedValues[code] = amount
                    }
                }
            }
        }
        
        // Alternative approach: Look for specific patterns in the entire text
        // This helps when the tabular format isn't clearly defined
        let specificCodePattern = "([A-Z][A-Z\\-]+)\\s*[^0-9]*\\s*([0-9,.]+)"
        let specificMatches = normalizedText.matches(for: specificCodePattern)
        
        for match in specificMatches {
            if match.count >= 3 {
                let code = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr = match[2].replacingOccurrences(of: ",", with: "")
                
                if let amount = Double(amountStr), amount > 1 {
                    allExtractedValues[code] = amount
                }
            }
        }
        
        // Look for two-column format (common in Indian payslips)
        // This pattern looks for "Description Amount Description Amount" format
        let twoColumnPattern = "([A-Z][A-Z\\-]+)\\s+([0-9,.]+)\\s+([A-Z][A-Z\\-]+)\\s+([0-9,.]+)"
        let twoColumnMatches = normalizedText.matches(for: twoColumnPattern)
        
        for match in twoColumnMatches {
            if match.count >= 5 {
                // First column
                let code1 = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr1 = match[2].replacingOccurrences(of: ",", with: "")
                
                // Second column
                let code2 = match[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr2 = match[4].replacingOccurrences(of: ",", with: "")
                
                if let amount1 = Double(amountStr1), amount1 > 1 {
                    allExtractedValues[code1] = amount1
                }
                
                if let amount2 = Double(amountStr2), amount2 > 1 {
                    allExtractedValues[code2] = amount2
                }
            }
        }
        
        // Now categorize all extracted values based on standard components
        for (code, value) in allExtractedValues {
            // Skip blacklisted terms
            if isBlacklisted(code, in: "earnings") {
                print("PayslipPatternManager: Skipping blacklisted term \(code)")
                continue
            }
            
            // Apply appropriate thresholds based on component type
            if standardEarningsComponents.contains(code) {
                // This is a standard earnings component - apply earnings threshold
                if value >= minimumEarningsAmount {
                    earnings[code] = value
                    print("PayslipPatternManager: Categorized \(code) as earnings with amount \(value)")
                } else {
                    print("PayslipPatternManager: Skipping earnings \(code) with amount \(value) below threshold \(minimumEarningsAmount)")
                }
            } else if standardDeductionsComponents.contains(code) {
                // This is a standard deductions component - apply deductions threshold
                if value >= minimumDeductionsAmount {
                    deductions[code] = value
                    print("PayslipPatternManager: Categorized \(code) as deductions with amount \(value)")
                } else {
                    print("PayslipPatternManager: Skipping deduction \(code) with amount \(value) below threshold \(minimumDeductionsAmount)")
                }
            } else {
                // For non-standard components, we'll ignore them
                print("PayslipPatternManager: Ignoring unknown code \(code) with amount \(value)")
            }
        }
        
        // Final validation: ensure standard components are in the correct category
        for component in standardEarningsComponents {
            if let value = deductions[component] {
                // Move from deductions to earnings
                earnings[component] = value
                deductions.removeValue(forKey: component)
                print("PayslipPatternManager: Moved standard earnings component \(component) from deductions to earnings")
            }
        }
        
        for component in standardDeductionsComponents {
            if let value = earnings[component] {
                // Move from earnings to deductions
                deductions[component] = value
                earnings.removeValue(forKey: component)
                print("PayslipPatternManager: Moved standard deductions component \(component) from earnings to deductions")
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
        let shortMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Check for month name in the statement period
        for (index, month) in months.enumerated() {
            if statementPeriod.contains(month) {
                return months[index]
            }
        }
        
        // Check for short month name
        for (index, shortMonth) in shortMonths.enumerated() {
            if statementPeriod.contains(shortMonth) {
                return months[index]
            }
        }
        
        // Format is typically MM/YYYY
        let components = statementPeriod.components(separatedBy: CharacterSet(charactersIn: "/-"))
        if components.count >= 1, let monthNumber = Int(components[0]), 
           monthNumber >= 1 && monthNumber <= 12 {
            return months[monthNumber - 1]
        }
        
        // Check for YYYY-MM-DD format
        if components.count >= 3, let monthNumber = Int(components[1]),
           monthNumber >= 1 && monthNumber <= 12 {
            return months[monthNumber - 1]
        }
        
        return "Unknown"
    }
    
    /// Extracts the year from a statement period string.
    /// - Parameter statementPeriod: The statement period string.
    /// - Returns: The year as an integer.
    static func getYear(from statementPeriod: String) -> Int {
        // Check for YYYY-MM format
        if statementPeriod.contains("-") {
            let components = statementPeriod.split(separator: "-")
            if components.count >= 1, let year = Int(components[0]) {
                return year
            }
        }
        
        // Check for MM/YYYY format
        if statementPeriod.contains("/") {
            let components = statementPeriod.split(separator: "/")
            if components.count >= 2, let year = Int(components[1]) {
                return year
            }
        }
        
        // Default to current year if no match
        return Calendar.current.component(.year, from: Date())
    }
    
    /// Helper method to extract numeric value from a string that might contain currency symbols or commas
    /// - Parameter string: The string to extract a numeric value from
    /// - Returns: The extracted Double value, or nil if extraction fails
    static func extractNumericValue(from string: String) -> Double? {
        // Remove currency symbols, commas, and other non-numeric characters except decimal point
        let cleanedString = string.replacingOccurrences(of: "[$,]", with: "", options: .regularExpression)
        return Double(cleanedString)
    }
    
    /// Creates a PayslipItem from extracted data.
    ///
    /// - Parameters:
    ///   - extractedData: The extracted data dictionary.
    ///   - earnings: The earnings dictionary.
    ///   - deductions: The deductions dictionary.
    ///   - pdfData: The PDF data.
    /// - Returns: A PayslipItem.
    static func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        // Validate and clean the extracted data
        let validatedEarnings = validateFinancialData(earnings)
        let validatedDeductions = validateFinancialData(deductions)
        
        // Extract month and year from statement period
        var month = "Unknown"
        var year = Calendar.current.component(.year, from: Date())
        
        if let statementPeriod = extractedData["statementPeriod"] {
            month = getMonthName(from: statementPeriod)
            year = getYear(from: statementPeriod)
        } else if let extractedMonth = extractedData["month"], !extractedMonth.isEmpty {
            month = extractedMonth
            if let extractedYear = extractedData["year"], let yearInt = Int(extractedYear) {
                year = yearInt
            }
        }
        
        // Check if we have special military payslip keys
        let credits: Double
        let debits: Double
        var dsop: Double = 0.0
        var tax: Double = 0.0
        
        // Use special military keys if available, otherwise calculate from dictionaries
        if let militaryCredits = validatedEarnings["__CREDITS_TOTAL"] {
            // Use the special military total
            credits = militaryCredits
            print("PayslipPatternManager: Using military credits total: \(credits)")
        } else {
            // Calculate credits from all earnings
            credits = validatedEarnings.values.reduce(0, +)
            print("PayslipPatternManager: Calculated credits total: \(credits)")
        }
        
        if let militaryDebits = validatedDeductions["__DEBITS_TOTAL"] {
            // Use the special military total
            debits = militaryDebits
            print("PayslipPatternManager: Using military debits total: \(debits)")
        } else {
            // Calculate debits from all deductions
            debits = validatedDeductions.values.reduce(0, +)
            print("PayslipPatternManager: Calculated debits total: \(debits)")
        }
        
        // First check for pattern extracted values
        if let dsopStr = extractedData["dsop"], let dsopValue = Double(dsopStr), dsopValue >= minimumDSOPAmount {
            dsop = dsopValue
            print("PayslipPatternManager: Using pattern-extracted DSOP value: \(dsop)")
        } else if let dsopSubscriptionStr = extractedData["dsopSubscription"], let dsopValue = Double(dsopSubscriptionStr), dsopValue >= minimumDSOPAmount {
            dsop = dsopValue
            print("PayslipPatternManager: Using DSOP subscription value: \(dsop)")
        } else if let militaryDsop = validatedDeductions["__DSOP_TOTAL"], militaryDsop >= minimumDSOPAmount {
            // Use the special military DSOP value if it's large enough
            dsop = militaryDsop
            print("PayslipPatternManager: Using military DSOP total: \(dsop)")
        } else if let deductionDsop = validatedDeductions["DSOP"], deductionDsop >= minimumDSOPAmount {
            // Use the deductions DSOP field if available and large enough
            dsop = deductionDsop
            print("PayslipPatternManager: Using deductions DSOP value: \(dsop)")
        } else if let earningDsop = validatedEarnings["DSOP"], earningDsop >= minimumDSOPAmount {
            // If DSOP was incorrectly categorized as earnings, use it anyway
            dsop = earningDsop
            print("PayslipPatternManager: Using earnings DSOP value (incorrectly categorized): \(dsop)")
        }
        
        // Similar approach for tax
        if let itaxStr = extractedData["itax"], let itaxValue = Double(itaxStr), itaxValue >= minimumTaxAmount {
            tax = itaxValue
            print("PayslipPatternManager: Using pattern-extracted ITAX value: \(tax)")
        } else if let incomeTaxStr = extractedData["incomeTaxDeducted"], let taxValue = Double(incomeTaxStr), taxValue >= minimumTaxAmount {
            tax = taxValue
            print("PayslipPatternManager: Using income tax deducted value: \(tax)")
        } else if let militaryTax = validatedDeductions["__TAX_TOTAL"], militaryTax >= minimumTaxAmount {
            // Use the special military tax value if it's large enough
            tax = militaryTax
            print("PayslipPatternManager: Using military tax total: \(tax)")
        } else if let deductionTax = validatedDeductions["ITAX"], deductionTax >= minimumTaxAmount {
            // Use the deductions ITAX field if available
            tax = deductionTax
            print("PayslipPatternManager: Using deductions ITAX value: \(tax)")
        } else if let earningTax = validatedEarnings["ITAX"], earningTax >= minimumTaxAmount {
            // If ITAX was incorrectly categorized as earnings, use it anyway
            tax = earningTax
            print("PayslipPatternManager: Using earnings ITAX value (incorrectly categorized): \(tax)")
        }
        
        // Double-check with debug log the final values we're using
        print("PayslipPatternManager: Final values - Credits: \(credits), Debits: \(debits), DSOP: \(dsop), Tax: \(tax)")
        
        // Create a PayslipItem
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            location: extractedData["location"] ?? "Unknown",
            name: extractedData["name"] ?? "Unknown",
            accountNumber: extractedData["accountNumber"] ?? "Unknown",
            panNumber: extractedData["panNumber"] ?? "Unknown",
            pdfData: pdfData
        )
        
        // Remove special keys before setting earnings and deductions
        var cleanEarnings = validatedEarnings
        cleanEarnings.removeValue(forKey: "__CREDITS_TOTAL")
        
        var cleanDeductions = validatedDeductions
        cleanDeductions.removeValue(forKey: "__DEBITS_TOTAL")
        cleanDeductions.removeValue(forKey: "__DSOP_TOTAL")
        cleanDeductions.removeValue(forKey: "__TAX_TOTAL")
        
        // Set earnings and deductions
        payslip.earnings = cleanEarnings
        payslip.deductions = cleanDeductions
        
        return payslip
    }
    
    /// Validates financial data to ensure values are reasonable.
    ///
    /// - Parameter data: The financial data to validate.
    /// - Returns: Validated financial data.
    static func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        var validatedData: [String: Double] = [:]
        
        for (key, value) in data {
            // Skip values that are too small (likely errors)
            if value < 2 {
                print("PayslipPatternManager: Skipping \(key) with value \(value) as it's too small")
                continue
            }
            
            // Skip values that are unreasonably large (likely errors)
            if value > 10_000_000 {
                print("PayslipPatternManager: Skipping \(key) with value \(value) as it's too large")
                continue
            }
            
            // Add the validated value
            validatedData[key] = value
        }
        
        return validatedData
    }
    
    /// Integrates with the AbbreviationManager to categorize unknown abbreviations
    ///
    /// - Parameters:
    ///   - abbreviation: The abbreviation to categorize
    ///   - value: The value associated with the abbreviation
    ///   - abbreviationManager: The abbreviation manager instance
    /// - Returns: The type of the abbreviation (earning or deduction)
    static func categorizeAbbreviation(_ abbreviation: String, 
                                      value: Double, 
                                      abbreviationManager: AbbreviationManager) -> AbbreviationManager.AbbreviationType {
        // First check if it's already known
        let type = abbreviationManager.getType(for: abbreviation)
        if type != .unknown {
            return type
        }
        
        // Track the unknown abbreviation
        abbreviationManager.trackUnknownAbbreviation(abbreviation, value: value)
        
        // Use heuristics to guess the type
        // Common earnings prefixes/keywords
        let earningsKeywords = ["PAY", "ALLOW", "BONUS", "ARREAR", "ARR", "SALARY", "WAGE", "STIPEND", "GRANT"]
        
        // Common deductions prefixes/keywords
        let deductionsKeywords = ["TAX", "FUND", "RECOVERY", "FEE", "CHARGE", "DEDUCT", "LOAN", "ADVANCE", "SUBSCRIPTION"]
        
        // Check if the abbreviation contains any earnings keywords
        for keyword in earningsKeywords {
            if abbreviation.contains(keyword) {
                return .earning
            }
        }
        
        // Check if the abbreviation contains any deductions keywords
        for keyword in deductionsKeywords {
            if abbreviation.contains(keyword) {
                return .deduction
            }
        }
        
        // Default to unknown
        return .unknown
    }
    
    // MARK: - Helper Methods
    
    /// Get description for Risk & Hardship components
    ///
    /// - Parameter code: The component code (e.g., "RH11", "RH23")
    /// - Returns: A human-readable description of the Risk & Hardship component, or nil if not a valid RH code
    static func getRiskHardshipDescription(for code: String) -> String? {
        // Check if this is a Risk & Hardship component
        guard code.hasPrefix("RH"), code.count == 4 else {
            return nil
        }
        
        // Extract risk and hardship levels
        guard let riskLevel = Int(String(code[code.index(code.startIndex, offsetBy: 2)])),
              let hardshipLevel = Int(String(code[code.index(code.startIndex, offsetBy: 3)])),
              riskLevel >= 1 && riskLevel <= 3,
              hardshipLevel >= 1 && hardshipLevel <= 3 else {
            return nil
        }
        
        // Generate description
        let riskDesc: String
        switch riskLevel {
        case 1: riskDesc = "High Risk"
        case 2: riskDesc = "Medium Risk"
        case 3: riskDesc = "Lower Risk"
        default: riskDesc = "Unknown Risk"
        }
        
        let hardshipDesc: String
        switch hardshipLevel {
        case 1: hardshipDesc = "High Hardship"
        case 2: hardshipDesc = "Medium Hardship"
        case 3: hardshipDesc = "Lower Hardship"
        default: hardshipDesc = "Unknown Hardship"
        }
        
        return "Risk & Hardship Allowance (\(riskDesc), \(hardshipDesc))"
    }
}

// Add this extension to String for regex matching
extension String {
    func matches(for regex: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            
            return results.map { result in
                var matches: [String] = []
                // Add the entire match
                if let range = Range(result.range, in: self) {
                    matches.append(String(self[range]))
                }
                
                // Add each capture group
                for i in 1..<result.numberOfRanges {
                    if let range = Range(result.range(at: i), in: self) {
                        matches.append(String(self[range]))
                    } else {
                        matches.append("")
                    }
                }
                return matches
            }
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
} 
