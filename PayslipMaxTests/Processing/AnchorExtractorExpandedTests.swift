import XCTest
@testable import PayslipMax

/// Tests for expanded anchor patterns covering bilingual payslips,
/// 2025-format PCDA(O) layouts, and additional JCO/OR label variants.
final class AnchorExtractorExpandedTests: XCTestCase {

    private var sut: PayslipAnchorExtractor!

    override func setUp() {
        super.setUp()
        sut = PayslipAnchorExtractor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 2025 PCDA(O) Bilingual Format

    func test_bilingualGrossPay_extractsFromGrossPayLabel() {
        let text = """
        kuula Aaya
        Gross Pay
        275015 kuula kTaOtI
        Total Deductions
        102029
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors, "Should extract anchors from 2025 bilingual format")
        XCTAssertEqual(anchors?.grossPay, 275015)
    }

    func test_bilingualTotalDeductions_extractsFromTotalDeductionsLabel() {
        let text = """
        Gross Pay
        275015 kuula kTaOtI
        Total Deductions
        102029
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.totalDeductions, 102029)
    }

    func test_bilingualNetRemittance_extractsWithRsPrefix() {
        let text = """
        Gross Pay 275015
        Total Deductions 102029
        Net Remittance : Rs.1,72,986
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance, 172986)
    }

    // MARK: - 2023 PCDA(O) Format

    func test_totalCredit_singularForm_extracts() {
        let text = """
        Total Credit 220810 Total Debit 220810
        REMITTANCE 123052
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors, "Should extract from Total Credit / Total Debit format")
        XCTAssertEqual(anchors?.grossPay, 220810)
    }

    func test_remittanceLabel_extractsAsNet() {
        let text = """
        Total Credit 220810
        Total Debit 97758
        REMITTANCE 123052
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance, 123052)
    }

    // MARK: - JCO/OR Additional Hindi Patterns

    func test_hindiGrossPay_kuulJama() {
        let text = """
        कुल जमा 86953
        कुल नामे 28701
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors, "Should extract anchors from Hindi labels")
        XCTAssertEqual(anchors?.grossPay, 86953)
    }

    func test_hindiTotalDebits_kuulName() {
        let text = """
        कुल जमा 86953
        कुल नामे 28701
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.totalDeductions, 28701)
    }

    func test_bankCreditWithLineBreak_extracts() {
        let text = """
        TOTAL CREDITS 86953
        TOTAL DEBITS 28701
        AMOUNT CREDITED TO
        BANK 58252
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance, 58252)
    }

    // MARK: - Page Boundary Detection

    func test_pageBoundary_2025Format_stopsAtPage2() {
        let text = """
        Gross Pay 275015
        Total Deductions 102029
        Net Remittance : Rs.172986
        Page 1 of 7
        Page 2 of 7
        DETAILS OF DO2s
        Some other data 999999
        """
        let firstPage = sut.extractFirstPageText(from: text)
        XCTAssertFalse(firstPage.contains("999999"))
    }

    // MARK: - Edge Cases

    func test_commaSeparatedAmount_parses() {
        let text = """
        Total Credits 1,02,029
        Total Debits 45,678
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors, "Should parse comma-separated amounts")
        XCTAssertEqual(anchors?.grossPay, 102029)
    }

    func test_spaceSeparatedOCRAmount_parses() {
        let text = """
        TOTAL CREDITS 8 6 9 5 3
        TOTAL DEBITS 2 8 7 0 1
        """
        let anchors = sut.extractAnchors(from: text, usePreferredTopSection: false)

        XCTAssertNotNil(anchors, "Should parse OCR space-separated digits")
        XCTAssertEqual(anchors?.grossPay, 86953)
    }
}
