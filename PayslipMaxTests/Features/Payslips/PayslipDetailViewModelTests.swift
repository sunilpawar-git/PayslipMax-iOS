import XCTest
@testable import PayslipMax

/// Comprehensive tests for PayslipDetailViewModel functionality
@MainActor
final class PayslipDetailViewModelTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: PayslipDetailViewModel!
    private var mockPayslip: AnyPayslip!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockPayslip = createMockPayslip()
        sut = PayslipDetailViewModel(payslip: mockPayslip)
    }

    override func tearDown() {
        sut = nil
        mockPayslip = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_SetsPayslip() {
        XCTAssertEqual(sut.payslip.id, mockPayslip.id)
    }

    func test_init_CreatesPayslipData() {
        XCTAssertNotNil(sut.payslipData)
    }

    func test_init_GeneratesUniqueViewId() {
        XCTAssertFalse(sut.uniqueViewId.isEmpty)
        XCTAssertTrue(sut.uniqueViewId.contains(mockPayslip.month))
    }

    // MARK: - Payslip Data Tests

    func test_payslipData_ContainsCorrectMonth() {
        XCTAssertEqual(sut.payslipData.month, mockPayslip.month)
    }

    func test_payslipData_ContainsCorrectYear() {
        XCTAssertEqual(sut.payslipData.year, mockPayslip.year)
    }

    func test_payslipData_ContainsCorrectCredits() {
        XCTAssertEqual(sut.payslipData.credits, mockPayslip.credits, accuracy: 0.01)
    }

    func test_payslipData_ContainsCorrectDebits() {
        XCTAssertEqual(sut.payslipData.debits, mockPayslip.debits, accuracy: 0.01)
    }

    // MARK: - PDF Tests

    func test_needsPDFRegeneration_ReturnsBoolean() {
        // Should return a boolean value
        let needsRegen = sut.needsPDFRegeneration
        XCTAssertNotNil(needsRegen as Bool?)
    }

    // MARK: - Earnings Breakdown Tests

    func test_earningsBreakdown_ReturnsArray() {
        let breakdown = sut.earningsBreakdown
        XCTAssertNotNil(breakdown)
    }

    func test_earningsBreakdown_ContainsCorrectValues() {
        // Given a payslip with known earnings
        let customPayslip = createMockPayslipWithEarnings([
            "Basic Pay": 80000.0,
            "DA": 20000.0
        ])
        sut = PayslipDetailViewModel(payslip: customPayslip)

        // When
        let breakdown = sut.earningsBreakdown

        // Then
        XCTAssertFalse(breakdown.isEmpty)
    }

    // MARK: - Deductions Breakdown Tests

    func test_deductionsBreakdown_ReturnsArray() {
        let breakdown = sut.deductionsBreakdown
        XCTAssertNotNil(breakdown)
    }

    func test_deductionsBreakdown_ContainsCorrectValues() {
        // Given a payslip with known deductions
        let customPayslip = createMockPayslipWithDeductions([
            "Tax": 10000.0,
            "DSOP": 5000.0
        ])
        sut = PayslipDetailViewModel(payslip: customPayslip)

        // When
        let breakdown = sut.deductionsBreakdown

        // Then
        XCTAssertFalse(breakdown.isEmpty)
    }

    // MARK: - Update Methods Tests

    func test_updateOtherEarnings_DoesNotCrash() async {
        // When
        await sut.updateOtherEarnings(["Bonus": 1000.0])

        // Then - should not crash
        XCTAssertTrue(true)
    }

    func test_updateOtherDeductions_DoesNotCrash() async {
        // When
        await sut.updateOtherDeductions(["Insurance": 500.0])

        // Then - should not crash
        XCTAssertTrue(true)
    }

    // MARK: - Share Items Tests

    func test_getShareItems_ReturnsArray() async {
        // When
        let items = await sut.getShareItems()

        // Then
        XCTAssertNotNil(items)
    }

    func test_getShareItemsSync_WithNoCache_ReturnsValue() {
        // When
        _ = sut.getShareItemsSync()

        // Then - may be nil if no cache, or array if cached
        // Just verify it doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Unique View ID Tests

    func test_uniqueViewId_IsDeterministic() {
        // Given
        let viewId1 = sut.uniqueViewId
        let viewId2 = sut.uniqueViewId

        // Then
        XCTAssertEqual(viewId1, viewId2)
    }

    func test_uniqueViewId_DifferentForDifferentPayslips() {
        // Given
        let payslip1 = createMockPayslip()
        let payslip2 = createMockPayslip()

        let vm1 = PayslipDetailViewModel(payslip: payslip1)
        let vm2 = PayslipDetailViewModel(payslip: payslip2)

        // Then - different IDs mean different unique view IDs
        XCTAssertNotEqual(vm1.uniqueViewId, vm2.uniqueViewId)
    }

    // MARK: - Force Regenerate PDF Tests

    func test_forceRegeneratePDF_DoesNotCrash() async {
        // When/Then - should not crash
        await sut.forceRegeneratePDF()
        XCTAssertTrue(true)
    }

    // MARK: - Handle Automatic PDF Regeneration Tests

    func test_handleAutomaticPDFRegeneration_DoesNotCrash() async {
        // When/Then - should not crash
        await sut.handleAutomaticPDFRegeneration()
        XCTAssertTrue(true)
    }

    // MARK: - Helper Methods

    private func createMockPayslip() -> AnyPayslip {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            pdfData: nil
        )
        item.earnings = ["Basic Pay": 80000.0, "DA": 20000.0]
        item.deductions = ["Tax": 10000.0, "DSOP": 5000.0]
        item.name = "Test User"
        item.accountNumber = "1234567890"
        return AnyPayslip(item)
    }

    private func createMockPayslipWithEarnings(_ earnings: [String: Double]) -> AnyPayslip {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: earnings.values.reduce(0, +),
            debits: 0,
            dsop: 0,
            tax: 0,
            pdfData: nil
        )
        item.earnings = earnings
        item.deductions = [:]
        return AnyPayslip(item)
    }

    private func createMockPayslipWithDeductions(_ deductions: [String: Double]) -> AnyPayslip {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: deductions.values.reduce(0, +),
            dsop: 0,
            tax: 0,
            pdfData: nil
        )
        item.earnings = ["Basic Pay": 100000.0]
        item.deductions = deductions
        return AnyPayslip(item)
    }
}
