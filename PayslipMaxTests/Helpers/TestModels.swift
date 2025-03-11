import Foundation
import XCTest
@testable import Payslip_Max

// Test-specific version of PayslipItem for use in tests
class TestPayslipItem: PayslipItemProtocol {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    
    // Private flags for sensitive data encryption status
    private var isNameEncrypted: Bool = false
    private var isAccountNumberEncrypted: Bool = false
    private var isPanNumberEncrypted: Bool = false
    
    init(
        id: UUID = UUID(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
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
        self.dsop = dsop
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
            dsop: dsop,
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
            dsop: payslipItem.dsop,
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
            dsop: 500.0,
            tax: 800.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    // Implementation of PayslipItemProtocol methods
    func encryptSensitiveData() throws {
        if !isNameEncrypted {
            name = "ENCRYPTED_" + name
            isNameEncrypted = true
        }
        
        if !isAccountNumberEncrypted {
            accountNumber = "ENCRYPTED_" + accountNumber
            isAccountNumberEncrypted = true
        }
        
        if !isPanNumberEncrypted {
            panNumber = "ENCRYPTED_" + panNumber
            isPanNumberEncrypted = true
        }
    }
    
    func decryptSensitiveData() throws {
        if isNameEncrypted {
            name = name.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isNameEncrypted = false
        }
        
        if isAccountNumberEncrypted {
            accountNumber = accountNumber.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isAccountNumberEncrypted = false
        }
        
        if isPanNumberEncrypted {
            panNumber = panNumber.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isPanNumberEncrypted = false
        }
    }
} 