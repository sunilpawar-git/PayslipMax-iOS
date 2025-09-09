import XCTest
@testable import PayslipMax

/// Test class for income calculation functionality
final class FinancialIncomeTests: XCTestCase {

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

    // MARK: - Income Calculation Tests

    func testAggregateTotalIncome_SinglePayslip() {
        // Given
        let payslips = [testDataHelper.createTestPayslips()[0]] // January payslip

        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)

        // Then
        XCTAssertEqual(totalIncome, 50000.0, accuracy: 0.01)
    }

    func testAggregateTotalIncome_MultiplePayslips() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)

        // Then
        let expectedTotal = 50000.0 + 52000.0 + 51000.0 // Jan + Feb + Mar
        XCTAssertEqual(totalIncome, expectedTotal, accuracy: 0.01)
    }

    func testAggregateTotalIncome_EmptyArray() {
        // Given
        let payslips: [PayslipItem] = []

        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)

        // Then
        XCTAssertEqual(totalIncome, 0.0)
    }

    // MARK: - Net Income Calculation Tests

    func testAggregateNetIncome_SinglePayslip() {
        // Given
        let payslips = [testDataHelper.createTestPayslips()[0]]

        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)

        // Then
        let expectedNet = 50000.0 - 12000.0 // credits - debits
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }

    func testAggregateNetIncome_MultiplePayslips() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)

        // Then
        let expectedTotalIncome = 50000.0 + 52000.0 + 51000.0
        let expectedTotalDeductions = 12000.0 + 13000.0 + 12500.0
        let expectedNet = expectedTotalIncome - expectedTotalDeductions
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }

    func testCalculateNetIncome_IndividualPayslip() {
        // Given
        let payslip = testDataHelper.createTestPayslips()[0]

        // When
        let netIncome = utility.calculateNetIncome(for: payslip)

        // Then
        let expectedNet = payslip.credits - payslip.debits
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
        XCTAssertEqual(netIncome, 38000.0, accuracy: 0.01) // 50000 - 12000
    }
}
