//
//  PayslipDataTestHelpers.swift
//  PayslipMaxTests
//
//  Shared test helpers and utilities for PayslipData tests
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import Foundation
@testable import PayslipMax

struct PayslipDataTestHelpers {

    static func createMockPayslipWithDualSectionKeys() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "May",
            year: 2025,
            credits: 98125.0,
            debits: 19518.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 50000.0,
                "DA_EARNINGS": 15000.0,
                "Dearness Allowance": 10000.0,  // Legacy + dual-section
                "MSP": 15500.0,
                "RH12_EARNINGS": 21125.0
            ],
            deductions: [
                "AGIF": 2000.0,
                "DSOP": 5000.0,
                "ITAX": 8000.0,
                "HRA_DEDUCTIONS": 5000.0,
                "RH12_DEDUCTIONS": 7518.0
            ],
            name: "Test Officer",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }

    static func createComplexDualSectionPayslip() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "June",
            year: 2025,
            credits: 125000.0,
            debits: 25000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: [
                "BPAY": 60000.0,
                "DA_EARNINGS": 18000.0,
                "MSP": 17000.0,
                "HRA_EARNINGS": 15000.0,
                "CEA_EARNINGS": 3375.0,
                "RH12_EARNINGS": 11625.0
            ],
            deductions: [
                "AGIF": 2500.0,
                "DSOP": 5000.0,
                "ITAX": 10000.0,
                "HRA_DEDUCTIONS": 2500.0,
                "CEA_DEDUCTIONS": 1000.0,
                "RH12_DEDUCTIONS": 4000.0
            ],
            name: "Complex Test Officer",
            accountNumber: "XXXX5678",
            panNumber: "FGHIJ5678K",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }

    static func createMockPayslipWithArrearsComponents() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "July",
            year: 2025,
            credits: 85000.0,
            debits: 20000.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 55000.0,
                "DA": 16000.0,
                "MSP": 12350.0,
                "ARR-HRA_EARNINGS": 1650.0
            ],
            deductions: [
                "AGIF": 2000.0,
                "DSOP": 5000.0,
                "ITAX": 8000.0,
                "ARR-CEA_DEDUCTIONS": 2000.0,
                "UTILITIES": 3000.0
            ],
            name: "Arrears Test Officer",
            accountNumber: "XXXX9876",
            panNumber: "KLMNO9876P",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }

    static func createEmptyPayslipData() -> PayslipData {
        return PayslipData()
    }

    static func createPayslipDataWithDualSectionTotals() -> PayslipData {
        var data = PayslipData()
        data.totalCredits = 105000.0
        data.totalDebits = 22000.0
        data.credits = 105000.0  // Set protocol property
        data.debits = 22000.0    // Set protocol property
        data.netRemittance = 83000.0
        data.allEarnings = [
            "BPAY": 55000.0,
            "DA_EARNINGS": 18000.0,
            "MSP": 16000.0,
            "RH12_EARNINGS": 16000.0
        ]
        data.allDeductions = [
            "AGIF": 2500.0,
            "DSOP": 5500.0,
            "ITAX": 9000.0,
            "RH12_DEDUCTIONS": 5000.0
        ]
        // Set earnings and deductions for protocol compatibility
        data.earnings = data.allEarnings
        data.deductions = data.allDeductions
        return data
    }

    static func createMockPayslipWithMixedKeys() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "August",
            year: 2025,
            credits: 95000.0,
            debits: 18000.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 50000.0,  // Legacy key
                "DA_EARNINGS": 12000.0,  // Dual-section key
                "Dearness Allowance": 8000.0,  // Legacy display key
                "MSP": 15500.0,  // Legacy key
                "HRA_EARNINGS": 9500.0  // Dual-section key
            ],
            deductions: [
                "AGIF": 2000.0,  // Legacy key
                "DSOP": 5000.0,  // Legacy key
                "ITAX": 8000.0,  // Legacy key
                "HRA_DEDUCTIONS": 3000.0  // Dual-section key
            ],
            name: "Mixed Keys Test Officer",
            accountNumber: "XXXX4321",
            panNumber: "PQRST4321U",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }
}
