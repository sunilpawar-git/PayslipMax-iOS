import Foundation

/// Provides the default system-defined patterns for payslip data extraction.
///
/// This class is a fundamental component of the Pattern Matching System, serving as the central
/// repository for all core pattern definitions used across the application. It operates as a
/// factory class that creates and configures standardized `PatternDefinition` objects, organized
/// by data category.
///
/// The patterns defined here target various payslip formats commonly encountered, including:
/// - Military payslips (Army, Navy, Air Force)
/// - Government employee payslips (PCDA format)
/// - Corporate payslips (standard format)
///
/// Each pattern is configured with:
/// - Appropriate regex or keyword patterns
/// - Preprocessing steps to normalize input text
/// - Postprocessing steps to format extracted values
/// - Priority levels to determine the order of pattern application
///
/// The `CorePatternsProvider` is typically used by the `DefaultPatternRepository` to initialize
/// the system with a standard set of extraction patterns that can be supplemented by user-defined
/// patterns. This separation ensures that core extraction capabilities are preserved even when
/// users customize the pattern library.
class CorePatternsProvider {
    /// Retrieves all default core patterns organized by category.
    ///
    /// This is the primary entry point for obtaining the complete set of system-defined patterns.
    /// The method aggregates patterns from all available categories:
    /// - Personal information (name, rank, dates)
    /// - Earnings (salary components, allowances)
    /// - Deductions (funds, insurances)
    /// - Banking details (account numbers)
    /// - Tax information (TDS, PAN)
    ///
    /// The returned patterns are configured for immediate use with `PatternMatchingService`
    /// or other components that consume `PatternDefinition` objects.
    ///
    /// - Returns: A complete array of core `PatternDefinition` objects across all categories.
    static func getDefaultCorePatterns() -> [PatternDefinition] {
        var patterns: [PatternDefinition] = []
        
        // Add personal information patterns
        patterns.append(contentsOf: getPersonalInfoPatterns())
        
        // Add earnings patterns
        patterns.append(contentsOf: getEarningsPatterns())
        
        // Add deductions patterns
        patterns.append(contentsOf: getDeductionsPatterns())
        
        // Add banking patterns
        patterns.append(contentsOf: getBankingPatterns())
        
        // Add tax patterns
        patterns.append(contentsOf: getTaxPatterns())
        
        return patterns
    }
    
    /// Creates pattern definitions for extracting personal information from payslips.
    ///
    /// This method defines patterns for extracting personal identification details including:
    /// - Full name: Handles various name formats with different prefixes and layouts
    /// - Rank/Grade: Extracts military rank or employment grade information
    /// - Month/Year: Identifies the payslip period using various date formats
    ///
    /// The patterns prioritize the most common formats first (higher priority values)
    /// and include fallback patterns for less standard formats.
    ///
    /// - Returns: An array of `PatternDefinition` objects for personal information extraction.
    static func getPersonalInfoPatterns() -> [PatternDefinition] {
        let namePatterns = [
            // Common name formats
            ExtractorPattern.regex(
                pattern: "(?:name|officer)[\\s:]*([A-Za-z\\s]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.keyword(
                keyword: "name",
                contextAfter: "\n",
                priority: 5
            ),
            ExtractorPattern.regex(
                pattern: "(?:service no & name)[\\s:]*\\d+\\s+([A-Za-z\\s]+)",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim],
                priority: 8
            )
        ]
        
        // Create name pattern definition
        let namePattern = PatternDefinition.createCorePattern(
            name: "Full Name",
            key: "name",
            category: .personal,
            patterns: namePatterns
        )
        
