import Foundation

/// Protocol for providing regex patterns for payslip data extraction
protocol PatternProvider {
    /// Get all patterns for general data extraction
    var patterns: [String: String] { get }
    
    /// Get patterns specifically for earnings extraction
    var earningsPatterns: [String: String] { get }
    
    /// Get patterns specifically for deductions extraction
    var deductionsPatterns: [String: String] { get }
    
    /// Get standard earnings components for categorization
    var standardEarningsComponents: [String] { get }
    
    /// Get standard deductions components for categorization
    var standardDeductionsComponents: [String] { get }
    
    /// Get blacklisted terms that should not be considered as pay items
    var blacklistedTerms: [String] { get }
    
    /// Get context-specific blacklisted terms
    var contextSpecificBlacklist: [String: [String]] { get }
    
    /// Get patterns to identify merged codes
    var mergedCodePatterns: [String: String] { get }
    
    /// Get minimum thresholds for various financial values
    var minimumEarningsAmount: Double { get }
    var minimumDeductionsAmount: Double { get }
    var minimumDSOPAmount: Double { get }
    var minimumTaxAmount: Double { get }
    
    /// Add a pattern to the patterns collection
    func addPattern(key: String, pattern: String)
}

/// Default implementation of PatternProvider
class DefaultPatternProvider: PatternProvider {
    private var _patterns: [String: String]
    private var _earningsPatterns: [String: String]
    private var _deductionsPatterns: [String: String]
    
    init() {
        // Initialize with default patterns from PayslipPatternManager
        _patterns = DefaultPatternProvider.defaultPatterns
        _earningsPatterns = DefaultPatternProvider.defaultEarningsPatterns
        _deductionsPatterns = DefaultPatternProvider.defaultDeductionsPatterns
    }
    
    var patterns: [String: String] {
        return _patterns
    }
    
    var earningsPatterns: [String: String] {
        return _earningsPatterns
    }
    
    var deductionsPatterns: [String: String] {
        return _deductionsPatterns
    }
    
    var standardEarningsComponents: [String] {
        return DefaultPatternProvider.defaultStandardEarningsComponents
    }
    
    var standardDeductionsComponents: [String] {
        return DefaultPatternProvider.defaultStandardDeductionsComponents
    }
    
    var blacklistedTerms: [String] {
        return DefaultPatternProvider.defaultBlacklistedTerms
    }
    
    var contextSpecificBlacklist: [String: [String]] {
        return DefaultPatternProvider.defaultContextSpecificBlacklist
    }
    
    var mergedCodePatterns: [String: String] {
        return DefaultPatternProvider.defaultMergedCodePatterns
    }
    
    var minimumEarningsAmount: Double {
        return 100.0
    }
    
    var minimumDeductionsAmount: Double {
        return 10.0
    }
    
    var minimumDSOPAmount: Double {
        return 1000.0
    }
    
    var minimumTaxAmount: Double {
        return 1000.0
    }
    
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
        "netRemittance": "(?:Net\\s*Remittance|Net\\s*Amount|NET\\s*AMOUNT|Net\\s*Pay|Net\\s*Salary|Net\\s*Payment)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([\\-0-9,.]+)",
        
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