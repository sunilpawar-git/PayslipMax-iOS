import XCTest
@testable import PayslipMax

/// Tests for JCOORTextSectionSplitter -- splits PDFKit-extracted flat text from
/// JCO/OR payslips into credit (left) and debit (right) sections.
final class JCOORTextSectionSplitterTests: XCTestCase {

    private var sut: JCOORTextSectionSplitter!

    override func setUp() {
        super.setUp()
        sut = JCOORTextSectionSplitter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Section Detection

    func test_isJCOORLayout_trueWhenAccountsAtAGlance() {
        let text = """
        Some header text
        ACCOUNTS AT A GLANCE
        BPAY 37000 DSOP 2220
        """
        XCTAssertTrue(sut.isJCOORLayout(text))
    }

    func test_isJCOORLayout_trueWithHindiMarker() {
        let text = """
        एक नज़र में खाते
        BPAY 37000
        """
        XCTAssertTrue(sut.isJCOORLayout(text))
    }

    func test_isJCOORLayout_trueWithTotalCreditsAndDebits() {
        let text = """
        TOTAL CREDITS 86953
        TOTAL DEBITS 86953
        AMOUNT CREDITED TO BANK 58252
        """
        XCTAssertTrue(sut.isJCOORLayout(text))
    }

    func test_isJCOORLayout_falseForOfficerPayslip() {
        let text = """
        PCDA(O) ALLAHABAD
        Gross Pay 275015
        Total Deductions 102029
        """
        XCTAssertFalse(sut.isJCOORLayout(text))
    }

    // MARK: - Section Splitting

    func test_split_extractsCreditSection() {
        let text = makeSampleJCOORText()
        let result = sut.split(text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.creditText.contains("BPAY"))
        XCTAssertTrue(result!.creditText.contains("37000"))
    }

    func test_split_extractsDebitSection() {
        let text = makeSampleJCOORText()
        let result = sut.split(text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.debitText.contains("DSOP"))
        XCTAssertTrue(result!.debitText.contains("2220"))
    }

    func test_split_extractsSummary() {
        let text = makeSampleJCOORText()
        let result = sut.split(text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.summaryText.contains("86953"))
    }

    func test_split_returnsNilForNonJCOOR() {
        let text = "PCDA(O) ALLAHABAD\nGross Pay 275015\n"
        let result = sut.split(text)
        XCTAssertNil(result, "Should return nil for non-JCO/OR text")
    }

    // MARK: - Anchor Extraction Integration

    func test_splitSummary_worksWithAnchorExtractor() {
        let text = makeSampleJCOORText()
        guard let result = sut.split(text) else {
            XCTFail("Split should succeed for JCO/OR text")
            return
        }

        let extractor = PayslipAnchorExtractor()
        let anchors = extractor.extractAnchors(
            from: result.summaryText,
            usePreferredTopSection: false
        )
        XCTAssertNotNil(anchors, "Anchor extractor should parse summary section")
        XCTAssertEqual(anchors?.grossPay, 86953)
    }

    // MARK: - Edge Cases

    func test_split_toleratesOCRNoise() {
        let text = """
        ACCOUNTS AT A GLANCE
        जमा Credits नामे Debits
        बैंड वेतन BPAY 37 000 DSOP DSOP 22 20
        TOTAL CREDITS 86953
        TOTAL DEBITS 86953
        AMOUNT CREDITED TO BANK 58252
        """
        let result = sut.split(text)
        XCTAssertNotNil(result, "Should tolerate OCR noise in JCO/OR text")
    }

    func test_split_multiLinePaycodes_preserved() {
        let text = """
        ACCOUNTS AT A GLANCE
        Credits Debits
        BPAY 37000 DSOP 2220
        DA 24200 AGIF 7500
        MSP 5200 PLI 800
        TOTAL CREDITS 66400
        TOTAL DEBITS 10520
        AMOUNT CREDITED TO BANK 55880
        """
        guard let result = sut.split(text) else {
            XCTFail("Split should succeed")
            return
        }
        XCTAssertTrue(result.creditText.contains("DA"))
        XCTAssertTrue(result.debitText.contains("AGIF"))
    }

    // MARK: - Helpers

    private func makeSampleJCOORText() -> String {
        """
        PAY ACCOUNT OFFICE (OTHER RANKS)
        ACCOUNTS AT A GLANCE
        जमा Credits नामे Debits
        बैंड वेतन BPAY 37000 DSOP सब्सक्र DSOP 2220
        महँगाई भत्ता DA 24200 AGIF 7500
        MSP 5200 PLI 800
        TPAL 4500 ITAX 3000
        TOTAL CREDITS 86953
        TOTAL DEBITS 86953
        AMOUNT CREDITED TO BANK 58252
        """
    }
}
