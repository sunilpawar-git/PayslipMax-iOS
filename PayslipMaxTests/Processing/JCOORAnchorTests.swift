import XCTest
import PDFKit
@testable import PayslipMax

final class JCOORAnchorTests: XCTestCase {

    func testNetAnchorRecognizesAmountCreditedToBank() {
        let sampleText = """
        TOTAL CREDITS 86593
        TOTAL DEBITS 86953
        Amount credited to bank 58252
        """

        let extractor = PayslipAnchorExtractor()
        let anchors = extractor.extractAnchors(from: sampleText)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance, 58252)
        XCTAssertFalse(anchors?.isNetDerived ?? true)
    }

    func testNetIsDerivedWhenNetAnchorMissing() {
        let sampleText = """
        TOTAL CREDITS 86593
        TOTAL DEBITS 28341
        """

        let extractor = PayslipAnchorExtractor()
        let anchors = extractor.extractAnchors(from: sampleText)

        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.netRemittance ?? 0, 58252, accuracy: 0.1)
        XCTAssertTrue(anchors?.isNetDerived ?? false)
    }

    func testFormatDetectionHonorsUserHint() async {
        let detection = PayslipFormatDetectionService(textExtractionService: StubTextExtractionService())
        detection.updateUserHint(.jcoOr)

        let format = detection.detectFormat(fromText: "random content without defense keywords")
        XCTAssertEqual(format, .defense)
    }
}

private final class StubTextExtractionService: TextExtractionServiceProtocol {
    func extractText(from pdfDocument: PDFDocument) async -> String { "" }
    func extractText(from page: PDFPage) -> String { "" }
    func extractDetailedText(from pdfDocument: PDFDocument) async -> String { "" }
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) { }
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool { false }
}

