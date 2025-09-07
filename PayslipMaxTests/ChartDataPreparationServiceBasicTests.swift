import XCTest
import Foundation
@testable import PayslipMax

/// Basic functionality tests for ChartDataPreparationService
/// Tests initialization, empty data, and fundamental data conversion operations
final class ChartDataPreparationServiceBasicTests: XCTestCase {

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

    // MARK: - Basic Functionality Tests

    /// Test 1: Service initialization
    func testServiceInitialization() {
        // Given & When: ChartDataPreparationService is initialized
        let service = ChartDataPreparationService()

        // Then: Service should be properly initialized
        XCTAssertNotNil(service)
    }

    /// Test 2: Empty payslips array
    func testPrepareChartDataWithEmptyPayslips() {
        // Given: Empty payslips array
        let emptyPayslips: [PayslipItem] = []

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: emptyPayslips)

        // Then: Should return empty array
        XCTAssertTrue(chartData.isEmpty)
        XCTAssertEqual(chartData.count, 0)
    }

    /// Test 3: Single payslip conversion
    func testPrepareChartDataWithSinglePayslip() {
        // Given: Single test payslip
        let payslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1500.0
        )
        let payslips = [payslip]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should return single item
        XCTAssertEqual(chartData.count, 1)

        let firstItem = chartData.first!
        XCTAssertEqual(firstItem.month, "January")
        XCTAssertEqual(firstItem.credits, 5000.0)
        XCTAssertEqual(firstItem.debits, 1500.0)
        XCTAssertEqual(firstItem.net, 3500.0) // 5000 - 1500
    }

    /// Test 4: Multiple payslips conversion
    func testPrepareChartDataWithMultiplePayslips() {
        // Given: Multiple test payslips
        let payslip1 = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1500.0
        )

        let payslip2 = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "February",
            year: 2024,
            credits: 5200.0,
            debits: 1600.0
        )

        let payslips = [payslip1, payslip2]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should return items for both payslips
        XCTAssertEqual(chartData.count, 2)

        // Check first item
        let firstItem = chartData[0]
        XCTAssertEqual(firstItem.month, "January")
        XCTAssertEqual(firstItem.credits, 5000.0)
        XCTAssertEqual(firstItem.debits, 1500.0)
        XCTAssertEqual(firstItem.net, 3500.0)

        // Check second item
        let secondItem = chartData[1]
        XCTAssertEqual(secondItem.month, "February")
        XCTAssertEqual(secondItem.credits, 5200.0)
        XCTAssertEqual(secondItem.debits, 1600.0)
        XCTAssertEqual(secondItem.net, 3600.0)
    }

    /// Test 13: Different data types and formats
    func testPrepareChartDataWithVariedFormats() {
        // Given: Payslips with different month formats and years
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Jan",
                year: 2023,
                credits: 4000.0,
                debits: 800.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "February",
                year: 2024,
                credits: 4200.0,
                debits: 900.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "03",
                year: 2024,
                credits: 4100.0,
                debits: 850.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "December",
                year: 2025,
                credits: 4500.0,
                debits: 950.0
            )
        ]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should handle different month formats correctly
        XCTAssertEqual(chartData.count, 4)
        XCTAssertEqual(chartData[0].month, "Jan")
        XCTAssertEqual(chartData[1].month, "February")
        XCTAssertEqual(chartData[2].month, "03")
        XCTAssertEqual(chartData[3].month, "December")

        // Verify calculations are correct for all
        XCTAssertEqual(chartData[0].net, 3200.0)
        XCTAssertEqual(chartData[1].net, 3300.0)
        XCTAssertEqual(chartData[2].net, 3250.0)
        XCTAssertEqual(chartData[3].net, 3550.0)
    }
}
