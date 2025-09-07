//
//  PatternDefinitions.swift
//  PayslipMax
//
//  Created on: Phase 1 Refactoring
//  Description: Extracted pattern definitions and constants following SOLID principles
//

import Foundation

/// Protocol defining access to pattern definitions and constants
protocol UnifiedPatternDefinitionsProtocol {
    /// Dictionary of general extraction patterns
    var patterns: [String: String] { get }

    /// Dictionary of patterns specifically for earnings extraction
    var earningsPatterns: [String: String] { get }

    /// Dictionary of patterns specifically for deductions extraction
    var deductionsPatterns: [String: String] { get }

    /// Array of standard earnings component codes
    var standardEarningsComponents: [String] { get }

    /// Array of standard deductions component codes
    var standardDeductionsComponents: [String] { get }

    /// Array of general blacklisted terms
    var blacklistedTerms: [String] { get }

    /// Dictionary mapping context keys to arrays of terms blacklisted within those contexts
    var contextSpecificBlacklist: [String: [String]] { get }

    /// Dictionary of patterns used to identify lines where multiple codes might be merged
    var mergedCodePatterns: [String: String] { get }

    /// The minimum plausible monetary value for an earnings item
    var minimumEarningsAmount: Double { get }

    /// The minimum plausible monetary value for a deduction item
    var minimumDeductionsAmount: Double { get }

    /// The minimum plausible monetary value for a DSOP item
    var minimumDSOPAmount: Double { get }

    /// The minimum plausible monetary value for an income tax item
    var minimumTaxAmount: Double { get }

    /// Adds a new pattern to the patterns dictionary
    func addPattern(key: String, pattern: String)
}

/// Default implementation of pattern definitions
class UnifiedPatternDefinitions: UnifiedPatternDefinitionsProtocol {
    private let patternProvider: PatternProvider

    /// Initializes with pattern provider dependency
    /// - Parameter patternProvider: The provider of patterns and definitions
    init(patternProvider: PatternProvider) {
        self.patternProvider = patternProvider
    }

    /// Convenience initializer with default pattern provider
    convenience init() {
        self.init(patternProvider: DefaultPatternProvider())
    }

    var patterns: [String: String] {
        return patternProvider.patterns
    }

    var earningsPatterns: [String: String] {
        return patternProvider.earningsPatterns
    }

    var deductionsPatterns: [String: String] {
        return patternProvider.deductionsPatterns
    }

    var standardEarningsComponents: [String] {
        return patternProvider.standardEarningsComponents
    }

    var standardDeductionsComponents: [String] {
        return patternProvider.standardDeductionsComponents
    }

    var blacklistedTerms: [String] {
        return patternProvider.blacklistedTerms
    }

    var contextSpecificBlacklist: [String: [String]] {
        return patternProvider.contextSpecificBlacklist
    }

    var mergedCodePatterns: [String: String] {
        return patternProvider.mergedCodePatterns
    }

    var minimumEarningsAmount: Double {
        return patternProvider.minimumEarningsAmount
    }

    var minimumDeductionsAmount: Double {
        return patternProvider.minimumDeductionsAmount
    }

    var minimumDSOPAmount: Double {
        return patternProvider.minimumDSOPAmount
    }

    var minimumTaxAmount: Double {
        return patternProvider.minimumTaxAmount
    }

    func addPattern(key: String, pattern: String) {
        patternProvider.addPattern(key: key, pattern: pattern)
    }
}

/// Static wrapper class for backward compatibility with pattern definitions
class UnifiedPatternDefinitionsCompat {
    private static let sharedDefinitions = UnifiedPatternDefinitions()

    // Static properties for backward compatibility
    static var patterns: [String: String] {
        return sharedDefinitions.patterns
    }

    static var earningsPatterns: [String: String] {
        return sharedDefinitions.earningsPatterns
    }

    static var deductionsPatterns: [String: String] {
        return sharedDefinitions.deductionsPatterns
    }

    static var standardEarningsComponents: [String] {
        return sharedDefinitions.standardEarningsComponents
    }

    static var standardDeductionsComponents: [String] {
        return sharedDefinitions.standardDeductionsComponents
    }

    static var blacklistedTerms: [String] {
        return sharedDefinitions.blacklistedTerms
    }

    static var contextSpecificBlacklist: [String: [String]] {
        return sharedDefinitions.contextSpecificBlacklist
    }

    static var mergedCodePatterns: [String: String] {
        return sharedDefinitions.mergedCodePatterns
    }

    static var minimumEarningsAmount: Double {
        return sharedDefinitions.minimumEarningsAmount
    }

    static var minimumDeductionsAmount: Double {
        return sharedDefinitions.minimumDeductionsAmount
    }

    static var minimumDSOPAmount: Double {
        return sharedDefinitions.minimumDSOPAmount
    }

    static var minimumTaxAmount: Double {
        return sharedDefinitions.minimumTaxAmount
    }

    // Static methods for backward compatibility
    static func addPattern(key: String, pattern: String) {
        sharedDefinitions.addPattern(key: key, pattern: pattern)
    }
}
