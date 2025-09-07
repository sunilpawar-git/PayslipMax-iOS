//
//  PatternMatcher.swift
//  PayslipMax
//
//  Created on: Phase 1 Refactoring
//  Description: Extracted pattern matching logic following SOLID principles
//

import Foundation

/// Protocol defining pattern matching capabilities
protocol PatternMatcherProtocol {
    /// Extracts key-value data from text using predefined patterns
    func extractData(from text: String) -> [String: String]

    /// Extracts tabular financial data (earnings and deductions) from payslip text
    func extractTabularData(from text: String) -> ([String: Double], [String: Double])

    /// Extracts month and year information from payslip text
    func extractMonthAndYear(from text: String) -> (month: String?, year: String?)

    /// Extracts a numeric value from text using a specified regex pattern
    func extractNumericValue(from text: String, using pattern: String) -> Double?

    /// Cleans a numeric string value for conversion to a number
    func cleanNumericValue(_ value: String) -> String

    /// Checks if a term is blacklisted in a specific context
    func isBlacklisted(_ term: String, in context: String) -> Bool

    /// Attempts to extract a clean code from a potentially merged code
    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?)

    /// Retrieves a human-readable description for Risk & Hardship component codes
    func getRiskHardshipDescription(for code: String) -> String?
}

/// Default implementation of pattern matching
class PatternMatcher: PatternMatcherProtocol {
    private let patternProvider: PatternProvider
    private let textExtractor: TextExtractor
    private let textExtractorImpl: TextExtractorImplementation

    /// Initializes with dependency injection following SOLID principles
    /// - Parameters:
    ///   - patternProvider: Provider of regex patterns and categorization rules
    ///   - textExtractor: Service for pattern-based text extraction
    ///   - textExtractorImpl: Low-level text extraction implementation
    init(
        patternProvider: PatternProvider,
        textExtractor: TextExtractor,
        textExtractorImpl: TextExtractorImplementation
    ) {
        self.patternProvider = patternProvider
        self.textExtractor = textExtractor
        self.textExtractorImpl = textExtractorImpl
    }

    /// Convenience initializer with default implementations
    convenience init() {
        let provider = DefaultPatternProvider()
        self.init(
            patternProvider: provider,
            textExtractor: DefaultTextExtractor(patternProvider: provider),
            textExtractorImpl: TextExtractorImplementation(patternProvider: provider)
        )
    }

    func extractData(from text: String) -> [String: String] {
        return textExtractor.extractData(from: text)
    }

    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return textExtractor.extractTabularData(from: text)
    }

    func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return textExtractorImpl.extractMonthAndYear(from: text)
    }

    func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return textExtractorImpl.extractNumericValue(from: text, using: pattern)
    }

    func cleanNumericValue(_ value: String) -> String {
        return textExtractorImpl.cleanNumericValue(value)
    }

    func isBlacklisted(_ term: String, in context: String) -> Bool {
        return textExtractorImpl.isBlacklisted(term, in: context)
    }

    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return textExtractorImpl.extractCleanCode(from: code)
    }

    func getRiskHardshipDescription(for code: String) -> String? {
        return textExtractorImpl.getRiskHardshipDescription(for: code)
    }
}

/// Protocol defining pattern validation capabilities
protocol PatternValidatorProtocol {
    /// Validates financial data to ensure values are reasonable
    func validateFinancialData(_ data: [String: Double]) -> [String: Double]

    /// Calculates the total sum of all earnings
    func calculateTotalEarnings(from earnings: [String: Double]) -> Double

    /// Calculates the total sum of all deductions
    func calculateTotalDeductions(from deductions: [String: Double]) -> Double
}

/// Default implementation of pattern validation
class PatternValidator: PatternValidatorProtocol {
    private let validator: PayslipValidator

    /// Initializes with dependency injection
    /// - Parameter validator: Service for validating extracted financial data
    init(validator: PayslipValidator) {
        self.validator = validator
    }

    /// Convenience initializer with default implementation
    convenience init(patternProvider: PatternProvider) {
        self.init(validator: PayslipValidator(patternProvider: patternProvider))
    }

    func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return validator.validateFinancialData(data)
    }

    func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return earnings.values.reduce(0, +)
    }

    func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return deductions.values.reduce(0, +)
    }
}

/// Static wrapper class for backward compatibility
class PatternMatcherCompat {
    private static let sharedMatcher = PatternMatcher()
    private static let sharedValidator = PatternValidator(patternProvider: DefaultPatternProvider())

    // Static methods for backward compatibility
    static func extractData(from text: String) -> [String: String] {
        return sharedMatcher.extractData(from: text)
    }

    static func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return sharedMatcher.extractTabularData(from: text)
    }

    static func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return sharedValidator.calculateTotalEarnings(from: earnings)
    }

    static func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return sharedValidator.calculateTotalDeductions(from: deductions)
    }

    static func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return sharedValidator.validateFinancialData(data)
    }

    static func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return sharedMatcher.extractMonthAndYear(from: text)
    }

    static func cleanNumericValue(_ value: String) -> String {
        return sharedMatcher.cleanNumericValue(value)
    }

    static func isBlacklisted(_ term: String, in context: String) -> Bool {
        return sharedMatcher.isBlacklisted(term, in: context)
    }

    static func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return sharedMatcher.extractNumericValue(from: text, using: pattern)
    }

    static func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return sharedMatcher.extractCleanCode(from: code)
    }

    static func parseAmount(_ amountString: String) -> Double? {
        // Remove currency symbols, commas, and whitespace
        let cleanedString = amountString
            .replacingOccurrences(of: "[$₹,\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleanedString)
    }
}
