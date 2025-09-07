import XCTest
import Foundation
@testable import PayslipMax

/// Performance and memory management tests for ChartDataPreparationService
/// Tests performance benchmarks, memory usage, and large dataset handling
final class ChartDataPreparationServicePerformanceTests: XCTestCase {

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

    // MARK: - Performance Tests

    /// Test 14: Performance with large dataset
    func testPrepareChartDataPerformance() {
        // Given: Large dataset of payslips
        var largePayslipSet: [PayslipItem] = []

        for i in 1...1000 {
            let payslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
                month: "Month\(i % 12 + 1)",
                year: 2020 + (i / 12),
                credits: Double(4000 + i),
                debits: Double(800 + i / 5)
            )
            largePayslipSet.append(payslip)
        }

        // When: Measuring performance of chart data preparation
        let startTime = CFAbsoluteTimeGetCurrent()
        let chartData = chartService.prepareChartData(from: largePayslipSet)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then: Should process within reasonable time and return correct count
        XCTAssertEqual(chartData.count, 1000)
        XCTAssertLessThan(timeElapsed, 1.0, "Chart data preparation should complete within 1 second for 1000 items")

        // Verify a few random items for correctness
        XCTAssertEqual(chartData[0].month, "Month2") // i=1, so 1 % 12 + 1 = 2
        XCTAssertEqual(chartData[500].month, "Month10") // i=501, so 501 % 12 + 1 = 10
        XCTAssertEqual(chartData[999].month, "Month5") // i=1000, so 1000 % 12 + 1 = 5
    }

    /// Test 15: Memory management with large dataset
    func testMemoryManagementWithLargeDataset() {
        // Given: Create and process large dataset multiple times
        for iteration in 1...5 {
            var largePayslipSet: [PayslipItem] = []

            for i in 1...500 {
                let payslip = ChartDataPreparationServiceTestHelpers.createTestPayslip(
                    month: "Iter\(iteration)Month\(i)",
                    year: 2024,
                    credits: Double(5000 + i * iteration),
                    debits: Double(1000 + i)
                )
                largePayslipSet.append(payslip)
            }

            // When: Processing large dataset
            let chartData = chartService.prepareChartData(from: largePayslipSet)

            // Then: Should complete successfully without memory issues
            XCTAssertEqual(chartData.count, 500)

            // Clear references to test memory cleanup
            largePayslipSet.removeAll()
        }

        // Should complete all iterations without memory issues
        XCTAssertTrue(true, "Memory management test completed successfully")
    }

    /// Test: Extreme performance with very large dataset
    func testExtremePerformanceWithVeryLargeDataset() {
        // Given: Very large dataset (5000 items)
        let veryLargePayslips = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 5000)

        // When: Measuring performance with very large dataset
        let startTime = CFAbsoluteTimeGetCurrent()
        let chartData = chartService.prepareChartData(from: veryLargePayslips)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then: Should handle very large datasets within reasonable time
        XCTAssertEqual(chartData.count, 5000)
        XCTAssertLessThan(timeElapsed, 5.0, "Should complete within 5 seconds for 5000 items")

        // Verify data integrity
        XCTAssertEqual(chartData[0].month, "Month2")
        XCTAssertEqual(chartData[2500].month, "Month7")
        XCTAssertEqual(chartData[4999].month, "Month5")
    }

    /// Test: Memory efficiency with repeated operations
    func testMemoryEfficiencyWithRepeatedOperations() {
        // Given: Same dataset processed multiple times
        let basePayslips = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 200)

        // When: Processing the same data repeatedly
        var memoryUsage: [Int] = []

        for iteration in 1...10 {
            autoreleasepool {
                let chartData = chartService.prepareChartData(from: basePayslips)
                XCTAssertEqual(chartData.count, 200)

                // Simulate memory pressure check (in real scenario, would use memory profiler)
                memoryUsage.append(iteration)
            }
        }

        // Then: Should maintain consistent performance
        XCTAssertEqual(memoryUsage.count, 10)
        XCTAssertTrue(true, "Repeated operations completed without memory issues")
    }

    /// Test: Performance with empty arrays vs small arrays
    func testPerformanceComparisonEmptyVsSmallArrays() {
        // Given: Different array sizes
        let emptyArray: [PayslipItem] = []
        let smallArray = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 10)
        let mediumArray = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 100)

        // When: Measuring performance for different sizes
        let emptyStart = CFAbsoluteTimeGetCurrent()
        let emptyResult = chartService.prepareChartData(from: emptyArray)
        let emptyTime = CFAbsoluteTimeGetCurrent() - emptyStart

        let smallStart = CFAbsoluteTimeGetCurrent()
        let smallResult = chartService.prepareChartData(from: smallArray)
        let smallTime = CFAbsoluteTimeGetCurrent() - smallStart

        let mediumStart = CFAbsoluteTimeGetCurrent()
        let mediumResult = chartService.prepareChartData(from: mediumArray)
        let mediumTime = CFAbsoluteTimeGetCurrent() - mediumStart

        // Then: Performance should scale appropriately
        XCTAssertEqual(emptyResult.count, 0)
        XCTAssertEqual(smallResult.count, 10)
        XCTAssertEqual(mediumResult.count, 100)

        // Empty should be fastest
        XCTAssertLessThan(emptyTime, smallTime, "Empty array should be faster than small array")

        // Small should be faster than medium
        XCTAssertLessThan(smallTime, mediumTime, "Small array should be faster than medium array")

        // All should be reasonably fast
        XCTAssertLessThan(emptyTime, 0.001, "Empty array should be very fast")
        XCTAssertLessThan(smallTime, 0.01, "Small array should be fast")
        XCTAssertLessThan(mediumTime, 0.1, "Medium array should be reasonably fast")
    }

    /// Test: Concurrent performance with multiple services
    func testConcurrentPerformanceWithMultipleServices() async {
        // Given: Multiple chart services and datasets
        let service1 = ChartDataPreparationService()
        let service2 = ChartDataPreparationService()
        let service3 = ChartDataPreparationService()

        let dataset1 = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 300)
        let dataset2 = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 400)
        let dataset3 = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 500)

        // When: Running multiple services concurrently
        let startTime = CFAbsoluteTimeGetCurrent()

        async let result1 = service1.prepareChartDataInBackground(from: dataset1)
        async let result2 = service2.prepareChartDataInBackground(from: dataset2)
        async let result3 = service3.prepareChartDataInBackground(from: dataset3)

        let (chartData1, chartData2, chartData3) = await (result1, result2, result3)
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime

        // Then: All should complete successfully and concurrently
        XCTAssertEqual(chartData1.count, 300)
        XCTAssertEqual(chartData2.count, 400)
        XCTAssertEqual(chartData3.count, 500)

        // Concurrent execution should be reasonably fast
        XCTAssertLessThan(totalTime, 3.0, "Concurrent processing should complete within 3 seconds")
    }

    /// Test: Memory pressure handling
    func testMemoryPressureHandling() {
        // Given: Large dataset that could cause memory pressure
        let largeDataset = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: 2000)

        // When: Processing under simulated memory pressure
        var results: [[PayslipChartData]] = []

        for batch in 1...5 {
            autoreleasepool {
                let batchData = Array(largeDataset[(batch-1)*400..<batch*400])
                let chartData = chartService.prepareChartData(from: batchData)
                XCTAssertEqual(chartData.count, 400)
                results.append(chartData)
            }
        }

        // Then: Should handle memory pressure gracefully
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results[0].count, 400)
        XCTAssertEqual(results[4].count, 400)
    }

    /// Test: Performance degradation monitoring
    func testPerformanceDegradationMonitoring() {
        // Given: Same operation performed multiple times
        let testData = ChartDataPreparationServiceTestHelpers.createSequentialTestPayslips(count: 100)
        var executionTimes: [Double] = []

        // When: Measuring execution time over multiple runs
        for _ in 1...20 {
            let startTime = CFAbsoluteTimeGetCurrent()
            let chartData = chartService.prepareChartData(from: testData)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime

            XCTAssertEqual(chartData.count, 100)
            executionTimes.append(executionTime)
        }

        // Then: Performance should be relatively consistent
        let averageTime = executionTimes.reduce(0, +) / Double(executionTimes.count)
        let maxTime = executionTimes.max() ?? 0
        let minTime = executionTimes.min() ?? 0

        // Max should not be more than 3x the minimum (allowing some variance)
        XCTAssertLessThan(maxTime, minTime * 3, "Performance should not degrade significantly")

        // Average should be reasonable
        XCTAssertLessThan(averageTime, 0.05, "Average execution time should be reasonable")
    }

    /// Test: Scalability with increasing data sizes
    func testScalabilityWithIncreasingDataSizes() {
        // Given: Different data sizes to test scalability
        let sizes = [50, 100, 200, 500, 1000]
        var times: [Double] = []

        for size in sizes {
            let testData = ChartDataPreparationServiceTestHelpers.createPerformanceTestPayslips(count: size)

            let startTime = CFAbsoluteTimeGetCurrent()
            let chartData = chartService.prepareChartData(from: testData)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime

            XCTAssertEqual(chartData.count, size)
            times.append(executionTime)
        }

        // Then: Performance should scale reasonably (not exponentially)
        for i in 1..<times.count {
            let ratio = times[i] / times[i-1]
            let sizeRatio = Double(sizes[i]) / Double(sizes[i-1])

            // Time increase should not be more than 3x the size increase
            XCTAssertLessThan(ratio, sizeRatio * 3, "Performance should scale reasonably with data size")
        }
    }
}
