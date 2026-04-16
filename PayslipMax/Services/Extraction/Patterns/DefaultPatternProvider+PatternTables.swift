import Foundation

// MARK: - Default Pattern Collections

extension DefaultPatternProvider {

    // swiftlint:disable line_length
    static let defaultPatterns: [String: String] = [
        "name": "(?:Name|Employee\\s*Name|Name\\s*of\\s*Employee|SERVICE NO & NAME|ARMY NO AND NAME|Employee)\\s*:?\\s*([A-Za-z0-9\\s.'-]+?)(?:\\s*$|\\s*\\n|\\s*Date|\\s*Pay\\s*Date)",
        "accountNumber": "(?:Account\\s*No|A/C\\s*No|Account\\s*Number)\\s*[-:.]?\\s*([0-9\\-/]+)",
        "panNumber": "(?:PAN|PAN\\s*No|Permanent\\s*Account\\s*Number)\\s*[-:.]?\\s*([A-Z0-9]+)",
        "statementPeriod": "(?:Statement\\s*Period|Period|For\\s*the\\s*Month|Month|Pay\\s*Period|Pay\\s*Date)\\s*:?\\s*(?:([A-Za-z]+)\\s*(?:\\s*\\/|\\s*\\-|\\s*\\,|\\s*)(\\d{4})|(?:(\\d{1,2})\\s*\\/\\s*(\\d{1,2})\\s*\\/\\s*(\\d{4})))",
        "month": "(?:Month|Pay\\s*Month|Statement\\s*Month|For\\s*Month|Month\\s*of)\\s*:?\\s*([A-Za-z]+)",
        "year": "(?:Year|Pay\\s*Year|Statement\\s*Year|For\\s*Year|Year\\s*of|\\d{2}/\\d{2}/(\\d{4})|\\d{4})",

        "grossPay": "(?is)(?:Gross\\s*Pay|Total\\s*Earnings|Total\\s*Pay|Total\\s*Salary|TOTAL\\s*CREDITS)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "totalDeductions": "(?:Total\\s*Deductions|Total\\s*Debits|TOTAL\\s*DEBITS|Deductions\\s*Total)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "netRemittance": "(?:Net\\s*Remittance|Net\\s*Amount|NET\\s*AMOUNT|Net\\s*Pay|Net\\s*Salary|Net\\s*Payment|AMOUNT\\s+CREDITED\\s+TO\\s+BANK|AMOUNT\\s+CREDITED\\s+TO\\s*A/C|Amount\\s*Credited\\s*to\\s*Bank|Amount\\s*Credited\\s*to\\s*A/C|Credited\\s*to\\s*Bank|नेट\\s*क्रेडिटेड\\s*टू\\s*बैंक)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([\\-0-9,.]+)",

        "basicPay": "(?:BPAY|Basic\\s*Pay|BASIC\\s*PAY|Basic\\s*Pay\\s*:|Basic\\s*Salary\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "da": "(?:DA|Dearness\\s*Allowance|D\\.A\\.|DA\\s*:|Dearness\\s*Allowance\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "msp": "(?:MSP|Military\\s*Service\\s*Pay|MSP\\s*:|Military\\s*Service\\s*Pay\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "tpta": "(?:TPTA|Transport\\s*Allowance|T\\.P\\.T\\.A\\.|Transport\\s*Allowance\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "tptada": "(?:TPTADA|Transport\\s*DA|T\\.P\\.T\\.A\\.\\s*DA|Transport\\s*DA\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrDa": "(?:ARR-DA|DA\\s*Arrears|DA\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrSpcdo": "(?:ARR-SPCDO|SPCDO\\s*Arrears|SPCDO\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "arrTptada": "(?:ARR-TPTADA|TPTADA\\s*Arrears|TPTADA\\s*Arrears\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "hra": "(?:HRA|House\\s*Rent\\s*Allowance|H\\.R\\.A\\.|HRA\\s*:|House\\s*Rent\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",

        "etkt": "(?:ETKT|E-Ticket\\s*Recovery|E-Ticket\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "fur": "(?:FUR|Furniture\\s*Recovery|Furniture\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "lf": "(?:LF|License\\s*Fee|License\\s*Fee\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "agif": "(?:AGIF|Army\\s*Group\\s*Insurance\\s*Fund|AGIF\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "itax": "(?:Income\\s*Tax|Tax\\s*Deducted|TDS|ITAX)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "ehcess": "(?:EHCESS|Education\\s*Health\\s*Cess|Ed\\.\\s*Health\\s*Cess\\s*:)\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",

        "incomeTaxDeducted": "(?:Income\\s*Tax\\s*Deducted|TDS)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "edCessDeducted": "(?:Ed\\.\\s*Cess\\s*Deducted|Education\\s*Cess)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "totalTaxPayable": "(?:Total\\s*Tax\\s*Payable|Tax\\s*Payable)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "grossSalary": "(?:Gross\\s*Salary|Gross\\s*Income)\\s*(?:upto|excluding)\\s*[0-9\\/]+\\s*(?:excluding\\s*HRA)?\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "standardDeduction": "(?:Standard\\s*Deduction)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "netTaxableIncome": "(?:Net\\s*Taxable\\s*Income|Taxable\\s*Income)\\s*\\([0-9]\\s*-\\s*[0-9]\\s*-\\s*[0-9]\\)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "assessmentYear": "(?:Assessment\\s*Year)\\s*([0-9\\-\\.]+)",
        "estimatedFutureSalary": "(?:Estimated\\s*future\\s*Salary)\\s*upto\\s*[0-9\\/]+\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",

        "dsopOpeningBalance": "(?:Opening\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopSubscription": "(?:Subscription|Monthly\\s*Contribution)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopMiscAdj": "(?:Misc\\s*Adj|Miscellaneous\\s*Adjustment)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopWithdrawal": "(?:Withdrawal)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopRefund": "(?:Refund)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",
        "dsopClosingBalance": "(?:Closing\\s*Balance)\\s*:?\\s*(?:Rs\\.)?\\s*([0-9,]+)",

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

        "tax": "(?:Income\\s*Tax|Tax\\s*Deducted|TDS|ITAX)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)",
        "dsop": "(?:DSOP|DSOP\\s*Fund|Defence\\s*Services\\s*Officers\\s*Provident\\s*Fund)\\s*:?\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+(?:\\.\\d{2})?)"
    ]
    // swiftlint:enable line_length

    // MARK: - Earnings & Deductions Patterns

    static let defaultEarningsPatterns: [String: String] = [
        "BPAY": "(?:BPAY|Basic\\s*Pay|BASIC\\s*PAY)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "DA": "(?:DA|Dearness\\s*Allowance|D\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "MSP": "(?:MSP|Military\\s*Service\\s*Pay)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "TPTA": "(?:TPTA|Transport\\s*Allowance|T\\.P\\.T\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "TPTADA": "(?:TPTADA|Transport\\s*DA|T\\.P\\.T\\.A\\.\\s*DA)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "HRA": "(?:HRA|House\\s*Rent\\s*Allowance|H\\.R\\.A\\.)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)"
    ]

    static let defaultDeductionsPatterns: [String: String] = [
        "ETKT": "(?:ETKT|E-Ticket\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "FUR": "(?:FUR|Furniture\\s*Recovery)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "LF": "(?:LF|License\\s*Fee)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "DSOP": "(?:DSOP|DSOP\\s*Fund|Provident\\s*Fund|PF)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "AGIF": "(?:AGIF|Army\\s*Group\\s*Insurance\\s*Fund)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)",
        "ITAX": "(?:ITAX|Income\\s*Tax|I\\.Tax|Tax\\s*Deducted)\\s*:?\\s*(?:Rs\\.)?\\s*\\$?\\s*([0-9,.]+)"
    ]

    // MARK: - Component Classifications

    static let defaultStandardEarningsComponents = [
        "BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA",
        "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA", "HADA",
        "HAUTA", "MISC", "NPA", "OTA", "PMA", "SDA", "SPLAL", "SPLDA",
        "ARR-BPAY", "ARR-DA", "ARR-HRA", "ARR-MSP", "ARR-TA", "ARR-TPTA", "ARR-TPTADA",
        "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
        "DRESALW", "SPCDO"
    ]

    static let defaultStandardDeductionsComponents = [
        "DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS",
        "FUR", "LF", "WATER", "ELEC", "EHCESS", "RENT", "ACCM", "QTRS",
        "ADVHBA", "ADVCP", "ADVFES", "ADVMCA", "ADVPF", "ADVSCTR", "LOAN", "LOANS",
        "AFMSD", "AOBF", "AOCBF", "AOCSF", "AWHO", "AWWA", "DESA", "ECHS", "NGIF",
        "SPCDO", "ARR-RSHNA", "RSHNA", "TR", "UPTO", "MP", "MESS", "CLUB", "AFTI",
        "AAO", "AFPP", "AFWWA", "ARMY", "CSD", "CST", "IAFBA", "IAFCL", "IAFF", "IAFWWA",
        "NAVY", "NWWA", "PBOR", "PNBHFL", "POSB", "RSHNA", "SAO", "SBICC", "SBIL", "SBIPL",
        "ETKT"
    ]

    // MARK: - Blacklists

    static let defaultBlacklistedTerms = [
        "STATEMENT", "CONTACT", "DEDUCTIONS", "EARNINGS", "TOTAL", "DETAILS", "SECTION", "PAGE",
        "SUMMARY", "BREAKDOWN", "ACCOUNT", "PERIOD", "MONTH", "YEAR", "DATE", "PAYSLIP",
        "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII",
        "PAN", "SAO", "AAO", "PRO", "DI", "RL", "IT", "PCDA", "CDA", "OFFICE", "BRANCH",
        "DAK", "UPTO", "LOANS", "WATER", "INCOME", "HRA",
        "NAME", "RANK", "UNIT", "LOCATION", "ADDRESS", "PHONE", "EMAIL", "WEBSITE", "CONTACT",
        "SI", "NO", "FROM", "TO", "BILL", "PAY", "CODE", "TYPE", "AMT", "PRINCIPAL",
        "INT", "BALANCE", "CUR", "INST", "DESCRIPTION", "AMOUNT",
        "GROSS", "NET", "RECOVERY", "ARREAR", "ARREARS", "CLOSING", "OPENING", "SUBSCRIPTION",
        "WITHDRAWAL", "REFUND", "MISC", "ADJ", "ADJUSTMENT", "CURRENT", "PREVIOUS", "NEXT",
        "ASSESSMENT", "TAXABLE", "STANDARD", "FUTURE", "SALARY", "PROPERTY", "SOURCE", "HOUSE",
        "SURCHARGE", "CESS", "DEDUCTED", "PAYABLE", "EXCLUDING", "INCLUDING", "ESTIMATED"
    ]

    static let defaultContextSpecificBlacklist: [String: [String]] = [
        "earnings": ["DSOP", "AGIF", "ITAX", "CGEIS", "CGHS", "GPF", "NPS", "EHCESS", "RSHNA", "FUR", "LF"],
        "deductions": ["BPAY", "DA", "MSP", "TPTA", "TPTADA", "TA", "CEA", "CGEIS", "CGHS", "CLA", "DADA", "DAUTA", "DEPUTA"]
    ]

    // MARK: - Merged Code Patterns

    static let defaultMergedCodePatterns: [String: String] = [
        "numericPrefix": "^(\\d+)(\\D+)$",
        "abbreviationPrefix": "^([A-Z]{2,4})-(\\d+)$"
    ]
}
