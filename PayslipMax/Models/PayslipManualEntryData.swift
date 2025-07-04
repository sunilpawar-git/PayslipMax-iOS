import Foundation

/// Data structure for comprehensive manual entry of payslip information
struct PayslipManualEntryData {
    // MARK: - Personal Information
    /// Name of the payslip owner.
    let name: String
    /// Month of the payslip period.
    let month: String
    /// Year of the payslip period.
    let year: Int
    /// Account number.
    let accountNumber: String
    /// PAN number.
    let panNumber: String
    /// Rank (for military personnel).
    let rank: String
    /// Service number (for military personnel).
    let serviceNumber: String
    /// Posted location.
    let postedTo: String
    
    // MARK: - Financial Summary
    /// Total credits (earnings) entered.
    let credits: Double
    /// Total debits (deductions) entered.
    let debits: Double
    /// Tax amount entered.
    let tax: Double
    /// DSOP contribution entered.
    let dsop: Double
    
    // MARK: - Detailed Earnings and Deductions
    /// Dictionary of individual earnings components.
    let earnings: [String: Double]
    /// Dictionary of individual deductions components.
    let deductions: [String: Double]
    
    // MARK: - Additional Financial Details
    /// Basic pay amount.
    let basicPay: Double
    /// Dearness allowance amount.
    let dearnessPay: Double
    /// Military service pay amount.
    let militaryServicePay: Double
    /// Net remittance amount.
    let netRemittance: Double
    /// Income tax amount.
    let incomeTax: Double
    
    // MARK: - DSOP Details
    /// DSOP opening balance.
    let dsopOpeningBalance: Double?
    /// DSOP closing balance.
    let dsopClosingBalance: Double?
    
    // MARK: - Contact Information
    /// Contact phone numbers.
    let contactPhones: [String]
    /// Contact email addresses.
    let contactEmails: [String]
    /// Contact websites.
    let contactWebsites: [String]
    
    // MARK: - Metadata
    /// Source of the payslip data.
    let source: String
    /// Any additional notes.
    let notes: String?
    
    /// Initializer with default values for optional fields
    init(
        name: String,
        month: String,
        year: Int,
        accountNumber: String = "",
        panNumber: String = "",
        rank: String = "",
        serviceNumber: String = "",
        postedTo: String = "",
        credits: Double,
        debits: Double,
        tax: Double,
        dsop: Double,
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:],
        basicPay: Double = 0,
        dearnessPay: Double = 0,
        militaryServicePay: Double = 0,
        netRemittance: Double = 0,
        incomeTax: Double = 0,
        dsopOpeningBalance: Double? = nil,
        dsopClosingBalance: Double? = nil,
        contactPhones: [String] = [],
        contactEmails: [String] = [],
        contactWebsites: [String] = [],
        source: String = "Manual Entry",
        notes: String? = nil
    ) {
        self.name = name
        self.month = month
        self.year = year
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.rank = rank
        self.serviceNumber = serviceNumber
        self.postedTo = postedTo
        self.credits = credits
        self.debits = debits
        self.tax = tax
        self.dsop = dsop
        self.earnings = earnings
        self.deductions = deductions
        self.basicPay = basicPay
        self.dearnessPay = dearnessPay
        self.militaryServicePay = militaryServicePay
        self.netRemittance = netRemittance
        self.incomeTax = incomeTax
        self.dsopOpeningBalance = dsopOpeningBalance
        self.dsopClosingBalance = dsopClosingBalance
        self.contactPhones = contactPhones
        self.contactEmails = contactEmails
        self.contactWebsites = contactWebsites
        self.source = source
        self.notes = notes
    }
} 