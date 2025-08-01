import Foundation
import PDFKit
@testable import PayslipMax
class TestPayslipItem: PayslipProtocol {
    var id: UUID
    var timestamp: Date
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String
    var accountNumber: String
    var panNumber: String
    
    // Add the missing properties required by PayslipProtocol
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    
    // PayslipEncryptionProtocol properties
    var isNameEncrypted: Bool = false
    var isAccountNumberEncrypted: Bool = false
    var isPanNumberEncrypted: Bool = false
    
    // PayslipMetadataProtocol properties
    var pdfData: Data? = nil
    var pdfURL: URL? = nil
    var isSample: Bool = false
    var source: String = "Test"
    var status: String = "Active"
    var notes: String? = nil
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        name: String,
        accountNumber: String,
        panNumber: String,
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.earnings = earnings
        self.deductions = deductions
    }
    
    // Helper to convert to the real PayslipItem
    func toPayslipItem() -> PayslipItem {
        let payslipItem = PayslipItem(
            id: id,
            timestamp: timestamp,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
        
        // Copy earnings and deductions
        payslipItem.earnings = self.earnings
        payslipItem.deductions = self.deductions
        
        return payslipItem
    }
    
    // Helper to create from the real PayslipItem
    static func from(_ payslipItem: PayslipItem) -> TestPayslipItem {
        let testItem = TestPayslipItem(
            id: payslipItem.id,
            timestamp: payslipItem.timestamp,
            month: payslipItem.month,
            year: payslipItem.year,
            credits: payslipItem.credits,
            debits: payslipItem.debits,
            dsop: payslipItem.dsop,
            tax: payslipItem.tax,
            name: payslipItem.name,
            accountNumber: payslipItem.accountNumber,
            panNumber: payslipItem.panNumber
        )
        
        // Copy earnings and deductions
        testItem.earnings = payslipItem.earnings
        testItem.deductions = payslipItem.deductions
        
        return testItem
    }
    
    // Helper to create a sample test payslip item
    static func sample() -> TestPayslipItem {
        let testItem = TestPayslipItem(
            timestamp: Date(),
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Add sample earnings and deductions
        testItem.earnings = [
            "Basic Pay": 3000.0,
            "DA": 1500.0,
            "MSP": 500.0
        ]
        
        testItem.deductions = [
            "DSOP": 500.0,
            "ITAX": 800.0,
            "AGIF": 200.0
        ]
        
        return testItem
    }
    
    // PayslipProtocol methods
    func getFullDescription() -> String {
        return "Test Payslip for \(month) \(year)"
    }
    
    func getNetAmount() -> Double {
        return credits - debits
    }
    
    func getTotalTax() -> Double {
        return tax
    }
    
    // Implementation of PayslipEncryptionProtocol methods
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