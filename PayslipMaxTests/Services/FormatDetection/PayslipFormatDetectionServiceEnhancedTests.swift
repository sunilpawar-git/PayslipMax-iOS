import XCTest
import PDFKit
@testable import PayslipMax

/// Tests for enhanced format detection service
final class PayslipFormatDetectionServiceEnhancedTests: XCTestCase {

    private var sut: PayslipFormatDetectionService!
    private var mockTextExtractor: MockTextExtractionService!
    private var mockJCOORDetector: MockJCOORFormatDetector!

    override func setUp() {
        super.setUp()
        mockTextExtractor = MockTextExtractionService()
        mockJCOORDetector = MockJCOORFormatDetector()
        sut = PayslipFormatDetectionService(
            textExtractionService: mockTextExtractor,
            jcoORDetector: mockJCOORDetector
        )
    }

    override func tearDown() {
        sut = nil
        mockJCOORDetector = nil
        mockTextExtractor = nil
        super.tearDown()
    }

    // MARK: - Enhanced Detection Tests

    func testDetectFormatEnhanced_withJCOORMarkers_returnsJCOOR() async {
        // Given
        let text = """
        STATEMENT OF ACCOUNT FOR MONTH ENDING 31 DEC 2024
        PAO: PCDA PUNE
        """
        mockJCOORDetector.shouldDetectJCOOR = true

        // When
        let result = await sut.detectFormatEnhanced(fromText: text, pdfData: nil)

        // Then
        XCTAssertEqual(result, .jcoOR)
    }

    func testDetectFormatEnhanced_withOfficerPayslip_returnsDefense() async {
        // Given
        let text = """
        INDIAN ARMY
        Captain John Doe
        Basic Pay: 70000
        """
        mockJCOORDetector.shouldDetectJCOOR = false

        // When
        let result = await sut.detectFormatEnhanced(fromText: text, pdfData: nil)

        // Then
        XCTAssertEqual(result, .defense)
    }

    func testDetectFormatEnhanced_withUserHintJCOOR_returnsJCOOR() async {
        // Given
        sut.updateUserHint(.jcoOr)
        let text = "Any payslip text"
        mockJCOORDetector.shouldDetectJCOOR = false

        // When
        let result = await sut.detectFormatEnhanced(fromText: text, pdfData: nil)

        // Then
        XCTAssertEqual(result, .jcoOR, "User hint should take priority")
    }

    func testDetectFormatEnhanced_withNoMarkers_fallbackToStandardDetection() async {
        // Given
        let text = "INDIAN ARMY Basic Pay"
        mockJCOORDetector.shouldDetectJCOOR = false

        // When
        let result = await sut.detectFormatEnhanced(fromText: text, pdfData: nil)

        // Then
        XCTAssertEqual(result, .defense, "Should fallback to standard detection logic")
    }

    // MARK: - Dependency Injection Tests

    func testInit_withCustomJCOORDetector_usesProvidedDetector() async {
        // Given
        let customDetector = MockJCOORFormatDetector()
        customDetector.shouldDetectJCOOR = true
        let service = PayslipFormatDetectionService(
            textExtractionService: mockTextExtractor,
            jcoORDetector: customDetector
        )

        // When
        let result = await service.detectFormatEnhanced(fromText: "test", pdfData: nil)

        // Then
        XCTAssertEqual(result, .jcoOR, "Should use injected detector")
        XCTAssertTrue(customDetector.isJCOORFormatCalled, "Should call injected detector")
    }

    // MARK: - Edge Cases

    func testDetectFormatEnhanced_withEmptyText_returnsUnknown() async {
        // Given
        let emptyText = ""

        // When
        let result = await sut.detectFormatEnhanced(fromText: emptyText, pdfData: nil)

        // Then
        XCTAssertEqual(result, .unknown)
    }
}

// MARK: - Mock JCOORFormatDetector

class MockJCOORFormatDetector: JCOORFormatDetectorProtocol {
    var shouldDetectJCOOR = false
    var isJCOORFormatCalled = false

    func isJCOORFormat(text: String) async -> Bool {
        isJCOORFormatCalled = true
        return shouldDetectJCOOR
    }
}

// MARK: - Mock TextExtractionService

class MockTextExtractionService: TextExtractionServiceProtocol {
    var textToReturn = ""

    func extractText(from document: PDFDocument) async -> String {
        return textToReturn
    }

    func extractText(from page: PDFPage) -> String {
        return textToReturn
    }

    func extractDetailedText(from pdfDocument: PDFDocument) async -> String {
        return textToReturn
    }

    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // No-op for mock
    }

    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        return !textToReturn.isEmpty
    }
}
