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
    ///
    /// This method defines patterns for identifying tax-related details:
    /// - PAN Number: Permanent Account Number for tax identification
    /// - Tax Deductions: Various tax deduction amounts
    /// - TDS Information: Tax Deducted at Source details
    /// - Tax Calculation Components: Breakdown of tax calculations
    ///
    /// ## Pattern Types and Configurations
    ///
    /// ### PAN Number Patterns
    /// Patterns for extracting PAN (Permanent Account Number):
    /// - Standard 10-character PAN format (AAAAA9999A)
    /// - PAN with various separators or formatting
    /// - Context-aware extraction from tax sections
    ///
    /// ### Tax Deduction Patterns
    /// Patterns for extracting various tax deduction amounts:
    /// - Income tax deductions
    /// - Professional tax
    /// - TDS (Tax Deducted at Source)
    /// - Advance tax payments
    ///
    /// ### Tax Information
    /// Patterns for extracting tax calculation details:
    /// - Taxable income amounts
    /// - Tax exemption details
    /// - Tax calculation breakdowns
    ///
    /// - Returns: An array of `PatternDefinition` objects for tax information extraction.
    static func getTaxPatterns() -> [PatternDefinition] {
        // PAN Number patterns
        let panPatterns = [
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
        
        let panPattern = PatternDefinition.createCorePattern(
            name: "PAN Number",
            key: "panNumber",
            category: .taxInfo,
            patterns: panPatterns
        )
        
        // Income Tax patterns
        let incomeTaxPatterns = [
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
        
        let incomeTaxPattern = PatternDefinition.createCorePattern(
            name: "Income Tax",
            key: "incomeTax",
            category: .taxInfo,
            patterns: incomeTaxPatterns
        )
        
        // TDS patterns
        let tdsPatterns = [
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
        
        let tdsPattern = PatternDefinition.createCorePattern(
            name: "TDS",
            key: "tds",
            category: .taxInfo,
            patterns: tdsPatterns
        )
        
        // Professional Tax patterns
        let professionalTaxPatterns = [
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
        
        let professionalTaxPattern = PatternDefinition.createCorePattern(
            name: "Professional Tax",
            key: "professionalTax",
            category: .taxInfo,
            patterns: professionalTaxPatterns
        )
        
        // Taxable Income patterns
        let taxableIncomePatterns = [
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
        
        let taxableIncomePattern = PatternDefinition.createCorePattern(
            name: "Taxable Income",
            key: "taxableIncome",
            category: .taxInfo,
            patterns: taxableIncomePatterns
        )
        
        return [panPattern, incomeTaxPattern, tdsPattern, professionalTaxPattern, taxableIncomePattern]
    }
}
