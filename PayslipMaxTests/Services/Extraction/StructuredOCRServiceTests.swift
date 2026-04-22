import XCTest
import CoreGraphics
@testable import PayslipMax

final class StructuredOCRServiceTests: XCTestCase {

    // MARK: - OCRTextBlock Model Tests

    func test_ocrTextBlock_centerX_calculatedCorrectly() {
        let block = OCRTextBlock(
            text: "TEST",
            boundingBox: CGRect(x: 0.2, y: 0.5, width: 0.3, height: 0.1),
            confidence: 0.9
        )

        XCTAssertEqual(block.centerX, 0.35, accuracy: 0.001)
    }

    func test_ocrTextBlock_centerY_calculatedCorrectly() {
        let block = OCRTextBlock(
            text: "TEST",
            boundingBox: CGRect(x: 0.2, y: 0.5, width: 0.3, height: 0.1),
            confidence: 0.9
        )

        XCTAssertEqual(block.centerY, 0.55, accuracy: 0.001)
    }

    func test_ocrTextBlock_equality() {
        let block1 = OCRTextBlock(
            text: "BPAY",
            boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.03),
            confidence: 0.95
        )
        let block2 = OCRTextBlock(
            text: "BPAY",
            boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.03),
            confidence: 0.95
        )

        XCTAssertEqual(block1, block2)
    }

    // MARK: - StructuredOCRResult Tests

    func test_structuredOCRResult_averageConfidence_withBlocks() {
        let blocks = [
            OCRTextBlock(text: "A", boundingBox: .zero, confidence: 0.8),
            OCRTextBlock(text: "B", boundingBox: .zero, confidence: 1.0),
        ]
        let result = StructuredOCRResult(blocks: blocks)

        XCTAssertEqual(result.averageConfidence, 0.9, accuracy: 0.001)
    }

    func test_structuredOCRResult_averageConfidence_empty() {
        let result = StructuredOCRResult(blocks: [])

        XCTAssertEqual(result.averageConfidence, 0)
    }

    func test_structuredOCRResult_hasMinimumContent_withEnoughBlocks() {
        let blocks = [
            OCRTextBlock(text: "A", boundingBox: .zero, confidence: 0.9),
            OCRTextBlock(text: "B", boundingBox: .zero, confidence: 0.9),
            OCRTextBlock(text: "C", boundingBox: .zero, confidence: 0.9),
        ]
        let result = StructuredOCRResult(blocks: blocks)

        XCTAssertTrue(result.hasMinimumContent)
    }

    func test_structuredOCRResult_hasMinimumContent_tooFewBlocks() {
        let blocks = [
            OCRTextBlock(text: "A", boundingBox: .zero, confidence: 0.9),
            OCRTextBlock(text: "B", boundingBox: .zero, confidence: 0.9),
        ]
        let result = StructuredOCRResult(blocks: blocks)

        XCTAssertFalse(result.hasMinimumContent)
    }

    // MARK: - Mock Service Behavior Tests

    func test_mockService_returnsConfiguredResult() async {
        let mock = MockStructuredOCRService()
        let blocks = [
            OCRTextBlock(text: "BPAY", boundingBox: .zero, confidence: 0.95),
        ]
        mock.stubbedResult = StructuredOCRResult(blocks: blocks)

        let result = await mock.recognizeText(from: Data())

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.blocks.count, 1)
        XCTAssertEqual(result?.blocks.first?.text, "BPAY")
        XCTAssertEqual(mock.recognizeCallCount, 1)
    }

    func test_mockService_returnsNilWhenNotConfigured() async {
        let mock = MockStructuredOCRService()

        let result = await mock.recognizeText(from: Data())

        XCTAssertNil(result)
    }
}
