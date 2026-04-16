import Foundation
@testable import PayslipMax

extension ScenarioBuilder {

    func buildZeroBalanceScenario() -> TestScenario {
        let params = PayslipItemParams(
            id: UUID(), month: "January", year: 2023,
            credits: 0, debits: 0, dsop: 0, tax: 0,
            name: "Zero Balance Employee", accountNumber: "ZERO000000", panNumber: "ZEROZ1234F"
        )
        let payslip = dataFactory.createPayslipItem(params: params)

        return TestScenario(
            title: "Zero Balance Edge Case",
            description: "Payslip with all zero values to test zero balance handling",
            payslips: [payslip],
            expectedTotalCredits: 0,
            expectedTotalDebits: 0,
            expectedNetAmount: 0,
            tags: ["edge-case", "zero-balance", "boundary"]
        )
    }

    func buildHighValueScenario() -> TestScenario {
        let highAmount = 1_000_000.0
        let params = PayslipItemParams(
            id: UUID(), month: "January", year: 2023,
            credits: highAmount, debits: highAmount * 0.3, dsop: highAmount * 0.05, tax: highAmount * 0.2,
            name: "High Value Employee", accountNumber: "HIGH123456", panNumber: "HIGHP1234F"
        )
        let payslip = dataFactory.createPayslipItem(params: params)

        let expectedTotalDebits = highAmount * 0.3 + highAmount * 0.05 + highAmount * 0.2

        return TestScenario(
            title: "High Value Edge Case",
            description: "Payslip with very high monetary values to test large number handling",
            payslips: [payslip],
            expectedTotalCredits: highAmount,
            expectedTotalDebits: expectedTotalDebits,
            expectedNetAmount: highAmount - expectedTotalDebits,
            tags: ["edge-case", "high-value", "large-numbers"]
        )
    }

    func buildNegativeBalanceScenario() -> TestScenario {
        let params = PayslipItemParams(
            id: UUID(), month: "January", year: 2023,
            credits: 1000, debits: 1500, dsop: 300, tax: 200,
            name: "Negative Balance Employee", accountNumber: "NEG123456", panNumber: "NEGAT1234F"
        )
        let payslip = dataFactory.createPayslipItem(params: params)

        let expectedTotalDebits = 1500 + 300 + 200

        return TestScenario(
            title: "Negative Balance Edge Case",
            description: "Payslip where debits exceed credits resulting in negative net amount",
            payslips: [payslip],
            expectedTotalCredits: 1000,
            expectedTotalDebits: Double(expectedTotalDebits),
            expectedNetAmount: 1000 - Double(expectedTotalDebits),
            tags: ["edge-case", "negative-balance", "deficit"]
        )
    }

    func buildSpecialCharactersScenario() -> TestScenario {
        let params = PayslipItemParams(
            id: UUID(), month: "January", year: 2023,
            credits: 5000.0, debits: 1000.0, dsop: 300.0, tax: 800.0,
            name: "José María O'Connor-Smith, Jr.", accountNumber: "TEST-123/456.789", panNumber: "TESTP1234F&"
        )
        let payslip = dataFactory.createPayslipItem(params: params)

        return TestScenario(
            title: "Special Characters Edge Case",
            description: "Payslip with special characters in name and account details",
            payslips: [payslip],
            expectedTotalCredits: payslip.credits,
            expectedTotalDebits: payslip.debits + payslip.dsop + payslip.tax,
            expectedNetAmount: payslip.credits - (payslip.debits + payslip.dsop + payslip.tax),
            tags: ["edge-case", "special-characters", "unicode"]
        )
    }

    func buildLargeDataSetScenario() -> TestScenario {
        let largePayslips = (1...50).map { index in
            let params = PayslipItemParams(
                id: UUID(), month: "January", year: 2023,
                credits: Double(1000 + index * 100), debits: Double(200 + index * 10),
                dsop: Double(50 + index * 5), tax: Double(150 + index * 15),
                name: "Large Dataset Employee \(index)",
                accountNumber: "LARGE\(String(format: "%04d", index))",
                panNumber: "LARGE\(String(format: "%04d", index))F"
            )
            return dataFactory.createPayslipItem(params: params)
        }

        let totalCredits = largePayslips.reduce(0) { $0 + $1.credits }
        let totalDebits = largePayslips.reduce(0) { $0 + $1.debits + $1.dsop + $1.tax }

        return TestScenario(
            title: "Large Dataset Scenario",
            description: "Large collection of 50 payslips for performance and bulk processing testing",
            payslips: largePayslips,
            expectedTotalCredits: totalCredits,
            expectedTotalDebits: totalDebits,
            expectedNetAmount: totalCredits - totalDebits,
            tags: ["large-dataset", "performance", "bulk-processing"]
        )
    }

    func buildStandardVariations() -> [PayslipItem] {
        let variations: [(credits: Double, debits: Double, dsop: Double, tax: Double, empNum: Int)] = [
            (5000, 1000, 300, 800, 1),
            (6000, 1200, 400, 900, 2),
            (7000, 1400, 500, 1000, 3)
        ]

        return variations.map { v in
            let params = PayslipItemParams(
                id: UUID(), month: "January", year: 2023,
                credits: v.credits, debits: v.debits, dsop: v.dsop, tax: v.tax,
                name: "Standard Employee \(v.empNum)",
                accountNumber: "STD00\(v.empNum)234",
                panNumber: "STD00\(v.empNum)234F"
            )
            return dataFactory.createPayslipItem(params: params)
        }
    }

    func buildEdgeCaseVariations() -> [PayslipItem] {
        return [
            dataFactory.createEdgeCasePayslipItem(type: .zeroValues),
            dataFactory.createEdgeCasePayslipItem(type: .veryLargeValues),
            dataFactory.createEdgeCasePayslipItem(type: .decimalPrecision)
        ]
    }
}
