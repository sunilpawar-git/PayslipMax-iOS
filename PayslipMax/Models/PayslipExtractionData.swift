import Foundation

/// Structure to hold extracted data during parsing.
public struct PayslipExtractionData {
    /// Extracted name of the payslip owner.
    var name: String = ""
    /// Extracted month of the payslip period.
    var month: String = ""
    /// Extracted year of the payslip period.
    var year: Int = 0
    /// Extracted total credits (earnings).
    var credits: Double = 0.0
    /// Extracted total debits (deductions).
    var debits: Double = 0.0
    /// Extracted DSOP contribution amount.
    var dsop: Double = 0.0
    /// Extracted tax deduction amount.
    var tax: Double = 0.0
    /// Extracted account number.
    var accountNumber: String = ""
    /// Extracted PAN (Permanent Account Number).
    var panNumber: String = ""
    /// Timestamp indicating when the extraction occurred or the payslip date if available.
    var timestamp: Date = Date.distantPast
    
    // Additional fields for intermediate extraction
    /// Extracted basic pay amount, if found separately.
    var basicPay: Double = 0.0
    /// Extracted gross pay amount, if found.
    var grossPay: Double = 0.0
    
    public init(
        name: String = "",
        month: String = "",
        year: Int = 0,
        credits: Double = 0.0,
        debits: Double = 0.0,
        dsop: Double = 0.0,
        tax: Double = 0.0,
        accountNumber: String = "",
        panNumber: String = "",
        timestamp: Date = Date.distantPast,
        basicPay: Double = 0.0,
        grossPay: Double = 0.0
    ) {
        self.name = name
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
        self.basicPay = basicPay
        self.grossPay = grossPay
    }
} 