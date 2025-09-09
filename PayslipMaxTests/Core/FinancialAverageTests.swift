import XCTest
@testable import PayslipMax

/// Test class for average calculation functionality
final class FinancialAverageTests: XCTestCase {

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

    // MARK: - Average Calculation Tests

    func testCalculateAverageMonthlyIncome() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)

        // Then
        let expectedAverage = (50000.0 + 52000.0 + 51000.0) / 3.0
        XCTAssertEqual(averageIncome, expectedAverage, accuracy: 0.01)
    }

    func testCalculateAverageMonthlyIncome_SinglePayslip() {
        // Given
        let payslips = [testDataHelper.createTestPayslips()[0]]

        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)

        // Then
        XCTAssertEqual(averageIncome, 50000.0, accuracy: 0.01)
    }

    func testCalculateAverageMonthlyIncome_EmptyArray() {
        // Given
        let payslips: [PayslipItem] = []

        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)

        // Then
        XCTAssertEqual(averageIncome, 0.0)
    }

    func testCalculateAverageNetRemittance() {
        // Given
        let payslips = testDataHelper.createTestPayslips()

        // When
        let averageNet = utility.calculateAverageNetRemittance(for: payslips)

        // Then
        let totalIncome = 50000.0 + 52000.0 + 51000.0
        let totalDeductions = 12000.0 + 13000.0 + 12500.0
        let expectedAverage = (totalIncome - totalDeductions) / 3.0
        XCTAssertEqual(averageNet, expectedAverage, accuracy: 0.01)
    }
}
