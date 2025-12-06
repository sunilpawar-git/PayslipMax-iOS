import XCTest
@testable import PayslipMax

/// Comprehensive unit tests for PayslipComparisonService
final class PayslipComparisonServiceTests: XCTestCase {

    var sut: PayslipComparisonService!

    override func setUp() {
        super.setUp()
        sut = PayslipComparisonService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Find Previous Payslip Tests

    func testFindPreviousPayslip_WithMultiplePayslips_ReturnsPreviousMonth() {
        // Given
        let january = createPayslip(month: "January", year: 2025)
        let february = createPayslip(month: "February", year: 2025)
        let march = createPayslip(month: "March", year: 2025)
        let allPayslips = [march, january, february] // Intentionally unordered

        // When
        let previous = sut.findPreviousPayslip(for: march, in: allPayslips)

        // Then
        XCTAssertNotNil(previous)
        XCTAssertEqual(previous?.month, "February")
        XCTAssertEqual(previous?.year, 2025)
    }

    func testFindPreviousPayslip_WithFirstPayslip_ReturnsNil() {
        // Given
        let january = createPayslip(month: "January", year: 2025)
        let february = createPayslip(month: "February", year: 2025)
        let allPayslips = [january, february]

        // When
        let previous = sut.findPreviousPayslip(for: january, in: allPayslips)

        // Then
        XCTAssertNil(previous)
    }

    func testFindPreviousPayslip_WithSkippedMonths_ReturnsChronologicalPrevious() {
        // Given
        let january = createPayslip(month: "January", year: 2025)
        let march = createPayslip(month: "March", year: 2025)
        let may = createPayslip(month: "May", year: 2025)
        let allPayslips = [january, march, may]

        // When
        let previous = sut.findPreviousPayslip(for: may, in: allPayslips)

        // Then
        XCTAssertNotNil(previous)
        XCTAssertEqual(previous?.month, "March")
        XCTAssertEqual(previous?.year, 2025)
    }

    func testFindPreviousPayslip_WithYearBoundary_ReturnsPreviousYear() {
        // Given
        let december2024 = createPayslip(month: "December", year: 2024)
        let january2025 = createPayslip(month: "January", year: 2025)
        let allPayslips = [december2024, january2025]

        // When
        let previous = sut.findPreviousPayslip(for: january2025, in: allPayslips)

        // Then
        XCTAssertNotNil(previous)
        XCTAssertEqual(previous?.month, "December")
        XCTAssertEqual(previous?.year, 2024)
    }

    // MARK: - Compare Payslips - Net Remittance Tests

    func testComparePayslips_IncreasedNetRemittance_ReturnsPositiveChange() {
        // Given
        let previous = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 110000, debits: 25000)

        // When
        let comparison = sut.comparePayslips(current: current, previous: previous)

        // Then
        XCTAssertTrue(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 10000)
        XCTAssertEqual(comparison.netRemittancePercentageChange ?? 0, (10000 / 75000) * 100, accuracy: 0.01)
    }

    func testComparePayslips_DecreasedNetRemittance_ReturnsNegativeChange() {
        // Given
        let previous = createPayslip(month: "January", year: 2025, credits: 110000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 100000, debits: 25000)

        // When
        let comparison = sut.comparePayslips(current: current, previous: previous)

        // Then
        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertTrue(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, -10000)
        XCTAssertEqual(comparison.netRemittancePercentageChange ?? 0, (-10000 / 85000) * 100, accuracy: 0.01)
    }

    func testComparePayslips_SameNetRemittance_ReturnsZeroChange() {
        // Given
        let previous = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 100000, debits: 25000)

        // When
        let comparison = sut.comparePayslips(current: current, previous: previous)

