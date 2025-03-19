import Foundation
import PDFKit

/// Default implementation of the PDFExtractorProtocol.
///
/// This class provides a basic implementation of PDF data extraction
/// for payslip documents.
class DefaultPDFExtractor: PDFExtractorProtocol {
    // MARK: - Properties
    
    private let enhancedParser: EnhancedPDFParser
    private let useEnhancedParser: Bool
    
    // MARK: - Initialization
    
    init(useEnhancedParser: Bool = true) {
        self.useEnhancedParser = useEnhancedParser
        self.enhancedParser = EnhancedPDFParser()
    }
    
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        do {
            // Ensure we capture the PDF data before any extraction
            let pdfData = pdfDocument.dataRepresentation()
            print("DefaultPDFExtractor: PDF data size: \(pdfData?.count ?? 0) bytes")
            
            if useEnhancedParser {
                return try extractPayslipDataUsingEnhancedParser(from: pdfDocument, pdfData: pdfData)
            } else {
                return try extractPayslipDataUsingLegacyParser(from: pdfDocument, pdfData: pdfData)
            }
        } catch {
            print("DefaultPDFExtractor: Error extracting payslip data: \(error)")
            return nil
        }
    }
    
    /// Extracts payslip data from extracted text.
    ///
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        do {
            print("DefaultPDFExtractor: Extracting payslip data from text only (no PDF data available)")
            
            // Use the existing pattern manager to extract data from text
            let payslipItem = try parsePayslipData(from: text)
            
            // Convert to PayslipItem if it's not already
            if let typedItem = payslipItem as? PayslipItem {
                print("DefaultPDFExtractor: Successfully extracted payslip from text (no PDF data)")
                // Note: We don't have the original PDF data in this case
                return typedItem
            } else {
                // Create a new PayslipItem from the PayslipItemProtocol
                print("DefaultPDFExtractor: Creating new PayslipItem from protocol (no PDF data)")
                return PayslipItem(
                    month: payslipItem.month,
                    year: payslipItem.year,
                    credits: payslipItem.credits,
                    debits: payslipItem.debits,
                    dsop: payslipItem.dsop,
                    tax: payslipItem.tax,
                    location: payslipItem.location,
                    name: payslipItem.name,
                    accountNumber: payslipItem.accountNumber,
                    panNumber: payslipItem.panNumber,
                    timestamp: payslipItem.timestamp,
                    pdfData: nil // No PDF data available when extracting from text only
                )
            }
        } catch {
            print("DefaultPDFExtractor: Error extracting payslip data from text: \(error)")
            return nil
        }
    }
    
    /// Extracts text from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract text from.
    /// - Returns: The extracted text.
    func extractText(from pdfDocument: PDFDocument) -> String {
        return pdfDocument.string ?? ""
    }
    
    /// Gets the available parsers.
    ///
    /// - Returns: Array of parser names.
    func getAvailableParsers() -> [String] {
        return ["Enhanced Parser", "Legacy Parser"]
    }
    
    /// Parses payslip data from text using the PayslipPatternManager.
    ///
    /// - Parameters:
    ///   - text: The text to parse.
    ///   - pdfData: The PDF data.
    /// - Returns: A payslip item containing the parsed data.
    /// - Throws: An error if parsing fails.
    private func parsePayslipDataUsingPatternManager(from text: String, pdfData: Data?) throws -> any PayslipItemProtocol {
        print("DefaultPDFExtractor: Starting to parse payslip data using PayslipPatternManager")
        
        // Extract data using the PayslipPatternManager
        let extractedData = PayslipPatternManager.extractData(from: text)
        print("DefaultPDFExtractor: Extracted data using patterns: \(extractedData)")
        
        // Extract tabular data
        var (earnings, deductions) = PayslipPatternManager.extractTabularData(from: text)
        print("DefaultPDFExtractor: Extracted earnings: \(earnings)")
        print("DefaultPDFExtractor: Extracted deductions: \(deductions)")
        
        // Add fallback for name if it's missing
        var updatedData = extractedData
        
        // Try to extract data using the PCDA format specific to Indian defense payslips
        if text.contains("Principal Controller of Defence Accounts") || text.contains("PCDA") || text.contains("Ministry of Defence") {
            print("DefaultPDFExtractor: Detected PCDA format payslip")
            
            // Extract data using PCDA specific patterns
            let pcdaPatterns = [
                "name": "Name:\\s*([A-Za-z\\s.]+)",
                "accountNumber": "A\\/C\\s*No\\s*-\\s*([0-9\\/]+[A-Z]?)",
                "panNumber": "PAN\\s*No:\\s*([A-Z0-9]+)",
                "statementPeriod": "STATEMENT\\s*OF\\s*ACCOUNT\\s*FOR\\s*([0-9\\/]+)"
            ]
            
            for (key, pattern) in pcdaPatterns {
                if updatedData[key] == nil || updatedData[key]?.isEmpty == true {
                    if let match = text.range(of: pattern, options: .regularExpression) {
                        let matchedText = String(text[match])
                        if let captureRange = matchedText.range(of: "([A-Za-z0-9\\s.\\/]+)$", options: .regularExpression) {
                            let value = String(matchedText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            updatedData[key] = value
                            print("DefaultPDFExtractor: Extracted \(key) using PCDA pattern: '\(value)'")
                        }
                    }
                }
            }
            
            // Extract earnings and deductions from the two-column format common in PCDA payslips
            // This pattern looks for "Description Amount Description Amount" format
            let twoColumnPattern = "([A-Z][A-Z\\-]+)\\s+([0-9,.]+)\\s+([A-Z][A-Z\\-]+)\\s+([0-9,.]+)"
            
            // Define standard earnings and deductions components
            let standardEarningsComponents = ["BPAY", "DA", "MSP", "TPTA", "TPTADA"]
            let standardDeductionsComponents = ["DSOP", "AGIF", "ITAX", "FUR", "LF", "WATER", "EHCESS", "SPCDO", "ARR-RSHNA", "RSHNA", "TR", "UPTO", "MP"]
            
            // Temporary dictionary to collect all extracted values
            var allExtractedValues: [String: Double] = [:]
            
            if let regex = try? NSRegularExpression(pattern: twoColumnPattern, options: []) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 4 {
                        // First column
                        let code1 = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                        let amountStr1 = nsString.substring(with: match.range(at: 2))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: ",", with: "")
                        
                        // Second column
                        let code2 = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                        let amountStr2 = nsString.substring(with: match.range(at: 4))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: ",", with: "")
                        
                        if let amount1 = Double(amountStr1), amount1 > 1 {
                            allExtractedValues[code1] = amount1
                        }
                        
                        if let amount2 = Double(amountStr2), amount2 > 1 {
                            allExtractedValues[code2] = amount2
                        }
                    }
                }
            }
            
            // Now categorize all extracted values based on standard components
            for (code, amount) in allExtractedValues {
                if standardEarningsComponents.contains(code) {
                    // This is a standard earnings component
                    earnings[code] = amount
                    print("DefaultPDFExtractor: Categorized \(code) as earnings with amount \(amount)")
                } else if standardDeductionsComponents.contains(code) {
                    // This is a standard deductions component
                    deductions[code] = amount
                    print("DefaultPDFExtractor: Categorized \(code) as deductions with amount \(amount)")
                } else {
                    // For non-standard components, use heuristics
                    if code.contains("PAY") || code.contains("ALLOW") || code.contains("SALARY") || code.contains("WAGE") {
                        earnings[code] = amount
                        print("DefaultPDFExtractor: Categorized \(code) as earnings based on name with amount \(amount)")
                    } else if code.contains("TAX") || code.contains("FUND") || code.contains("FEE") || code.contains("RECOVERY") {
                        deductions[code] = amount
                        print("DefaultPDFExtractor: Categorized \(code) as deductions based on name with amount \(amount)")
                    } else {
                        // Default to deductions for unknown codes
                        deductions[code] = amount
                        print("DefaultPDFExtractor: Defaulted \(code) to deductions with amount \(amount)")
                    }
                }
            }
            
            // Final validation: ensure standard components are in the correct category
            for component in standardEarningsComponents {
                if let value = deductions[component] {
                    // Move from deductions to earnings
                    earnings[component] = value
                    deductions.removeValue(forKey: component)
                    print("DefaultPDFExtractor: Moved standard earnings component \(component) from deductions to earnings")
                }
            }
            
            for component in standardDeductionsComponents {
                if let value = earnings[component] {
                    // Move from earnings to deductions
                    deductions[component] = value
                    earnings.removeValue(forKey: component)
                    print("DefaultPDFExtractor: Moved standard deductions component \(component) from earnings to deductions")
                }
            }
        }
        
        // Create a PayslipItem from the extracted data
        let payslip = PayslipPatternManager.createPayslipItem(
            from: updatedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: pdfData
        )
        
        // Override the credits with grossPay if it exists
        // Check first for explicit grossPay in the updatedData
        if let grossPayStr = updatedData["grossPay"], let grossPay = Double(grossPayStr), grossPay > 0 {
            print("DefaultPDFExtractor: Overriding credits with explicit grossPay value from pattern: \(grossPay)")
            // Create a new item with the correct gross pay
            let updatedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: grossPay,  // Use the extracted gross pay
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: pdfData
            )
            
            // Set earnings and deductions separately
            updatedPayslip.earnings = earnings
            updatedPayslip.deductions = deductions
            
            // Make sure the grossPay value is correctly set in the earnings dictionary
            updatedPayslip.earnings["grossPay"] = grossPay
            updatedPayslip.earnings["TOTAL"] = grossPay
            
            // Log the updated payslip
            logExtractedPayslip(updatedPayslip)
            
            return updatedPayslip
        }
        // Fall back to the grossPay from earnings dictionary
        else if let grossPay = earnings["grossPay"], grossPay > 0 {
            print("DefaultPDFExtractor: Overriding credits with grossPay value from earnings dictionary: \(grossPay)")
            // Create a new item with the correct gross pay
            let updatedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: grossPay,  // Use the actual gross pay
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: pdfData
            )
            
            // Set earnings and deductions separately
            updatedPayslip.earnings = earnings
            updatedPayslip.deductions = deductions
            
            // Log the updated payslip
            logExtractedPayslip(updatedPayslip)
            
            return updatedPayslip
        }
        // Check if we have a TOTAL in the earnings dictionary as fallback
        else if let totalCredits = earnings["TOTAL"], totalCredits > 0 {
            print("DefaultPDFExtractor: Overriding credits with TOTAL value from earnings dictionary: \(totalCredits)")
            // Create a new item with the correct gross pay
            let updatedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: totalCredits,  // Use the total credits
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: pdfData
            )
            
            // Set earnings and deductions separately
            updatedPayslip.earnings = earnings
            updatedPayslip.deductions = deductions
            
            // Make sure the grossPay value is correctly set in the earnings dictionary
            updatedPayslip.earnings["grossPay"] = totalCredits
            updatedPayslip.earnings["TOTAL"] = totalCredits
            
            // Log the updated payslip
            logExtractedPayslip(updatedPayslip)
            
            return updatedPayslip
        }
        
        // Log the extracted data
        logExtractedPayslip(payslip)
        
        return payslip
    }
    
    /// Parses payslip data from text.
    ///
    /// - Parameter text: The text to parse.
    /// - Returns: A payslip item containing the parsed data.
    /// - Throws: An error if parsing fails.
    func parsePayslipData(from text: String) throws -> any PayslipItemProtocol {
        print("DefaultPDFExtractor: Starting to parse payslip data")
        
        // Add military-specific patterns for common military payslips
        PayslipPatternManager.addPattern(key: "name", pattern: "(?:Name|Employee\\s*Name|Name\\s*of\\s*Employee|SERVICE NO & NAME|ARMY NO AND NAME)\\s*:?\\s*([A-Za-z0-9\\s.]+?)(?:\\s*$|\\s*\\n)")
        PayslipPatternManager.addPattern(key: "accountNumber", pattern: "(?:A\\/C\\s*No|Account\\s*Number|Account\\s*No|Bank\\s*A\\/c\\s*No)\\s*[-:.]?\\s*([0-9\\/\\-]+)")
        PayslipPatternManager.addPattern(key: "location", pattern: "(?:Location|Duty\\s*Station|Station|UNIT|UNIT\\s*ADDRESS)\\s*[:.]?\\s*([A-Za-z0-9\\s.,\\-]+?)(?:\\s*$|\\s*\\n)")
        
        // Military specific
        PayslipPatternManager.addPattern(key: "dsop", pattern: "(?:DSOP|D\\.S\\.O\\.P|Defence\\s*Services\\s*Officers\\s*Provident|DSOP\\s*FUND)\\s*(?:Fund)?\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)")
        PayslipPatternManager.addPattern(key: "tax", pattern: "(?:Income\\s*Tax|I\\.TAX|TAX|IT|INCOME\\s*TAX)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)")
        
        // Try using the pattern manager first
        do {
            // Try to parse with military patterns first
            if isMilitaryPayslip(text) {
                print("DefaultPDFExtractor: Detected military payslip format")
                
                // Apply military-specific extraction logic
                return try extractMilitaryPayslipData(from: text)
            }
            
            // Standard extraction path using the pattern manager
            return try parsePayslipDataUsingPatternManager(from: text, pdfData: nil)
        } catch {
            // Fallback to enhanced extraction for non-standard formats
            print("DefaultPDFExtractor: Pattern matching failed, trying enhanced extraction")
            
            // Try enhanced PDF parser for more complex formats
            if useEnhancedParser {
                let parsedData = enhancedParser.parsePayslip(from: PDFDocument(data: text.data(using: .utf8) ?? Data()) ?? PDFDocument())
                
                // Convert ParsedPayslipData to PayslipItem
                let payslip = PayslipItem(
                    month: parsedData.metadata["month"] ?? "",
                    year: Int(parsedData.metadata["year"] ?? "") ?? 0,
                    credits: parsedData.earnings.values.reduce(0, +),
                    debits: parsedData.deductions.values.reduce(0, +),
                    dsop: parsedData.dsopDetails.values.reduce(0, +),
                    tax: parsedData.taxDetails.values.reduce(0, +),
                    location: parsedData.contactDetails["location"] ?? parsedData.personalInfo["location"] ?? "",
                    name: parsedData.personalInfo["name"] ?? "",
                    accountNumber: parsedData.personalInfo["accountNumber"] ?? "",
                    panNumber: parsedData.personalInfo["panNumber"] ?? "",
                    timestamp: Date()
                )
                
                return payslip
            }
            
            // If all else fails, use the original pattern manager with fallbacks
            return try parsePayslipDataUsingPatternManager(from: text, pdfData: nil)
        }
    }
    
    /// Determines if the text appears to be from a military payslip
    private func isMilitaryPayslip(_ text: String) -> Bool {
        // First, check for our special marker format
        if text.contains("MILPDF:") {
            print("DefaultPDFExtractor: Detected military PDF by marker")
            return true
        }
        
        // Check for common military terms
        let militaryTerms = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", "PCDA", "CDA", "Defence", 
            "DSOP FUND", "SERVICE NO", "ARMY NO", "UNIT", "PRINCIPAL CONTROLLER",
            "DEFENCE ACCOUNTS", "MILITARY", "Indian Army", "AIR HQ", "Naval HQ",
            "Defence Services", "Armed Forces", "Military Service"
        ]
        
        // Check if any military term appears in the text
        for term in militaryTerms {
            if text.contains(term) {
                print("DefaultPDFExtractor: Detected military payslip with term: \(term)")
                return true
            }
        }
        
        // If the text is exceptionally short (like in encrypted PDFs), check if 
        // it might be a military PDF that wasn't properly extracted
        if text.count < 50 && text.contains("PAY") {
            print("DefaultPDFExtractor: Short text with PAY - assuming military")
            return true
        }
        
        return false
    }
    
    /// Extracts data from military payslips with specialized logic
    private func extractMilitaryPayslipData(from text: String) throws -> any PayslipItemProtocol {
        print("DefaultPDFExtractor: Extracting military payslip data")
        
        // If the text is too short (like in failed extractions from password-protected PDFs),
        // create a basic payslip with default values
        if text.count < 100 {
            print("DefaultPDFExtractor: Extracted text too short, creating fallback payslip item")
            
            // Create a default PayslipItem with minimal data
            let fallbackItem = PayslipItem(
                month: getCurrentMonth(),
                year: getCurrentYear(),
                credits: 2025.0,  // Special value to indicate it's using the fallback
                debits: 0.0,
                dsop: 0.0,
                tax: 0.0,
                location: "Military",
                name: "Military Personnel",
                accountNumber: "",
                panNumber: "",
                timestamp: Date()
            )
            
            return fallbackItem
        }
        
        // Customize pattern manager for military payslips
        let militaryPatterns: [String: String] = [
            "name": "(?:SERVICE NO & NAME|ARMY NO AND NAME|NAME|Name|Personnel|Employee Name)[\\s:]*(?:[A-Z0-9]+\\s*)?([A-Za-z\\s.]+)",
            "month": "(?:FOR THE MONTH OF|MONTH|PAY FOR|PAYSLIP FOR|STATEMENT OF ACCOUNT FOR|MONTH OF|SALARY FOR)\\s*(?:THE MONTH OF)?\\s*([A-Za-z]+)\\s*([0-9]{4})?",
            "year": "(?:YEAR|FOR THE YEAR|FOR FINANCIAL YEAR|FY|FOR THE MONTH OF|DATED)\\s*(?:[A-Za-z]+\\s*)?([0-9]{4})",
            "accountNumber": "(?:BANK A\\/C NO|A\\/C NO|Account No|Bank Account)\\s*[:.]?\\s*([0-9\\-]+)",
            "location": "(?:UNIT|UNIT ADDRESS|PLACE OF DUTY|Station|Location|Base)\\s*[:.]?\\s*([A-Za-z0-9\\s.,\\-]+)"
        ]
        
        // Add all military patterns to the pattern manager
        for (key, pattern) in militaryPatterns {
            PayslipPatternManager.addPattern(key: key, pattern: pattern)
        }
        
        // Extract data using the enhanced patterns
        let extractedData = PayslipPatternManager.extractData(from: text)
        print("DefaultPDFExtractor: Extracted military data using patterns: \(extractedData)")
        
        // Extract tabular data with military-specific components
        var (earnings, deductions) = extractMilitaryTabularData(from: text)
        
        // IMPORTANT: Check if we have a gross pay in the extracted pattern data
        // This fixes the issue where the pattern extraction finds a different gross pay
        // than what's calculated in the tabular data extraction
        if let grossPayStr = extractedData["grossPay"], let grossPay = Double(grossPayStr), grossPay > 0 {
            print("DefaultPDFExtractor: Found gross pay in pattern extraction: \(grossPay)")
            
            // Add this to the earnings dictionary to ensure it's used
            earnings["grossPay"] = grossPay
            earnings["TOTAL"] = grossPay
            
            // This should ensure it gets prioritized in the final calculation
        }
        
        // If we couldn't extract month/year properly, try to infer from text
        var updatedData = extractedData
        
        // Set month and year if not already set
        if updatedData["month"] == nil || updatedData["month"]?.isEmpty == true {
            // Try to extract from statement period
            let periodPattern = "(?:FOR THE MONTH OF|MONTH OF|STATEMENT OF ACCOUNT FOR|PAY FOR)\\s*([A-Za-z]+)\\s*,?\\s*([0-9]{4})"
            if let match = text.range(of: periodPattern, options: .regularExpression) {
                let matchedText = String(text[match])
                
                // Extract month
                if let monthRange = matchedText.range(of: "([A-Za-z]+)\\s*,?\\s*[0-9]{4}", options: .regularExpression) {
                    let monthText = String(matchedText[monthRange])
                    if let captureRange = monthText.range(of: "([A-Za-z]+)", options: .regularExpression) {
                        let month = String(monthText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        updatedData["month"] = month
                        print("DefaultPDFExtractor: Extracted month from period: '\(month)'")
                    }
                }
                
                // Extract year
                if let yearRange = matchedText.range(of: "([0-9]{4})", options: .regularExpression) {
                    let year = String(matchedText[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedData["year"] = year
                    print("DefaultPDFExtractor: Extracted year from period: '\(year)'")
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
        
        // Create a PayslipItem from the extracted data
        let payslip = PayslipPatternManager.createPayslipItem(
            from: updatedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: nil
        )
        
        // Override the credits with grossPay if it exists
        if let grossPay = earnings["grossPay"], grossPay > 0 {
            print("DefaultPDFExtractor: Overriding credits with grossPay value from military extraction: \(grossPay)")
            // Create a new item with the correct gross pay
            let updatedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: grossPay,  // Use the actual gross pay
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: nil
            )
            
            // Set earnings and deductions separately
            updatedPayslip.earnings = earnings
            updatedPayslip.deductions = deductions
            
            // Log the updated payslip
            logExtractedPayslip(updatedPayslip)
            
            return updatedPayslip
        }
        // Try with TOTAL as a fallback
        else if let totalCredits = earnings["TOTAL"], totalCredits > 0 {
            print("DefaultPDFExtractor: Overriding credits with TOTAL value from military extraction: \(totalCredits)")
            // Create a new item with the correct gross pay
            let updatedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: totalCredits,  // Use the total credits
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp,
                pdfData: nil
            )
            
            // Set earnings and deductions separately
            updatedPayslip.earnings = earnings
            updatedPayslip.deductions = deductions
            
            // Make sure the grossPay value is correctly set in the earnings dictionary
            updatedPayslip.earnings["grossPay"] = totalCredits
            updatedPayslip.earnings["TOTAL"] = totalCredits
            
            // Log the updated payslip
            logExtractedPayslip(updatedPayslip)
            
            return updatedPayslip
        }
        
        // Log the extracted data
        logExtractedPayslip(payslip)
        
        return payslip
    }
    
    /// Extracts tabular data specifically from military payslips
    private func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        print("DefaultPDFExtractor: Extracting military tabular data")
        
        // Check if we have a PCDA format with standard table structure
        if text.contains("Principal Controller of Defence Accounts") || text.contains("PCDA") {
            print("DefaultPDFExtractor: Detected PCDA format table")
            
            // Standard PCDA table format
            // Look for rows in the format "CODE   AMOUNT   CODE   AMOUNT"
            let rowPattern = "([A-Z][A-Z0-9]+)\\s+(\\d+[.,]?\\d*)\\s+([A-Z][A-Z0-9]+)\\s+(\\d+[.,]?\\d*)"
            
            let nsString = text as NSString
            if let regex = try? NSRegularExpression(pattern: rowPattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                print("DefaultPDFExtractor: Found \(matches.count) PCDA format rows")
                
                // Define correct categorization for PCDA format
                let earningCodes = ["BPAY", "DA", "MSP", "TPTA"]
                let deductionCodes = ["DSOP", "AGIF", "ITAX", "EHCESS", "RH12", "TPTADA"]
                
                for match in matches {
                    if match.numberOfRanges > 4 {
                        // First column
                        let code1 = nsString.substring(with: match.range(at: 1))
                        let amountStr1 = nsString.substring(with: match.range(at: 2))
                            .replacingOccurrences(of: ",", with: "")
                        
                        // Second column
                        let code2 = nsString.substring(with: match.range(at: 3))
                        let amountStr2 = nsString.substring(with: match.range(at: 4))
                            .replacingOccurrences(of: ",", with: "")
                        
                        // Categorize first column appropriately
                        if let amount1 = Double(amountStr1) {
                            if earningCodes.contains(code1) {
                                print("DefaultPDFExtractor: Found earning \(code1): \(amount1)")
                                earnings[code1] = amount1
                            } else if deductionCodes.contains(code1) {
                                print("DefaultPDFExtractor: Found deduction \(code1): \(amount1)")
                                deductions[code1] = amount1
                            } else {
                                // Default as earning if not in known lists (can be refined)
                                print("DefaultPDFExtractor: Found unknown code, treating as earning \(code1): \(amount1)")
                                earnings[code1] = amount1
                            }
                        }
                        
                        // Categorize second column appropriately
                        if let amount2 = Double(amountStr2) {
                            if earningCodes.contains(code2) {
                                print("DefaultPDFExtractor: Found earning \(code2): \(amount2)")
                                earnings[code2] = amount2
                            } else if deductionCodes.contains(code2) {
                                print("DefaultPDFExtractor: Found deduction \(code2): \(amount2)")
                                deductions[code2] = amount2
                            } else {
                                // Default as deduction if not in known lists (can be refined)
                                print("DefaultPDFExtractor: Found unknown code, treating as deduction \(code2): \(amount2)")
                                deductions[code2] = amount2
                            }
                        }
                    }
                }
            }
            
            // Look for gross pay (total earnings)
            if let grossMatch = text.range(of: "(?:Total|Gross|कुल आय)[\\s:]*(?:Rs\\.)?\\s*(\\d+[.,]?\\d*)", options: .regularExpression) {
                let grossString = String(text[grossMatch])
                if let amountMatch = grossString.range(of: "(\\d+[.,]?\\d*)", options: .regularExpression) {
                    let amountString = String(grossString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found gross pay: \(amount)")
                        earnings["TOTAL"] = amount
                        earnings["grossPay"] = amount  // Add under standardized key
                    }
                }
            }
            
            // Also look for specific PCDA gross pay format (common in military payslips)
            if let grossMatch = text.range(of: "कुल आय\\s+Gross Pay\\s+(\\d+[.,]?\\d*)", options: .regularExpression) {
                let grossString = String(text[grossMatch])
                if let amountMatch = grossString.range(of: "(\\d+[.,]?\\d*)", options: .regularExpression) {
                    let amountString = String(grossString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found PCDA format gross pay: \(amount)")
                        earnings["TOTAL"] = amount
                        earnings["grossPay"] = amount  // Add under standardized key
                    }
                }
            }
            
            // Look for any specific gross pay value using a more generic pattern
            if let grossMatch = text.range(of: "Gross\\s+Pay\\s*[:.]?\\s*(?:Rs\\.)?\\s*(\\d+[.,]?\\d*)", options: .regularExpression) {
                let grossString = String(text[grossMatch])
                if let amountMatch = grossString.range(of: "(\\d+[.,]?\\d*)", options: .regularExpression) {
                    let amountString = String(grossString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found specific gross pay value: \(amount)")
                        earnings["TOTAL"] = amount
                        earnings["grossPay"] = amount  // Prioritize this value
                    }
                }
            }
            
            // Alternative pattern for estimated future salary which is also gross pay
            if let grossMatch = text.range(of: "(?:Estimated|Future)\\s+(?:Salary|Pay)\\s*[:.]?\\s*(?:Rs\\.)?\\s*(\\d+[.,]?\\d*)", options: .regularExpression) {
                let grossString = String(text[grossMatch])
                if let amountMatch = grossString.range(of: "(\\d+[.,]?\\d*)", options: .regularExpression) {
                    let amountString = String(grossString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found estimated future salary: \(amount) (not using as gross pay)")
                        // Don't use estimated future salary as gross pay
                        // Instead, just store it separately
                        earnings["estimatedFutureSalary"] = amount
                    }
                }
            }
            
            // Look for total deductions
            if let deductionsMatch = text.range(of: "(?:Total Deduction|Total Deductions|कुल कटौती)[\\s:]*(?:Rs\\.)?\\s*(\\d+[.,]?\\d*)", options: .regularExpression) {
                let deductionsString = String(text[deductionsMatch])
                if let amountMatch = deductionsString.range(of: "(\\d+[.,]?\\d*)", options: .regularExpression) {
                    let amountString = String(deductionsString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found total deductions: \(amount)")
                        deductions["TOTAL DEDUCTION"] = amount
                    }
                }
            }
            
            // Look for net remittance - improved to handle large numbers with commas
            let netRemittancePattern = "(?:Net Remittance|Net Amount|Net Salary)\\s*[:.]?\\s*(?:Rs\\.)?\\s*([0-9]+(?:[,.][0-9]+)*)"
            if let netMatch = text.range(of: netRemittancePattern, options: .regularExpression) {
                let netString = String(text[netMatch])
                if let amountMatch = netString.range(of: "([0-9]+(?:[,.][0-9]+)*)", options: .regularExpression) {
                    let amountString = String(netString[amountMatch]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountString) {
                        print("DefaultPDFExtractor: Found net remittance: \(amount)")
                        // Store this for validation
                        deductions["__NET_REMITTANCE"] = amount
                    }
                }
            }
            
            // Recognize which values are earnings vs deductions more accurately
            // Earnings components (now correctly categorized)
            let earningsComponents = ["BPAY", "DA", "MSP", "TPTA"]
            
            // Calculate total credits (total of all earnings)
            var totalCredits: Double = 0
            for component in earningsComponents {
                if let value = earnings[component] {
                    totalCredits += value
                    print("DefaultPDFExtractor: Adding \(component) to credits: \(value)")
                }
            }
            
            // Check if we have an explicitly defined gross pay from the document
            let extractedGrossPay = earnings["grossPay"] ?? earnings["TOTAL"]
            
            // IMPORTANT: Always use the explicitly defined gross pay if available, otherwise fall back to sum of components
            let finalCredits: Double
            if let extractedGrossPay = extractedGrossPay, extractedGrossPay > 0 {
                // We have an explicitly extracted gross pay, use it
                finalCredits = extractedGrossPay
                print("DefaultPDFExtractor: Using extracted gross pay (\(finalCredits)) instead of calculated sum (\(totalCredits))")
            } else {
                // Fall back to calculated sum
                finalCredits = totalCredits
                print("DefaultPDFExtractor: No explicit gross pay found, using calculated sum: \(finalCredits)")
            }
            
            print("DefaultPDFExtractor: Final credits (prioritizing gross pay): \(finalCredits)")
            
            // Store the primary value for quick access
            earnings["__CREDITS_TOTAL"] = finalCredits
            
            // Update the TOTAL and grossPay keys to ensure they reflect the correct value
            earnings["TOTAL"] = finalCredits
            earnings["grossPay"] = finalCredits
            
            // Deduction components (now correctly categorized)
            let deductionComponents = ["DSOP", "AGIF", "ITAX", "EHCESS", "RH12", "TPTADA"]
            
            // Calculate total debits
            var totalDebits: Double = 0
            for component in deductionComponents {
                if let value = deductions[component] {
                    totalDebits += value
                    print("DefaultPDFExtractor: Adding \(component) to debits: \(value)")
                }
            }
            
            // Use the explicitly defined total if available
            let finalDebits = deductions["TOTAL DEDUCTION"] ?? totalDebits
            print("DefaultPDFExtractor: Final debits: \(finalDebits)")
            
            // Get specific values for DSOP and Income Tax
            let dsopValue = deductions["DSOP"] ?? 0
            let taxValue = deductions["ITAX"] ?? deductions["INCOME TAX"] ?? 0
            
            // Set special keys for the main totals
            deductions["__DEBITS_TOTAL"] = finalDebits
            deductions["__DSOP_TOTAL"] = dsopValue
            deductions["__TAX_TOTAL"] = taxValue
            
            print("DefaultPDFExtractor: Final values - Credits: \(finalCredits), Debits: \(finalDebits), DSOP: \(dsopValue), Tax: \(taxValue)")
            
            return (earnings, deductions)
        }
        
        // If not PCDA format, use generic military patterns
        // Military-specific earnings codes
        let earningsPatterns = [
            "BASIC PAY": "BASIC\\s*PAY\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "PAY": "PAY\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "DA": "(?:DA|DEARNESS ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "TA": "(?:TA|TRANSPORT ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "MSP": "(?:MSP|MILITARY SERVICE PAY)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "HRA": "(?:HRA|HOUSE RENT ALLOWANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "TOTAL": "(?:TOTAL|TOTAL EARNINGS|GROSS SALARY|GROSS EARNING)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "NETT": "(?:NETT|NET SALARY|NET AMOUNT|AMOUNT PAYABLE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"
        ]
        
        // Military-specific deduction codes
        let deductionsPatterns = [
            "DSOP": "(?:DSOP|DSOP FUND)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "AGIF": "(?:AGIF|ARMY GROUP INSURANCE)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "INCOME TAX": "(?:INCOME TAX|I\\.TAX|IT)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "CGEIS": "CGEIS\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "AFPP": "AFPP\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)",
            "TOTAL DEDUCTION": "(?:TOTAL DEDUCTION|TOTAL DEDUCTIONS)\\s*[:.]?\\s*(?:Rs\\.?)?\\s*([0-9,.]+)"
        ]
        
        // Extract earnings
        for (key, pattern) in earningsPatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[match])
                if let captureRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueText = String(matchedText[captureRange])
                        .replacingOccurrences(of: ",", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let value = Double(valueText), value > 0 {
                        earnings[key] = value
                        print("DefaultPDFExtractor: Extracted earnings \(key): \(value)")
                    }
                }
            }
        }
        
        // Extract deductions
        for (key, pattern) in deductionsPatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchedText = String(text[match])
                if let captureRange = matchedText.range(of: "([0-9,.]+)$", options: .regularExpression) {
                    let valueText = String(matchedText[captureRange])
                        .replacingOccurrences(of: ",", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let value = Double(valueText), value > 0 {
                        deductions[key] = value
                        print("DefaultPDFExtractor: Extracted deduction \(key): \(value)")
                    }
                }
            }
        }
        
        // Calculate credits, debits, dsop, and tax from the extracted values
        let totalCredits = earnings["TOTAL"] ?? earnings.values.reduce(0, +)
        let totalDebits = deductions["TOTAL DEDUCTION"] ?? (deductions.values.reduce(0, +) - (deductions["DSOP"] ?? 0) - (deductions["INCOME TAX"] ?? 0))
        
        // Set main totals
        earnings["__CREDITS_TOTAL"] = totalCredits
        deductions["__DEBITS_TOTAL"] = totalDebits
        deductions["__DSOP_TOTAL"] = deductions["DSOP"] ?? 0
        deductions["__TAX_TOTAL"] = deductions["INCOME TAX"] ?? 0
        
        return (earnings, deductions)
    }
    
    // Helper to get current month name
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    // Helper to get current year
    private func getCurrentYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }
    
    // MARK: - Extraction Methods
    
    /// Extracts data using pattern matching on individual lines.
    private func extractDataUsingPatternMatching(from lines: [String], into data: inout PayslipExtractionData) {
        // Define keyword patterns for different fields
        let namePatterns = ["Name:", "Employee Name:", "Emp Name:", "Employee:", "Name of Employee:", "Name of the Employee:"]
        let basicPayPatterns = ["Basic Pay:", "Basic:", "Basic Salary:", "Basic Pay", "BASIC PAY", "BPAY"]
        let grossPayPatterns = ["Gross Pay:", "Gross:", "Gross Salary:", "Gross Earnings:", "Total Earnings:", "Gross Amount:", "TOTAL EARNINGS"]
        let netPayPatterns = ["Net Pay:", "Net:", "Net Salary:", "Net Amount:", "Take Home:", "Amount Payable:", "NET AMOUNT"]
        let taxPatterns = ["Income Tax:", "Tax:", "TDS:", "I.Tax:", "Income-tax:", "IT:", "ITAX", "Income Tax"]
        let dsopPatterns = ["DSOP:", "PF:", "Provident Fund:", "EPF:", "Employee PF:", "PF Contribution:", "DSOP FUND"]
        let locationPatterns = ["Location:", "Place:", "Branch:", "Office:", "Work Location:", "LOCATION"]
        let panPatterns = ["PAN:", "PAN No:", "PAN Number:", "Permanent Account Number:", "PAN NO"]
        let accountPatterns = ["A/C:", "Account No:", "Bank A/C:", "Account Number:", "A/C NO"]
        let datePatterns = ["Pay Date:", "Salary Date:", "Date:", "For the month of:", "Pay Period:", "Month:", "STATEMENT OF ACCOUNT FOR"]
        
        // Process each line
        for line in lines {
            // Extract name with improved pattern matching
            if data.name.isEmpty {
                if let name = extractValueForPatterns(namePatterns, from: line) {
                    // Clean up the name - remove any numbers or special characters
                    let cleanedName = name.replacingOccurrences(of: "[0-9\\(\\)\\[\\]\\{\\}]", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !cleanedName.isEmpty {
                        data.name = cleanedName
                        print("DefaultPDFExtractor: Extracted name: \(cleanedName)")
                    }
                }
            }
            
            // Extract basic pay
            if data.basicPay == 0, let basicPay = extractAmountForPatterns(basicPayPatterns, from: line) {
                data.basicPay = basicPay
                print("DefaultPDFExtractor: Extracted basic pay: \(basicPay)")
            }
            
            // Extract gross pay (credits)
            if data.credits == 0, let grossPay = extractAmountForPatterns(grossPayPatterns, from: line) {
                data.credits = grossPay
                data.grossPay = grossPay
                print("DefaultPDFExtractor: Extracted gross pay (credits): \(grossPay)")
            }
            
            // Extract net pay
            if data.credits == 0, let netPay = extractAmountForPatterns(netPayPatterns, from: line) {
                data.credits = netPay
                print("DefaultPDFExtractor: Extracted net pay: \(netPay)")
            }
            
            // Extract tax
            if data.tax == 0, let tax = extractAmountForPatterns(taxPatterns, from: line) {
                data.tax = tax
                print("DefaultPDFExtractor: Extracted tax: \(tax)")
            }
            
            // Extract DSOP
            if data.dsop == 0, let dsop = extractAmountForPatterns(dsopPatterns, from: line) {
                data.dsop = dsop
                print("DefaultPDFExtractor: Extracted DSOP: \(dsop)")
            }
            
            // Extract location
            if data.location.isEmpty, let location = extractValueForPatterns(locationPatterns, from: line) {
                data.location = location
                print("DefaultPDFExtractor: Extracted location: \(location)")
            }
            
            // Extract PAN
            if data.panNumber.isEmpty {
                if let pan = extractValueForPatterns(panPatterns, from: line) {
                    data.panNumber = pan
                    print("DefaultPDFExtractor: Extracted PAN: \(pan)")
                } else if let panMatch = line.range(of: "[A-Z]{5}[0-9]{4}[A-Z]{1}", options: .regularExpression) {
                    // Direct PAN pattern match
                    data.panNumber = String(line[panMatch])
                    print("DefaultPDFExtractor: Extracted PAN using direct pattern: \(data.panNumber)")
                }
            }
            
            // Extract account number
            if data.accountNumber.isEmpty, let account = extractValueForPatterns(accountPatterns, from: line) {
                data.accountNumber = account
                print("DefaultPDFExtractor: Extracted account number: \(account)")
            }
            
            // Extract date with improved handling
            if let dateString = extractValueForPatterns(datePatterns, from: line) {
                if let date = parseDate(dateString) {
                    data.timestamp = date
                    let calendar = Calendar.current
                    data.month = getMonthName(from: calendar.component(.month, from: date))
                    data.year = calendar.component(.year, from: date)
                    print("DefaultPDFExtractor: Extracted date: \(data.month) \(data.year)")
                } else {
                    // Try to extract month/year directly from the string
                    extractMonthYearFromString(dateString, into: &data)
                }
            }
            
            // Extract deductions (debits)
            if line.contains("Total Deduction") || line.contains("Total Deductions") || line.contains("TOTAL DEDUCTIONS") {
                if let deductions = extractAmount(from: line) {
                    data.debits = deductions
                    print("DefaultPDFExtractor: Extracted deductions (debits): \(deductions)")
                }
            }
        }
    }
    
    /// Attempts to extract month and year directly from a string
    private func extractMonthYearFromString(_ string: String, into data: inout PayslipExtractionData) {
        // Try to find month names
        let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Check for full month names
        for (_, monthName) in monthNames.enumerated() {
            if string.contains(monthName) {
                data.month = monthName
                // Try to find a year (4 digits) near the month name
                if let yearMatch = string.range(of: "\\b(20\\d{2})\\b", options: .regularExpression) {
                    if let year = Int(string[yearMatch]) {
                        data.year = year
                    }
                }
                print("DefaultPDFExtractor: Extracted month from string: \(data.month)")
                return
            }
        }
        
        // Check for abbreviated month names
        for (index, shortName) in shortMonthNames.enumerated() {
            if string.contains(shortName) {
                data.month = monthNames[index]
                // Try to find a year (4 digits) near the month name
                if let yearMatch = string.range(of: "\\b(20\\d{2})\\b", options: .regularExpression) {
                    if let year = Int(string[yearMatch]) {
                        data.year = year
                    }
                }
                print("DefaultPDFExtractor: Extracted month from abbreviated name: \(data.month)")
                return
            }
        }
        
        // Check for MM/YYYY format
        if let dateMatch = string.range(of: "(\\d{1,2})\\s*[/\\-]\\s*(20\\d{2})", options: .regularExpression) {
            let dateString = string[dateMatch]
            let components = dateString.components(separatedBy: CharacterSet(charactersIn: "/- "))
            let filteredComponents = components.filter { !$0.isEmpty }
            
            if filteredComponents.count >= 2, 
               let monthNumber = Int(filteredComponents[0]),
               monthNumber >= 1 && monthNumber <= 12,
               let year = Int(filteredComponents[1]) {
                data.month = monthNames[monthNumber - 1]
                data.year = year
                print("DefaultPDFExtractor: Extracted month/year from MM/YYYY format: \(data.month) \(data.year)")
            }
        }
    }
    
    /// Extracts data using regular expressions on the full text.
    private func extractDataUsingRegex(from text: String, into data: inout PayslipExtractionData) {
        // Extract PAN number using regex
        if data.panNumber.isEmpty {
            if let panMatch = text.range(of: "[A-Z]{5}[0-9]{4}[A-Z]{1}", options: .regularExpression) {
                data.panNumber = String(text[panMatch])
                print("DefaultPDFExtractor: Found PAN number using regex: \(data.panNumber)")
            }
        }
        
        // Extract name if still empty
        if data.name.isEmpty {
            // Try to find name patterns like "Name: John Doe" or "Employee: John Doe"
            let nameRegexPatterns = [
                "(?:Name|Employee|Employee Name|Emp Name)[:\\s]+([A-Za-z\\s]+)",
                "Name of Employee[:\\s]+([A-Za-z\\s]+)",
                "Employee Details[\\s\\S]*?Name[:\\s]+([A-Za-z\\s]+)"
            ]
            
            for pattern in nameRegexPatterns {
                if let nameMatch = text.range(of: pattern, options: .regularExpression) {
                    let nameText = String(text[nameMatch])
                    let extractedName = extractValue(from: nameText, prefix: ["Name:", "Employee:", "Employee Name:", "Emp Name:", "Name of Employee:"])
                    if !extractedName.isEmpty {
                        data.name = extractedName
                        print("DefaultPDFExtractor: Found name using regex: \(data.name)")
                        break
                    }
                }
            }
        }
        
        // Extract month and year if still empty
        if data.month.isEmpty || data.year == 0 {
            // Look for date patterns like "March 2023" or "03/2023" or "For the month of March 2023"
            let dateRegexPatterns = [
                "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* [0-9]{4}",
                "For the month of (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* [0-9]{4}",
                "Month: (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* [0-9]{4}",
                "Period: (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* [0-9]{4}",
                "[0-9]{1,2}/[0-9]{4}"
            ]
            
            for pattern in dateRegexPatterns {
                if let dateMatch = text.range(of: pattern, options: .regularExpression) {
                    let dateText = String(text[dateMatch])
                    if let date = parseDate(dateText) {
                        let calendar = Calendar.current
                        data.month = getMonthName(from: calendar.component(.month, from: date))
                        data.year = calendar.component(.year, from: date)
                        data.timestamp = date
                        print("DefaultPDFExtractor: Found month and year using regex: \(data.month) \(data.year)")
                        break
                    }
                }
            }
        }
        
        // Extract amounts if still missing
        if data.credits == 0 {
            // Look for currency patterns like "₹12,345.67" or "Rs. 12,345.67"
            let currencyRegexPatterns = [
                "Net Pay[:\\s]+[₹Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)",
                "Net Amount[:\\s]+[₹Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)",
                "Amount Payable[:\\s]+[₹Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)",
                "Take Home[:\\s]+[₹Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)"
            ]
            
            for pattern in currencyRegexPatterns {
                if let amountMatch = text.range(of: pattern, options: .regularExpression) {
                    let amountText = String(text[amountMatch])
                    if let amount = extractAmount(from: amountText) {
                        data.credits = amount
                        print("DefaultPDFExtractor: Found credits using regex: \(data.credits)")
                        break
                    }
                }
            }
        }
    }
    
    /// Extracts data using context awareness (looking at surrounding lines).
    private func extractDataUsingContextAwareness(from lines: [String], into data: inout PayslipExtractionData) {
        // Look for tables with earnings and deductions
        var inEarningsSection = false
        var inDeductionsSection = false
        
        for (index, line) in lines.enumerated() {
            // Detect sections
            if line.contains("Earnings") || line.contains("Income") || line.contains("Salary Details") {
                inEarningsSection = true
                inDeductionsSection = false
                continue
            } else if line.contains("Deductions") || line.contains("Recoveries") || line.contains("Less") {
                inEarningsSection = false
                inDeductionsSection = true
                continue
            }
            
            // Process based on section
            if inEarningsSection {
                // Look for basic pay in earnings section
                if line.contains("Basic") && data.basicPay == 0 {
                    if let amount = extractAmount(from: line) {
                        data.basicPay = amount
                        print("DefaultPDFExtractor: Found basic pay in earnings section: \(amount)")
                    } else if index + 1 < lines.count {
                        // Check next line for amount
                        if let amount = extractAmount(from: lines[index + 1]) {
                            data.basicPay = amount
                            print("DefaultPDFExtractor: Found basic pay in next line: \(amount)")
                        }
                    }
                }
                
                // Look for total earnings
                if (line.contains("Total") || line.contains("Gross")) && data.grossPay == 0 {
                    if let amount = extractAmount(from: line) {
                        data.grossPay = amount
                        print("DefaultPDFExtractor: Found gross pay in earnings section: \(amount)")
                    }
                }
            } else if inDeductionsSection {
                // Look for tax in deductions section
                if (line.contains("Tax") || line.contains("TDS") || line.contains("I.Tax")) && data.tax == 0 {
                    if let amount = extractAmount(from: line) {
                        data.tax = amount
                        print("DefaultPDFExtractor: Found tax in deductions section: \(amount)")
                    }
                }
                
                // Look for PF/DSOP in deductions section
                if (line.contains("PF") || line.contains("Provident") || line.contains("DSOP")) && data.dsop == 0 {
                    if let amount = extractAmount(from: line) {
                        data.dsop = amount
                        print("DefaultPDFExtractor: Found DSOP in deductions section: \(amount)")
                    }
                }
                
                // Look for total deductions
                if line.contains("Total") && data.debits == 0 {
                    if let amount = extractAmount(from: line) {
                        data.debits = amount
                        print("DefaultPDFExtractor: Found total deductions: \(amount)")
                    }
                }
            }
            
            // Look for name patterns in a generic way
            if data.name.isEmpty {
                // Try to find name patterns like "Name: John Doe"
                let namePatterns = ["Name:", "Employee:", "Employee Name:"]
                for pattern in namePatterns {
                    if line.contains(pattern) {
                        let name = extractValue(from: line, prefix: [pattern])
                        if !name.isEmpty {
                            data.name = name
                            print("DefaultPDFExtractor: Found name in line: \(data.name)")
                            break
                        }
                    }
                }
                
                // If still no name, try to find capitalized words that might be a name
                if data.name.isEmpty {
                    if let nameMatch = line.range(of: "\\b([A-Z][a-z]+\\s+[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?)\\b", options: .regularExpression) {
                        let name = String(line[nameMatch])
                        data.name = name
                        print("DefaultPDFExtractor: Found potential name using capitalization pattern: \(data.name)")
                    }
                }
            }
        }
    }
    
    /// Applies fallbacks for any missing data.
    private func applyFallbacksForMissingData(_ data: inout PayslipExtractionData) {
        // Set default name if still empty
        if data.name.isEmpty {
            if !data.panNumber.isEmpty {
                data.name = "Employee (\(data.panNumber))"
                print("DefaultPDFExtractor: Using PAN-based name placeholder: \(data.name)")
            } else {
                data.name = "Unknown Employee"
                print("DefaultPDFExtractor: Using generic name placeholder: \(data.name)")
            }
        }
        
        // Set default month and year if still empty
        if data.month.isEmpty {
            data.month = "March"
            print("DefaultPDFExtractor: Using default month: \(data.month)")
        }
        
        if data.year == 0 {
            data.year = Calendar.current.component(.year, from: Date())
            print("DefaultPDFExtractor: Using default year: \(data.year)")
        }
        
        // Set default timestamp if still empty
        if data.timestamp == Date.distantPast {
            data.timestamp = Date()
            print("DefaultPDFExtractor: Using current date as timestamp")
        }
        
        // If we have gross pay but no credits, use gross pay
        if data.credits == 0 && data.grossPay > 0 {
            data.credits = data.grossPay
            print("DefaultPDFExtractor: Using gross pay as credits: \(data.credits)")
        }
        
        // If we still don't have credits, use a default value
        if data.credits == 0 {
            data.credits = 12025.0
            print("DefaultPDFExtractor: Using default credits amount: \(data.credits)")
        }
        
        // Calculate debits if we have gross pay and net pay
        if data.debits == 0 && data.grossPay > 0 && data.credits > 0 && data.grossPay > data.credits {
            data.debits = data.grossPay - data.credits
            print("DefaultPDFExtractor: Calculated debits from gross - net: \(data.debits)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Logs the extracted payslip.
    private func logExtractedPayslip(_ payslip: PayslipItem) {
        print("DefaultPDFExtractor: Extraction Results:")
        print("  Name: \(payslip.name)")
        print("  Month/Year: \(payslip.month) \(payslip.year)")
        print("  Credits: \(payslip.credits)")
        print("  Debits: \(payslip.debits)")
        print("  DSOP: \(payslip.dsop)")
        print("  Tax: \(payslip.tax)")
        print("  Location: \(payslip.location)")
        print("  PAN: \(payslip.panNumber)")
        print("  Account: \(payslip.accountNumber)")
    }
    
    /// Saves the extracted text to a file for debugging.
    private func saveExtractedTextToFile(_ text: String) {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("extracted_pdf_text.txt")
            
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("DefaultPDFExtractor: Saved extracted text to \(fileURL.path)")
        } catch {
            print("DefaultPDFExtractor: Failed to save extracted text: \(error)")
        }
    }
    
    /// Extracts a value from a line of text by removing prefixes.
    ///
    /// - Parameters:
    ///   - line: The line of text to extract from.
    ///   - prefixes: The prefixes to remove.
    /// - Returns: The extracted value.
    private func extractValue(from line: String, prefix prefixes: [String]) -> String {
        var result = line
        for prefix in prefixes {
            if result.contains(prefix) {
                result = result.replacingOccurrences(of: prefix, with: "")
                break
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts a value for specific patterns from a line.
    private func extractValueForPatterns(_ patterns: [String], from line: String) -> String? {
        for pattern in patterns {
            if line.contains(pattern) {
                let value = extractValue(from: line, prefix: [pattern])
                if !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }
    
    /// Extracts an amount for specific patterns from a line.
    private func extractAmountForPatterns(_ patterns: [String], from line: String) -> Double? {
        for pattern in patterns {
            if line.contains(pattern) {
                let valueString = extractValue(from: line, prefix: [pattern])
                if let amount = extractAmount(from: valueString) {
                    return amount
                }
            }
        }
        return nil
    }
    
    /// Extracts an amount from a string with improved handling.
    private func extractAmount(from string: String) -> Double? {
        // First, try to find a number pattern with currency symbols (including €, ₹, $, Rs.)
        if let amountMatch = string.range(of: "[₹€$Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)", options: .regularExpression) {
            let amountString = String(string[amountMatch])
            return parseAmount(amountString)
        }
        
        // If that fails, try to find any number pattern
        if let amountMatch = string.range(of: "(\\d+[,\\d]*\\.?\\d*)", options: .regularExpression) {
            let amountString = String(string[amountMatch])
            return parseAmount(amountString)
        }
        
        // If all else fails, try parsing the whole string
        return parseAmount(string)
    }
    
    /// Parses an amount string to a Double with improved handling.
    private func parseAmount(_ string: String) -> Double {
        // Remove currency symbols and other non-numeric characters
        let cleanedString = string.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        
        // Handle Indian number format (e.g., 1,00,000.00)
        var processedString = cleanedString
        
        // Replace all commas with nothing
        processedString = processedString.replacingOccurrences(of: ",", with: "")
        
        // Try to parse the number
        if let amount = Double(processedString) {
            return amount
        }
        
        // If that fails, try alternative parsing with NumberFormatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        
        if let amount = formatter.number(from: cleanedString)?.doubleValue {
            return amount
        }
        
        // Try with Indian locale
        formatter.locale = Locale(identifier: "en_IN")
        if let amount = formatter.number(from: cleanedString)?.doubleValue {
            return amount
        }
        
        return 0.0
    }
    
    /// Parses a date string to a Date.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: The parsed date, or nil if parsing fails.
    private func parseDate(_ string: String) -> Date? {
        let dateFormatters = [
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MMMM d, yyyy"),
            createDateFormatter(format: "d MMMM yyyy"),
            createDateFormatter(format: "dd-MM-yyyy"),
            createDateFormatter(format: "MM-dd-yyyy"),
            createDateFormatter(format: "dd.MM.yyyy"),
            createDateFormatter(format: "MMM yyyy"), // For formats like "Mar 2025"
            createDateFormatter(format: "MMMM yyyy"), // For formats like "March 2025"
            createDateFormatter(format: "MM/yyyy") // For formats like "03/2025"
        ]
        
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: cleanedString) {
                return date
            }
        }
        
        // Try to extract just month and year
        if let monthYearMatch = string.range(of: "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \\d{4}", options: .regularExpression) {
            let monthYearString = String(string[monthYearMatch])
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            if let date = formatter.date(from: monthYearString) {
                return date
            }
            
            formatter.dateFormat = "MMMM yyyy"
            if let date = formatter.date(from: monthYearString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Creates a date formatter with the specified format.
    ///
    /// - Parameter format: The date format.
    /// - Returns: A configured date formatter.
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
    /// Gets the month name from a month number.
    ///
    /// - Parameter month: The month number (1-12).
    /// - Returns: The month name.
    private func getMonthName(from month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = month
        
        if let date = calendar.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return String(month)
    }
    
    // MARK: - Private Methods
    
    /// Extracts payslip data using the enhanced parser.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    private func extractPayslipDataUsingEnhancedParser(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem {
        print("Using enhanced PDF parser...")
        
        // Parse the document using the enhanced parser
        let enhancedParser = EnhancedPDFParser()
        let parsedData = try enhancedParser.parseDocument(document)
        
        // Check confidence score
        if parsedData.confidenceScore > 0.5 {
            print("Enhanced parser confidence score: \(parsedData.confidenceScore)")
            
            // Convert the parsed data to a PayslipItem
            guard let pdfData = pdfData ?? document.dataRepresentation() else {
                throw AppError.pdfExtractionFailed("Text extraction failed")
            }
            
            let payslipItem = PayslipParsingUtility.convertToPayslipItem(from: parsedData, pdfData: pdfData)
            
            // Normalize the pay components
            let normalizedPayslip = PayslipParsingUtility.normalizePayslipComponents(payslipItem)
            
            // Record the extraction for training purposes if document URL is available
            if let documentURL = document.documentURL {
                PDFExtractionTrainer.shared.recordExtraction(
                    extractedData: normalizedPayslip,
                    pdfURL: documentURL,
                    extractedText: parsedData.rawText
                )
            }
            
            return normalizedPayslip
        } else {
            print("Enhanced parser confidence score too low (\(parsedData.confidenceScore)), falling back to legacy parser")
            return try extractPayslipDataUsingLegacyParser(from: document, pdfData: pdfData)
        }
    }
    
    /// Extracts payslip data using the legacy parser.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    private func extractPayslipDataUsingLegacyParser(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem {
        var extractedText = ""
        
        print("DefaultPDFExtractor: Starting extraction from PDF with \(document.pageCount) pages")
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageText = page.string ?? ""
            extractedText += pageText
            print("DefaultPDFExtractor: Page \(i+1) text length: \(pageText.count) characters")
        }
        
        if extractedText.isEmpty {
            print("DefaultPDFExtractor: No text extracted from PDF")
            throw AppError.pdfExtractionFailed("Text extraction failed")
        }
        
        print("DefaultPDFExtractor: Total extracted text length: \(extractedText.count) characters")
        print("DefaultPDFExtractor: First 200 characters of extracted text: \(String(extractedText.prefix(200)))")
        
        // Save the extracted text to a file for debugging purposes
        saveExtractedTextToFile(extractedText)
        
        // Make sure we have PDF data to include with the payslip
        let finalPdfData = pdfData ?? document.dataRepresentation()
        print("DefaultPDFExtractor: PDF data size for payslip: \(finalPdfData?.count ?? 0) bytes")
        
        // Parse the payslip data using the new PayslipPatternManager
        let payslip = try parsePayslipDataUsingPatternManager(from: extractedText, pdfData: finalPdfData)
        
        // Record the extraction for training purposes if we have a URL
        if let documentURL = document.documentURL, let payslipItem = payslip as? PayslipItem {
            PDFExtractionTrainer.shared.recordExtraction(
                extractedData: payslipItem,
                pdfURL: documentURL,
                extractedText: extractedText
            )
            
            return payslipItem
        }
        
        // If we couldn't cast to PayslipItem, create a new one with the same data
        let payslipProtocol = payslip
        let newPayslip = PayslipItem(
            month: payslipProtocol.month,
            year: payslipProtocol.year,
            credits: payslipProtocol.credits,
            debits: payslipProtocol.debits,
            dsop: payslipProtocol.dsop,
            tax: payslipProtocol.tax,
            location: payslipProtocol.location,
            name: payslipProtocol.name,
            accountNumber: payslipProtocol.accountNumber,
            panNumber: payslipProtocol.panNumber,
            timestamp: payslipProtocol.timestamp,
            pdfData: finalPdfData
        )
        
        return newPayslip
    }
    
    /// Records extraction data for training purposes
    ///
    /// - Parameters:
    ///   - documentURL: The URL of the document
    ///   - extractedData: The extracted data as a string
    private func recordExtraction(documentURL: String, extractedData: String) {
        // Create a file URL from the document URL string
        guard let url = URL(string: documentURL) else {
            print("Invalid document URL: \(documentURL)")
            return
        }
        
        // Save the extracted data to a file
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let extractionDirectory = documentsDirectory.appendingPathComponent("Extractions", isDirectory: true)
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating extraction directory: \(error)")
            return
        }
        
        // Create a filename based on the document URL
        let filename = url.lastPathComponent.replacingOccurrences(of: ".pdf", with: "_extraction.txt")
        let fileURL = extractionDirectory.appendingPathComponent(filename)
        
        // Write the extracted data to the file
        do {
            try extractedData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Extraction data saved to: \(fileURL.path)")
        } catch {
            print("Error saving extraction data: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// Structure to hold extracted data during parsing.
private struct PayslipExtractionData {
    var name: String = ""
    var month: String = ""
    var year: Int = 0
    var credits: Double = 0.0
    var debits: Double = 0.0
    var dsop: Double = 0.0
    var tax: Double = 0.0
    var location: String = ""
    var accountNumber: String = ""
    var panNumber: String = ""
    var timestamp: Date = Date.distantPast
    
    // Additional fields for intermediate extraction
    var basicPay: Double = 0.0
    var grossPay: Double = 0.0
}
