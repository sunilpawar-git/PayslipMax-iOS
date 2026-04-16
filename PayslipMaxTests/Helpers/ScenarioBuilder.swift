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

    let dataFactory: DataFactoryProtocol

    init(dataFactory: DataFactoryProtocol = DataFactory()) {
        self.dataFactory = dataFactory
    }

    // MARK: - ScenarioBuilderProtocol Implementation

    func buildMonthlyScenario(for month: String, year: Int, baseAmount: Double) -> TestScenario {
        let params = PayslipItemParams(
            id: UUID(),
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
        let payslip = dataFactory.createPayslipItem(params: params)

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

            let params = PayslipItemParams(
                id: UUID(),
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
            return dataFactory.createPayslipItem(params: params)
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

}