        // Then
        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 0)
        XCTAssertEqual(comparison.netRemittancePercentageChange, 0)
    }

    func testComparePayslips_NoPreviousPayslip_ReturnsZeroChange() {
        // Given
        let current = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)

        // When
        let comparison = sut.comparePayslips(current: current, previous: nil)

        // Then
        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 0)
        XCTAssertNil(comparison.netRemittancePercentageChange)
        XCTAssertNil(comparison.previousPayslip)
    }

    // MARK: - Compare Item - Earnings Tests

    func testCompareItem_NewEarning_MarksAsNew() {
        // When
        let comparison = sut.compareItem(name: "Bonus", current: 5000, previous: nil, isEarning: true)

        // Then
        XCTAssertTrue(comparison.isNew)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.currentAmount, 5000)
        XCTAssertNil(comparison.previousAmount)
        XCTAssertEqual(comparison.absoluteChange, 5000)
        XCTAssertNil(comparison.percentageChange)
    }

    func testCompareItem_IncreasedEarning_CalculatesPercentage() {
        // When
        let comparison = sut.compareItem(name: "Basic Pay", current: 60000, previous: 50000, isEarning: true)

        // Then
        XCTAssertFalse(comparison.isNew)
        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertFalse(comparison.hasDecreased)
        XCTAssertFalse(comparison.needsAttention) // Increased earnings don't need attention
        XCTAssertEqual(comparison.absoluteChange, 10000)
        XCTAssertEqual(comparison.percentageChange ?? 0, 20, accuracy: 0.01)
    }

    func testCompareItem_DecreasedEarning_MarksNeedsAttention() {
        // When
        let comparison = sut.compareItem(name: "HRA", current: 25000, previous: 30000, isEarning: true)

        // Then
        XCTAssertTrue(comparison.hasDecreased)
        XCTAssertTrue(comparison.needsAttention) // Decreased earnings need attention
        XCTAssertEqual(comparison.absoluteChange, -5000)
        XCTAssertEqual(comparison.percentageChange ?? 0, (-5000 / 30000) * 100, accuracy: 0.01)
    }

    func testCompareItem_UnchangedEarning_ReturnsZeroChange() {
        // When
        let comparison = sut.compareItem(name: "DA", current: 10000, previous: 10000, isEarning: true)

        // Then
        XCTAssertTrue(comparison.isUnchanged)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, 0)
        XCTAssertEqual(comparison.percentageChange, 0)
    }

    // MARK: - Compare Item - Deductions Tests

    func testCompareItem_NewDeduction_MarksAsNew() {
        // When
        let comparison = sut.compareItem(name: "Professional Tax", current: 2000, previous: nil, isEarning: false)

        // Then
        XCTAssertTrue(comparison.isNew)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.currentAmount, 2000)
        XCTAssertNil(comparison.previousAmount)
    }

    func testCompareItem_IncreasedDeduction_MarksNeedsAttention() {
        // When
        let comparison = sut.compareItem(name: "Income Tax", current: 18000, previous: 15000, isEarning: false)

        // Then
        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertTrue(comparison.needsAttention) // Increased deductions need attention
        XCTAssertEqual(comparison.absoluteChange, 3000)
        XCTAssertEqual(comparison.percentageChange ?? 0, 20, accuracy: 0.01)
    }

    func testCompareItem_DecreasedDeduction_DoesNotNeedAttention() {
        // When
        let comparison = sut.compareItem(name: "DSOP", current: 7000, previous: 8000, isEarning: false)

        // Then
        XCTAssertTrue(comparison.hasDecreased)
        XCTAssertFalse(comparison.needsAttention) // Decreased deductions don't need attention
        XCTAssertEqual(comparison.absoluteChange, -1000)
    }

    // MARK: - Edge Cases

    func testCompareItem_ZeroToPreviousAmount_HandlesCorrectly() {
        // When
        let comparison = sut.compareItem(name: "Allowance", current: 5000, previous: 0, isEarning: true)

        // Then
        XCTAssertFalse(comparison.isNew)
        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertEqual(comparison.absoluteChange, 5000)
        XCTAssertNil(comparison.percentageChange) // Can't calculate percentage from zero
    }

    func testComparePayslips_WithEarningsAndDeductions_ComparesAllItems() {
        // Given
        let previousEarnings = ["Basic": 50000.0, "HRA": 30000.0]
        let previousDeductions = ["Tax": 15000.0, "DSOP": 8000.0]
        let previous = createPayslip(
            month: "January",
            year: 2025,
            earnings: previousEarnings,
            deductions: previousDeductions
        )

        let currentEarnings = ["Basic": 55000.0, "HRA": 30000.0, "Bonus": 10000.0] // Basic increased, Bonus new
        let currentDeductions = ["Tax": 16000.0, "DSOP": 8000.0] // Tax increased
        let current = createPayslip(
            month: "February",
            year: 2025,
            earnings: currentEarnings,
            deductions: currentDeductions
        )

        // When
        let comparison = sut.comparePayslips(current: current, previous: previous)

        // Then
        XCTAssertEqual(comparison.earningsChanges.count, 3) // Basic, HRA, Bonus
        XCTAssertEqual(comparison.deductionsChanges.count, 2) // Tax, DSOP

        // Verify Basic Pay increased
        XCTAssertTrue(comparison.earningsChanges["Basic"]?.hasIncreased ?? false)
        XCTAssertEqual(comparison.earningsChanges["Basic"]?.absoluteChange, 5000)

        // Verify Bonus is new
        XCTAssertTrue(comparison.earningsChanges["Bonus"]?.isNew ?? false)

        // Verify HRA unchanged
        XCTAssertTrue(comparison.earningsChanges["HRA"]?.isUnchanged ?? false)

        // Verify Tax increased and needs attention
        XCTAssertTrue(comparison.deductionsChanges["Tax"]?.hasIncreased ?? false)
        XCTAssertTrue(comparison.deductionsChanges["Tax"]?.needsAttention ?? false)

        // Verify DSOP unchanged
        XCTAssertTrue(comparison.deductionsChanges["DSOP"]?.isUnchanged ?? false)
    }

    // MARK: - Helper Methods

    private func createPayslip(
        month: String,
        year: Int,
        credits: Double = 100000,
        debits: Double = 25000,
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:]
    ) -> any PayslipProtocol {
        MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: deductions["DSOP"] ?? 8000,
            tax: deductions["Tax"] ?? 15000,
            earnings: earnings.isEmpty ? ["Basic": credits - 20000, "HRA": 20000] : earnings,
            deductions: deductions.isEmpty ? ["Tax": 15000, "DSOP": debits - 15000] : deductions,
            name: "Test User",
            accountNumber: "123456",
            panNumber: "ABCDE1234F",
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )
    }
}
