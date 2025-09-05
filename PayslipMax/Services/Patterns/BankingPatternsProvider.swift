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
    ///
    /// This method defines patterns for identifying banking and payment details:
    /// - Account Number: Bank account numbers in various formats
    /// - IFSC Code: Indian Financial System Code for bank identification
    /// - Bank Name: Financial institution names
    /// - Branch Information: Bank branch details
    ///
    /// ## Pattern Types and Configurations
    ///
    /// ### Account Number Patterns
    /// Patterns for extracting bank account numbers:
    /// - Standard numeric account numbers
    /// - Alphanumeric account formats
    /// - Formatted account numbers with spaces or hyphens
    ///
    /// ### IFSC Code Patterns
    /// Patterns for extracting IFSC (Indian Financial System Code):
    /// - Standard 11-character IFSC format
    /// - IFSC with various separators or formatting
    /// - Context-aware extraction from banking sections
    ///
    /// ### Bank Details
    /// Patterns for extracting bank and branch information:
    /// - Bank names (SBI, HDFC, ICICI, etc.)
    /// - Branch names and locations
    /// - Banking section headers and labels
    ///
    /// - Returns: An array of `PatternDefinition` objects for banking information extraction.
    static func getBankingPatterns() -> [PatternDefinition] {
        // Account Number patterns
        let accountPatterns = [
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
        
        let accountPattern = PatternDefinition.createCorePattern(
            name: "Account Number",
            key: "accountNumber",
            category: .banking,
            patterns: accountPatterns
        )
        
        // IFSC Code patterns
        let ifscPatterns = [
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
        
        let ifscPattern = PatternDefinition.createCorePattern(
            name: "IFSC Code",
            key: "ifscCode",
            category: .banking,
            patterns: ifscPatterns
        )
        
        // Bank Name patterns
        let bankNamePatterns = [
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
        
        let bankNamePattern = PatternDefinition.createCorePattern(
            name: "Bank Name",
            key: "bankName",
            category: .banking,
            patterns: bankNamePatterns
        )
        
        // Branch patterns
        let branchPatterns = [
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
        
        let branchPattern = PatternDefinition.createCorePattern(
            name: "Branch",
            key: "branch",
            category: .banking,
            patterns: branchPatterns
        )
        
        return [accountPattern, ifscPattern, bankNamePattern, branchPattern]
    }
}
