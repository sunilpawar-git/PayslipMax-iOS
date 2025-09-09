import XCTest
@testable import PayslipMax

/// Test class for edge cases in financial calculations
final class FinancialEdgeCasesTests: XCTestCase {

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

    // MARK: - Edge Cases Tests

    func testFinancialCalculations_WithZeroValues() {
        // Given
        let zeroPayslip = testDataHelper.createZeroValuePayslip()
        let payslips = [zeroPayslip]

        // When & Then
        XCTAssertEqual(utility.aggregateTotalIncome(for: payslips), 0.0)
        XCTAssertEqual(utility.aggregateTotalDeductions(for: payslips), 0.0)
        XCTAssertEqual(utility.aggregateNetIncome(for: payslips), 0.0)
        XCTAssertEqual(utility.calculateAverageMonthlyIncome(for: payslips), 0.0)
    }

    func testFinancialCalculations_WithNegativeNetIncome() {
        // Given
        let negativePayslip = testDataHelper.createNegativeNetIncomePayslip()
        let payslips = [negativePayslip]

        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)

        // Then
        XCTAssertLessThan(netIncome, 0.0) // Should handle negative net income
        XCTAssertEqual(netIncome, -5000.0, accuracy: 0.01) // 30000 - 35000
    }
}
