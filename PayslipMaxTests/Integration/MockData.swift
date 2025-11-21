//
//  MockData.swift
//  PayslipMaxTests
//
//  Mock data for integration testing
//

import Foundation
@testable import PayslipMax

struct MockData {
    // A "Honey Pot" payslip text with fake PII
    static let honeyPotText = """
    PAYSLIP FOR THE MONTH OF JUNE 2025

    Employee Name: John Doe
    Employee ID: EMP12345
    Designation: Senior Software Engineer
    Department: Engineering
    Location: Bangalore, Karnataka

    PAN No: ABCDE1234F
    Bank A/C No: 123456789012
    PF No: MH/BAN/12345/123
    UAN: 100123456789

    Earnings              Amount    Deductions            Amount
    ------------------------------------------------------------
    Basic Salary          50,000    Provident Fund        6,000
    HRA                   20,000    Professional Tax      200
    Special Allowance     30,000    Income Tax            5,000
    Transport Allowance   5,000
    Medical Allowance     1,250
    ------------------------------------------------------------
    Total Earnings        106,250   Total Deductions      11,200

    Net Pay: ₹95,050
    (Rupees Ninety Five Thousand Fifty Only)
    """

    // Expected JSON response from the LLM (simulated)
    static let expectedLLMResponse = """
    {
        "netPay": 95050.0,
        "grossPay": 106250.0,
        "deductions": 11200.0,
        "payPeriod": "June 2025",
        "earnings": [
            {"name": "Basic Salary", "amount": 50000.0},
            {"name": "HRA", "amount": 20000.0},
            {"name": "Special Allowance", "amount": 30000.0},
            {"name": "Transport Allowance", "amount": 5000.0},
            {"name": "Medical Allowance", "amount": 1250.0}
        ],
        "deductionBreakdown": [
            {"name": "Provident Fund", "amount": 6000.0},
            {"name": "Professional Tax", "amount": 200.0},
            {"name": "Income Tax", "amount": 5000.0}
        ]
    }
    """

    // Expected PayslipItem object
    static var expectedPayslip: PayslipItem {
        let earnings: [String: Double] = [
            "Basic Salary": 50000.0,
            "HRA": 20000.0,
            "Special Allowance": 30000.0,
            "Transport Allowance": 5000.0,
            "Medical Allowance": 1250.0
        ]

        let deductions: [String: Double] = [
            "Provident Fund": 6000.0,
            "Professional Tax": 200.0,
            "Income Tax": 5000.0
        ]

        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "June",
            year: 2025,
            credits: 106250.0,
            debits: 11200.0
        )

        item.earnings = earnings
        item.deductions = deductions
        item.name = "John Doe"
        item.accountNumber = "123456789012"
        item.panNumber = "ABCDE1234F"
        item.pdfURL = URL(fileURLWithPath: "/tmp/test.pdf") // Safe for mocks

        return item
    }
}
