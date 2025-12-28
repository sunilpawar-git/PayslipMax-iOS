import Foundation

/// Provides patterns for extracting financial data (earnings and deductions) from payslips.
///
/// This provider is part of the domain-specific pattern architecture, focusing
/// exclusively on financial data patterns. It was extracted from CorePatternsProvider
/// as part of SOLID compliance improvements to achieve better separation of concerns.
///
/// ## Single Responsibility
/// This provider handles only financial patterns:
/// - Earnings components (basic pay, allowances, bonuses)
/// - Deduction components (taxes, insurance, funds)
/// - Financial totals and summaries
///
/// ## Pattern Categories
/// Patterns created by this provider belong to:
/// - `.earnings` category for income-related patterns
/// - `.deductions` category for expense-related patterns
class FinancialPatternsProvider {

    /// Creates pattern definitions for extracting earnings-related financial data.
    /// - Returns: An array of `PatternDefinition` objects for earnings extraction.
    static func getEarningsPatterns() -> [PatternDefinition] {
        [
            createBasicPayPattern(),
            createDearnessAllowancePattern(),
            createMilitaryServicePayPattern(),
            createTotalEarningsPattern()
        ]
    }

    /// Creates pattern definitions for extracting deduction-related financial data.
    /// - Returns: An array of `PatternDefinition` objects for deductions extraction.
    static func getDeductionsPatterns() -> [PatternDefinition] {
        [
            createDSOPPattern(),
            createAGIFPattern(),
            createIncomeTaxPattern(),
            createTotalDeductionsPattern()
        ]
    }

    // MARK: - Earnings Patterns

    private static func createBasicPayPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:basic pay|base pay|bp)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "BPAY[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Basic Pay",
            key: "basicPay",
            category: .earnings,
            patterns: patterns
        )
    }

    private static func createDearnessAllowancePattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:dearness allowance|da)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "DA[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Dearness Allowance",
            key: "dearnessAllowance",
            category: .earnings,
            patterns: patterns
        )
    }

    private static func createMilitaryServicePayPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:military service pay|msp)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "MSP[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Military Service Pay",
            key: "militaryServicePay",
            category: .earnings,
            patterns: patterns
        )
    }

    private static func createTotalEarningsPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:total earnings|gross pay|total income)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:credits|total)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 6
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Total Earnings",
            key: "totalEarnings",
            category: .earnings,
            patterns: patterns
        )
    }

    // MARK: - Deductions Patterns

    private static func createDSOPPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:dsop|defence.*provident)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "DSOP[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "DSOP",
            key: "dsop",
            category: .deductions,
            patterns: patterns
        )
    }

    private static func createAGIFPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:agif|army.*insurance)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "AGIF[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "AGIF",
            key: "agif",
            category: .deductions,
            patterns: patterns
        )
    }

    private static func createIncomeTaxPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:income tax|itax|tax)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:tds|tax deducted)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Income Tax",
            key: "incomeTax",
            category: .deductions,
            patterns: patterns
        )
    }

    private static func createTotalDeductionsPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:total deductions|total debits|debits)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:deductions|total)[\\s:]+([\\d,]+\\.?\\d*)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 6
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Total Deductions",
            key: "totalDeductions",
            category: .deductions,
            patterns: patterns
        )
    }
}
