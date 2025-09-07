//
//  PayslipPatternManager.swift
//  PayslipMax
//
//  Refactored on: Phase 1 Refactoring
//  Description: Refactored to use extracted components following SOLID principles and dependency injection
//

import Foundation

/// A legacy utility class that provides a unified interface for pattern-based payslip extraction.
///
/// `PayslipPatternManager` serves as a facade over the Pattern Matching System, providing a
/// simple, cohesive API for payslip data extraction while abstracting away the complexity of
/// multiple specialized components. In the current architecture, it functions as a compatibility
/// layer between older code and the newer, more modular pattern matching components.
///
/// This class offers two parallel interfaces:
/// 1. **Instance methods** - For new code, leveraging dependency injection
/// 2. **Static methods/properties** - For backward compatibility with existing code
///
/// The manager coordinates several underlying services through extracted components:
/// - `PatternMatcher`: Handles pattern matching and extraction logic
/// - `PatternValidator`: Handles validation and calculation logic
/// - `PatternDefinitions`: Provides access to pattern definitions and constants
/// - `PayslipBuilder`: Constructs PayslipItem objects from extracted data
///
/// While new code should prefer using more specialized components directly, this class remains
/// useful for quick integration or simpler extraction needs.
class PayslipPatternManager {
    // MARK: - Dependencies (Extracted Components)

    /// The pattern matcher for text extraction and pattern matching operations
    private let patternMatcher: PatternMatcherProtocol

    /// The pattern validator for financial data validation and calculations
    private let patternValidator: PatternValidatorProtocol

    /// The pattern definitions provider for constants and configurations
    private let patternDefinitions: PatternDefinitionsProtocol

    /// The service that builds PayslipItem objects from extracted data
    private let payslipBuilder: PayslipBuilder

    // MARK: - Initialization

    /// Initializes the manager with default implementations of all dependencies.
    ///
    /// This initializer creates extracted components with their default implementations.
    /// It provides a convenient way to get a fully configured manager with minimal setup.
    init() {
        let patternProvider = DefaultPatternProvider()
        self.patternMatcher = PatternMatcher()
        self.patternValidator = PatternValidator(patternProvider: patternProvider)
        self.patternDefinitions = PatternDefinitions(patternProvider: patternProvider)
        self.payslipBuilder = PayslipBuilder(
            patternProvider: patternProvider,
            validator: PayslipValidator(patternProvider: patternProvider)
        )
    }

    /// Initializes the manager with custom implementations of extracted components.
    ///
    /// This initializer supports dependency injection, allowing for greater
    /// flexibility, testability, and customization of the extraction process.
    ///
    /// - Parameters:
    ///   - patternMatcher: The pattern matcher for extraction operations
    ///   - patternValidator: The pattern validator for data validation
    ///   - patternDefinitions: The pattern definitions provider
    ///   - payslipBuilder: The service that builds PayslipItem objects
    init(
        patternMatcher: PatternMatcherProtocol,
        patternValidator: PatternValidatorProtocol,
        patternDefinitions: PatternDefinitionsProtocol,
        payslipBuilder: PayslipBuilder
    ) {
        self.patternMatcher = patternMatcher
        self.patternValidator = patternValidator
        self.patternDefinitions = patternDefinitions
        self.payslipBuilder = payslipBuilder
    }
    
    // MARK: - Public Methods

    /// Adds a new pattern to the patterns dictionary.
    ///
    /// This method allows for dynamic registration of new extraction patterns at runtime,
    /// enabling adaptive extraction capabilities for previously unseen payslip formats.
    ///
    /// - Parameters:
    ///   - key: The identifier for the pattern, used to retrieve the extracted value.
    ///   - pattern: The regex pattern string. Should include a capture group to extract the desired value.
    func addPattern(key: String, pattern: String) {
        patternDefinitions.addPattern(key: key, pattern: pattern)
    }

    /// Checks if a term is blacklisted in a specific context.
    ///
    /// This method helps filter out false positives during extraction by checking if a
    /// term appears in a blacklist for a given context.
    ///
    /// - Parameters:
    ///   - term: The term to check against the blacklist.
    ///   - context: The context identifier (e.g., "earnings", "deductions", "header").
    /// - Returns: `true` if the term is blacklisted in the given context, `false` otherwise.
    func isBlacklisted(_ term: String, in context: String) -> Bool {
        return patternMatcher.isBlacklisted(term, in: context)
    }

