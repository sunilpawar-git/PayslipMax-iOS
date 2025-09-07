import Foundation
@testable import PayslipMax

/// Protocol for building test scenarios with predefined configurations
protocol ScenarioBuilderProtocol {
    /// Builds a complete monthly payslip scenario for testing
    func buildMonthlyScenario(for month: String, year: Int, baseAmount: Double) -> TestScenario

    /// Builds a yearly scenario with all 12 months
    func buildYearlyScenario(startingYear: Int, baseAmount: Double) -> TestScenario

    /// Builds an edge case scenario for boundary testing
    func buildEdgeCaseScenario(type: ScenarioType) -> TestScenario

    /// Builds a mixed scenario with various pay patterns
    func buildMixedScenario() -> TestScenario
}

/// Represents a complete test scenario with payslips and metadata
struct TestScenario {
    let title: String
    let description: String
    let payslips: [PayslipItem]
    let expectedTotalCredits: Double
    let expectedTotalDebits: Double
    let expectedNetAmount: Double
    let tags: [String]
}

/// Types of test scenarios
enum ScenarioType {
    case zeroBalance
    case highValue
    case negativeBalance
    case specialCharacters
    case largeDataSet
}

/// Builder for creating comprehensive test scenarios
class ScenarioBuilder: ScenarioBuilderProtocol {

    private let dataFactory: DataFactoryProtocol

    init(dataFactory: DataFactoryProtocol = DataFactory()) {
        self.dataFactory = dataFactory
    }

    // MARK: - ScenarioBuilderProtocol Implementation

    func buildMonthlyScenario(for month: String, year: Int, baseAmount: Double) -> TestScenario {
        let payslip = dataFactory.createPayslipItem(
            month: month,
            year: year,
            credits: baseAmount,
            debits: baseAmount * 0.2,
            dsop: baseAmount * 0.05,
            tax: baseAmount * 0.15,
            name: "Test Employee",
            accountNumber: "TEST123456",
            panNumber: "TESTP1234F"
        )

        let expectedTotalCredits = baseAmount
        let expectedTotalDebits = baseAmount * 0.2 + baseAmount * 0.05 + baseAmount * 0.15
        let expectedNetAmount = expectedTotalCredits - expectedTotalDebits

        return TestScenario(
            title: "\(month) \(year) Monthly Scenario",
            description: "Standard monthly payslip for \(month) \(year) with base amount ₹\(String(format: "%.0f", baseAmount))",
            payslips: [payslip],
            expectedTotalCredits: expectedTotalCredits,
            expectedTotalDebits: expectedTotalDebits,
            expectedNetAmount: expectedNetAmount,
            tags: ["monthly", month.lowercased(), "standard"]
        )
    }

    func buildYearlyScenario(startingYear: Int, baseAmount: Double) -> TestScenario {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]

        let payslips = months.enumerated().map { (index, month) in
            let yearOffset = index / 12
            let monthlyVariation = Double.random(in: 0.8...1.2) // ±20% variation

            return dataFactory.createPayslipItem(
                month: month,
                year: startingYear + yearOffset,
                credits: baseAmount * monthlyVariation,
                debits: baseAmount * 0.2 * monthlyVariation,
                dsop: baseAmount * 0.05,
                tax: baseAmount * 0.15 * monthlyVariation,
                name: "Yearly Test Employee",
                accountNumber: "YEARLY123456",
                panNumber: "YEART1234F"
            )
        }

        let totalCredits = payslips.reduce(0) { $0 + $1.credits }
        let totalDebits = payslips.reduce(0) { $0 + $1.debits + $1.dsop + $1.tax }
        let netAmount = totalCredits - totalDebits

