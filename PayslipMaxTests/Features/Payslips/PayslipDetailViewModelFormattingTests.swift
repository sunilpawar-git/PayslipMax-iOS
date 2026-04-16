import XCTest
@testable import PayslipMax

/// Integration tests covering the formatting, sharing, and breakdown-extraction
/// contracts that will be extracted from PayslipDetailViewModel into dedicated
/// extension files.  These tests act as a refactoring safety net — they must
/// remain GREEN before and after the extraction.
@MainActor
final class PayslipDetailViewModelFormattingTests: XCTestCase {

    // MARK: - Properties

    private var sut: PayslipDetailViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = PayslipDetailViewModel(payslip: Self.makePayslip())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - formatCurrency Tests

    func test_formatCurrency_withPositiveValue_returnsNonEmptyString() {
        let result = sut.formatCurrency(80_000.0)
        XCTAssertFalse(result.isEmpty, "Expected a non-empty currency string for a positive value")
    }

    func test_formatCurrency_withZero_returnsNonEmptyString() {
        let result = sut.formatCurrency(0.0)
        XCTAssertFalse(result.isEmpty, "Expected a non-empty currency string for zero")
    }

    func test_formatCurrency_withNil_returnsNonEmptyString() {
        let result = sut.formatCurrency(nil)
        XCTAssertFalse(result.isEmpty, "Expected a fallback string when value is nil")
    }

    // MARK: - formatYear Tests

    func test_formatYear_withValidYear_returnsNonEmptyString() {
        let result = sut.formatYear(2025)
        XCTAssertFalse(result.isEmpty, "Expected a non-empty string for a valid year")
    }

    func test_formatYear_returnValueContainsYear() {
        let result = sut.formatYear(2025)
        XCTAssertTrue(result.contains("2025"), "Expected the formatted year to contain '2025', got: \(result)")
    }

    // MARK: - getShareText Tests

    func test_getShareText_returnsNonEmptyString() {
        let text = sut.getShareText()
        XCTAssertFalse(text.isEmpty, "Expected share text to be non-empty")
    }

    // MARK: - earningsBreakdown Tests

    func test_earningsBreakdown_withKnownEarnings_returnsNonEmptyBreakdown() {
        let payslip = Self.makePayslip(earnings: ["Basic Pay": 80_000.0, "DA": 20_000.0])
        sut = PayslipDetailViewModel(payslip: payslip)

        let breakdown = sut.earningsBreakdown
        XCTAssertFalse(breakdown.isEmpty, "Expected at least one earnings breakdown item")
    }

    func test_earningsBreakdown_returnsArray() {
        XCTAssertNotNil(sut.earningsBreakdown)
    }

    // MARK: - deductionsBreakdown Tests

    func test_deductionsBreakdown_withKnownDeductions_returnsNonEmptyBreakdown() {
        let payslip = Self.makePayslip(deductions: ["Income Tax": 10_000.0, "DSOP": 5_000.0])
        sut = PayslipDetailViewModel(payslip: payslip)

        let breakdown = sut.deductionsBreakdown
        XCTAssertFalse(breakdown.isEmpty, "Expected at least one deductions breakdown item")
    }

    func test_deductionsBreakdown_returnsArray() {
        XCTAssertNotNil(sut.deductionsBreakdown)
    }

    // MARK: - extractBreakdownFromPayslip Tests

    func test_extractBreakdownFromPayslip_withOnlyStandardFields_returnsEmpty() {
        let input: [String: Double] = [
            "Basic Pay": 80_000.0,
            "Dearness Allowance": 20_000.0,
            "Military Service Pay": 5_000.0,
            "Other Earnings": 1_000.0,
            "DSOP": 5_000.0,
            "AGIF": 500.0,
            "Income Tax": 10_000.0,
            "Other Deductions": 2_000.0
        ]
        let result = sut.extractBreakdownFromPayslip(input)
        XCTAssertTrue(result.isEmpty, "Standard fields should be excluded from the breakdown")
    }

    func test_extractBreakdownFromPayslip_withMixedFields_returnsOnlyNonStandard() {
        let input: [String: Double] = [
            "Basic Pay": 80_000.0,
            "Bonus": 15_000.0,
            "Special Allowance": 5_000.0
        ]
        let result = sut.extractBreakdownFromPayslip(input)
        XCTAssertEqual(result.count, 2, "Only non-standard fields should be returned")
        XCTAssertNil(result["Basic Pay"], "Standard field 'Basic Pay' must not appear in breakdown")
        XCTAssertEqual(result["Bonus"] ?? -1, 15_000.0, accuracy: 0.01)
        XCTAssertEqual(result["Special Allowance"] ?? -1, 5_000.0, accuracy: 0.01)
    }

    func test_extractBreakdownFromPayslip_withEmptyInput_returnsEmpty() {
        let result = sut.extractBreakdownFromPayslip([:])
        XCTAssertTrue(result.isEmpty, "Empty input should produce empty breakdown")
    }

    func test_extractBreakdownFromPayslip_withAllNonStandardFields_returnsAll() {
        let input: [String: Double] = ["Bonus": 5_000.0, "Overtime": 3_000.0]
        let result = sut.extractBreakdownFromPayslip(input)
        XCTAssertEqual(result.count, 2, "All non-standard fields must be returned")
    }

    // MARK: - getShareItems Tests

    func test_getShareItems_returnsNonEmptyArray() async {
        let items = await sut.getShareItems()
        XCTAssertFalse(items.isEmpty, "Expected at least one share item")
    }

    func test_getShareItemsSync_afterAsyncCall_returnsValue() async {
        _ = await sut.getShareItems()
        let syncItems = sut.getShareItemsSync()
        XCTAssertNotNil(syncItems, "Expected cached share items after async call")
    }

    // MARK: - Helpers

    private static func makePayslip(
        earnings: [String: Double] = ["Basic Pay": 80_000.0],
        deductions: [String: Double] = ["Income Tax": 10_000.0]
    ) -> AnyPayslip {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2025,
            credits: earnings.values.reduce(0, +),
            debits: deductions.values.reduce(0, +),
            dsop: 5_000.0,
            tax: 10_000.0,
            pdfData: nil
        )
        item.earnings = earnings
        item.deductions = deductions
        item.name = "Test Soldier"
        item.accountNumber = "0000000000"
        return AnyPayslip(item)
    }
}