    /// Attempts to extract a clean code from a potentially merged code.
    ///
    /// In some payslip formats, codes and values may be merged (e.g., "BPAY12500").
    /// This method attempts to separate them into a code and a numeric value.
    ///
    /// - Parameter code: The potentially merged code string to clean.
    /// - Returns: A tuple containing:
    ///   - cleanedCode: The isolated code portion.
    ///   - extractedValue: The numeric value if successfully extracted, otherwise nil.
    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return patternMatcher.extractCleanCode(from: code)
    }

    /// Extracts key-value data from text using predefined patterns.
    ///
    /// This method applies all patterns from the pattern provider to the input text,
    /// collecting successful matches into a dictionary. It's the primary method for
    /// extracting non-tabular information from payslip text.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    func extractData(from text: String) -> [String: String] {
        return patternMatcher.extractData(from: text)
    }

    /// Extracts tabular financial data (earnings and deductions) from payslip text.
    ///
    /// This method identifies line items representing earnings and deductions in the
    /// payslip text and categorizes them appropriately. It handles various tabular
    /// formats commonly found in payslips.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: A tuple containing:
    ///   - First dictionary: Earnings items (code/name → amount).
    ///   - Second dictionary: Deductions items (code/name → amount).
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return patternMatcher.extractTabularData(from: text)
    }

    /// Calculates the total sum of all earnings.
    ///
    /// A convenience method that adds up all values in the earnings dictionary.
    ///
    /// - Parameter earnings: Dictionary of earnings items (code → amount).
    /// - Returns: The sum of all earnings amounts.
    func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return patternValidator.calculateTotalEarnings(from: earnings)
    }

    /// Calculates the total sum of all deductions.
    ///
    /// A convenience method that adds up all values in the deductions dictionary.
    ///
    /// - Parameter deductions: Dictionary of deductions items (code → amount).
    /// - Returns: The sum of all deductions amounts.
    func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return patternValidator.calculateTotalDeductions(from: deductions)
    }

    /// Validates financial data to ensure values are reasonable.
    ///
    /// This method applies validation rules to filter out unlikely or erroneous
    /// financial values based on typical ranges and expectations for payslip data.
    ///
    /// - Parameter data: Dictionary of financial data (code → amount) to validate.
    /// - Returns: A filtered dictionary containing only the validated financial data.
    func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return patternValidator.validateFinancialData(data)
    }

    /// Creates a structured PayslipItem from extracted payslip data.
    ///
    /// This method transforms the raw extracted data into a fully-formed PayslipItem
    /// object that can be stored, displayed, or analyzed.
    ///
    /// - Parameters:
    ///   - extractedData: Dictionary of extracted text data (field identifiers → values).
    ///   - earnings: Dictionary of earnings items (code → amount).
    ///   - deductions: Dictionary of deductions items (code → amount).
    ///   - pdfData: Optional raw PDF data to include in the PayslipItem.
    /// - Returns: A structured PayslipItem containing all the extracted information.
    func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        return payslipBuilder.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: pdfData
        )
    }

    /// Retrieves a human-readable description for Risk & Hardship component codes.
    ///
    /// Military payslips often contain Risk & Hardship (RH) allowances identified by codes.
    /// This method translates those codes into descriptive text.
    ///
    /// - Parameter code: The RH component code (e.g., "RH11", "RH23").
    /// - Returns: A human-readable description of the Risk & Hardship component,
    ///   or nil if not a valid RH code.
    func getRiskHardshipDescription(for code: String) -> String? {
        return patternMatcher.getRiskHardshipDescription(for: code)
    }

    /// Extracts a numeric value from text using a specified regex pattern.
    ///
    /// This method applies a single pattern to extract a numeric value from text.
    /// It handles currency symbols and formatting characters commonly found in financial values.
    ///
    /// - Parameters:
    ///   - text: The text content to extract from.
    ///   - pattern: The regex pattern to use for extraction.
    /// - Returns: The extracted numeric value as a Double, or nil if no match was found
    ///   or the extracted value couldn't be converted to a number.
    func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return patternMatcher.extractNumericValue(from: text, using: pattern)
    }

    /// Extracts month and year information from payslip text.
    ///
    /// This method identifies and parses date information in various formats
    /// commonly found in payslips to determine the month and year.
    ///
    /// - Parameter text: The text content to parse for date information.
    /// - Returns: A tuple containing:
    ///   - month: The extracted month name (e.g., "January"), or nil if not found.
    ///   - year: The extracted year (e.g., "2023"), or nil if not found.
    func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return patternMatcher.extractMonthAndYear(from: text)
    }

    /// Cleans a numeric string value for conversion to a number.
    ///
    /// This method removes or standardizes characters that might interfere with
    /// numeric parsing, such as currency symbols, commas, and formatting characters.
    ///
    /// - Parameter value: The string value to clean.
    /// - Returns: A cleaned string suitable for conversion to a number.
    func cleanNumericValue(_ value: String) -> String {
        return patternMatcher.cleanNumericValue(value)
    }

    /// Parses a complete payslip from raw text content.
    ///
    /// This is a high-level convenience method that performs the complete extraction
    /// process from raw text to structured PayslipItem in a single call.
    ///
    /// - Parameter text: The raw payslip text content.
    /// - Returns: A structured PayslipItem if successful, nil otherwise.
    func parsePayslipData(_ text: String) -> PayslipItem? {
        let extractedData = patternMatcher.extractData(from: text)
        let (earnings, deductions) = patternMatcher.extractTabularData(from: text)

        // Create PayslipItem with extracted data
        return createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions
        )
    }
    
    /// Parses a monetary amount string into a numeric value.
    ///
    /// This method cleans and converts a string representing a monetary amount
    /// to a Double value. It handles common currency notations.
    ///
    /// - Parameter amountString: The amount string to parse (e.g., "$1,234.56", "₹1,000").
    /// - Returns: The parsed amount as a Double, or nil if parsing fails.
    static func parseAmount(_ amountString: String) -> Double? {
        return PatternMatcherCompat.parseAmount(amountString)
    }

    // MARK: - Static Methods for Backward Compatibility

    /// Static version of extractData for backward compatibility with legacy code.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    static func extractData(from text: String) -> [String: String] {
        return PatternMatcherCompat.extractData(from: text)
    }

    /// Static version of extractTabularData for backward compatibility with legacy code.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: A tuple containing earnings and deductions dictionaries.
    static func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return PatternMatcherCompat.extractTabularData(from: text)
    }

    /// Static version of calculateTotalEarnings for backward compatibility with legacy code.
    ///
    /// - Parameter earnings: Dictionary of earnings items.
    /// - Returns: The sum of all earnings amounts.
    static func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return PatternMatcherCompat.calculateTotalEarnings(from: earnings)
    }

    /// Static version of calculateTotalDeductions for backward compatibility with legacy code.
    ///
    /// - Parameter deductions: Dictionary of deductions items.
    /// - Returns: The sum of all deductions amounts.
    static func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return PatternMatcherCompat.calculateTotalDeductions(from: deductions)
    }

    /// Static version of validateFinancialData for backward compatibility with legacy code.
    ///
    /// - Parameter data: Dictionary of financial data to validate.
    /// - Returns: A filtered dictionary containing only the validated financial data.
    static func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return PatternMatcherCompat.validateFinancialData(data)
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
        let manager = PayslipPatternManager()
        return manager.createPayslipItem(
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
        return PatternMatcherCompat.extractData(from: text).isEmpty ? nil : {
            let extractedData = PatternMatcherCompat.extractData(from: text)
            let (earnings, deductions) = PatternMatcherCompat.extractTabularData(from: text)
            let manager = PayslipPatternManager()
            return manager.createPayslipItem(
                from: extractedData,
                earnings: earnings,
                deductions: deductions
            )
        }()
    }

    /// Static version of extractMonthAndYear for backward compatibility with legacy code.
    ///
    /// - Parameter text: The text content to parse for date information.
    /// - Returns: A tuple containing the extracted month and year, or nil values if not found.
    static func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return PatternMatcherCompat.extractMonthAndYear(from: text)
    }

    /// Static version of cleanNumericValue for backward compatibility with legacy code.
    ///
    /// - Parameter value: The string value to clean.
    /// - Returns: A cleaned string suitable for conversion to a number.
    static func cleanNumericValue(_ value: String) -> String {
        return PatternMatcherCompat.cleanNumericValue(value)
    }

    /// Static version of isBlacklisted for backward compatibility with legacy code.
    ///
    /// - Parameters:
    ///   - term: The term to check against the blacklist.
    ///   - context: The context identifier.
    /// - Returns: true if the term is blacklisted in the given context, false otherwise.
    static func isBlacklisted(_ term: String, in context: String) -> Bool {
        return PatternMatcherCompat.isBlacklisted(term, in: context)
    }

    /// Static version of addPattern for backward compatibility with legacy code.
    ///
    /// - Parameters:
    ///   - key: The identifier for the pattern.
    ///   - pattern: The regex pattern string.
    static func addPattern(key: String, pattern: String) {
        PatternDefinitionsCompat.addPattern(key: key, pattern: pattern)
    }
    
    // MARK: - Static Properties for Backward Compatibility

    /// Dictionary of general extraction patterns, providing direct access to
    /// the pattern provider's patterns for backward compatibility.
    static var patterns: [String: String] {
        return PatternDefinitionsCompat.patterns
    }

    /// Dictionary of patterns specifically for earnings extraction, providing direct
    /// access to the pattern provider's earnings patterns for backward compatibility.
    static var earningsPatterns: [String: String] {
        return PatternDefinitionsCompat.earningsPatterns
    }

    /// Dictionary of patterns specifically for deductions extraction, providing direct
    /// access to the pattern provider's deductions patterns for backward compatibility.
    static var deductionsPatterns: [String: String] {
        return PatternDefinitionsCompat.deductionsPatterns
    }

    /// Array of standard earnings component codes, used to determine if an extracted
    /// code should be categorized as an earning, accessible for backward compatibility.
    static var standardEarningsComponents: [String] {
        return PatternDefinitionsCompat.standardEarningsComponents
    }

    /// Array of standard deductions component codes, used to determine if an extracted
    /// code should be categorized as a deduction, accessible for backward compatibility.
    static var standardDeductionsComponents: [String] {
        return PatternDefinitionsCompat.standardDeductionsComponents
    }

    /// Array of general blacklisted terms that should be ignored during extraction,
    /// accessible for backward compatibility.
    static var blacklistedTerms: [String] {
        return PatternDefinitionsCompat.blacklistedTerms
    }

    /// Dictionary mapping context keys to arrays of terms blacklisted within those
    /// specific contexts, accessible for backward compatibility.
    static var contextSpecificBlacklist: [String: [String]] {
        return PatternDefinitionsCompat.contextSpecificBlacklist
    }

    /// Dictionary of patterns used to identify lines where multiple codes might
    /// be merged, accessible for backward compatibility.
    static var mergedCodePatterns: [String: String] {
        return PatternDefinitionsCompat.mergedCodePatterns
    }

    /// The minimum plausible monetary value for an earnings item,
    /// accessible for backward compatibility.
    static var minimumEarningsAmount: Double {
        return PatternDefinitionsCompat.minimumEarningsAmount
    }

    /// The minimum plausible monetary value for a deduction item,
    /// accessible for backward compatibility.
    static var minimumDeductionsAmount: Double {
        return PatternDefinitionsCompat.minimumDeductionsAmount
    }

    /// The minimum plausible monetary value for a DSOP (Defence Services
    /// Officers' Provident Fund) item, accessible for backward compatibility.
    static var minimumDSOPAmount: Double {
        return PatternDefinitionsCompat.minimumDSOPAmount
    }

    /// The minimum plausible monetary value for an income tax item,
    /// accessible for backward compatibility.
    static var minimumTaxAmount: Double {
        return PatternDefinitionsCompat.minimumTaxAmount
    }

    // MARK: - Additional Static Methods for Test Compatibility

    /// Static wrapper for extractNumericValue instance method
    static func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return PatternMatcherCompat.extractNumericValue(from: text, using: pattern)
    }

    /// Static wrapper for extractCleanCode instance method
    static func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return PatternMatcherCompat.extractCleanCode(from: code)
    }
} 