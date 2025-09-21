//
//  PayslipDataMockFactory.swift
//  PayslipMaxTests
//
//  Mock implementations for PayslipData tests
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import Foundation
@testable import PayslipMax

// MARK: - Mock PayslipProtocol Implementation

struct MockPayslip: PayslipProtocol {
    let id: UUID
    var timestamp: Date
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var earnings: [String: Double]
    var deductions: [String: Double]
    var name: String
    var accountNumber: String
    var panNumber: String
    var isNameEncrypted: Bool = false
    var isAccountNumberEncrypted: Bool = false
    var isPanNumberEncrypted: Bool = false
    var pdfData: Data?
    var pdfURL: URL? = nil
    var isSample: Bool
    var source: String
    var status: String
    var notes: String? = nil

    func calculateNetAmount() -> Double {
        return credits - debits
    }

    func getFullDescription() -> String {
        return "Mock Payslip for \(name) - \(month) \(year)"
    }

    func encryptSensitiveData() async throws {
        // Mock implementation
    }

    func decryptSensitiveData() async throws {
        // Mock implementation
    }
}
