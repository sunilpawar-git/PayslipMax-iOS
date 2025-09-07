import XCTest
import Foundation
@testable import PayslipMax

/// Data validation tests for ChartDataPreparationService
/// Tests edge cases including zero values, negative values, large values, and decimal precision
final class ChartDataPreparationServiceDataValidationTests: XCTestCase {

    // MARK: - Properties

    private var chartService: ChartDataPreparationService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        chartService = ChartDataPreparationService()
    }

    override func tearDown() {
        chartService = nil
        super.tearDown()
    }

    // MARK: - Data Validation Tests

    /// Test 5: Zero values handling
    func testPrepareChartDataWithZeroValues() {
        // Given: Payslip with zero values
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "December",
            year: 2023,
            credits: 0.0,
            debits: 0.0
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])

        // Then: Should handle zero values correctly
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "December")
        XCTAssertEqual(item.credits, 0.0)
        XCTAssertEqual(item.debits, 0.0)
        XCTAssertEqual(item.net, 0.0)
    }

    /// Test 6: Negative net value handling
    func testPrepareChartDataWithNegativeNet() {
        // Given: Payslip with debits greater than credits (negative net)
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "August",
            year: 2024,
            credits: 3000.0,
            debits: 4000.0
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])

        // Then: Should handle negative net correctly
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "August")
        XCTAssertEqual(item.credits, 3000.0)
        XCTAssertEqual(item.debits, 4000.0)
        XCTAssertEqual(item.net, -1000.0) // 3000 - 4000
    }

    /// Test 7: Large values handling
    func testPrepareChartDataWithLargeValues() {
        // Given: Payslip with large financial values
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "July",
            year: 2024,
            credits: 999999.99,
            debits: 123456.78
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])

        // Then: Should handle large values correctly
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "July")
        XCTAssertEqual(item.credits, 999999.99, accuracy: 0.01)
        XCTAssertEqual(item.debits, 123456.78, accuracy: 0.01)
        XCTAssertEqual(item.net, 876543.21, accuracy: 0.01)
    }

    /// Test 8: Decimal precision handling
    func testPrepareChartDataWithDecimalPrecision() {
        // Given: Payslip with precise decimal values
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "September",
            year: 2024,
            credits: 4567.89,
            debits: 1234.56
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])

        // Then: Should preserve decimal precision
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.credits, 4567.89, accuracy: 0.001)
        XCTAssertEqual(item.debits, 1234.56, accuracy: 0.001)
        XCTAssertEqual(item.net, 3333.33, accuracy: 0.001)
    }

    /// Test: Very small decimal values
    func testPrepareChartDataWithSmallDecimalValues() {
        // Given: Payslip with very small decimal values
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "Micro",
            year: 2024,
            credits: 0.01,
            debits: 0.005
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])

        // Then: Should handle small decimal values correctly
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "Micro")
        XCTAssertEqual(item.credits, 0.01, accuracy: 0.0001)
        XCTAssertEqual(item.debits, 0.005, accuracy: 0.0001)
        XCTAssertEqual(item.net, 0.005, accuracy: 0.0001)
    }

    /// Test: Mixed positive and negative values
    func testPrepareChartDataWithMixedValues() {
        // Given: Multiple payslips with mixed positive/negative scenarios
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Positive",
                year: 2024,
                credits: 5000.0,
                debits: 2000.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Zero",
                year: 2024,
                credits: 3000.0,
                debits: 3000.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Negative",
                year: 2024,
                credits: 1000.0,
                debits: 2000.0
            )
        ]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should handle all scenarios correctly
        XCTAssertEqual(chartData.count, 3)

        XCTAssertEqual(chartData[0].net, 3000.0) // 5000 - 2000
        XCTAssertEqual(chartData[1].net, 0.0)    // 3000 - 3000
        XCTAssertEqual(chartData[2].net, -1000.0) // 1000 - 2000
    }

    /// Test: Boundary values around zero
    func testPrepareChartDataWithBoundaryValues() {
        // Given: Payslips with values very close to zero
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "NearZeroPos",
                year: 2024,
                credits: 0.001,
                debits: 0.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "NearZeroNeg",
                year: 2024,
                credits: 0.0,
                debits: 0.001
            )
        ]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should handle boundary values correctly
        XCTAssertEqual(chartData.count, 2)

        XCTAssertEqual(chartData[0].net, 0.001, accuracy: 0.0001)
        XCTAssertEqual(chartData[1].net, -0.001, accuracy: 0.0001)
    }

    /// Test: Rounding behavior with decimal values
    func testPrepareChartDataWithRoundingScenarios() {
        // Given: Payslips that test rounding behavior
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Round1",
                year: 2024,
                credits: 100.005,
                debits: 50.003
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Round2",
                year: 2024,
                credits: 123.456789,
                debits: 78.901234
            )
        ]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should maintain expected precision
        XCTAssertEqual(chartData.count, 2)

        // Verify calculations are mathematically correct
        XCTAssertEqual(chartData[0].net, 50.002, accuracy: 0.001) // 100.005 - 50.003
        XCTAssertEqual(chartData[1].net, 44.555555, accuracy: 0.000001) // 123.456789 - 78.901234
    }
}
