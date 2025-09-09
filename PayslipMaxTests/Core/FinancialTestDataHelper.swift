import Foundation
@testable import PayslipMax

/// Protocol for creating test data for financial calculations
protocol FinancialTestDataFactoryProtocol {
    func createTestPayslips() -> [PayslipItem]
    func createZeroValuePayslip() -> PayslipItem
    func createNegativeNetIncomePayslip() -> PayslipItem
    func createLargePayslipArray(repeatCount: Int) -> [PayslipItem]
}

/// Helper class for creating test data used in financial calculation tests
final class FinancialTestDataHelper: FinancialTestDataFactoryProtocol {

    // MARK: - Test Data Creation

    func createTestPayslips() -> [PayslipItem] {
        return [
            createJanuaryPayslip(),
            createFebruaryPayslip(),
            createMarchPayslip()
        ]
    }

    func createZeroValuePayslip() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 0.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            earnings: [:],
            deductions: [:]
        )
    }

    func createNegativeNetIncomePayslip() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 30000.0,
            debits: 35000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: ["BPAY": 30000.0],
            deductions: ["ITAX": 10000.0, "DSOP": 5000.0, "OTHER": 20000.0]
        )
    }

    func createLargePayslipArray(repeatCount: Int) -> [PayslipItem] {
        let basePayslips = createTestPayslips()
        var largeArray: [PayslipItem] = []

        for _ in 0..<repeatCount {
            largeArray.append(contentsOf: basePayslips)
        }

        return largeArray
    }

    // MARK: - Private Helper Methods

    private func createJanuaryPayslip() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 12000.0,
            dsop: 4000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 30000.0,
                "DA": 15000.0,
                "HRA": 5000.0
            ],
            deductions: [
                "DSOP": 4000.0,
                "ITAX": 8000.0
            ],
            name: "Test User",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F"
        )
    }

    private func createFebruaryPayslip() -> PayslipItem {
        return PayslipItem(
            month: "February",
            year: 2024,
            credits: 52000.0,
            debits: 13000.0,
            dsop: 4500.0,
            tax: 8500.0,
            earnings: [
                "BPAY": 31000.0,
                "DA": 15500.0,
                "HRA": 5500.0
            ],
            deductions: [
                "DSOP": 4500.0,
                "ITAX": 8500.0,
                "OTHER": 300.0
            ],
            name: "Test User",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F"
        )
    }

    private func createMarchPayslip() -> PayslipItem {
        return PayslipItem(
            month: "March",
            year: 2024,
            credits: 51000.0,
            debits: 12500.0,
            dsop: 4100.0,
            tax: 8200.0,
            earnings: [
                "BPAY": 30500.0,
                "DA": 15250.0,
                "HRA": 5250.0
            ],
            deductions: [
                "DSOP": 4100.0,
                "ITAX": 8200.0,
                "OTHER": 200.0
            ],
            name: "Test User",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F"
        )
    }
}
