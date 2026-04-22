import XCTest
import CoreGraphics
@testable import PayslipMax

final class TabularTextAssemblerTests: XCTestCase {

    private var sut: TabularTextAssembler!

    override func setUp() {
        super.setUp()
        sut = TabularTextAssembler()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Two-Column Detection

    func test_assemble_twoColumnLayout_detectsTabularStructure() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isTabularLayoutDetected)
    }

    func test_assemble_singleColumnLayout_returnsNilOrNonTabular() {
        let blocks = makeSingleColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        if let result = result {
            XCTAssertFalse(result.isTabularLayoutDetected)
        }
    }

    func test_assemble_emptyInput_returnsNil() {
        let ocrResult = StructuredOCRResult(blocks: [])

        let result = sut.assemble(from: ocrResult)

        XCTAssertNil(result)
    }

    // MARK: - Column Classification

    func test_assemble_leftColumnBlocks_appearInLeftColumnText() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.leftColumn.text.contains("BAND PAY"))
        XCTAssertTrue(result!.leftColumn.text.contains("37000"))
    }

    func test_assemble_rightColumnBlocks_appearInRightColumnText() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.rightColumn.text.contains("DSOP"))
        XCTAssertTrue(result!.rightColumn.text.contains("2220"))
    }

    func test_assemble_leftColumnDoesNotContainRightContent() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertFalse(result!.leftColumn.text.contains("DSOP"))
        XCTAssertFalse(result!.leftColumn.text.contains("2220"))
    }

    // MARK: - Full-Width Text

    func test_assemble_fullWidthHeader_appearsInFullWidthText() {
        let blocks = makeBlocksWithFullWidthHeader()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.fullWidthText.contains("ACCOUNTS AT A GLANCE"))
    }

    // MARK: - Column Divider

    func test_assemble_columnDivider_isBetweenColumns() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.columnDivider, 0.3)
        XCTAssertLessThan(result!.columnDivider, 0.7)
    }

    // MARK: - Row Ordering

    func test_assemble_blocksOrderedTopToBottom() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        let leftLines = result!.leftColumn.text.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty }
        XCTAssertGreaterThanOrEqual(leftLines.count, 2)
    }

    // MARK: - Block Count

    func test_assemble_blockCountsReflectInput() {
        let blocks = makeTwoColumnBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.leftColumn.blockCount, 0)
        XCTAssertGreaterThan(result!.rightColumn.blockCount, 0)
    }

    // MARK: - Military Payslip Simulation

    func test_assemble_jcoorPayslipLayout_separatesCreditsAndDebits() {
        let blocks = makeJCOORPayslipBlocks()
        let ocrResult = StructuredOCRResult(blocks: blocks)

        let result = sut.assemble(from: ocrResult)

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isTabularLayoutDetected)

        let left = result!.leftColumn.text.uppercased()
        let right = result!.rightColumn.text.uppercased()

        XCTAssertTrue(left.contains("BAND PAY") || left.contains("BPAY"))
        XCTAssertTrue(left.contains("DA"))
        XCTAssertTrue(right.contains("AGIF") || right.contains("DSOP"))
    }
}

// MARK: - Test Data Factories

extension TabularTextAssemblerTests {

    /// Two clearly separated columns (left: x 0.05–0.35, right: x 0.55–0.85)
    private func makeTwoColumnBlocks() -> [OCRTextBlock] {
        [
            makeBlock("BAND PAY", x: 0.05, y: 0.80, w: 0.20, h: 0.03),
            makeBlock("37000", x: 0.25, y: 0.80, w: 0.10, h: 0.03),
            makeBlock("DA", x: 0.05, y: 0.75, w: 0.10, h: 0.03),
            makeBlock("24200", x: 0.25, y: 0.75, w: 0.10, h: 0.03),
            makeBlock("DSOP", x: 0.55, y: 0.80, w: 0.15, h: 0.03),
            makeBlock("2220", x: 0.75, y: 0.80, w: 0.10, h: 0.03),
            makeBlock("AGIF", x: 0.55, y: 0.75, w: 0.15, h: 0.03),
            makeBlock("7500", x: 0.75, y: 0.75, w: 0.10, h: 0.03),
        ]
    }

    /// Single column of text (all blocks in x 0.1–0.4)
    private func makeSingleColumnBlocks() -> [OCRTextBlock] {
        [
            makeBlock("Basic Pay 136400", x: 0.10, y: 0.80, w: 0.30, h: 0.03),
            makeBlock("DA 63798", x: 0.10, y: 0.75, w: 0.20, h: 0.03),
            makeBlock("MSP 15500", x: 0.10, y: 0.70, w: 0.20, h: 0.03),
        ]
    }

    /// Two columns with a full-width header spanning both
    private func makeBlocksWithFullWidthHeader() -> [OCRTextBlock] {
        var blocks = [makeBlock("ACCOUNTS AT A GLANCE", x: 0.15, y: 0.90, w: 0.70, h: 0.04)]
        blocks.append(contentsOf: makeTwoColumnBlocks())
        return blocks
    }

    /// Simulates a real JCO/OR payslip layout
    private func makeJCOORPayslipBlocks() -> [OCRTextBlock] {
        [
            makeBlock("ACCOUNTS AT A GLANCE", x: 0.15, y: 0.90, w: 0.70, h: 0.03),
            makeBlock("CREDITS", x: 0.10, y: 0.86, w: 0.15, h: 0.02),
            makeBlock("DEBITS", x: 0.55, y: 0.86, w: 0.15, h: 0.02),
            makeBlock("BAND PAY", x: 0.05, y: 0.82, w: 0.18, h: 0.02),
            makeBlock("37000", x: 0.28, y: 0.82, w: 0.10, h: 0.02),
            makeBlock("AFPP FUND SUBSCRIPTION", x: 0.52, y: 0.82, w: 0.25, h: 0.02),
            makeBlock("2220", x: 0.80, y: 0.82, w: 0.08, h: 0.02),
            makeBlock("DA", x: 0.05, y: 0.78, w: 0.08, h: 0.02),
            makeBlock("24200", x: 0.28, y: 0.78, w: 0.10, h: 0.02),
            makeBlock("AGIF", x: 0.52, y: 0.78, w: 0.10, h: 0.02),
            makeBlock("7500", x: 0.80, y: 0.78, w: 0.08, h: 0.02),
            makeBlock("MSP", x: 0.05, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("5200", x: 0.28, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("PLI", x: 0.52, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("3396", x: 0.80, y: 0.74, w: 0.08, h: 0.02),
            makeBlock("TOTAL CREDITS", x: 0.05, y: 0.60, w: 0.20, h: 0.02),
            makeBlock("86953", x: 0.28, y: 0.60, w: 0.10, h: 0.02),
            makeBlock("TOTAL DEBITS", x: 0.52, y: 0.60, w: 0.18, h: 0.02),
            makeBlock("86953", x: 0.80, y: 0.60, w: 0.10, h: 0.02),
        ]
    }

    private func makeBlock(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat,
        confidence: Float = 0.95
    ) -> OCRTextBlock {
        OCRTextBlock(
            text: text,
            boundingBox: CGRect(x: x, y: y, width: w, height: h),
            confidence: confidence
        )
    }
}
