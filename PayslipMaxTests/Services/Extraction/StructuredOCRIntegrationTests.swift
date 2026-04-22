import XCTest
import CoreGraphics
@testable import PayslipMax

/// Integration tests verifying the full pipeline:
/// Mock OCR -> TabularTextAssembler -> PayslipAnchorExtractor -> PayCodeSearchEngine
///
/// These tests simulate a JCO/OR payslip by providing positioned text blocks
/// (as if from Apple Vision OCR) and verify that the regex pipeline correctly
/// extracts credits, debits, and line items from the column-separated text.
final class StructuredOCRIntegrationTests: XCTestCase {

    private var assembler: TabularTextAssembler!
    private var anchorExtractor: PayslipAnchorExtractor!

    override func setUp() {
        super.setUp()
        assembler = TabularTextAssembler()
        anchorExtractor = PayslipAnchorExtractor()
    }

    override func tearDown() {
        assembler = nil
        anchorExtractor = nil
        super.tearDown()
    }

    // MARK: - End-to-End: OCR Blocks -> Anchors
    // Anchors require BOTH columns combined (gross from left, deductions/net from right).
    // Line items use columns separately (left = earnings, right = deductions).

    func test_jcoorBlocks_combinedColumns_anchorExtractsGrossAndNet() {
        let result = assembleJCOORBlocks()
        guard let assembly = result else {
            XCTFail("Assembly should succeed for JCOOR blocks")
            return
        }

        let combinedText = assembly.leftColumn.text + "\n" + assembly.rightColumn.text
        let anchors = anchorExtractor.extractAnchors(from: combinedText)

        XCTAssertNotNil(anchors, "Should extract anchors from combined columns")
        if let anchors = anchors {
            XCTAssertEqual(anchors.grossPay, 86953, accuracy: 1)
            XCTAssertEqual(anchors.netRemittance, 58252, accuracy: 1)
        }
    }

    func test_jcoorBlocks_leftColumnAlone_containsGrossPayLabel() {
        let result = assembleJCOORBlocks()
        guard let assembly = result else {
            XCTFail("Assembly should succeed for JCOOR blocks")
            return
        }

        XCTAssertTrue(
            assembly.leftColumn.text.contains("TOTAL CREDITS"),
            "Left column should contain TOTAL CREDITS label"
        )
        XCTAssertTrue(
            assembly.leftColumn.text.contains("86953"),
            "Left column should contain gross pay amount"
        )
    }

    // MARK: - Column Isolation Prevents Cross-Contamination

    func test_leftColumn_doesNotContainDeductionAmounts() {
        let result = assembleJCOORBlocks()
        guard let assembly = result else {
            XCTFail("Assembly should succeed")
            return
        }

        let leftText = assembly.leftColumn.text
        XCTAssertFalse(leftText.contains("2220"), "DSOP amount should not be in left column")
        XCTAssertFalse(leftText.contains("7500"), "AGIF amount should not be in left column")
    }

    func test_rightColumn_doesNotContainEarningsAmounts() {
        let result = assembleJCOORBlocks()
        guard let assembly = result else {
            XCTFail("Assembly should succeed")
            return
        }

        let rightText = assembly.rightColumn.text
        XCTAssertFalse(rightText.contains("37000"), "BPAY amount should not be in right column")
        XCTAssertFalse(rightText.contains("24200"), "DA amount should not be in right column")
    }

    // MARK: - Assembly + Regex Confidence

    func test_assembledText_regexFindsKeyComponents() {
        let result = assembleJCOORBlocks()
        guard let assembly = result else {
            XCTFail("Assembly should succeed")
            return
        }

        let leftText = assembly.leftColumn.text.uppercased()
        let rightText = assembly.rightColumn.text.uppercased()

        XCTAssertTrue(leftText.contains("BAND PAY") || leftText.contains("BPAY"))
        XCTAssertTrue(leftText.contains("DA"))
        XCTAssertTrue(leftText.contains("MS PAY") || leftText.contains("MSP"))
        XCTAssertTrue(rightText.contains("DSOP") || rightText.contains("AFPP"))
        XCTAssertTrue(rightText.contains("AGIF"))
    }

