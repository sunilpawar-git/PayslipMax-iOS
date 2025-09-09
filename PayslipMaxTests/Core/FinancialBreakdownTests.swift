import XCTest
@testable import PayslipMax

/// Test class for breakdown calculation functionality
final class FinancialBreakdownTests: XCTestCase {

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

    // MARK: - Breakdown Calculation Tests

    func testCalculateEarningsBreakdown() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let breakdown = utility.calculateEarningsBreakdown(for: payslips)

        // Then
        XCTAssertFalse(breakdown.isEmpty)

        // Find BPAY category
        if let bpayBreakdown = breakdown.first(where: { $0.category == "BPAY" }) {
            let expectedBpayTotal = 30000.0 + 31000.0 + 30500.0 // Jan + Feb + Mar
            XCTAssertEqual(bpayBreakdown.amount, expectedBpayTotal, accuracy: 0.01)
            XCTAssertGreaterThan(bpayBreakdown.percentage, 0)
        } else {
            XCTFail("BPAY category should be in earnings breakdown")
        }
    }

    func testCalculateDeductionsBreakdown() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let breakdown = utility.calculateDeductionsBreakdown(for: payslips)

        // Then
        XCTAssertFalse(breakdown.isEmpty)

        // Find DSOP category
        if let dsopBreakdown = breakdown.first(where: { $0.category == "DSOP" }) {
            let expectedDsopTotal = 4000.0 + 4500.0 + 4100.0 // Jan + Feb + Mar
            XCTAssertEqual(dsopBreakdown.amount, expectedDsopTotal, accuracy: 0.01)
            XCTAssertGreaterThan(dsopBreakdown.percentage, 0)
        } else {
            XCTFail("DSOP category should be in deductions breakdown")
        }
    }
}
