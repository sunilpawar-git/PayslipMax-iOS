import XCTest
@testable import PayslipMax

/// Tests for JCOORFormatDetector to verify correct identification of JCO/OR format payslips
final class JCOORFormatDetectorTests: XCTestCase {

    private var sut: JCOORFormatDetector!

    override func setUp() {
        super.setUp()
        sut = JCOORFormatDetector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - JCO/OR Format Detection Tests

    func testIsJCOORFormat_withTwoMarkers_returnsTrue() async {
        // Given: Text containing exactly 2 JCO/OR markers
        let text = """
        STATEMENT OF ACCOUNT FOR MONTH ENDING 31 DEC 2024
        PAO: PCDA PUNE
        Name: Hawaldar Kumar
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertTrue(result, "Should detect JCO/OR format with 2 markers")
    }

    func testIsJCOORFormat_withMultipleMarkers_returnsTrue() async {
        // Given: Text containing multiple JCO/OR markers
        let text = """
        STATEMENT OF ACCOUNT FOR MONTH ENDING 31 DEC 2024
        PAO: PCDA PUNE
        SUS NO: 12345
        TASK: 678
        AMOUNT CREDITED TO BANK: 45000
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertTrue(result, "Should detect JCO/OR format with multiple markers")
    }

    func testIsJCOORFormat_withHindiMarkers_returnsTrue() async {
        // Given: Text containing Hindi markers
        let text = """
        वेतन विवरण
        दिसम्बर 2024
        बैंक में जमा राशि: 45000
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertTrue(result, "Should detect JCO/OR format with Hindi markers")
    }

    func testIsJCOORFormat_withMixedCaseMarkers_returnsTrue() async {
        // Given: Text with mixed case markers
        let text = """
        statement of account for month ending 31 dec 2024
        pao: pcda pune
        sus no: 12345
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertTrue(result, "Should be case-insensitive")
    }

    // MARK: - Officer Format Detection Tests

    func testIsJCOORFormat_withOfficerPayslip_returnsFalse() async {
        // Given: Text from typical Officer payslip (no JCO/OR markers)
        let text = """
        INDIAN ARMY
        Pay Slip for December 2024
        Captain John Doe
        Basic Pay: 70000
        DA: 35000
        Total: 105000
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertFalse(result, "Should not detect Officer payslip as JCO/OR format")
    }

    func testIsJCOORFormat_withOneMarker_returnsFalse() async {
        // Given: Text with only 1 marker (below threshold of 2)
        let text = """
        Monthly Salary Statement
        PAO: PCDA PUNE
        Name: John Doe
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertFalse(result, "Should require at least 2 markers")
    }

    // MARK: - Edge Cases

    func testIsJCOORFormat_withEmptyText_returnsFalse() async {
        // Given
        let emptyText = ""

        // When
        let result = await sut.isJCOORFormat(text: emptyText)

        // Then
        XCTAssertFalse(result, "Should return false for empty text")
    }

    func testIsJCOORFormat_withWhitespaceOnly_returnsFalse() async {
        // Given
        let whitespaceText = "   \n\t  "

        // When
        let result = await sut.isJCOORFormat(text: whitespaceText)

        // Then
        XCTAssertFalse(result, "Should return false for whitespace-only text")
    }

    func testIsJCOORFormat_withPartialMarkerMatch_returnsFalse() async {
        // Given: Text with partial/incomplete markers
        let text = """
        STATEMENT OF ACCOUNT
        PA: Something
        """

        // When
        let result = await sut.isJCOORFormat(text: text)

        // Then
        XCTAssertFalse(result, "Should not match partial markers")
    }

    func testIsJCOORFormat_performsWellWithLargeText() async {
        // Given: Large text with markers
        let largeText = String(repeating: "Some filler text. ", count: 1000) +
                        "STATEMENT OF ACCOUNT FOR MONTH ENDING 31 DEC 2024\n" +
                        "PAO: PCDA PUNE"

        // When
        let startTime = Date()
        let result = await sut.isJCOORFormat(text: largeText)
        let duration = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(result, "Should detect markers in large text")
        XCTAssertLessThan(duration, 1.0, "Should complete in reasonable time")
    }
}
