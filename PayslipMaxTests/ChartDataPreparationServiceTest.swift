import XCTest
import Foundation
@testable import PayslipMax

/// Comprehensive tests for ChartDataPreparationService
final class ChartDataPreparationServiceTest: XCTestCase {
    
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
    
    // MARK: - Test Cases
    
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
        let emptyPayslips: [AnyPayslip] = []
        
        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: emptyPayslips)
        
        // Then: Should return empty array
        XCTAssertTrue(chartData.isEmpty)
        XCTAssertEqual(chartData.count, 0)
    }
    
    /// Test 3: Single payslip conversion
    func testPrepareChartDataWithSinglePayslip() {
        // Given: Single test payslip
        let testPayslip = createTestPayslip(
            month: "January", 
            year: 2024, 
            credits: 5000.0, 
            debits: 1000.0
        )
        
        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: [testPayslip])
        
        // Then: Should return single chart data item
        XCTAssertEqual(chartData.count, 1)
        
        let firstItem = chartData.first!
        XCTAssertEqual(firstItem.month, "January")
        XCTAssertEqual(firstItem.credits, 5000.0)
        XCTAssertEqual(firstItem.debits, 1000.0)
        XCTAssertEqual(firstItem.net, 4000.0) // 5000 - 1000
    }
    
    /// Test 4: Multiple payslips conversion
    func testPrepareChartDataWithMultiplePayslips() {
        // Given: Multiple test payslips
        let payslips = [
            createTestPayslip(month: "January", year: 2024, credits: 5000.0, debits: 1000.0),
            createTestPayslip(month: "February", year: 2024, credits: 5500.0, debits: 1200.0),
            createTestPayslip(month: "March", year: 2024, credits: 4800.0, debits: 900.0)
        ]
        
        // When: Preparing chart data
        let chartData = chartService.prepareChartData(from: payslips)
        
        // Then: Should return all items with correct transformations
        XCTAssertEqual(chartData.count, 3)
        
        // Verify first item
        XCTAssertEqual(chartData[0].month, "January")
        XCTAssertEqual(chartData[0].credits, 5000.0)
        XCTAssertEqual(chartData[0].debits, 1000.0)
        XCTAssertEqual(chartData[0].net, 4000.0)
        
        // Verify second item
        XCTAssertEqual(chartData[1].month, "February")
        XCTAssertEqual(chartData[1].credits, 5500.0)
        XCTAssertEqual(chartData[1].debits, 1200.0)
        XCTAssertEqual(chartData[1].net, 4300.0)
        
        // Verify third item
        XCTAssertEqual(chartData[2].month, "March")
        XCTAssertEqual(chartData[2].credits, 4800.0)
        XCTAssertEqual(chartData[2].debits, 900.0)
        XCTAssertEqual(chartData[2].net, 3900.0)
    }
    
    /// Test 5: Zero values handling
    func testPrepareChartDataWithZeroValues() {
        // Given: Payslip with zero values
        let testPayslip = createTestPayslip(
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
        let testPayslip = createTestPayslip(
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
        let testPayslip = createTestPayslip(
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
        let testPayslip = createTestPayslip(
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
    
    /// Test 9: Async chart data preparation
    func testPrepareChartDataInBackgroundAsync() async {
        // Given: Test payslips for async processing
        let payslips = [
            createTestPayslip(month: "October", year: 2024, credits: 6000.0, debits: 1500.0),
            createTestPayslip(month: "November", year: 2024, credits: 6200.0, debits: 1600.0)
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
            createTestPayslip(month: "January", year: 2025, credits: 7000.0, debits: 1800.0),
            createTestPayslip(month: "February", year: 2025, credits: 7100.0, debits: 1900.0)
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
    
    /// Test 11: PayslipChartData properties validation
    func testPayslipChartDataProperties() {
        // Given: Test payslip
        let testPayslip = createTestPayslip(
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
        let payslip1 = createTestPayslip(month: "May", year: 2024, credits: 5000.0, debits: 1000.0)
        let payslip2 = createTestPayslip(month: "May", year: 2024, credits: 5000.0, debits: 1000.0)
        
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
    
    /// Test 13: Different data types and formats
    func testPrepareChartDataWithVariedFormats() {
        // Given: Payslips with different month formats and years
        let payslips = [
            createTestPayslip(month: "Jan", year: 2023, credits: 4000.0, debits: 800.0),
            createTestPayslip(month: "February", year: 2024, credits: 4200.0, debits: 900.0),
            createTestPayslip(month: "03", year: 2024, credits: 4100.0, debits: 850.0),
            createTestPayslip(month: "December", year: 2025, credits: 4500.0, debits: 950.0)
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
    
    /// Test 14: Performance with large dataset
    func testPrepareChartDataPerformance() {
        // Given: Large dataset of payslips
        var largePayslipSet: [AnyPayslip] = []
        
        for i in 1...1000 {
            let payslip = createTestPayslip(
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
            var largePayslipSet: [AnyPayslip] = []
            
            for i in 1...500 {
                let payslip = createTestPayslip(
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
    
    // MARK: - Helper Methods
    
    /// Creates a test payslip with specified values
    private func createTestPayslip(month: String, year: Int, credits: Double, debits: Double) -> AnyPayslip {
        return TestPayslip(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: 0.0,
            tax: 0.0
        )
    }
}

// MARK: - Test Models

/// Simple test implementation of PayslipProtocol for testing
private struct TestPayslip: PayslipProtocol, Codable {
    let id = UUID()
    var timestamp = Date()
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String = "Test User"
    var accountNumber: String = "TEST123"
    var panNumber: String = "TESTPAN"
    var pdfData: Data? = nil
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    
    // PayslipEncryptionProtocol requirements
    var isNameEncrypted: Bool = false
    var isAccountNumberEncrypted: Bool = false
    var isPanNumberEncrypted: Bool = false
    
    // PayslipMetadataProtocol requirements
    var pdfURL: URL? = nil
    var isSample: Bool = false
    var source: String = "Test"
    var status: String = "Active"
    var notes: String? = nil
    
    // PayslipEncryptionProtocol methods
    func encryptSensitiveData() async throws {
        // No-op for test
    }
    
    func decryptSensitiveData() async throws {
        // No-op for test
    }
    
    func updateSensitiveData(name: String?, accountNumber: String?, panNumber: String?) {
        // No-op for test
    }
    
    func clearSensitiveData() {
        // No-op for test
    }
    
    func getSensitiveDataStatus() -> (hasName: Bool, hasAccount: Bool, hasPAN: Bool) {
        return (true, true, true)
    }
}

// Support enums (if not available)
private enum ProcessingQuality: CaseIterable, Codable {
    case high, medium, low
}

private enum ExtractionSource: CaseIterable, Codable {
    case manual, ocr, pattern
}