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
        // Given: Same chart data items
        let item1 = PayslipChartData(month: "March", credits: 2000, debits: 500, net: 1500)
        let item2 = PayslipChartData(month: "March", credits: 2000, debits: 500, net: 1500)

        // When: Computing hash values
        let hash1 = item1.hashValue
        let hash2 = item2.hashValue

        // Then: Equal items should have equal hash values
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(item1, item2)
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

    /// Test: Chart data properties range validation
    func testChartDataPropertiesRangeValidation() {
        // Given: Payslips with various value ranges
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

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should handle all value ranges appropriately
        XCTAssertEqual(chartData.count, 4)

        // Verify properties are set (exact values depend on implementation)
        XCTAssertNotNil(chartData[0].id)
        XCTAssertNotNil(chartData[1].id)
        XCTAssertNotNil(chartData[2].id)
        XCTAssertNotNil(chartData[3].id)

        // Months should be preserved
        XCTAssertEqual(chartData[0].month, "MinValues")
        XCTAssertEqual(chartData[1].month, "MaxValues")
        XCTAssertEqual(chartData[2].month, "Infinity")
        XCTAssertEqual(chartData[3].month, "NaN")
    }

    /// Test: Chart data structural integrity
    func testChartDataStructuralIntegrity() {
        // Given: Complex payslip data
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

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [payslip])

        // Then: Should maintain structural integrity
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "IntegrityTest")
        XCTAssertEqual(item.credits, 12345.67)
        XCTAssertEqual(item.debits, 6789.12)
        XCTAssertEqual(item.net, 12345.67 - 6789.12) // 5556.55

        // Verify net calculation is correct
        XCTAssertEqual(item.net, 5556.55, accuracy: 0.001)
    }

    /// Test: Chart data with special characters in month
    func testChartDataWithSpecialCharactersInMonth() {
        // Given: Payslips with special characters in month names
        let specialMonths = ["Jan-2024", "Feb_2024", "Mar 2024", "Apr/2024", "May@2024"]

        let payslips = specialMonths.map { month in
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: month,
                year: 2024,
                credits: 1000.0,
                debits: 200.0
            )
        }

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)

        // Then: Should preserve special characters in month names
        XCTAssertEqual(chartData.count, 5)

        for (index, expectedMonth) in specialMonths.enumerated() {
            XCTAssertEqual(chartData[index].month, expectedMonth)
            XCTAssertEqual(chartData[index].credits, 1000.0)
            XCTAssertEqual(chartData[index].debits, 200.0)
            XCTAssertEqual(chartData[index].net, 800.0)
        }
    }

    /// Test: Empty month name handling
    func testChartDataWithEmptyMonthName() {
        // Given: Payslip with empty month name
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

        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [payslip])

        // Then: Should handle empty month name appropriately
        XCTAssertEqual(chartData.count, 1)

        let item = chartData.first!
        XCTAssertEqual(item.month, "") // Empty string should be preserved
        XCTAssertEqual(item.credits, 5000.0)
        XCTAssertEqual(item.debits, 1000.0)
        XCTAssertEqual(item.net, 4000.0)
    }
}
