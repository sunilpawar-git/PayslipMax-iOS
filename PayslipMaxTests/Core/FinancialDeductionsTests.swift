import XCTest
@testable import PayslipMax

/// Test class for deductions calculation functionality
final class FinancialDeductionsTests: XCTestCase {

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

    // MARK: - Deductions Calculation Tests

    func testAggregateTotalDeductions_SinglePayslip() {
        // Given
        let payslips = [testDataHelper.createTestPayslips()[0]]

        // When
        let totalDeductions = utility.aggregateTotalDeductions(for: payslips)

        // Then
        XCTAssertEqual(totalDeductions, 12000.0, accuracy: 0.01)
    }

    func testAggregateTotalDeductions_MultiplePayslips() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let totalDeductions = utility.aggregateTotalDeductions(for: payslips)

        // Then
        let expectedTotal = 12000.0 + 13000.0 + 12500.0 // Jan + Feb + Mar
        XCTAssertEqual(totalDeductions, expectedTotal, accuracy: 0.01)
    }

    func testCalculateTotalDeductions_IndividualPayslip() {
        // Given
        let payslip = testDataHelper.createTestPayslips()[0]

        // When
        let totalDeductions = utility.calculateTotalDeductions(for: payslip)

        // Then
        // Should use debits field as authoritative total
        XCTAssertEqual(totalDeductions, payslip.debits, accuracy: 0.01)
        XCTAssertEqual(totalDeductions, 12000.0, accuracy: 0.01)
    }
}
