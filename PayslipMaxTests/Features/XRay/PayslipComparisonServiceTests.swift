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

    func testFindPreviousPayslip_WithLowercaseMonth_ReturnsPrevious() {
        // Given
        let january = createPayslip(month: "january", year: 2025)
        let february = createPayslip(month: "february", year: 2025)
        let allPayslips = [january, february]

        // When
        let previous = sut.findPreviousPayslip(for: february, in: allPayslips)

        // Then
        XCTAssertNotNil(previous)
        XCTAssertEqual(previous?.month.lowercased(), "january")
    }

    func testFindPreviousPayslip_WithAbbreviatedMonth_ReturnsPrevious() {
        // Given
        let january = createPayslip(month: "Jan", year: 2025)
        let february = createPayslip(month: "Feb", year: 2025)
        let allPayslips = [february, january]

        // When
        let previous = sut.findPreviousPayslip(for: february, in: allPayslips)

        // Then
        XCTAssertNotNil(previous)
        XCTAssertEqual(previous?.month, "Jan")
    }

    func testFindPreviousPayslip_WithInvalidMonth_SortsAsEarliest() {
        let invalidTimestamp = createDate(month: 1, day: 1, year: 2025)
        let januaryTimestamp = createDate(month: 1, day: 2, year: 2025)
        let invalid = createPayslip(month: "Foo", year: 2025, timestamp: invalidTimestamp)
        let january = createPayslip(month: "January", year: 2025, timestamp: januaryTimestamp)
        let allPayslips = [invalid, january]

        let previous = sut.findPreviousPayslip(for: january, in: allPayslips)

        XCTAssertEqual(previous?.month, "Foo")
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

    func testFindPreviousPayslip_FebruaryMarchApril_AllAfterFirstHavePrevious() {
        // Given (unordered list)
        let february = createPayslip(month: "February", year: 2025, credits: 100000, debits: 25000)
        let march = createPayslip(month: "March", year: 2025, credits: 110000, debits: 25000)
        let april = createPayslip(month: "April", year: 2025, credits: 105000, debits: 26000)
        let allPayslips = [april, february, march]

        // When
        let previousForMarch = sut.findPreviousPayslip(for: march, in: allPayslips)
        let previousForApril = sut.findPreviousPayslip(for: april, in: allPayslips)

        // Then
        XCTAssertEqual(previousForMarch?.month, "February")
        XCTAssertEqual(previousForApril?.month, "March")

        let marchComparison = sut.comparePayslips(current: march, previous: previousForMarch)
        let aprilComparison = sut.comparePayslips(current: april, previous: previousForApril)

        XCTAssertTrue(marchComparison.hasIncreasedNetRemittance)
        XCTAssertTrue(aprilComparison.hasDecreasedNetRemittance)
    }

    // MARK: - Helper Methods

    private func createPayslip(
        month: String,
        year: Int,
        credits: Double = 100000,
        debits: Double = 25000,
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:],
        timestamp: Date = Date()
    ) -> any PayslipProtocol {
        MockPayslip(
            id: UUID(),
            timestamp: timestamp,
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

    private func createDate(month: Int, day: Int, year: Int) -> Date {
        let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(abbreviation: "UTC"), year: year, month: month, day: day)
        return components.date ?? Date()
    }
}
