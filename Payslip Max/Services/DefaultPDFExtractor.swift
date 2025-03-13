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
    /// - Throws: An error if extraction fails.
    func extractPayslipData(from document: PDFDocument) async throws -> any PayslipItemProtocol {
        if useEnhancedParser {
            return try extractPayslipDataUsingEnhancedParser(from: document)
        } else {
            return try extractPayslipDataUsingLegacyParser(from: document)
        }
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
        let (earnings, deductions) = PayslipPatternManager.extractTabularData(from: text)
        print("DefaultPDFExtractor: Extracted earnings: \(earnings)")
        print("DefaultPDFExtractor: Extracted deductions: \(deductions)")
        
        // Add fallback for name if it's missing
        var updatedData = extractedData
        if updatedData["name"] == nil || updatedData["name"]?.isEmpty == true {
            print("DefaultPDFExtractor: Name is missing, trying fallback methods")
            
            // Try to find the name using more generic patterns
            let namePatterns = [
                "(?:Name|Employee|Employee Name)\\s*:?\\s*([A-Za-z\\s.]+)",
                "(?:Officer|Employee)\\s+([A-Za-z\\s.]+)",
                "(?:Mr\\.|Mrs\\.|Ms\\.|Dr\\.)\\s+([A-Za-z\\s.]+)",
                "(?:Pay\\s+slip\\s+for|Salary\\s+statement\\s+of)\\s+([A-Za-z\\s.]+)"
            ]
            
            for pattern in namePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    let nsString = text as NSString
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                    
                    if let match = matches.first, match.numberOfRanges > 1 {
                        let valueRange = match.range(at: 1)
                        let name = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        updatedData["name"] = name
                        print("DefaultPDFExtractor: Found name using fallback pattern: '\(name)'")
                        break
                    }
                }
            }
            
            // If still no name, try to extract any capitalized words that might be a name
            if updatedData["name"] == nil || updatedData["name"]?.isEmpty == true {
                if let nameMatch = text.range(of: "\\b([A-Z][a-z]+\\s+[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?)\\b", options: .regularExpression) {
                    let name = String(text[nameMatch]).trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedData["name"] = name
                    print("DefaultPDFExtractor: Found potential name using capitalization pattern: '\(name)'")
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
        
        // Try using the new pattern manager first
        do {
            return try parsePayslipDataUsingPatternManager(from: text, pdfData: nil)
        } catch {
            print("DefaultPDFExtractor: Error using pattern manager: \(error.localizedDescription). Falling back to legacy method.")
            
            // Create a new PayslipItem with default values
            var extractedData = PayslipExtractionData()
            
            // Split text into lines for processing
            let lines = text.components(separatedBy: .newlines)
            print("DefaultPDFExtractor: Found \(lines.count) lines in text")
            
            // First pass: Extract data using pattern matching
            extractDataUsingPatternMatching(from: lines, into: &extractedData)
            
            // Second pass: Use regular expressions for more complex patterns
            extractDataUsingRegex(from: text, into: &extractedData)
            
            // Third pass: Context-aware extraction for nearby values
            extractDataUsingContextAwareness(from: lines, into: &extractedData)
            
            // Apply fallbacks for missing data
            applyFallbacksForMissingData(&extractedData)
            
            // Create a PayslipItem from the extracted data
            let payslip = PayslipItem(
                month: extractedData.month,
                year: extractedData.year,
                credits: extractedData.credits,
                debits: extractedData.debits,
                dsop: extractedData.dsop,
                tax: extractedData.tax,
                location: extractedData.location,
                name: extractedData.name,
                accountNumber: extractedData.accountNumber,
                panNumber: extractedData.panNumber,
                timestamp: extractedData.timestamp
            )
            
            return payslip
        }
    }
    
    // MARK: - Extraction Methods
    
    /// Extracts data using pattern matching on individual lines.
    private func extractDataUsingPatternMatching(from lines: [String], into data: inout PayslipExtractionData) {
        // Define keyword patterns for different fields
        let namePatterns = ["Name:", "Employee Name:", "Emp Name:", "Employee:", "Name of Employee:"]
        let basicPayPatterns = ["Basic Pay:", "Basic:", "Basic Salary:", "Basic Pay", "BASIC PAY"]
        let grossPayPatterns = ["Gross Pay:", "Gross:", "Gross Salary:", "Gross Earnings:", "Total Earnings:", "Gross Amount:"]
        let netPayPatterns = ["Net Pay:", "Net:", "Net Salary:", "Net Amount:", "Take Home:", "Amount Payable:"]
        let taxPatterns = ["Income Tax:", "Tax:", "TDS:", "I.Tax:", "Income-tax:", "IT:"]
        let dsopPatterns = ["DSOP:", "PF:", "Provident Fund:", "EPF:", "Employee PF:", "PF Contribution:"]
        let locationPatterns = ["Location:", "Place:", "Branch:", "Office:", "Work Location:"]
        let panPatterns = ["PAN:", "PAN No:", "PAN Number:", "Permanent Account Number:"]
        let accountPatterns = ["A/C:", "Account No:", "Bank A/C:", "Account Number:"]
        let datePatterns = ["Pay Date:", "Salary Date:", "Date:", "For the month of:", "Pay Period:", "Month:"]
        
        // Process each line
        for line in lines {
            // Extract name
            if data.name.isEmpty, let name = extractValueForPatterns(namePatterns, from: line) {
                data.name = name
                print("DefaultPDFExtractor: Extracted name: \(name)")
            }
            
            // Extract basic pay
            if data.basicPay == 0, let basicPay = extractAmountForPatterns(basicPayPatterns, from: line) {
                data.basicPay = basicPay
                print("DefaultPDFExtractor: Extracted basic pay: \(basicPay)")
            }
            
            // Extract gross pay (credits)
            if data.grossPay == 0, let grossPay = extractAmountForPatterns(grossPayPatterns, from: line) {
                data.grossPay = grossPay
                data.credits = grossPay // Set credits to gross pay
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
            if data.panNumber.isEmpty, let pan = extractValueForPatterns(panPatterns, from: line) {
                data.panNumber = pan
                print("DefaultPDFExtractor: Extracted PAN: \(pan)")
            }
            
            // Extract account number
            if data.accountNumber.isEmpty, let account = extractValueForPatterns(accountPatterns, from: line) {
                data.accountNumber = account
                print("DefaultPDFExtractor: Extracted account number: \(account)")
            }
            
            // Extract date
            if let dateString = extractValueForPatterns(datePatterns, from: line) {
                if let date = parseDate(dateString) {
                    data.timestamp = date
                    let calendar = Calendar.current
                    data.month = getMonthName(from: calendar.component(.month, from: date))
                    data.year = calendar.component(.year, from: date)
                    print("DefaultPDFExtractor: Extracted date: \(data.month) \(data.year)")
                }
            }
            
            // Extract deductions (debits)
            if line.contains("Total Deduction") || line.contains("Total Deductions") {
                if let deductions = extractAmount(from: line) {
                    data.debits = deductions
                    print("DefaultPDFExtractor: Extracted deductions (debits): \(deductions)")
                }
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
    
    /// Extracts an amount from a string.
    private func extractAmount(from string: String) -> Double? {
        // First, try to find a number pattern with currency symbols
        if let amountMatch = string.range(of: "[₹Rs.\\s]+(\\d+[,\\d]*\\.?\\d*)", options: .regularExpression) {
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
    
    /// Parses an amount string to a Double.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: The parsed amount.
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
        
        // If that fails, try alternative parsing
        if let amount = NumberFormatter().number(from: cleanedString)?.doubleValue {
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
    private func extractPayslipDataUsingEnhancedParser(from document: PDFDocument) throws -> PayslipItem {
        print("Using enhanced PDF parser...")
        
        // Parse the document using the enhanced parser
        let enhancedParser = EnhancedPDFParser()
        let parsedData = try enhancedParser.parseDocument(document)
        
        // Check confidence score
        if parsedData.confidenceScore > 0.5 {
            print("Enhanced parser confidence score: \(parsedData.confidenceScore)")
            
            // Convert the parsed data to a PayslipItem
            guard let pdfData = document.dataRepresentation() else {
                throw PDFExtractionError.textExtractionFailed
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
            return try extractPayslipDataUsingLegacyParser(from: document)
        }
    }
    
    /// Extracts payslip data using the legacy parser.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    private func extractPayslipDataUsingLegacyParser(from document: PDFDocument) throws -> PayslipItem {
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
            throw PDFExtractionError.textExtractionFailed
        }
        
        print("DefaultPDFExtractor: Total extracted text length: \(extractedText.count) characters")
        print("DefaultPDFExtractor: First 200 characters of extracted text: \(String(extractedText.prefix(200)))")
        
        // Save the extracted text to a file for debugging purposes
        saveExtractedTextToFile(extractedText)
        
        // Parse the payslip data using the new PayslipPatternManager
        let payslip = try parsePayslipDataUsingPatternManager(from: extractedText, pdfData: document.dataRepresentation())
        
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
            pdfData: document.dataRepresentation()
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
