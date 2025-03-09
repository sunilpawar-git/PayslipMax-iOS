import Foundation
import XCTest
@testable import Payslip_Max

// Test-specific version of PayslipItem for use in tests
// This avoids the issues with importing PayslipItem as a struct vs class
class TestPayslipItem {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dspof: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    
    init(
        id: UUID = UUID(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dspof: Double,
        tax: Double,
        location: String,
        name: String,
        accountNumber: String,
        panNumber: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dspof = dspof
        self.tax = tax
        self.location = location
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
    }
    
    // Helper to convert to the real PayslipItem
    func toPayslipItem() -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dspof: dspof,
            tax: tax,
            location: location,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: timestamp
        )
    }
    
    // Helper to create from the real PayslipItem
    static func from(_ payslipItem: PayslipItem) -> TestPayslipItem {
        return TestPayslipItem(
            id: payslipItem.id,
            month: payslipItem.month,
            year: payslipItem.year,
            credits: payslipItem.credits,
            debits: payslipItem.debits,
            dspof: payslipItem.dspof,
            tax: payslipItem.tax,
            location: payslipItem.location,
            name: payslipItem.name,
            accountNumber: payslipItem.accountNumber,
            panNumber: payslipItem.panNumber,
            timestamp: payslipItem.timestamp
        )
    }
    
    // Helper to create a sample test payslip item
    static func sample() -> TestPayslipItem {
        return TestPayslipItem(
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dspof: 500.0,
            tax: 800.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
} 