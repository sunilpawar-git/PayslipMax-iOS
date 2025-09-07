import Foundation
import PDFKit

// MARK: - Protocol Definition

/// Protocol for text extraction services
protocol TextExtractor {
    /// Extracts text from a PDF document. Handles potential large documents asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text as a string
    func extractText(from document: PDFDocument) async -> String
    
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
    /// - Parameter text: The text to extract data from
    /// - Returns: A dictionary of extracted data
    func extractData(from text: String) -> [String: String] {
        return TextExtractionStrategies.extractContextualData(
            from: text,
            using: patternProvider.patterns,
            patternProvider: patternProvider
        )
    }
    
    /// Extracts tabular data from text
    ///
    /// - Parameter text: The text to extract data from
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Extract earnings using pattern strategies
        earnings = TextExtractionStrategies.extractEarnings(from: text, using: patternProvider.earningsPatterns)
        
        // Extract deductions using pattern strategies
        deductions = TextExtractionStrategies.extractDeductions(from: text, using: patternProvider.deductionsPatterns)
        
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
                    if TextExtractionValidation.isBlacklisted(code, in: "earnings", patternProvider: patternProvider) && 
                       TextExtractionValidation.isBlacklisted(code, in: "deductions", patternProvider: patternProvider) {
                        continue
                    }
                    
                    // Clean and convert amount
                    let cleaned = TextExtractionValidation.cleanNumericValue(amountStr)
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
    /// - Parameters:
    ///   - term: The term to check
    ///   - context: The context (e.g., "earnings" or "deductions")
    /// - Returns: True if the term is blacklisted in the given context
    func isBlacklisted(_ term: String, in context: String) -> Bool {
        return TextExtractionValidation.isBlacklisted(term, in: context, patternProvider: patternProvider)
    }
    
    /// Attempts to extract a clean code from a potentially merged code
    /// - Parameter code: The code to clean
    /// - Returns: A tuple containing the cleaned code and any extracted value
    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return TextExtractionValidation.extractCleanCode(from: code, patternProvider: patternProvider)
    }
    
    /// Extracts month and year from text
    /// - Parameter text: The text to parse
    /// - Returns: A tuple containing the month and year, or nil if not found
    func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return TextExtractionStrategies.extractMonthAndYear(from: text)
    }
    
    /// Extracts a numeric value from text
    /// - Parameters:
    ///   - text: The text to extract from
    ///   - pattern: The regex pattern to use
    /// - Returns: The extracted numeric value as a Double, or nil if not found
    func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return TextExtractionValidation.extractValidatedNumericValue(from: text, using: pattern)
    }
    
    // MARK: - Helper Methods
    
    /// Get description for Risk & Hardship components
    /// - Parameter code: The component code (e.g., "RH11", "RH23")
    /// - Returns: A human-readable description of the Risk & Hardship component, or nil if not a valid RH code
    func getRiskHardshipDescription(for code: String) -> String? {
        return TextExtractionValidation.getRiskHardshipDescription(for: code, patternProvider: patternProvider)
    }
    
    /// Cleans up a numeric string value
    /// - Parameter value: The string value to clean
    /// - Returns: A cleaned numeric string
    func cleanNumericValue(_ value: String) -> String {
        return TextExtractionValidation.cleanNumericValue(value)
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
    
    /// Extracts text from a PDF document. Handles potential large documents asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text as a string
    func extractText(from document: PDFDocument) async -> String {
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