        // Rank pattern
        let rankPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:rank|grade)[\\s:]*([A-Za-z0-9\\s]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            )
        ]
        
        let rankPattern = PatternDefinition.createCorePattern(
            name: "Rank/Grade",
            key: "rank",
            category: .personal,
            patterns: rankPatterns
        )
        
        // Month/Year extraction
        let datePatterns = [
            ExtractorPattern.regex(
                pattern: "(?:for|month of|period)[\\s:]*([A-Za-z]+)[\\s,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:date|month|period)[\\s:]*([A-Za-z]+)[\\s\\-,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 8
            )
        ]
        
        let monthPattern = PatternDefinition.createCorePattern(
            name: "Month",
            key: "month",
            category: .personal,
            patterns: datePatterns
        )
        
        let yearPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:for|month of|period)[\\s:]*[A-Za-z]+[\\s,]+(\\d{4})",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim],
                priority: 10
            )
        ]
        
        let yearPattern = PatternDefinition.createCorePattern(
            name: "Year",
            key: "year",
            category: .personal,
            patterns: yearPatterns
        )
        
        return [namePattern, rankPattern, monthPattern, yearPattern]
    }
    
    /// Creates pattern definitions for extracting earnings-related financial data.
    ///
    /// This method defines patterns for identifying various income components in payslips:
    /// - Basic Pay: The base salary component
    /// - Dearness Allowance (DA): Cost of living compensation 
    /// - Military Service Pay (MSP): Special allowance for military personnel
    /// - Total Earnings: Aggregate sum of all earnings
    ///
    /// These patterns handle various currency formats (₹, Rs., etc.) and numerical
    /// representations (with/without commas, decimal points, etc.).
    ///
    /// - Returns: An array of `PatternDefinition` objects for earnings data extraction.
    static func getEarningsPatterns() -> [PatternDefinition] {
        // Basic Pay pattern
        let basicPayPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:basic pay|bpay)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:basic)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 5
            )
        ]
        
        let basicPayPattern = PatternDefinition.createCorePattern(
            name: "Basic Pay",
            key: "basicPay",
            category: .earnings,
            patterns: basicPayPatterns
        )
        
        // Dearness Allowance
        let daPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:dearness allowance|da)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            )
        ]
        
        let daPattern = PatternDefinition.createCorePattern(
            name: "Dearness Allowance",
            key: "da",
            category: .earnings,
            patterns: daPatterns
        )
        
        // Military Service Pay
        let mspPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:military service pay|msp)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            )
        ]
        
        let mspPattern = PatternDefinition.createCorePattern(
            name: "Military Service Pay",
            key: "msp",
            category: .earnings,
            patterns: mspPatterns
        )
        
        // Total Earnings/Credits
        let totalEarningsPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:total credits|total earnings|gross pay)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:credits|earnings|gross)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 5
            )
        ]
        
        let totalEarningsPattern = PatternDefinition.createCorePattern(
            name: "Total Earnings",
            key: "totalCredits",
            category: .earnings,
            patterns: totalEarningsPatterns
        )
        
        return [basicPayPattern, daPattern, mspPattern, totalEarningsPattern]
    }
    
    /// Creates pattern definitions for extracting deduction-related financial data.
    ///
    /// This method defines patterns for identifying various deductions in payslips:
    /// - DSOP (Defence Services Officers' Provident Fund): Retirement contribution
    /// - AGIF (Army Group Insurance Fund): Insurance premium
    /// - Total Deductions: Aggregate sum of all deductions
    ///
    /// The patterns are designed to handle various formatting conventions and
    /// abbreviations found in different payslip formats.
    ///
    /// - Returns: An array of `PatternDefinition` objects for deductions data extraction.
    static func getDeductionsPatterns() -> [PatternDefinition] {
        // DSOP related patterns
        let dsopPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:dsop|defence service officers provident)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            )
        ]
        
        let dsopPattern = PatternDefinition.createCorePattern(
            name: "DSOP Fund",
            key: "dsop",
            category: .deductions,
            patterns: dsopPatterns
        )
        
        // AGIF related patterns
        let agifPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:agif|army group insurance fund)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            )
        ]
        
        let agifPattern = PatternDefinition.createCorePattern(
            name: "AGIF",
            key: "agif",
            category: .deductions,
            patterns: agifPatterns
        )
        
        // Total deductions pattern
        let totalDeductionsPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:total deductions|total debits)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:deductions|debits)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 5
            )
        ]
        
        let totalDeductionsPattern = PatternDefinition.createCorePattern(
            name: "Total Deductions",
            key: "totalDebits",
            category: .deductions,
            patterns: totalDeductionsPatterns
        )
        
        return [dsopPattern, agifPattern, totalDeductionsPattern]
    }
    
    /// Creates pattern definitions for extracting banking information.
    ///
    /// This method defines patterns for identifying banking details in payslips:
    /// - Account Number: Bank account number associated with the payslip
    ///
    /// The patterns handle various ways account numbers can be formatted and
    /// presented (with/without spaces, with A/C prefix, etc.).
    ///
    /// - Returns: An array of `PatternDefinition` objects for banking information extraction.
    static func getBankingPatterns() -> [PatternDefinition] {
        // Account number patterns
        let accountNumberPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:account|a/c)[\\s:]*(?:no|number)?[\\s:]*([\\d\\s]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .removeNonNumeric],
                priority: 10
            )
        ]
        
        let accountNumberPattern = PatternDefinition.createCorePattern(
            name: "Account Number",
            key: "accountNumber",
            category: .banking,
            patterns: accountNumberPatterns
        )
        
        return [accountNumberPattern]
    }
    
    /// Creates pattern definitions for extracting tax-related information.
    ///
    /// This method defines patterns for identifying tax details in payslips:
    /// - Income Tax: Tax deducted at source (TDS)
    /// - PAN Number: Permanent Account Number, a unique tax identifier in India
    ///
    /// The patterns handle various abbreviations (ITAX, TDS) and formatting
    /// conventions used in different payslip formats.
    ///
    /// - Returns: An array of `PatternDefinition` objects for tax information extraction.
    static func getTaxPatterns() -> [PatternDefinition] {
        // Income tax patterns
        let incomeTaxPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:income tax|itax|i\\.tax)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 10
            ),
            ExtractorPattern.regex(
                pattern: "(?:tax deducted|tds)[\\s:]*(?:Rs\\.?|₹)?\\s*([\\d,.]+)",
                preprocessing: [.normalizeNewlines, .normalizeCase],
                postprocessing: [.trim, .formatAsCurrency],
                priority: 8
            )
        ]
        
        let incomeTaxPattern = PatternDefinition.createCorePattern(
            name: "Income Tax",
            key: "incomeTax",
            category: .taxInfo,
            patterns: incomeTaxPatterns
        )
        
        // PAN number patterns
        let panNumberPatterns = [
            ExtractorPattern.regex(
                pattern: "(?:pan|permanent account number)[\\s:]*([A-Z0-9]{10})",
                preprocessing: [.normalizeNewlines],
                postprocessing: [.trim, .uppercase],
                priority: 10
            )
        ]
        
        let panNumberPattern = PatternDefinition.createCorePattern(
            name: "PAN Number",
            key: "panNumber",
            category: .taxInfo,
            patterns: panNumberPatterns
        )
        
        return [incomeTaxPattern, panNumberPattern]
    }
} 