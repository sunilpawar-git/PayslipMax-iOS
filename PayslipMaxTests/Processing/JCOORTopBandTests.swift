import XCTest
@testable import PayslipMax

final class JCOORTopBandTests: XCTestCase {

    func testAnchorsExtractedFromTopBandWithAmountCreditedToBank() {
        let text = """
        Statement of Account For Month Ending: 08/2025
        PAO: 82 SUS NO. : 0415010 TASK: 123
        EMPLOYEE ID. 105965
        TOTAL CREDITS 86953
        TOTAL DEBITS 86953
        AMOUNT CREDITED TO BANK 58252
        ---- NOISE BELOW ----
        ADVANCES
        FUND
        """

        let extractor = PayslipAnchorExtractor()
        let anchors = extractor.extractAnchors(from: text)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.grossPay, 86953)
        XCTAssertEqual(anchors?.totalDeductions, 86953)
        XCTAssertEqual(anchors?.netRemittance, 58252)
        XCTAssertFalse(anchors?.isNetDerived ?? true)
    }

    func testPreferredAnchorTextCropsTopSection() {
        let text = """
        Statement of Account For Month Ending: 08/2025
        TOTAL CREDITS 86953
        TOTAL DEBITS 86953
        AMOUNT CREDITED TO BANK 58252
        ---- lots of lower page content ----
        ADVANCES
        FUND
        """

        let extractor = PayslipAnchorExtractor()
        let cropped = extractor.extractPreferredAnchorText(from: text)

        XCTAssertTrue(cropped.contains("AMOUNT CREDITED TO BANK"))
        XCTAssertFalse(cropped.contains("ADVANCES"))
    }

    func testOfficerAnchorsRemainUnaffected() {
        let text = """
        Gross Pay: 100000
        Total Deductions: 25000
        Net Remittance: 75000
        """

        let extractor = PayslipAnchorExtractor()
        let anchors = extractor.extractAnchors(from: text)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance, 75000)
        XCTAssertFalse(anchors?.isNetDerived ?? true)
    }
}