        return TestScenario(
            title: "\(startingYear) Yearly Scenario",
            description: "Complete yearly payslip data for \(startingYear) with 12 months and monthly variations",
            payslips: payslips,
            expectedTotalCredits: totalCredits,
            expectedTotalDebits: totalDebits,
            expectedNetAmount: netAmount,
            tags: ["yearly", "complete", "variation"]
        )
    }

    func buildEdgeCaseScenario(type: ScenarioType) -> TestScenario {
        switch type {
        case .zeroBalance:
            return buildZeroBalanceScenario()
        case .highValue:
            return buildHighValueScenario()
        case .negativeBalance:
            return buildNegativeBalanceScenario()
        case .specialCharacters:
            return buildSpecialCharactersScenario()
        case .largeDataSet:
            return buildLargeDataSetScenario()
        }
    }

    func buildMixedScenario() -> TestScenario {
        var mixedPayslips: [PayslipItem] = []

        // Add various types of payslips
        mixedPayslips.append(contentsOf: buildStandardVariations())
        mixedPayslips.append(contentsOf: buildEdgeCaseVariations())

        let totalCredits = mixedPayslips.reduce(0) { $0 + $1.credits }
        let totalDebits = mixedPayslips.reduce(0) { $0 + $1.debits + $1.dsop + $1.tax }
        let netAmount = totalCredits - totalDebits

        return TestScenario(
            title: "Mixed Scenario Collection",
            description: "Collection of various payslip types including standard and edge cases for comprehensive testing",
            payslips: mixedPayslips,
            expectedTotalCredits: totalCredits,
            expectedTotalDebits: totalDebits,
            expectedNetAmount: netAmount,
            tags: ["mixed", "comprehensive", "edge-cases"]
        )
    }

    // MARK: - Private Helper Methods

    private func buildZeroBalanceScenario() -> TestScenario {
        let payslip = dataFactory.createPayslipItem(
            credits: 0, debits: 0, dsop: 0, tax: 0,
            name: "Zero Balance Employee",
            accountNumber: "ZERO000000",
            panNumber: "ZEROZ1234F"
        )

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

    private func buildHighValueScenario() -> TestScenario {
        let highAmount = 1_000_000.0
        let payslip = dataFactory.createPayslipItem(
            credits: highAmount,
            debits: highAmount * 0.3,
            dsop: highAmount * 0.05,
            tax: highAmount * 0.2,
            name: "High Value Employee",
            accountNumber: "HIGH123456",
            panNumber: "HIGHP1234F"
        )

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

    private func buildNegativeBalanceScenario() -> TestScenario {
        let payslip = dataFactory.createPayslipItem(
            credits: 1000,
            debits: 1500,
            dsop: 300,
            tax: 200,
            name: "Negative Balance Employee",
            accountNumber: "NEG123456",
            panNumber: "NEGAT1234F"
        )

        let expectedTotalDebits = 1500 + 300 + 200

        return TestScenario(
            title: "Negative Balance Edge Case",
            description: "Payslip where debits exceed credits resulting in negative net amount",
            payslips: [payslip],
            expectedTotalCredits: 1000,
            expectedTotalDebits: expectedTotalDebits,
            expectedNetAmount: 1000 - expectedTotalDebits,
            tags: ["edge-case", "negative-balance", "deficit"]
        )
    }

    private func buildSpecialCharactersScenario() -> TestScenario {
        let payslip = dataFactory.createPayslipItem(
            name: "José María O'Connor-Smith, Jr.",
            accountNumber: "TEST-123/456.789",
            panNumber: "TESTP1234F&"
        )

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

    private func buildLargeDataSetScenario() -> TestScenario {
        let largePayslips = (1...50).map { index in
            dataFactory.createPayslipItem(
                month: "January",
                year: 2023,
                credits: Double(1000 + index * 100),
                debits: Double(200 + index * 10),
                dsop: Double(50 + index * 5),
                tax: Double(150 + index * 15),
                name: "Large Dataset Employee \(index)",
                accountNumber: "LARGE\(String(format: "%04d", index))",
                panNumber: "LARGE\(String(format: "%04d", index))F"
            )
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

    private func buildStandardVariations() -> [PayslipItem] {
        return [
            dataFactory.createPayslipItem(credits: 5000, debits: 1000, dsop: 300, tax: 800),
            dataFactory.createPayslipItem(credits: 6000, debits: 1200, dsop: 400, tax: 900),
            dataFactory.createPayslipItem(credits: 7000, debits: 1400, dsop: 500, tax: 1000)
        ]
    }

    private func buildEdgeCaseVariations() -> [PayslipItem] {
        return [
            dataFactory.createEdgeCasePayslipItem(type: .zeroValues),
            dataFactory.createEdgeCasePayslipItem(type: .veryLargeValues),
            dataFactory.createEdgeCasePayslipItem(type: .decimalPrecision)
        ]
    }
}
