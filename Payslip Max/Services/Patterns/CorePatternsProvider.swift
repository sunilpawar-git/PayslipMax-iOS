import Foundation

/// Provides the default core patterns for payslip extraction
class CorePatternsProvider {
    /// Get all default core patterns
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
    
    /// Personal information extraction patterns
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
    
    /// Earnings related patterns
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
    
    /// Deduction related patterns
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
    
    /// Banking information patterns
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
    
    /// Tax information patterns
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