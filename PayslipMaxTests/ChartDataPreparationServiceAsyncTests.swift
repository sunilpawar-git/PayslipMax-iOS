import XCTest
import Foundation
@testable import PayslipMax

/// Async functionality tests for ChartDataPreparationService
/// Tests async processing, background execution, and sync/async consistency
final class ChartDataPreparationServiceAsyncTests: XCTestCase {

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

    // MARK: - Async Functionality Tests

    /// Test 9: Async chart data preparation
    func testPrepareChartDataInBackgroundAsync() async {
        // Given: Test payslips for async processing
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "October",
                year: 2024,
                credits: 6000.0,
                debits: 1500.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "November",
                year: 2024,
                credits: 6200.0,
                debits: 1600.0
            )
        ]

        // When: Preparing chart data asynchronously
        let chartData = await chartService.prepareChartDataInBackground(from: payslips)

        // Then: Should return same results as synchronous method
        XCTAssertEqual(chartData.count, 2)

        // Verify async processing produces correct results
        XCTAssertEqual(chartData[0].month, "October")
        XCTAssertEqual(chartData[0].credits, 6000.0)
        XCTAssertEqual(chartData[0].net, 4500.0)

        XCTAssertEqual(chartData[1].month, "November")
        XCTAssertEqual(chartData[1].credits, 6200.0)
        XCTAssertEqual(chartData[1].net, 4600.0)
    }

    /// Test 10: Async vs Sync consistency
    func testAsyncSyncConsistency() async {
        // Given: Same test payslips for both methods
        let payslips = [
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "January",
                year: 2025,
                credits: 7000.0,
                debits: 1800.0
            ),
            ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "February",
                year: 2025,
                credits: 7100.0,
                debits: 1900.0
            )
        ]

        // When: Preparing chart data with both methods
        let syncChartData = chartService.prepareChartData(from: payslips)
        let asyncChartData = await chartService.prepareChartDataInBackground(from: payslips)

        // Then: Both methods should return identical results
        XCTAssertEqual(syncChartData.count, asyncChartData.count)

        for i in 0..<syncChartData.count {
            XCTAssertEqual(syncChartData[i], asyncChartData[i])
        }
    }

    /// Test: Async processing with empty data
    func testAsyncPrepareChartDataWithEmptyPayslips() async {
        // Given: Empty payslips array
        let emptyPayslips: [PayslipItem] = []

        // When: Preparing chart data asynchronously
        let chartData = await chartService.prepareChartDataInBackground(from: emptyPayslips)

        // Then: Should return empty array
        XCTAssertTrue(chartData.isEmpty)
        XCTAssertEqual(chartData.count, 0)
    }

    /// Test: Async processing with large dataset
    func testAsyncPrepareChartDataWithLargeDataset() async {
        // Given: Large dataset of payslips
        let largePayslips = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 500)

        // When: Preparing chart data asynchronously
        let startTime = CFAbsoluteTimeGetCurrent()
        let chartData = await chartService.prepareChartDataInBackground(from: largePayslips)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then: Should process correctly and within reasonable time
        XCTAssertEqual(chartData.count, 500)
        XCTAssertLessThan(timeElapsed, 2.0, "Async chart data preparation should complete within 2 seconds for 500 items")

        // Verify a few items for correctness
        XCTAssertEqual(chartData[0].month, "Month2")
        XCTAssertEqual(chartData[250].month, "Month12")
        XCTAssertEqual(chartData[499].month, "Month9")
    }

    /// Test: Multiple concurrent async operations
    func testMultipleConcurrentAsyncOperations() async {
        // Given: Multiple datasets for concurrent processing
        let dataset1 = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 100)
        let dataset2 = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 150)
        let dataset3 = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 200)

        // When: Processing multiple datasets concurrently
        async let result1 = chartService.prepareChartDataInBackground(from: dataset1)
        async let result2 = chartService.prepareChartDataInBackground(from: dataset2)
        async let result3 = chartService.prepareChartDataInBackground(from: dataset3)

        let (chartData1, chartData2, chartData3) = await (result1, result2, result3)

        // Then: All operations should complete successfully
        XCTAssertEqual(chartData1.count, 100)
        XCTAssertEqual(chartData2.count, 150)
        XCTAssertEqual(chartData3.count, 200)

        // Verify data integrity for each result
        XCTAssertEqual(chartData1[0].month, "Month2")
        XCTAssertEqual(chartData2[0].month, "Month2")
        XCTAssertEqual(chartData3[0].month, "Month2")
    }

    /// Test: Async processing with edge case values
    func testAsyncPrepareChartDataWithEdgeCases() async {
        // Given: Payslips with edge case values
        let edgeCasePayslips = ChartDataPreparationServiceTestHelpers.createEdgeCasePayslips()

        // When: Preparing chart data asynchronously
        let chartData = await chartService.prepareChartDataInBackground(from: edgeCasePayslips)

        // Then: Should handle all edge cases correctly
        XCTAssertEqual(chartData.count, 4)

        // Zero values
        XCTAssertEqual(chartData[0].net, 0.0)

        // Negative net
        XCTAssertEqual(chartData[1].net, -1000.0) // 3000 - 4000

        // Large values
        XCTAssertEqual(chartData[2].net, 876543.21, accuracy: 0.01)

        // Decimal precision
        XCTAssertEqual(chartData[3].net, 3333.33, accuracy: 0.001)
    }

    /// Test: Async processing with cancellation
    func testAsyncPrepareChartDataWithCancellation() async {
        // Given: Large dataset that might be cancelled
        let largePayslips = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 1000)

        // When: Starting async processing and cancelling immediately
        let task = Task {
            return await chartService.prepareChartDataInBackground(from: largePayslips)
        }

        // Cancel the task immediately
        task.cancel()

        // Then: Task should be cancelled gracefully
        let result = await task.result

        switch result {
        case .success(let chartData):
            // If not cancelled, should still return valid data
            XCTAssertGreaterThan(chartData.count, 0)
        case .failure(let error):
            // If cancelled, should receive cancellation error
            let isCancellationError = error.localizedDescription.contains("cancel") ||
                                     error.localizedDescription.contains("Cancel")
            XCTAssertTrue(isCancellationError, "Expected cancellation error, got: \(error.localizedDescription)")
        }
    }

    /// Test: Async processing performance comparison
    func testAsyncVsSyncPerformanceComparison() async {
        // Given: Large dataset for performance comparison
        let largePayslips = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 2000)

        // When: Measuring both sync and async performance
        let syncStartTime = CFAbsoluteTimeGetCurrent()
        let syncChartData = chartService.prepareChartData(from: largePayslips)
        let syncTimeElapsed = CFAbsoluteTimeGetCurrent() - syncStartTime

        let asyncStartTime = CFAbsoluteTimeGetCurrent()
        let asyncChartData = await chartService.prepareChartDataInBackground(from: largePayslips)
        let asyncTimeElapsed = CFAbsoluteTimeGetCurrent() - asyncStartTime

        // Then: Both should complete and produce same results
        XCTAssertEqual(syncChartData.count, 2000)
        XCTAssertEqual(asyncChartData.count, 2000)

        // Verify results are identical
        for i in 0..<min(syncChartData.count, asyncChartData.count) {
            XCTAssertEqual(syncChartData[i], asyncChartData[i])
        }

        // Async should not be dramatically slower (allowing some overhead)
        XCTAssertLessThan(asyncTimeElapsed, syncTimeElapsed * 3, "Async should not be more than 3x slower than sync")

        // Both should complete within reasonable time
        XCTAssertLessThan(syncTimeElapsed, 5.0, "Sync processing should complete within 5 seconds")
        XCTAssertLessThan(asyncTimeElapsed, 5.0, "Async processing should complete within 5 seconds")
    }
}
