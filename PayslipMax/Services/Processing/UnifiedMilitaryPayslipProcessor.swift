import Foundation
import PDFKit

/// Unified processor for all defense personnel payslips (Military, PCDA, Army, Navy, Air Force)
/// This processor handles all formats used by Indian Armed Forces and eliminates the need for multiple processors
class UnifiedMilitaryPayslipProcessor: PayslipProcessorProtocol {
    
    // MARK: - Properties
    
    /// The format handled by this processor - now unified for all military formats
    var handlesFormat: PayslipFormat {
        return .military  // Handles military, pcda, and all defense formats
    }
    
    /// Military abbreviations service for terminology handling
    private let abbreviationsService = MilitaryAbbreviationsService.shared
    
    /// Pattern matching service for military-specific extraction patterns  
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes a new unified military payslip processor
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    /// Processes text from any defense personnel payslip (Military, PCDA, Army, Navy, Air Force)
    /// Extracts military-specific financial data (Basic Pay, MSP, DSOP, AGIF, HRA, DA)
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem representing the processed military payslip
    /// - Throws: An error if essential data cannot be determined
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UnifiedMilitaryPayslipProcessor] Processing defense payslip from \(text.count) characters")
        
        // Validate input
        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }
        
        // Use both modern pattern matching and legacy extraction for comprehensive parsing
        let (modernEarnings, modernDeductions) = patternMatchingService.extractTabularData(from: text)
        let legacyData = extractFinancialDataLegacy(from: text)
        
        // Merge and normalize all extracted data
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Process modern pattern matching results with military abbreviation normalization
        for (key, value) in modernEarnings {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            earnings[normalizedKey] = value
        }
        
        for (key, value) in modernDeductions {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            deductions[normalizedKey] = value
        }
        
        // Merge with legacy extraction (legacy takes precedence for military-specific fields)
        for (key, value) in legacyData {
            if key.contains("BPAY") || key.contains("BasicPay") {
                earnings["Basic Pay"] = value
            } else if key.contains("MSP") || key.contains("MilitaryServicePay") {
                earnings["Military Service Pay"] = value
            } else if key.contains("DA") || key.contains("DearnessAllowance") {
                earnings["Dearness Allowance"] = value
            } else if key.contains("HRA") {
                earnings["House Rent Allowance"] = value
            } else if key.contains("DSOP") {
                deductions["DSOP"] = value
            } else if key.contains("ITAX") || key.contains("IncomeTax") {
                deductions["Income Tax"] = value
            }
        }
        
        // Extract date information
        var month = ""
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateInfo = extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[UnifiedMilitaryPayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Fallback to current month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[UnifiedMilitaryPayslipProcessor] Using current date fallback: \(month) \(year)")
        }
        
        // Calculate totals
        let credits = earnings.values.reduce(0, +)
        let debits = deductions.values.reduce(0, +)
        let tax = deductions["Income Tax"] ?? deductions["ITAX"] ?? deductions["IT"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0
        
        // Extract personal information
        let name = extractName(from: text) ?? "Defense Personnel"
        let accountNumber = extractAccountNumber(from: text) ?? ""
        let panNumber = extractPANNumber(from: text) ?? ""
        
        print("[UnifiedMilitaryPayslipProcessor] Creating defense payslip - Credits: ₹\(credits), Debits: ₹\(debits), DSOP: ₹\(dsop)")
        
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
            pdfData: nil // Will be set by the processing pipeline
        )
        
        // Set detailed earnings and deductions
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions
        
        return payslipItem
    }
    
    /// Determines if the provided text represents any defense personnel payslip
    /// Unified confidence scoring for all military formats (Military, PCDA, Army, Navy, Air Force)
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A confidence score between 0.0 (unlikely) and 1.0 (likely)
    func canProcess(text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0
        
        // Military service indicators (high confidence)
        let militaryServiceKeywords = [
            "ARMY": 0.4,
            "NAVY": 0.4,
            "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5,
            "INDIAN NAVY": 0.5,
            "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3,
            "MILITARY": 0.3
        ]
        
        // PCDA and defense accounting indicators (high confidence)
        let pcdaKeywords = [
            "PCDA": 0.4,
            "PRINCIPAL CONTROLLER": 0.4,
            "DEFENCE ACCOUNTS": 0.4,
            "CONTROLLER OF DEFENCE ACCOUNTS": 0.5,
            "STATEMENT OF ACCOUNT": 0.3
        ]
        
        // Military-specific financial components (medium confidence) 
        let militaryFinancialKeywords = [
            "DSOP": 0.3,
            "DSOP FUND": 0.3,
            "AGIF": 0.2,
            "MSP": 0.2,
            "MILITARY SERVICE PAY": 0.3,
            "BPAY": 0.2,
            "BASIC PAY": 0.1,  // Lower since corporate also has this
            "SERVICE NO": 0.2,
            "RANK": 0.1
        ]
        
        // Calculate score based on all keyword categories
        let allKeywords = militaryServiceKeywords.merging(pcdaKeywords) { $0 + $1 }
            .merging(militaryFinancialKeywords) { $0 + $1 }
        
        for (keyword, weight) in allKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }
        
        // Bonus for multiple military indicators
        let militaryIndicatorCount = ["DSOP", "MSP", "AGIF", "PCDA", "ARMY", "NAVY", "AIR FORCE"].filter { 
            uppercaseText.contains($0) 
        }.count
        
        if militaryIndicatorCount >= 2 {
            score += 0.2  // Bonus for multiple military indicators
        }
        
        // Cap the score at 1.0
        score = min(score, 1.0)
        
        print("[UnifiedMilitaryPayslipProcessor] Defense format confidence score: \(score)")
        return score
    }
    
    // MARK: - Private Methods - Legacy Financial Data Extraction
    
    /// Legacy military financial data extraction using regex patterns from the original MilitaryPayslipProcessor
    /// This ensures we capture military-specific components that modern pattern matching might miss
    private func extractFinancialDataLegacy(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Military-specific patterns optimized for Indian Armed Forces payslips
        let militaryPatterns: [(key: String, regex: String)] = [
            // Basic Pay patterns
            ("BasicPay", "(?:BASIC\\s+PAY|BPAY)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Military Service Pay
            ("MSP", "(?:MSP|MILITARY\\s+SERVICE\\s+PAY)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Allowances
            ("DA", "(?:DA|DEARNESS\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("HRA", "(?:HRA|HOUSE\\s+RENT\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("TA", "(?:TA|TRANSPORT\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("KitMaintenance", "(?:KIT\\s+MAINTENANCE|UNIFORM\\s+ALLOWANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Military-specific funds and deductions
            ("DSOP", "(?:DSOP|DSOP\\s+FUND)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("AGIF", "(?:AGIF|ARMY\\s+GROUP\\s+INSURANCE)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("AFPF", "(?:AFPF|AIR\\s+FORCE\\s+PROVIDENT\\s+FUND)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Tax deductions
            ("ITAX", "(?:ITAX|INCOME\\s+TAX|IT)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Totals
            ("credits", "(?:GROSS\\s+EARNINGS|TOTAL\\s+EARNINGS|GROSS\\s+PAY)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("debits", "(?:GROSS\\s+DEDUCTIONS|TOTAL\\s+DEDUCTIONS)\\s*[:-]?\\s*(?:Rs\\.?|INR)?\\s*([0-9,.]+)")
        ]
        
        // Extract each value using the military-specific patterns
        for (key, pattern) in militaryPatterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[UnifiedMilitaryPayslipProcessor] Legacy extracted \(key): ₹\(value)")
            }
        }
        
        return extractedData
    }
    
    /// Helper function to extract numerical amount using regex pattern
    private func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                return Double(cleanValue)
            }
        } catch {
            print("[UnifiedMilitaryPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Extracts the payslip statement month and year from military payslip text
    private func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Military payslip date patterns
        let militaryDatePatterns = [
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})",
            "(?:STATEMENT\\s+FOR\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})",
            "(?:PAY\\s+ACCOUNT\\s+FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})"
        ]
        
        for pattern in militaryDatePatterns {
            if let dateValue = extractDateWithPattern(pattern, from: text) {
                return dateValue
            }
        }
        
        return nil
    }
    
    /// Helper to extract date with specific pattern
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
                    // If month is numeric, convert to name
                    if let monthNumber = Int(monthText), monthNumber >= 1 && monthNumber <= 12 {
                        let monthNames = ["January", "February", "March", "April", "May", "June",
                                        "July", "August", "September", "October", "November", "December"]
                        return (monthNames[monthNumber - 1], year)
                    } else {
                        // Month is already a name
                        return (monthText.capitalized, year)
                    }
                }
            }
        } catch {
            print("[UnifiedMilitaryPayslipProcessor] Error extracting date: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extracts service member name from military payslip
    private func extractName(from text: String) -> String? {
        let militaryNamePatterns = [
            "NAME\\s*[:-]\\s*([A-Za-z\\s.]+)",
            "SERVICE\\s+NO\\s*&\\s*NAME\\s*[:-]\\s*[A-Z0-9]+\\s+([A-Za-z\\s.]+)",
            "RANK\\s*&\\s*NAME\\s*[:-]\\s*[A-Za-z\\s]+\\s+([A-Za-z\\s.]+)"
        ]
        
        for pattern in militaryNamePatterns {
            if let name = extractStringWithPattern(pattern, from: text) {
                return name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Extracts account number from military payslip
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "ACCOUNT\\s+(?:NO|NUMBER)\\s*[:-]\\s*([0-9/]+[A-Z]*)",
            "A/C\\s+(?:NO|NUMBER)\\s*[:-]\\s*([0-9/]+[A-Z]*)",
            "BANK\\s+A/C\\s*[:-]\\s*([0-9/]+[A-Z]*)"
        ]
        
        for pattern in accountPatterns {
            if let account = extractStringWithPattern(pattern, from: text) {
                return account.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Extracts PAN number from military payslip
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "PAN\\s+(?:NO|NUMBER)\\s*[:-]\\s*([A-Z0-9*]+)",
            "PAN\\s*[:-]\\s*([A-Z0-9*]+)"
        ]
        
        for pattern in panPatterns {
            if let pan = extractStringWithPattern(pattern, from: text) {
                return pan.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Helper to extract string with specific pattern
    private func extractStringWithPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                return nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("[UnifiedMilitaryPayslipProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
}
