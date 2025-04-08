import Foundation
import PDFKit

// MARK: - Protocol Definition

/// Protocol for text extraction services
protocol TextExtractor {
    /// Extracts text from a PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text as a string
    func extractText(from document: PDFDocument) -> String
    
    /// Extracts data from text using patterns
    /// - Parameter text: The text to extract data from
    /// - Returns: A dictionary of extracted data with keys and values
    func extractData(from text: String) -> [String: String]
    
    /// Extracts tabular data from text
    /// - Parameter text: The text to extract data from
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractTabularData(from text: String) -> ([String: Double], [String: Double])
}

/// Responsible for extracting text and data from payslip content using patterns
class TextExtractorImplementation {
    private let patternProvider: PatternProvider
    
    init(patternProvider: PatternProvider) {
        self.patternProvider = patternProvider
    }
    
    /// Extracts data from text using the patterns dictionary
    ///
    /// - Parameter text: The text to extract data from
    /// - Returns: A dictionary of extracted data
    func extractData(from text: String) -> [String: String] {
        var extractedData: [String: String] = [:]
        
        // Extract month and year
        let (month, year) = extractMonthAndYear(from: text)
        if let month = month {
            extractedData["month"] = month
        }
        if let year = year {
            extractedData["year"] = year
        }
        
        // Extract other data using patterns
        for (key, pattern) in patternProvider.patterns {
            // Skip month and year patterns as we've already handled them
            if key == "month" || key == "year" || key == "statementPeriod" {
                continue
            }
            
            // Handle numeric values
            if ["grossPay", "totalDeductions", "netRemittance", "tax", "dsop", "credits", "debits"].contains(key) {
                if let value = extractNumericValue(from: text, using: pattern) {
                    extractedData[key] = String(format: "%.2f", value)
                }
                continue
            }
            
            // Handle text values
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: text) {
                        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        extractedData[key] = value
                    }
                }
            }
        }
        
        return extractedData
    }
    
    /// Extracts tabular data from text
    ///
    /// - Parameter text: The text to extract data from
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Extract earnings using patterns
        for (code, pattern) in patternProvider.earningsPatterns {
            if let value = extractNumericValue(from: text, using: pattern) {
                earnings[code] = value
            }
        }
        
        // Extract deductions using patterns
        for (code, pattern) in patternProvider.deductionsPatterns {
            if let value = extractNumericValue(from: text, using: pattern) {
                deductions[code] = value
            }
        }
        
        // Look for tabular data in the format "CODE AMOUNT"
        let tablePattern = "([A-Z][A-Z0-9\\-]+)\\s+(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)"
        if let regex = try? NSRegularExpression(pattern: tablePattern, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 2,
                   let codeRange = Range(match.range(at: 1), in: text),
                   let amountRange = Range(match.range(at: 2), in: text) {
                    let code = String(text[codeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let amountStr = String(text[amountRange])
                    
                    // Skip blacklisted terms
                    if isBlacklisted(code, in: "earnings") && isBlacklisted(code, in: "deductions") {
                        continue
                    }
                    
                    // Clean and convert amount
                    let cleaned = cleanNumericValue(amountStr)
                    if let amount = Double(cleaned) {
                        // Determine if this is an earning or deduction based on code and amount
                        if patternProvider.standardEarningsComponents.contains(code) {
                            if amount >= patternProvider.minimumEarningsAmount {
                                earnings[code] = amount
                            }
                        } else if patternProvider.standardDeductionsComponents.contains(code) {
                            if amount >= patternProvider.minimumDeductionsAmount {
                                deductions[code] = amount
                            }
                        } else {
                            // For unknown codes, use heuristics
                            if code.contains("PAY") || code.contains("ALLOW") || code.contains("SALARY") || code.contains("WAGE") {
                                if amount >= patternProvider.minimumEarningsAmount {
                                    earnings[code] = amount
                                }
                            } else if code.contains("TAX") || code.contains("FUND") || code.contains("FEE") || code.contains("RECOVERY") {
                                if amount >= patternProvider.minimumDeductionsAmount {
                                    deductions[code] = amount
                                }
                            } else if amount >= patternProvider.minimumEarningsAmount {
                                // Default to earnings for large amounts
                                earnings[code] = amount
                            }
                        }
                    }
                }
            }
        }
        
        return (earnings, deductions)
    }
    
    /// Checks if a term is blacklisted in a specific context
    ///
    /// - Parameters:
    ///   - term: The term to check
    ///   - context: The context (e.g., "earnings" or "deductions")
    /// - Returns: True if the term is blacklisted in the given context
    func isBlacklisted(_ term: String, in context: String) -> Bool {
        // Check global blacklist
        if patternProvider.blacklistedTerms.contains(term) {
            return true
        }
        
        // Check context-specific blacklist
        if let contextBlacklist = patternProvider.contextSpecificBlacklist[context], 
           contextBlacklist.contains(term) {
            return true
        }
        
        return false
    }
    
    /// Attempts to extract a clean code from a potentially merged code
    ///
    /// - Parameter code: The code to clean
    /// - Returns: A tuple containing the cleaned code and any extracted value
    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        // Check for numeric prefix pattern (e.g., "3600DSOP")
        if let regex = try? NSRegularExpression(pattern: patternProvider.mergedCodePatterns["numericPrefix"] ?? "^([0-9]+)([A-Z][A-Za-z0-9\\-]*)$", options: []),
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
        
        // Check for abbreviation with delimiter pattern (e.g., "ARR-RSHNA")
        if let regex = try? NSRegularExpression(pattern: patternProvider.mergedCodePatterns["abbreviationPrefix"] ?? "^([A-Z]+)\\-([A-Za-z0-9]+)$", options: []),
           let match = regex.firstMatch(in: code, options: [], range: NSRange(code.startIndex..., in: code)),
           match.numberOfRanges == 3,
           let prefixRange = Range(match.range(at: 1), in: code) {
            
            let prefix = String(code[prefixRange])
            return (prefix, 0.0)
        }
        
        // If no pattern matches, return the original code
        return (code, nil)
    }
    
    /// Extracts month and year from text
    /// - Parameter text: The text to parse
    /// - Returns: A tuple containing the month and year, or nil if not found
    func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        var extractedMonth: String?
        var extractedYear: String?
        
        // First check for explicit "Statement Period: Month Year" pattern
        if let regex = try? NSRegularExpression(pattern: "(?:Statement\\s*Period|Period|For\\s*the\\s*Month|Pay\\s*Period|Pay\\s*Date)\\s*:?\\s*([A-Za-z]+)\\s*(\\d{4})", options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 2,
           let monthRange = Range(match.range(at: 1), in: text),
           let yearRange = Range(match.range(at: 2), in: text) {
            extractedMonth = String(text[monthRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            extractedYear = String(text[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If we didn't find that pattern, try to extract from date formats like "15/04/2023" or "2023-04-15"
        if extractedMonth == nil || extractedYear == nil {
            if let regex = try? NSRegularExpression(pattern: "\\d{1,2}[/-](\\d{1,2})[/-](\\d{4})", options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 2,
               let monthRange = Range(match.range(at: 1), in: text),
               let yearRange = Range(match.range(at: 2), in: text) {
                let monthNumber = Int(String(text[monthRange]))
                if let monthNum = monthNumber, monthNum >= 1, monthNum <= 12 {
                    extractedMonth = monthNumberToText(monthNum)
                }
                extractedYear = String(text[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // If we still don't have month/year, try other formats
        if extractedMonth == nil || extractedYear == nil {
            // Try DD MonthName YYYY format
            if let regex = try? NSRegularExpression(pattern: "\\d{1,2}\\s+([A-Za-z]+)\\s+(\\d{4})", options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 2,
               let monthRange = Range(match.range(at: 1), in: text),
               let yearRange = Range(match.range(at: 2), in: text) {
                extractedMonth = String(text[monthRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                extractedYear = String(text[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Try MonthName YYYY format
            else if let regex = try? NSRegularExpression(pattern: "([A-Za-z]+)\\s+(\\d{4})", options: []),
                    let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
                    match.numberOfRanges > 2,
                    let monthRange = Range(match.range(at: 1), in: text),
                    let yearRange = Range(match.range(at: 2), in: text) {
                let potentialMonth = String(text[monthRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isValidMonthName(potentialMonth) {
                    extractedMonth = potentialMonth
                    extractedYear = String(text[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // If we still don't have a month or year, try looking for them separately
        if extractedMonth == nil {
            if let regex = try? NSRegularExpression(pattern: "(?:Month|Pay\\s*Month|Statement\\s*Month|For\\s*Month|Month\\s*of)\\s*:?\\s*([A-Za-z]+)", options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let monthRange = Range(match.range(at: 1), in: text) {
                extractedMonth = String(text[monthRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if extractedYear == nil {
            if let regex = try? NSRegularExpression(pattern: "\\b(20\\d{2})\\b", options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let yearRange = Range(match.range(at: 1), in: text) {
                extractedYear = String(text[yearRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Validate month name
        if let month = extractedMonth, !isValidMonthName(month) {
            extractedMonth = nil
        }
        
        return (extractedMonth, extractedYear)
    }
    
    /// Extracts a numeric value from text
    /// - Parameters:
    ///   - text: The text to extract from
    ///   - pattern: The regex pattern to use
    /// - Returns: The extracted numeric value as a Double, or nil if not found
    func extractNumericValue(from text: String, using pattern: String) -> Double? {
        // Find the match for the provided pattern
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1, // Ensure we have at least one capture group
              let valueRangeNS = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        // Extract the matched value and clean it
        let valueStr = String(text[valueRangeNS])
        let cleanedValueStr = cleanNumericValue(valueStr)
        
        // Convert to Double
        return Double(cleanedValueStr)
    }
    
    // MARK: - Helper Methods
    
    /// Get description for Risk & Hardship components
    ///
    /// - Parameter code: The component code (e.g., "RH11", "RH23")
    /// - Returns: A human-readable description of the Risk & Hardship component, or nil if not a valid RH code
    func getRiskHardshipDescription(for code: String) -> String? {
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
    
    /// Cleans up a numeric string value
    /// - Parameter value: The string value to clean
    /// - Returns: A cleaned numeric string
    func cleanNumericValue(_ value: String) -> String {
        // Remove currency symbols including "Rs." and other representations
        var cleanValue = value
            .replacingOccurrences(of: "Rs\\.?\\s*", with: "", options: .regularExpression) // Handle "Rs." or "Rs "
            .replacingOccurrences(of: "[$₹€£¥]\\s*", with: "", options: .regularExpression) // Handle currency symbols
            .replacingOccurrences(of: ",", with: "") // Remove commas
            .trimmingCharacters(in: .whitespacesAndNewlines) // Trim whitespace
        
        // Handle negative values in parentheses - e.g., (1234.56) -> -1234.56
        if cleanValue.hasPrefix("(") && cleanValue.hasSuffix(")") {
            cleanValue = "-" + cleanValue.dropFirst().dropLast()
        }
        
        return cleanValue
    }
    
    /// Checks if a string is a valid month name
    /// - Parameter month: The month name to check
    /// - Returns: true if valid, false otherwise
    private func isValidMonthName(_ month: String) -> Bool {
        let monthNames = ["January", "February", "March", "April", "May", "June", 
                          "July", "August", "September", "October", "November", "December"]
        let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        let normalizedMonth = month.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return monthNames.contains { $0.lowercased() == normalizedMonth } ||
               shortMonthNames.contains { $0.lowercased() == normalizedMonth }
    }
    
    /// Converts a month number to its text representation
    /// - Parameter month: The month number (1-12)
    /// - Returns: The month name
    private func monthNumberToText(_ month: Int) -> String? {
        let monthNames = ["January", "February", "March", "April", "May", "June", 
                          "July", "August", "September", "October", "November", "December"]
        
        guard month >= 1 && month <= 12 else { return nil }
        return monthNames[month - 1]
    }
}

// MARK: - Default Implementation

/// Default implementation of TextExtractor that uses PDFKit for text extraction
class DefaultTextExtractor: TextExtractor {
    private let patternProvider: PatternProvider
    private let extractor: TextExtractorImplementation
    
    init(patternProvider: PatternProvider = DefaultPatternProvider()) {
        self.patternProvider = patternProvider
        self.extractor = TextExtractorImplementation(patternProvider: patternProvider)
    }
    
    /// Extracts text from a PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text as a string
    func extractText(from document: PDFDocument) -> String {
        var allText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if let pageText = page.string {
                    allText += pageText
                }
            }
        }
        
        return allText
    }
    
    /// Extracts data from text using patterns
    /// - Parameter text: The text to extract data from
    /// - Returns: A dictionary of extracted data with keys and values
    func extractData(from text: String) -> [String: String] {
        return extractor.extractData(from: text)
    }
    
    /// Extracts tabular data from text
    /// - Parameter text: The text to extract data from
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return extractor.extractTabularData(from: text)
    }
} 