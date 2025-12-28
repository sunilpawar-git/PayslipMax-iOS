import Foundation

/// Provides patterns for extracting tax-related information from payslips.
///
/// This provider is part of the domain-specific pattern architecture, focusing
/// exclusively on tax and compliance-related patterns. It was extracted from
/// CorePatternsProvider as part of SOLID compliance improvements to achieve
/// better separation of concerns.
///
/// ## Single Responsibility
/// This provider handles only tax-related patterns:
/// - Tax identification numbers (PAN)
/// - Tax deduction amounts
/// - Tax calculation details
/// - Compliance information
///
/// ## Pattern Categories
/// All patterns created by this provider belong to the `.taxInfo` category
/// in the pattern classification system.
class TaxPatternsProvider {

    /// Creates pattern definitions for extracting tax information from payslips.
    /// - Returns: An array of `PatternDefinition` objects for tax information extraction.
    static func getTaxPatterns() -> [PatternDefinition] {
        [
            createPANPattern(),
            createIncomeTaxPattern(),
            createTDSPattern(),
            createProfessionalTaxPattern(),
            createTaxableIncomePattern()
        ]
    }

    // MARK: - PAN Number Pattern

    private static func createPANPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:pan|pan no|pan number)[\\s:]+([A-Z]{5}\\d{4}[A-Z])",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:pan)[\\s:]+([A-Z]{5}[\\s\\-]?\\d{4}[\\s\\-]?[A-Z])",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 8
            ),
            ExtractorPattern.regex(
                pattern: "([A-Z]{5}\\d{4}[A-Z])",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 6
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "PAN Number",
            key: "panNumber",
            category: .taxInfo,
            patterns: patterns
        )
    }

    // MARK: - Income Tax Pattern

    private static func createIncomeTaxPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:income tax|itax|i-tax)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:tax deducted|tax)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Income Tax",
            key: "incomeTax",
            category: .taxInfo,
            patterns: patterns
        )
    }

    // MARK: - TDS Pattern

    private static func createTDSPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:tds|tax deducted at source)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:tds)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "TDS",
            key: "tds",
            category: .taxInfo,
            patterns: patterns
        )
    }

    // MARK: - Professional Tax Pattern

    private static func createProfessionalTaxPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:professional tax|p\\.tax|ptax)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:prof tax|p tax)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Professional Tax",
            key: "professionalTax",
            category: .taxInfo,
            patterns: patterns
        )
    }

    // MARK: - Taxable Income Pattern

    private static func createTaxableIncomePattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:taxable income|taxable pay)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:taxable)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Taxable Income",
            key: "taxableIncome",
            category: .taxInfo,
            patterns: patterns
        )
    }
}
