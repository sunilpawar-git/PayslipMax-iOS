import Foundation

/// Protocol for providing regex patterns for payslip data extraction
protocol PatternProvider {
    /// Dictionary of general extraction patterns, keyed by field name (e.g., "name").
    var patterns: [String: String] { get }

    /// Dictionary of patterns specifically used for identifying earnings line items.
    var earningsPatterns: [String: String] { get }

    /// Dictionary of patterns specifically used for identifying deduction line items.
    var deductionsPatterns: [String: String] { get }

    /// An array of standard component names typically categorized as earnings.
    var standardEarningsComponents: [String] { get }

    /// An array of standard component names typically categorized as deductions.
    var standardDeductionsComponents: [String] { get }

    /// An array of terms that should generally be ignored when identifying potential pay items.
    var blacklistedTerms: [String] { get }

    /// A dictionary mapping context keys (e.g., "header") to arrays of terms blacklisted specifically within that context.
    var contextSpecificBlacklist: [String: [String]] { get }

    /// Dictionary of patterns used to identify lines where multiple codes might be merged.
    var mergedCodePatterns: [String: String] { get }

    /// The minimum plausible monetary value for an earnings item.
    var minimumEarningsAmount: Double { get }
    /// The minimum plausible monetary value for a deduction item.
    var minimumDeductionsAmount: Double { get }
    /// The minimum plausible monetary value for a DSOP (Defence Services Officers' Provident Fund) item.
    var minimumDSOPAmount: Double { get }
    /// The minimum plausible monetary value for an income tax item.
    var minimumTaxAmount: Double { get }

    /// Adds or updates a pattern in the main `patterns` collection.
    /// - Parameters:
    ///   - key: The field name key for the pattern.
    ///   - pattern: The regex pattern string.
    func addPattern(key: String, pattern: String)
}

/// Default implementation of `PatternProvider`, providing standard patterns for common payslip formats.
class DefaultPatternProvider: PatternProvider {
    /// Internal storage for general patterns.
    private var _patterns: [String: String]
    /// Internal storage for earnings patterns.
    private var _earningsPatterns: [String: String]
    /// Internal storage for deductions patterns.
    private var _deductionsPatterns: [String: String]

    /// Initializes the provider with default pattern sets.
    init() {
        _patterns = DefaultPatternProvider.defaultPatterns
        _earningsPatterns = DefaultPatternProvider.defaultEarningsPatterns
        _deductionsPatterns = DefaultPatternProvider.defaultDeductionsPatterns
    }

    /// Provides the dictionary of general extraction patterns.
    var patterns: [String: String] {
        return _patterns
    }

    /// Provides the dictionary of patterns specifically for earnings extraction.
    var earningsPatterns: [String: String] {
        return _earningsPatterns
    }

    /// Provides the dictionary of patterns specifically for deductions extraction.
    var deductionsPatterns: [String: String] {
        return _deductionsPatterns
    }

    /// Provides the array of standard earnings components.
    var standardEarningsComponents: [String] {
        return DefaultPatternProvider.defaultStandardEarningsComponents
    }

    /// Provides the array of standard deductions components.
    var standardDeductionsComponents: [String] {
        return DefaultPatternProvider.defaultStandardDeductionsComponents
    }

    /// Provides the array of general blacklisted terms.
    var blacklistedTerms: [String] {
        return DefaultPatternProvider.defaultBlacklistedTerms
    }

    /// Provides the dictionary of context-specific blacklisted terms.
    var contextSpecificBlacklist: [String: [String]] {
        return DefaultPatternProvider.defaultContextSpecificBlacklist
    }

    /// Provides the dictionary of patterns to identify merged codes.
    var mergedCodePatterns: [String: String] {
        return DefaultPatternProvider.defaultMergedCodePatterns
    }

    /// Provides the minimum plausible monetary value for an earnings item.
    var minimumEarningsAmount: Double {
        return 100.0
    }

    /// Provides the minimum plausible monetary value for a deduction item.
    var minimumDeductionsAmount: Double {
        return 10.0
    }

    /// Provides the minimum plausible monetary value for a DSOP item.
    var minimumDSOPAmount: Double {
        return 1000.0
    }

    /// Provides the minimum plausible monetary value for an income tax item.
    var minimumTaxAmount: Double {
        return 1000.0
    }

    /// Adds or updates a pattern in the main `patterns` collection.
    /// - Parameters:
    ///   - key: The field name key for the pattern.
    ///   - pattern: The regex pattern string.
    func addPattern(key: String, pattern: String) {
        _patterns[key] = pattern
    }
}
