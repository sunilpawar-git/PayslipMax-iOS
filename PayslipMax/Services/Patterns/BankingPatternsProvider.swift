import Foundation

/// Provides patterns for extracting banking information from payslips.
///
/// This provider is part of the domain-specific pattern architecture, focusing
/// exclusively on banking and payment-related patterns. It was extracted from
/// CorePatternsProvider as part of SOLID compliance improvements to achieve
/// better separation of concerns.
///
/// ## Single Responsibility
/// This provider handles only banking-related patterns:
/// - Bank account numbers
/// - IFSC codes
/// - Bank names and branches
/// - Payment destination information
///
/// ## Pattern Categories
/// All patterns created by this provider belong to the `.banking` category
/// in the pattern classification system.
class BankingPatternsProvider {

    /// Creates pattern definitions for extracting banking information from payslips.
    /// - Returns: An array of `PatternDefinition` objects for banking information extraction.
    static func getBankingPatterns() -> [PatternDefinition] {
        [
            createAccountNumberPattern(),
            createIFSCPattern(),
            createBankNamePattern(),
            createBranchPattern()
        ]
    }

    // MARK: - Account Number Pattern

    private static func createAccountNumberPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:account no|acc no|account number)[\\s:]+([\\d\\s\\-]{8,20})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:a/c no|account)[\\s:]+([\\d\\s\\-]{8,20})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 8
            ),
            ExtractorPattern.regex(
                pattern: "account[\\s:]+([\\d]{8,20})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 6
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Account Number",
            key: "accountNumber",
            category: .banking,
            patterns: patterns
        )
    }

    // MARK: - IFSC Pattern

    private static func createIFSCPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:ifsc|ifsc code)[\\s:]+([A-Z]{4}\\d{7})",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:ifsc)[\\s:]+([A-Z]{4}[\\s\\-]?\\d{7})",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 8
            ),
            ExtractorPattern.regex(
                pattern: "([A-Z]{4}\\d{7})",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 6
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "IFSC Code",
            key: "ifscCode",
            category: .banking,
            patterns: patterns
        )
    }

    // MARK: - Bank Name Pattern

    private static func createBankNamePattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:bank|bank name)[\\s:]+([A-Za-z\\s&]+(?:bank|ltd))",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.keyword(
                keyword: "state bank of india",
                contextBefore: "bank",
                priority: 8
            ),
            ExtractorPattern.keyword(
                keyword: "sbi",
                contextBefore: "bank",
                priority: 7
            ),
            ExtractorPattern.regex(
                pattern: "(hdfc|icici|axis|pnb|canara|union|boi)\\s*bank",
                preprocessing: [.normalizeCase],
                postprocessing: [.trim],
                priority: 9
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Bank Name",
            key: "bankName",
            category: .banking,
            patterns: patterns
        )
    }

    // MARK: - Branch Pattern

    private static func createBranchPattern() -> PatternDefinition {
        let patterns = [
            ExtractorPattern.regex(
                pattern: "(?:branch|branch name)[\\s:]+([A-Za-z\\s,]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:branch)[\\s:]+([A-Za-z\\s,]{3,50})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 8
            )
        ]

        return PatternDefinition.createCorePattern(
            name: "Branch",
            key: "branch",
            category: .banking,
            patterns: patterns
        )
    }
}
