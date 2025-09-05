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
    ///
    /// This method defines patterns for identifying various income components in payslips:
    /// - Basic Pay: The base salary component
    /// - Dearness Allowance (DA): Cost of living compensation 
    /// - Military Service Pay (MSP): Special allowance for military personnel
    /// - Total Earnings: Aggregate sum of all earnings
    ///
    /// ## Pattern Types and Configurations
    ///
    /// ### Basic Pay Patterns
    /// Primary and fallback patterns for identifying the base salary component:
    /// - Direct patterns matching "basic pay:" followed by amount
    /// - Abbreviated patterns for "BP:" or "BPAY:"
    /// - Table-style patterns for tabular data layouts
    ///
    /// ### Allowance Patterns
    /// Specialized patterns for different types of allowances:
    /// - Dearness Allowance (DA): Cost of living adjustments
    /// - Military Service Pay: Service-specific compensation
    /// - Housing and transport allowances
    ///
    /// ### Total Earnings
    /// Patterns for identifying aggregate earnings totals which serve as validation
    /// points for individual component extraction.
    ///
    /// - Returns: An array of `PatternDefinition` objects for earnings extraction.
    static func getEarningsPatterns() -> [PatternDefinition] {
        // Basic Pay patterns
        let basicPayPatterns = [
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
        
        let basicPayPattern = PatternDefinition.createCorePattern(
            name: "Basic Pay",
            key: "basicPay",
            category: .earnings,
            patterns: basicPayPatterns
        )
        
        // Dearness Allowance patterns
        let daPatterns = [
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
        
        let daPattern = PatternDefinition.createCorePattern(
            name: "Dearness Allowance",
            key: "dearnessAllowance",
            category: .earnings,
            patterns: daPatterns
        )
        
        // Military Service Pay patterns
        let mspPatterns = [
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
        
        let mspPattern = PatternDefinition.createCorePattern(
            name: "Military Service Pay",
            key: "militaryServicePay",
            category: .earnings,
            patterns: mspPatterns
        )
        
        // Total Earnings patterns
        let totalEarningsPatterns = [
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
        
        let totalEarningsPattern = PatternDefinition.createCorePattern(
            name: "Total Earnings",
            key: "totalEarnings",
            category: .earnings,
            patterns: totalEarningsPatterns
        )
        
        return [basicPayPattern, daPattern, mspPattern, totalEarningsPattern]
    }
    
    /// Creates pattern definitions for extracting deduction-related financial data.
    ///
    /// This method defines patterns for identifying various deduction components in payslips:
    /// - DSOP (Defence Services Officers Provident Fund): Retirement savings
    /// - AGIF (Army Group Insurance Fund): Insurance premiums
    /// - Income Tax: Tax deductions
    /// - Total Deductions: Aggregate sum of all deductions
    ///
    /// ## Pattern Types and Configurations
    ///
    /// ### Retirement Fund Patterns
    /// Patterns for various provident fund and retirement saving deductions:
    /// - DSOP: Military-specific provident fund
    /// - GPF: General Provident Fund for government employees
    /// - PF: Generic provident fund patterns
    ///
    /// ### Insurance Patterns
    /// Patterns for insurance-related deductions:
    /// - AGIF: Army Group Insurance Fund
    /// - Life insurance premiums
    /// - Medical insurance deductions
    ///
    /// ### Tax Patterns
    /// Patterns for tax-related deductions:
    /// - Income tax (various formats)
    /// - Professional tax
    /// - Service tax
    ///
    /// ### Total Deductions
    /// Patterns for aggregate deduction amounts that serve as validation
    /// points for individual component extraction.
    ///
    /// - Returns: An array of `PatternDefinition` objects for deductions extraction.
    static func getDeductionsPatterns() -> [PatternDefinition] {
        // DSOP patterns
        let dsopPatterns = [
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
        
        let dsopPattern = PatternDefinition.createCorePattern(
            name: "DSOP",
            key: "dsop",
            category: .deductions,
            patterns: dsopPatterns
        )
        
        // AGIF patterns
        let agifPatterns = [
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
        
        let agifPattern = PatternDefinition.createCorePattern(
            name: "AGIF",
            key: "agif",
            category: .deductions,
            patterns: agifPatterns
        )
        
        // Income Tax patterns
        let taxPatterns = [
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
        
        let taxPattern = PatternDefinition.createCorePattern(
            name: "Income Tax",
            key: "incomeTax",
            category: .deductions,
            patterns: taxPatterns
        )
        
        // Total Deductions patterns
        let totalDeductionsPatterns = [
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
        
        let totalDeductionsPattern = PatternDefinition.createCorePattern(
            name: "Total Deductions",
            key: "totalDeductions",
            category: .deductions,
            patterns: totalDeductionsPatterns
        )
        
        return [dsopPattern, agifPattern, taxPattern, totalDeductionsPattern]
    }
}
