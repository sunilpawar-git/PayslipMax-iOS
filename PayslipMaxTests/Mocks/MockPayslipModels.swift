import Foundation
@testable import PayslipMax

// MARK: - Mock Data Types

// PayslipManualEntryData is imported from main app

// PayslipChartData is defined in PayslipMax/Views/Home/Components/ChartsView.swift

// MARK: - AnyPayslip Wrapper

/// Type-erased wrapper for PayslipProtocol implementations.
/// Enables testing with different payslip types while maintaining protocol compliance.
class AnyPayslip: PayslipProtocol {
    let id: UUID
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
    var earnings: [String: Double]
    var deductions: [String: Double]

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

    /// Initializes from a PayslipItem
    init(_ payslipItem: PayslipItem) {
        self.id = payslipItem.id
        self.timestamp = payslipItem.timestamp
        self.month = payslipItem.month
        self.year = payslipItem.year
        self.credits = payslipItem.credits
        self.debits = payslipItem.debits
        self.dsop = payslipItem.dsop
        self.tax = payslipItem.tax
        self.name = payslipItem.name
        self.accountNumber = payslipItem.accountNumber
        self.panNumber = payslipItem.panNumber
        self.earnings = payslipItem.earnings
        self.deductions = payslipItem.deductions
        self.pdfData = payslipItem.pdfData
        self.pdfURL = payslipItem.pdfURL
        self.isSample = payslipItem.isSample
        self.source = payslipItem.source
        self.status = payslipItem.status
        self.notes = payslipItem.notes
    }

    /// Initializes with default test values
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "Test User",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F",
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

    // MARK: - PayslipEncryptionProtocol Methods

    /// Encrypts sensitive data asynchronously
    func encryptSensitiveData() async throws {
        // Mock implementation - just mark as encrypted
        isNameEncrypted = true
        isAccountNumberEncrypted = true
        isPanNumberEncrypted = true
    }

    /// Decrypts sensitive data asynchronously
    func decryptSensitiveData() async throws {
        // Mock implementation - just mark as decrypted
        isNameEncrypted = false
        isAccountNumberEncrypted = false
        isPanNumberEncrypted = false
    }
}
