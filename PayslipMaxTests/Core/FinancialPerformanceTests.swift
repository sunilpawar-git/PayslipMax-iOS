import XCTest
@testable import PayslipMax

/// Test class for performance testing of financial calculations
final class FinancialPerformanceTests: XCTestCase {

    // MARK: - Test Properties

    var utility: FinancialCalculationUtility!
    var testDataHelper: FinancialTestDataHelper!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        utility = FinancialCalculationUtility.shared
        testDataHelper = FinancialTestDataHelper()
    }

    override func tearDown() {
        utility = nil
        testDataHelper = nil
        super.tearDown()
    }

    // MARK: - Performance Tests

    func testFinancialCalculations_Performance() {
        // Given - Create a larger array by repeating individual payslips
        let largePayslipArray = testDataHelper.createLargePayslipArray(repeatCount: 300)

        // When & Then
        measure {
            _ = utility.aggregateTotalIncome(for: largePayslipArray)
            _ = utility.aggregateTotalDeductions(for: largePayslipArray)
            _ = utility.aggregateNetIncome(for: largePayslipArray)
            _ = utility.calculateAverageMonthlyIncome(for: largePayslipArray)
        }
    }
}
