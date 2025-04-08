import Foundation

/// Structure to hold extracted data during parsing.
public struct PayslipExtractionData {
    var name: String = ""
    var month: String = ""
    var year: Int = 0
    var credits: Double = 0.0
    var debits: Double = 0.0
    var dsop: Double = 0.0
    var tax: Double = 0.0
    var accountNumber: String = ""
    var panNumber: String = ""
    var timestamp: Date = Date.distantPast
    
    // Additional fields for intermediate extraction
    var basicPay: Double = 0.0
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