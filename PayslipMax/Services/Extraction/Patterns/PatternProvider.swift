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
        // Initialize with default patterns from static properties
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
        return 100.0 // Example value, consider configuration
    }

    /// Provides the minimum plausible monetary value for a deduction item.
    var minimumDeductionsAmount: Double {
        return 10.0 // Example value, consider configuration
    }

    /// Provides the minimum plausible monetary value for a DSOP item.
    var minimumDSOPAmount: Double {
        return 1000.0 // Example value, consider configuration
    }

    /// Provides the minimum plausible monetary value for an income tax item.
    var minimumTaxAmount: Double {
        return 1000.0 // Example value, consider configuration
    }

    /// Adds or updates a pattern in the main `patterns` collection.
    /// - Parameters:
    ///   - key: The field name key for the pattern.
    ///   - pattern: The regex pattern string.
    func addPattern(key: String, pattern: String) {
        _patterns[key] = pattern
    }

    // MARK: - Default Pattern Collections

    /// Default general patterns
    private static let defaultPatterns: [String: String] = [
        // Personal Information - More flexible patterns
        "name": "(?:Name|Employee\\s*Name|Name\\s*of\\s*Employee|SERVICE NO & NAME|ARMY NO AND NAME|Employee)\\s*:?\\s*([A-Za-z0-9\\s.'-]+?)(?:\\s*$|\\s*\\n|\\s*Date|\\s*Pay\\s*Date)",
        "accountNumber": "(?:Account\\s*No|A/C\\s*No|Account\\s*Number)\\s*[-:.]?\\s*([0-9\\-/]+)",
        "panNumber": "(?:PAN|PAN\\s*No|Permanent\\s*Account\\s*Number)\\s*[-:.]?\\s*([A-Z0-9]+)",
        "statementPeriod": "(?:Statement\\s*Period|Period|For\\s*the\\s*Month|Month|Pay\\s*Period|Pay\\s*Date)\\s*:?\\s*(?:([A-Za-z]+)\\s*(?:\\s*\\/|\\s*\\-|\\s*\\,|\\s*)(\\d{4})|(?:(\\d{1,2})\\s*\\/\\s*(\\d{1,2})\\s*\\/\\s*(\\d{4})))",
        "month": "(?:Month|Pay\\s*Month|Statement\\s*Month|For\\s*Month|Month\\s*of)\\s*:?\\s*([A-Za-z]+)",
        "year": "(?:Year|Pay\\s*Year|Statement\\s*Year|For\\s*Year|Year\\s*of|\\d{2}/\\d{2}/(\\d{4})|\\d{4})",

        // Financial Information - More flexible patterns
        "grossPay": "(?:Gross\\s*Pay|Total\\s*Earnings|Total\\s*Pay|Total\\s*Salary)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "totalDeductions": "(?:Total\\s*Deductions|Total\\s*Debits|Deductions\\s*Total)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "netRemittance": "(?:Net\\s*Remittance|Net\\s*Amount|NET\\s*AMOUNT|Net\\s*Pay|Net\\s*Salary|Net\\s*Payment|Amount\\s*Credited\\s*to\\s*Bank|Amount\\s*Credited\\s*to\\s*A/C|Credited\\s*to\\s*Bank|नेट\\s*क्रेडिटेड\\s*टू\\s*बैंक)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([\\-0-9,.]+)",

        // Earnings
        "basicPay": "(?:BPAY|Basic\\s*Pay|BASIC\\s*PAY|Basic\\s*Pay\\s*:|Basic\\s*Salary\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "da": "(?:DA|Dearness\\s*Allowance|D\\.A\\.|DA\\s*:|Dearness\\s*Allowance\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "msp": "(?:MSP|Military\\s*Service\\s*Pay|MSP\\s*:|Military\\s*Service\\s*Pay\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "tpta": "(?:TPTA|Transport\\s*Allowance|T\\.P\\.T\\.A\\.|Transport\\s*Allowance\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "tptada": "(?:TPTADA|Transport\\s*DA|T\\.P\\.T\\.A\\.\\s*DA|Transport\\s*DA\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrDa": "(?:ARR-DA|DA\\s*Arrears|DA\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrSpcdo": "(?:ARR-SPCDO|SPCDO\\s*Arrears|SPCDO\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrTptada": "(?:ARR-TPTADA|TPTADA\\s*Arrears|TPTADA\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "hra": "(?:HRA|House\\s*Rent\\s*Allowance|H\\.R\\.A\\.|HRA\\s*:|House\\s*Rent\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",

        // Deductions
        "etkt": "(?:ETKT|E-Ticket\\s*Recovery|E-Ticket\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "fur": "(?:FUR|Furniture\\s*Recovery|Furniture\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "lf": "(?:LF|License\\s*Fee|License\\s*Fee\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "agif": "(?:AGIF|Army\\s*Group\\s*Insurance\\s*Fund|AGIF\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "itax": "(?:Income\\s*Tax|Tax\\s*Deducted|TDS|ITAX)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "ehcess": "(?:EHCESS|Education\\s*Health\\s*Cess|Ed\\.\\s*Health\\s*Cess\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",

        // Income Tax Details
        "incomeTaxDeducted": "(?:Income\\s*Tax\\s*Deducted|TDS)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "edCessDeducted": "(?:Ed\\.\\s*Cess\\s*Deducted|Education\\s*Cess)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "totalTaxPayable": "(?:Total\\s*Tax\\s*Payable|Tax\\s*Payable)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "grossSalary": "(?:Gross\\s*Salary|Gross\\s*Income)\\s*(?:upto|excluding)\\s*[0-9\\/]+\\s*(?:excluding\\s*HRA)?\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "standardDeduction": "(?:Standard\\s*Deduction)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "netTaxableIncome": "(?:Net\\s*Taxable\\s*Income|Taxable\\s*Income)\\s*\\([0-9]\\s*-\\s*[0-9]\\s*-\\s*[0-9]\\)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "assessmentYear": "(?:Assessment\\s*Year)\\s*([0-9\\-\\.]+)",
        "estimatedFutureSalary": "(?:Estimated\\s*future\\s*Salary)\\s*upto\\s*[0-9\\/]+\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",

        // DSOP Fund Details
        "dsopOpeningBalance": "(?:Opening\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopSubscription": "(?:Subscription|Monthly\\s*Contribution)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopMiscAdj": "(?:Misc\\s*Adj|Miscellaneous\\s*Adjustment)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopWithdrawal": "(?:Withdrawal)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopRefund": "(?:Refund)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopClosingBalance": "(?:Closing\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",

        // Contact Details
        "contactSAOLW": "(?:SAO\\(LW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOLW": "(?:AAO\\(LW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactSAOTW": "(?:SAO\\(TW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactAAOTW": "(?:AAO\\(TW\\))\\s*([A-Za-z\\s]+\\([0-9\\-]+\\))",
        "contactProCivil": "(?:PRO\\s*CIVIL)\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactProArmy": "(?:PRO\\s*ARMY)\\s*:?\\s*\\(?([0-9\\-\\/]+)\\)?",
        "contactWebsite": "(?:Visit\\s*us)\\s*:?\\s*(https?:\\/\\/[\\w\\.-]+\\.[a-z]{2,}(?:\\/[\\w\\.-]*)*)",
        "contactEmailTADA": "(?:For\\s*TA\\/DA\\s*related\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailLedger": "(?:For\\s*Ledger\\s*Section\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailRankPay": "(?:For\\s*rank\\s*pay\\s*related\\s*matter)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",
        "contactEmailGeneral": "(?:For\\s*other\\s*grievances)\\s*:?\\s*([\\w\\.-]+@[\\w\\.-]+\\.[a-z]{2,})",

        // Tax and DSOP - More specific patterns
        "tax": "(?:Income\\s*Tax|Tax\\s*Deducted|TDS|ITAX)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "dsop": "(?:DSOP|DSOP\\s*Fund|Defence\\s*Services\\s*Officers\\s*Provident\\s*Fund)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)"
    ]

    /// Default earnings patterns
    private static let defaultEarningsPatterns: [String: String] = [
        "BPAY": "(?:BPAY|Basic\\s*Pay|BASIC\\s*PAY)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "DA": "(?:DA|Dearness\\s*Allowance|D\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "MSP": "(?:MSP|Military\\s*Service\\s*Pay)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "TPTA": "(?:TPTA|Transport\\s*Allowance|T\\.P\\.T\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "TPTADA": "(?:TPTADA|Transport\\s*DA|T\\.P\\.T\\.A\\.\\s*DA)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "HRA": "(?:HRA|House\\s*Rent\\s*Allowance|H\\.R\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)"
    ]

    /// Default deductions patterns
    private static let defaultDeductionsPatterns: [String: String] = [
        "ETKT": "(?:ETKT|E-Ticket\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "FUR": "(?:FUR|Furniture\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "LF": "(?:LF|License\\s*Fee)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "DSOP": "(?:DSOP|DSOP\\s*Fund|Provident\\s*Fund|PF)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "AGIF": "(?:AGIF|Army\\s*Group\\s*Insurance\\s*Fund)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "ITAX": "(?:ITAX|Income\\s*Tax|I\\.Tax|Tax\\s*Deducted)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)"
    ]

    /// Standard earnings components for categorization
    private static let defaultStandardEarningsComponents = [
        // Basic Pay and Allowances
        "BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA",
        // Special Allowances
        "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA", "HADA",
        "HAUTA", "MISC", "NPA", "OTA", "PMA", "SDA", "SPLAL", "SPLDA",
        // Arrears
        "ARR-BPAY", "ARR-DA", "ARR-HRA", "ARR-MSP", "ARR-TA", "ARR-TPTA", "ARR-TPTADA",
        // Risk & Hardship Allowances
        "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
        // Dress Allowances
        "DRESALW", "SPCDO"
    ]

    /// Standard deductions components for categorization
    private static let defaultStandardDeductionsComponents = [
        // Mandatory Deductions
        "DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS",
        // Housing and Utilities
        "FUR", "LF", "WATER", "ELEC", "EHCESS", "RENT", "ACCM", "QTRS",
        // Loans and Advances
        "ADVHBA", "ADVCP", "ADVFES", "ADVMCA", "ADVPF", "ADVSCTR", "LOAN", "LOANS",
        // Insurance and Funds
        "AFMSD", "AOBF", "AOCBF", "AOCSF", "AWHO", "AWWA", "DESA", "ECHS", "NGIF",
        // Recoveries and Miscellaneous
        "SPCDO", "ARR-RSHNA", "RSHNA", "TR", "UPTO", "MP", "MESS", "CLUB", "AFTI",
        // Specific Deductions
        "AAO", "AFPP", "AFWWA", "ARMY", "CSD", "CST", "IAFBA", "IAFCL", "IAFF", "IAFWWA",
        "NAVY", "NWWA", "PBOR", "PNBHFL", "POSB", "RSHNA", "SAO", "SBICC", "SBIL", "SBIPL",
        // E-Ticket
        "ETKT"
    ]

    /// Terms that should never be considered as pay items (blacklist)
    private static let defaultBlacklistedTerms = [
        // Headers and Sections
        "STATEMENT", "CONTACT", "DEDUCTIONS", "EARNINGS", "TOTAL", "DETAILS", "SECTION", "PAGE",
        "SUMMARY", "BREAKDOWN", "ACCOUNT", "PERIOD", "MONTH", "YEAR", "DATE", "PAYSLIP",
        // Roman Numerals and Numbering
        "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
        // Contact and Administrative Terms
        "PAN", "SAO", "AAO", "PRO", "DI", "RL", "IT", "PCDA", "CDA", "OFFICE", "BRANCH",
        "DAK", "UPTO", "LOANS", "WATER", "INCOME", "HRA",
        // Miscellaneous Non-Financial Terms
        "NAME", "RANK", "UNIT", "LOCATION", "ADDRESS", "PHONE", "EMAIL", "WEBSITE", "CONTACT",
        // Table Headers
        "SI", "NO", "FROM", "TO", "BILL", "PAY", "CODE", "TYPE", "AMT", "PRINCIPAL",
        "INT", "BALANCE", "CUR", "INST", "DESCRIPTION", "AMOUNT",
        // Additional terms that might cause confusion
        "GROSS", "NET", "RECOVERY", "ARREAR", "ARREARS", "CLOSING", "OPENING", "SUBSCRIPTION",
        "WITHDRAWAL", "REFUND", "MISC", "ADJ", "ADJUSTMENT", "CURRENT", "PREVIOUS", "NEXT",
        "ASSESSMENT", "TAXABLE", "STANDARD", "FUTURE", "SALARY", "PROPERTY", "SOURCE", "HOUSE",
        "SURCHARGE", "CESS", "DEDUCTED", "PAYABLE", "EXCLUDING", "INCLUDING", "ESTIMATED"
    ]

    /// Context-specific blacklisted terms (terms that should be blacklisted only in specific contexts)
    private static let defaultContextSpecificBlacklist: [String: [String]] = [
        "earnings": ["DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS", "EHCESS", "RSHNA", "FUR", "LF"],
        "deductions": ["BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA", "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA"]
    ]

    /// Patterns to identify merged codes (e.g., "3600DSOP")
    private static let defaultMergedCodePatterns: [String: String] = [
        "numericPrefix": "^(\\d+)(\\D+)$",  // e.g., "3600DSOP"
        "abbreviationPrefix": "^([A-Z]{2,4})-(\\d+)$"  // e.g., "ARR-RSHNA"
    ]
}
