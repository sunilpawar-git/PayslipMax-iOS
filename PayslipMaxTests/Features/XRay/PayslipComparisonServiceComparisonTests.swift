import XCTest
@testable import PayslipMax

/// Tests covering comparison outputs (net remittance and item-level changes)
final class PayslipComparisonServiceComparisonTests: XCTestCase {

    var sut: PayslipComparisonService!

    override func setUp() {
        super.setUp()
        sut = PayslipComparisonService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Compare Payslips - Net Remittance Tests

    func testComparePayslips_IncreasedNetRemittance_ReturnsPositiveChange() {
        let previous = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 110000, debits: 25000)

        let comparison = sut.comparePayslips(current: current, previous: previous)

        XCTAssertTrue(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 10000)
        XCTAssertEqual(comparison.netRemittancePercentageChange ?? 0, (10000 / 75000) * 100, accuracy: 0.01)
    }

    func testComparePayslips_DecreasedNetRemittance_ReturnsNegativeChange() {
        let previous = createPayslip(month: "January", year: 2025, credits: 110000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 100000, debits: 25000)

        let comparison = sut.comparePayslips(current: current, previous: previous)

        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertTrue(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, -10000)
        XCTAssertEqual(comparison.netRemittancePercentageChange ?? 0, (-10000 / 85000) * 100, accuracy: 0.01)
    }

    func testComparePayslips_SameNetRemittance_ReturnsZeroChange() {
        let previous = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)
        let current = createPayslip(month: "February", year: 2025, credits: 100000, debits: 25000)

        let comparison = sut.comparePayslips(current: current, previous: previous)

        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 0)
        XCTAssertEqual(comparison.netRemittancePercentageChange, 0)
    }

    func testComparePayslips_NoPreviousPayslip_ReturnsZeroChange() {
        let current = createPayslip(month: "January", year: 2025, credits: 100000, debits: 25000)

        let comparison = sut.comparePayslips(current: current, previous: nil)

        XCTAssertFalse(comparison.hasIncreasedNetRemittance)
        XCTAssertFalse(comparison.hasDecreasedNetRemittance)
        XCTAssertEqual(comparison.netRemittanceChange, 0)
        XCTAssertNil(comparison.netRemittancePercentageChange)
        XCTAssertNil(comparison.previousPayslip)
    }

    // MARK: - Compare Item - Earnings Tests

    func testCompareItem_NewEarning_MarksAsNew() {
        let comparison = sut.compareItem(name: "Bonus", current: 5000, previous: nil, isEarning: true)

        XCTAssertTrue(comparison.isNew)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.currentAmount, 5000)
        XCTAssertNil(comparison.previousAmount)
        XCTAssertEqual(comparison.absoluteChange, 5000)
        XCTAssertNil(comparison.percentageChange)
    }

    func testCompareItem_IncreasedEarning_CalculatesPercentage() {
        let comparison = sut.compareItem(name: "Basic Pay", current: 60000, previous: 50000, isEarning: true)

        XCTAssertFalse(comparison.isNew)
        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertFalse(comparison.hasDecreased)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, 10000)
        XCTAssertEqual(comparison.percentageChange ?? 0, 20, accuracy: 0.01)
    }

    func testCompareItem_DecreasedEarning_MarksNeedsAttention() {
        let comparison = sut.compareItem(name: "HRA", current: 25000, previous: 30000, isEarning: true)

        XCTAssertTrue(comparison.hasDecreased)
        XCTAssertTrue(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, -5000)
        XCTAssertEqual(comparison.percentageChange ?? 0, (-5000 / 30000) * 100, accuracy: 0.01)
    }

    func testCompareItem_UnchangedEarning_ReturnsZeroChange() {
        let comparison = sut.compareItem(name: "DA", current: 10000, previous: 10000, isEarning: true)

        XCTAssertTrue(comparison.isUnchanged)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, 0)
        XCTAssertEqual(comparison.percentageChange, 0)
    }

    // MARK: - Compare Item - Deductions Tests

    func testCompareItem_NewDeduction_MarksAsNew() {
        let comparison = sut.compareItem(name: "Professional Tax", current: 2000, previous: nil, isEarning: false)

        XCTAssertTrue(comparison.isNew)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.currentAmount, 2000)
        XCTAssertNil(comparison.previousAmount)
    }

    func testCompareItem_IncreasedDeduction_MarksNeedsAttention() {
        let comparison = sut.compareItem(name: "Income Tax", current: 18000, previous: 15000, isEarning: false)

        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertTrue(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, 3000)
        XCTAssertEqual(comparison.percentageChange ?? 0, 20, accuracy: 0.01)
    }

    func testCompareItem_DecreasedDeduction_DoesNotNeedAttention() {
        let comparison = sut.compareItem(name: "DSOP", current: 7000, previous: 8000, isEarning: false)

        XCTAssertTrue(comparison.hasDecreased)
        XCTAssertFalse(comparison.needsAttention)
        XCTAssertEqual(comparison.absoluteChange, -1000)
    }

    // MARK: - Edge Cases

    func testCompareItem_ZeroToPreviousAmount_HandlesCorrectly() {
        let comparison = sut.compareItem(name: "Allowance", current: 5000, previous: 0, isEarning: true)

        XCTAssertFalse(comparison.isNew)
        XCTAssertTrue(comparison.hasIncreased)
        XCTAssertEqual(comparison.absoluteChange, 5000)
        XCTAssertNil(comparison.percentageChange)
    }

    func testComparePayslips_WithEarningsAndDeductions_ComparesAllItems() {
        let previousEarnings = ["Basic": 50000.0, "HRA": 30000.0]
        let previousDeductions = ["Tax": 15000.0, "DSOP": 8000.0]
        let previous = createPayslip(
            month: "January",
            year: 2025,
            earnings: previousEarnings,
            deductions: previousDeductions
        )

        let currentEarnings = ["Basic": 55000.0, "HRA": 30000.0, "Bonus": 10000.0]
        let currentDeductions = ["Tax": 16000.0, "DSOP": 8000.0]
        let current = createPayslip(
            month: "February",
            year: 2025,
            earnings: currentEarnings,
            deductions: currentDeductions
        )

        let comparison = sut.comparePayslips(current: current, previous: previous)

        XCTAssertEqual(comparison.earningsChanges.count, 3)
        XCTAssertEqual(comparison.deductionsChanges.count, 2)
        XCTAssertTrue(comparison.earningsChanges["Basic"]?.hasIncreased ?? false)
        XCTAssertEqual(comparison.earningsChanges["Basic"]?.absoluteChange, 5000)
        XCTAssertTrue(comparison.earningsChanges["Bonus"]?.isNew ?? false)
        XCTAssertTrue(comparison.earningsChanges["HRA"]?.isUnchanged ?? false)
        XCTAssertTrue(comparison.deductionsChanges["Tax"]?.hasIncreased ?? false)
        XCTAssertTrue(comparison.deductionsChanges["Tax"]?.needsAttention ?? false)
        XCTAssertTrue(comparison.deductionsChanges["DSOP"]?.isUnchanged ?? false)
    }

    // MARK: - Helpers

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