    // MARK: - Mock OCR Service Integration

    func test_mockOCR_throughAssembler_producesValidResult() async {
        let mockOCR = MockStructuredOCRService()
        mockOCR.stubbedResult = StructuredOCRResult(blocks: makeJCOORBlocks())

        let ocrResult = await mockOCR.recognizeText(from: Data())
        guard let ocrResult = ocrResult else {
            XCTFail("Mock OCR should return result")
            return
        }

        let assembly = assembler.assemble(from: ocrResult)

        XCTAssertNotNil(assembly)
        XCTAssertTrue(assembly!.isTabularLayoutDetected)
        XCTAssertEqual(mockOCR.recognizeCallCount, 1)
    }

    // MARK: - Edge Cases

    func test_sparseBlocks_stillAssembles() {
        let blocks = [
            makeBlock("TOTAL CREDITS", x: 0.05, y: 0.60, w: 0.20, h: 0.02),
            makeBlock("86953", x: 0.28, y: 0.60, w: 0.10, h: 0.02),
            makeBlock("TOTAL DEBITS", x: 0.55, y: 0.60, w: 0.18, h: 0.02),
            makeBlock("86953", x: 0.80, y: 0.60, w: 0.10, h: 0.02),
        ]
        let ocrResult = StructuredOCRResult(blocks: blocks)
        let result = assembler.assemble(from: ocrResult)

        XCTAssertNotNil(result)
    }

    // MARK: - Helpers

    private func assembleJCOORBlocks() -> TabularAssemblyResult? {
        let blocks = makeJCOORBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)
        return assembler.assemble(from: ocrResult)
    }

    private func makeJCOORBlocks() -> [OCRTextBlock] {
        [
            makeBlock("BAND PAY", x: 0.05, y: 0.82, w: 0.18, h: 0.02),
            makeBlock("37000", x: 0.28, y: 0.82, w: 0.10, h: 0.02),
            makeBlock("AFPP FUND SUBSCRIPTION", x: 0.52, y: 0.82, w: 0.25, h: 0.02),
            makeBlock("2220", x: 0.80, y: 0.82, w: 0.08, h: 0.02),
            makeBlock("DA", x: 0.05, y: 0.78, w: 0.08, h: 0.02),
            makeBlock("24200", x: 0.28, y: 0.78, w: 0.10, h: 0.02),
            makeBlock("AGIF", x: 0.52, y: 0.78, w: 0.10, h: 0.02),
            makeBlock("7500", x: 0.80, y: 0.78, w: 0.08, h: 0.02),
            makeBlock("MS PAY", x: 0.05, y: 0.74, w: 0.10, h: 0.02),
            makeBlock("5200", x: 0.28, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("PLI", x: 0.52, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("3396", x: 0.80, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("TOTAL CREDITS", x: 0.05, y: 0.60, w: 0.20, h: 0.02),
            makeBlock("86953", x: 0.28, y: 0.60, w: 0.10, h: 0.02),
            makeBlock("TOTAL DEBITS", x: 0.52, y: 0.60, w: 0.18, h: 0.02),
            makeBlock("86953", x: 0.80, y: 0.60, w: 0.10, h: 0.02),
            makeBlock("AMOUNT CREDITED TO BANK", x: 0.52, y: 0.56, w: 0.25, h: 0.02),
            makeBlock("58252", x: 0.80, y: 0.56, w: 0.10, h: 0.02),
        ]
    }

    private func makeBlock(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat
    ) -> OCRTextBlock {
        OCRTextBlock(
            text: text,
            boundingBox: CGRect(x: x, y: y, width: w, height: h),
            confidence: 0.95
        )
    }
}
