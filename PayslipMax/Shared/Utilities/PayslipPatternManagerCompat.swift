//
//  PayslipPatternManagerCompat.swift
//  PayslipMax
//
//  Created on: Phase 3 Refactoring - Extracted static compatibility methods
//  Description: Static wrapper methods for backward compatibility with legacy code
//

import Foundation

/// Static wrapper class providing backward compatibility for PayslipPatternManager
/// This class contains all static methods that were previously in PayslipPatternManager
/// to maintain API compatibility while allowing the main manager to be refactored
class PayslipPatternManagerCompat {
    private static let sharedManager = PayslipPatternManager()

    // MARK: - Static Methods for Backward Compatibility

    /// Static version of parseAmount for backward compatibility with legacy code.
    ///
    /// - Parameter amountString: The amount string to parse (e.g., "$1,234.56", "₹1,000").
    /// - Returns: The parsed amount as a Double, or nil if parsing fails.
    static func parseAmount(_ amountString: String) -> Double? {
        return UnifiedPatternMatcherCompat.parseAmount(amountString)
    }

    /// Static version of extractData for backward compatibility with legacy code.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    static func extractData(from text: String) -> [String: String] {
        return UnifiedPatternMatcherCompat.extractData(from: text)
    }

    /// Static version of extractTabularData for backward compatibility with legacy code.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: A tuple containing earnings and deductions dictionaries.
    static func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return UnifiedPatternMatcherCompat.extractTabularData(from: text)
    }

    /// Static version of calculateTotalEarnings for backward compatibility with legacy code.
    ///
    /// - Parameter earnings: Dictionary of earnings items.
    /// - Returns: The sum of all earnings amounts.
    static func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return UnifiedPatternMatcherCompat.calculateTotalEarnings(from: earnings)
    }

    /// Static version of calculateTotalDeductions for backward compatibility with legacy code.
    ///
    /// - Parameter deductions: Dictionary of deductions items.
    /// - Returns: The sum of all deductions amounts.
    static func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return UnifiedPatternMatcherCompat.calculateTotalDeductions(from: deductions)
    }

    /// Static version of validateFinancialData for backward compatibility with legacy code.
    ///
    /// - Parameter data: Dictionary of financial data to validate.
    /// - Returns: A filtered dictionary containing only the validated financial data.
    static func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return UnifiedPatternMatcherCompat.validateFinancialData(data)
    }

    /// Static version of createPayslipItem for backward compatibility with legacy code.
    ///
    /// - Parameters:
    ///   - extractedData: Dictionary of extracted text data.
    ///   - earnings: Dictionary of earnings items.
    ///   - deductions: Dictionary of deductions items.
    ///   - pdfData: Optional raw PDF data.
    /// - Returns: A structured PayslipItem containing all the extracted information.
    static func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        return sharedManager.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: pdfData
        )
    }

    /// Static version of parsePayslipData for backward compatibility with legacy code.
    ///
    /// - Parameter text: The raw payslip text content.
    /// - Returns: A structured PayslipItem if successful, nil otherwise.
    static func parsePayslipData(_ text: String) -> PayslipItem? {
        let extractedData = UnifiedPatternMatcherCompat.extractData(from: text)
        let (earnings, deductions) = UnifiedPatternMatcherCompat.extractTabularData(from: text)
        return sharedManager.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions
        )
    }

    /// Static version of extractMonthAndYear for backward compatibility with legacy code.
    ///
    /// - Parameter text: The text content to parse for date information.
    /// - Returns: A tuple containing the extracted month and year, or nil values if not found.
    static func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return UnifiedPatternMatcherCompat.extractMonthAndYear(from: text)
    }

    /// Static version of cleanNumericValue for backward compatibility with legacy code.
    ///
    /// - Parameter value: The string value to clean.
    /// - Returns: A cleaned string suitable for conversion to a number.
    static func cleanNumericValue(_ value: String) -> String {
        return UnifiedPatternMatcherCompat.cleanNumericValue(value)
    }

    /// Static version of isBlacklisted for backward compatibility with legacy code.
    ///
    /// - Parameters:
    ///   - term: The term to check against the blacklist.
    ///   - context: The context identifier.
    /// - Returns: true if the term is blacklisted in the given context, false otherwise.
    static func isBlacklisted(_ term: String, in context: String) -> Bool {
        return UnifiedPatternMatcherCompat.isBlacklisted(term, in: context)
    }

    /// Static version of addPattern for backward compatibility with legacy code.
    ///
    /// - Parameters:
    ///   - key: The identifier for the pattern.
    ///   - pattern: The regex pattern string.
    static func addPattern(key: String, pattern: String) {
        UnifiedPatternDefinitionsCompat.addPattern(key: key, pattern: pattern)
    }

    /// Static version of extractNumericValue instance method
    static func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return UnifiedPatternMatcherCompat.extractNumericValue(from: text, using: pattern)
    }

    /// Static version of extractCleanCode instance method
    static func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return UnifiedPatternMatcherCompat.extractCleanCode(from: code)
    }

    // MARK: - Static Properties for Backward Compatibility

    /// Dictionary of general extraction patterns, providing direct access to
    /// the pattern provider's patterns for backward compatibility.
    static var patterns: [String: String] {
        return UnifiedPatternDefinitionsCompat.patterns
    }

    /// Dictionary of patterns specifically for earnings extraction, providing direct
    /// access to the pattern provider's earnings patterns for backward compatibility.
    static var earningsPatterns: [String: String] {
        return UnifiedPatternDefinitionsCompat.earningsPatterns
    }

    /// Dictionary of patterns specifically for deductions extraction, providing direct
    /// access to the pattern provider's deductions patterns for backward compatibility.
    static var deductionsPatterns: [String: String] {
        return UnifiedPatternDefinitionsCompat.deductionsPatterns
    }

    /// Array of standard earnings component codes, used to determine if an extracted
    /// code should be categorized as an earning, accessible for backward compatibility.
    static var standardEarningsComponents: [String] {
        return UnifiedPatternDefinitionsCompat.standardEarningsComponents
    }

    /// Array of standard deductions component codes, used to determine if an extracted
    /// code should be categorized as a deduction, accessible for backward compatibility.
    static var standardDeductionsComponents: [String] {
        return UnifiedPatternDefinitionsCompat.standardDeductionsComponents
    }

    /// Array of general blacklisted terms that should be ignored during extraction,
    /// accessible for backward compatibility.
    static var blacklistedTerms: [String] {
        return UnifiedPatternDefinitionsCompat.blacklistedTerms
    }

    /// Dictionary mapping context keys to arrays of terms blacklisted within those
    /// specific contexts, accessible for backward compatibility.
    static var contextSpecificBlacklist: [String: [String]] {
        return UnifiedPatternDefinitionsCompat.contextSpecificBlacklist
    }

    /// Dictionary of patterns used to identify lines where multiple codes might
    /// be merged, accessible for backward compatibility.
    static var mergedCodePatterns: [String: String] {
        return UnifiedPatternDefinitionsCompat.mergedCodePatterns
    }

    /// The minimum plausible monetary value for an earnings item,
    /// accessible for backward compatibility.
    static var minimumEarningsAmount: Double {
        return UnifiedPatternDefinitionsCompat.minimumEarningsAmount
    }

    /// The minimum plausible monetary value for a deduction item,
    /// accessible for backward compatibility.
    static var minimumDeductionsAmount: Double {
        return UnifiedPatternDefinitionsCompat.minimumDeductionsAmount
    }

    /// The minimum plausible monetary value for a DSOP (Defence Services
    /// Officers' Provident Fund) item, accessible for backward compatibility.
    static var minimumDSOPAmount: Double {
        return UnifiedPatternDefinitionsCompat.minimumDSOPAmount
    }

    /// The minimum plausible monetary value for an income tax item,
    /// accessible for backward compatibility.
    static var minimumTaxAmount: Double {
        return UnifiedPatternDefinitionsCompat.minimumTaxAmount
    }
}
