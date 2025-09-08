import Foundation

/// Handles loading and initialization of pattern sets for payslip data extraction.
///
/// This component is responsible for the pattern loading concern extracted from
/// PatternMatchingService as part of the SOLID compliance improvement initiative.
/// It focuses solely on obtaining and organizing pattern data from various sources.
///
/// ## Single Responsibility
/// The PatternLoader has one clear responsibility: loading pattern configurations
/// from external sources and organizing them for use by pattern matching components.
/// This separation allows pattern loading logic to be modified independently of
/// pattern matching algorithms.
///
/// ## Pattern Sources
/// Currently supports loading patterns from:
/// - PayslipPatternManager (legacy static provider)
/// - Future: Database configurations
/// - Future: External configuration files
/// - Future: Dynamic pattern updates
class PatternLoader: PatternLoaderProtocol {

    // MARK: - Pattern Loading

    /// Loads the complete set of pattern configurations from available sources.
    ///
    /// This method aggregates patterns from all configured sources and returns
    /// them in a structured format suitable for pattern matching operations.
    /// The returned configuration includes all pattern types and supporting data
    /// required for comprehensive payslip data extraction.
    ///
    /// The loading process is designed to be fault-tolerant, falling back to
    /// default empty collections if any pattern source is unavailable.
    ///
    /// - Returns: A complete pattern configuration including all pattern types and metadata.
    func loadPatternConfiguration() -> PatternConfiguration {
        do {
            return try loadFromPatternManager()
        } catch {
            print("PatternLoader: Failed to load patterns from PayslipPatternManager: \(error)")
            return createEmptyConfiguration()
        }
    }

    /// Loads pattern configuration from the legacy PayslipPatternManager.
    ///
    /// This method provides a bridge to the existing pattern management system
    /// while allowing for future migration to more flexible pattern storage
    /// mechanisms. It handles the conversion from the legacy static interface
    /// to the structured configuration format.
    ///
    /// - Returns: Pattern configuration loaded from PayslipPatternManager.
    /// - Throws: PatternLoadingError if loading fails.
    private func loadFromPatternManager() throws -> PatternConfiguration {
        let configuration = PatternConfiguration(
            patterns: PayslipPatternManagerCompat.patterns,
            earningsPatterns: PayslipPatternManagerCompat.earningsPatterns,
            deductionsPatterns: PayslipPatternManagerCompat.deductionsPatterns,
            standardEarningsComponents: PayslipPatternManagerCompat.standardEarningsComponents,
            standardDeductionsComponents: PayslipPatternManagerCompat.standardDeductionsComponents,
            blacklistedTerms: PayslipPatternManagerCompat.blacklistedTerms,
            contextSpecificBlacklist: PayslipPatternManagerCompat.contextSpecificBlacklist
        )

        // Validate the loaded configuration
        try validateLoadedConfiguration(configuration)

        print("PatternLoader: Successfully loaded configuration with \(configuration.patterns.count) patterns, \(configuration.earningsPatterns.count) earnings patterns, and \(configuration.deductionsPatterns.count) deductions patterns")

        return configuration
    }

    /// Creates an empty pattern configuration for fallback scenarios.
    ///
    /// This method provides a safe fallback when pattern loading fails,
    /// ensuring that the pattern matching system can still operate even
    /// if no patterns are available from external sources.
    ///
    /// - Returns: An empty but valid pattern configuration.
    private func createEmptyConfiguration() -> PatternConfiguration {
        print("PatternLoader: Creating empty pattern configuration as fallback")
        return PatternConfiguration(
            patterns: [:],
            earningsPatterns: [:],
            deductionsPatterns: [:],
            standardEarningsComponents: [],
            standardDeductionsComponents: [],
            blacklistedTerms: [],
            contextSpecificBlacklist: [:]
        )
    }

    /// Validates a loaded pattern configuration for basic consistency.
    ///
    /// This method performs basic validation checks on loaded patterns to
    /// ensure they meet minimum requirements for pattern matching operations.
    /// It checks for basic structure and format compliance.
    ///
    /// - Parameter configuration: The configuration to validate.
    /// - Throws: PatternLoadingError if validation fails.
    private func validateLoadedConfiguration(_ configuration: PatternConfiguration) throws {
        // Basic validation - ensure patterns are not completely empty
        // More sophisticated validation could be added here in the future
        if configuration.patterns.isEmpty &&
           configuration.earningsPatterns.isEmpty &&
           configuration.deductionsPatterns.isEmpty {
            throw PatternLoadingError.emptyConfiguration
        }

        // Validate that pattern strings are not empty
        for (key, pattern) in configuration.patterns {
            if pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw PatternLoadingError.invalidPattern(key: key, reason: "Empty pattern string")
            }
        }

        // Additional validation can be added here as needed
    }

    // MARK: - PatternLoaderProtocol Methods

    /// Reloads the pattern configuration from the source.
    ///
    /// This method provides the same functionality as `loadPatternConfiguration()`
    /// since the current implementation always loads fresh patterns from the source.
    /// Future implementations may cache patterns and use this method for explicit reloading.
    ///
    /// - Returns: The updated pattern configuration
    func reloadPatternConfiguration() -> PatternConfiguration {
        return loadPatternConfiguration()
    }

    /// Validates that the pattern configuration is correctly formed.
    ///
    /// This method performs basic validation checks on the configuration to ensure
    /// it contains valid patterns and meets minimum requirements for operation.
    ///
    /// - Parameter configuration: The configuration to validate
    /// - Returns: True if the configuration is valid, false otherwise
    func validateConfiguration(_ configuration: PatternConfiguration) -> Bool {
        // Check that we have some patterns defined
        guard !configuration.patterns.isEmpty else {
            print("PatternLoader: Validation failed - no general patterns found")
            return false
        }

        // Check that essential pattern categories exist
        let hasEarningsPatterns = configuration.earningsPatterns.count > 0
        let hasDeductionsPatterns = configuration.deductionsPatterns.count > 0

        if !hasEarningsPatterns {
            print("PatternLoader: Warning - no earnings patterns found")
        }

        if !hasDeductionsPatterns {
            print("PatternLoader: Warning - no deductions patterns found")
        }

        print("PatternLoader: Configuration validation passed")
        return true
    }
}

// MARK: - Supporting Types

/// Configuration structure containing all pattern data required for extraction operations.
struct PatternConfiguration {
    /// Dictionary of regex patterns for extracting general key-value data from payslips.
    let patterns: [String: String]

    /// Dictionary of regex patterns specifically for extracting earnings-related financial data.
    let earningsPatterns: [String: String]

    /// Dictionary of regex patterns specifically for extracting deduction-related financial data.
    let deductionsPatterns: [String: String]

    /// Standard earnings components for categorization of tabular data.
    let standardEarningsComponents: [String]

    /// Standard deductions components for categorization of tabular data.
    let standardDeductionsComponents: [String]

    /// Terms that should never be considered as pay items (blacklist).
    let blacklistedTerms: [String]

    /// Context-specific blacklisted terms mapped by context identifier.
    let contextSpecificBlacklist: [String: [String]]
}

/// Errors that can occur during pattern loading operations.
enum PatternLoadingError: Error, LocalizedError {
    case emptyConfiguration
    case invalidPattern(key: String, reason: String)
    case sourceUnavailable(source: String)

    var errorDescription: String? {
        switch self {
        case .emptyConfiguration:
            return "Pattern configuration is completely empty"
        case .invalidPattern(let key, let reason):
            return "Invalid pattern for key '\(key)': \(reason)"
        case .sourceUnavailable(let source):
            return "Pattern source '\(source)' is unavailable"
        }
    }
}
