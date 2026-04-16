import XCTest
import Foundation
@testable import PayslipMax

final class ChartDataPreparationServiceDataIntegrityTests: XCTestCase {

    private var chartService: ChartDataPreparationService!

    override func setUp() {
        super.setUp()
        chartService = ChartDataPreparationService()
    }

    override func tearDown() {
        chartService = nil
        super.tearDown()
    }

    // MARK: - Range & Integrity Tests

    func testChartDataPropertiesRangeValidation() {
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "MinValues",
                year: 2024,
                credits: .leastNormalMagnitude,
                debits: .leastNormalMagnitude
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "MaxValues",
                year: 2024,
                credits: .greatestFiniteMagnitude,
                debits: 0.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Infinity",
                year: 2024,
                credits: Double.infinity,
                debits: 0.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "NaN",
                year: 2024,
                credits: Double.nan,
                debits: 0.0
            )
        ]

        let chartData = chartService.prepareChartData(from: payslips)

        XCTAssertEqual(chartData.count, 4)

        XCTAssertNotNil(chartData[0].id)
        XCTAssertNotNil(chartData[1].id)
        XCTAssertNotNil(chartData[2].id)
        XCTAssertNotNil(chartData[3].id)

        XCTAssertEqual(chartData[0].month, "MinValues")
        XCTAssertEqual(chartData[1].month, "MaxValues")
        XCTAssertEqual(chartData[2].month, "Infinity")
        XCTAssertEqual(chartData[3].month, "NaN")
    }

    func testChartDataStructuralIntegrity() {
        let payslip = PayslipItem(
            month: "IntegrityTest",
            year: 2024,
            credits: 12345.67,
            debits: 6789.12,
            dsop: 500.0,
            tax: 1000.0,
            name: "Test Integrity User",
            accountNumber: "INT123456",
            panNumber: "INTEGRITYPAN"
        )

        let chartData = chartService.prepareChartData(from: [payslip])

        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "IntegrityTest")
        XCTAssertEqual(item.credits, 12345.67)
        XCTAssertEqual(item.debits, 6789.12)
        XCTAssertEqual(item.net, 12345.67 - 6789.12)

        XCTAssertEqual(item.net, 5556.55, accuracy: 0.001)
    }

    func testChartDataWithSpecialCharactersInMonth() {
        let specialMonths = ["Jan-2024", "Feb_2024", "Mar 2024", "Apr/2024", "May@2024"]

        let payslips = specialMonths.map { month in
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: month,
                year: 2024,
                credits: 1000.0,
                debits: 200.0
            )
        }

        let chartData = chartService.prepareChartData(from: payslips)

        XCTAssertEqual(chartData.count, 5)

        for (index, expectedMonth) in specialMonths.enumerated() {
            XCTAssertEqual(chartData[index].month, expectedMonth)
            XCTAssertEqual(chartData[index].credits, 1000.0)
            XCTAssertEqual(chartData[index].debits, 200.0)
            XCTAssertEqual(chartData[index].net, 800.0)
        }
    }

    func testChartDataWithEmptyMonthName() {
        let payslip = PayslipItem(
            month: "",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 0.0,
            tax: 0.0,
            name: "Test User",
            accountNumber: "EMPTY123",
            panNumber: "EMPTYPAN"
        )

        let chartData = chartService.prepareChartData(from: [payslip])

        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "")
        XCTAssertEqual(item.credits, 5000.0)
        XCTAssertEqual(item.debits, 1000.0)
        XCTAssertEqual(item.net, 4000.0)
    }
}
