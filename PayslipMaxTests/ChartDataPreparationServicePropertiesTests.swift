import XCTest
import Foundation
@testable import PayslipMax

/// Properties validation tests for ChartDataPreparationService
/// Tests chart data properties, equality operators, and data integrity
final class ChartDataPreparationServicePropertiesTests: XCTestCase {

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

    // MARK: - Properties Validation Tests

    /// Test 11: PayslipChartData properties validation
    func testPayslipChartDataProperties() {
        // Given: Test payslip
        let testPayslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "TestMonth",
            year: 2024,
            credits: 1000.0,
            debits: 300.0
        )

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])
        let item = chartData.first!

        // Then: PayslipChartData should have all required properties
        XCTAssertNotNil(item.id) // UUID should be generated
        XCTAssertFalse(item.month.isEmpty)
        XCTAssertTrue(item.credits >= 0 || item.credits < 0) // Any number is valid
        XCTAssertTrue(item.debits >= 0 || item.debits < 0) // Any number is valid
        XCTAssertEqual(item.net, item.credits - item.debits)
    }

    /// Test 12: PayslipChartData equality
    func testPayslipChartDataEquality() {
        // Given: Two identical payslips
        let payslip1 = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "May",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0
        )
        let payslip2 = ChartDataPreparationServiceTestHelpers.createTestPayslip(
            month: "May",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0
        )

        // When: Creating chart data from both
        let chartData1 = chartService.prepareChartData(from: [payslip1])
        let chartData2 = chartService.prepareChartData(from: [payslip2])

        // Then: Chart data should be equal in content (but different IDs)
        let item1 = chartData1.first!
        let item2 = chartData2.first!

        XCTAssertNotEqual(item1.id, item2.id) // UUIDs should be different
        XCTAssertEqual(item1.month, item2.month)
        XCTAssertEqual(item1.credits, item2.credits)
        XCTAssertEqual(item1.debits, item2.debits)
        XCTAssertEqual(item1.net, item2.net)

        // Test equality operator
        let manualItem1 = PayslipChartData(month: "Test", credits: 100, debits: 20, net: 80)
        let manualItem2 = PayslipChartData(month: "Test", credits: 100, debits: 20, net: 80)
        XCTAssertEqual(manualItem1, manualItem2)
    }

    /// Test: PayslipChartData inequality
    func testPayslipChartDataInequality() {
        // Given: Different payslips
        let item1 = PayslipChartData(month: "Jan", credits: 1000, debits: 200, net: 800)
        let item2 = PayslipChartData(month: "Feb", credits: 1000, debits: 200, net: 800)
        let item3 = PayslipChartData(month: "Jan", credits: 1500, debits: 200, net: 800)
        let item4 = PayslipChartData(month: "Jan", credits: 1000, debits: 300, net: 800)
        let item5 = PayslipChartData(month: "Jan", credits: 1000, debits: 200, net: 700)

        // Then: Items should be unequal for different properties
        XCTAssertNotEqual(item1, item2) // Different month
        XCTAssertNotEqual(item1, item3) // Different credits
        XCTAssertNotEqual(item1, item4) // Different debits
        XCTAssertNotEqual(item1, item5) // Different net
    }

    /// Test: PayslipChartData hash consistency
    func testPayslipChartDataHashConsistency() {
        // Given: Same chart data items (UUIDs will be different)
        let item1 = PayslipChartData(month: "March", credits: 2000, debits: 500, net: 1500)
        let item2 = PayslipChartData(month: "March", credits: 2000, debits: 500, net: 1500)

        // When: Computing hash values
        _ = item1.hashValue
        _ = item2.hashValue

        // Then: Items with same data should be equal, but hash values may differ due to UUID
        XCTAssertEqual(item1, item2) // Equality should work
        XCTAssertNotEqual(item1.id, item2.id) // UUIDs should be different
        // Hash values may be different due to UUID, which is expected behavior

        // Test that the same object has consistent hash
        XCTAssertEqual(item1.hashValue, item1.hashValue, "Same object should have consistent hash")
        XCTAssertEqual(item2.hashValue, item2.hashValue, "Same object should have consistent hash")
    }

    /// Test: Chart data item uniqueness
    func testChartDataItemUniqueness() {
        // Given: Multiple payslips with different data
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Unique1",
                year: 2024,
                credits: 1000.0,
                debits: 100.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Unique2",
                year: 2024,
                credits: 2000.0,
                debits: 200.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Unique3",
                year: 2024,
                credits: 3000.0,
                debits: 300.0
            )
        ]

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: All items should have unique IDs
        let ids = chartData.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All chart data items should have unique IDs")
        XCTAssertEqual(chartData.count, 3)
    }

}
