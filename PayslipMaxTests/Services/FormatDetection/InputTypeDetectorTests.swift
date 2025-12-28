import XCTest
@testable import PayslipMax

/// Tests for InputTypeDetector to verify correct identification of input types
final class InputTypeDetectorTests: XCTestCase {

    private var sut: InputTypeDetector!

    override func setUp() {
        super.setUp()
        sut = InputTypeDetector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Image Detection Tests

    func testGetInputType_withJPGData_returnsImageDirect() async {
        // Given: JPEG magic bytes (FF D8 FF E0)
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])

        // When
        let result = await sut.getInputType(jpegData)

        // Then
        if case .imageDirect(let data) = result {
            XCTAssertEqual(data, jpegData)
        } else {
            XCTFail("Expected imageDirect, got \(result)")
        }
    }

    func testGetInputType_withPNGData_returnsImageDirect() async {
        // Given: PNG magic bytes (89 50 4E 47)
        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])

        // When
        let result = await sut.getInputType(pngData)

        // Then
        if case .imageDirect(let data) = result {
            XCTAssertEqual(data, pngData)
        } else {
            XCTFail("Expected imageDirect, got \(result)")
        }
    }

    // MARK: - PDF Detection Tests

    func testGetInputType_withTextBasedPDF_returnsPDFTextBased() async {
        // Given: A PDF with significant text content
        guard let pdfData = createMockTextPDF(textContent: String(repeating: "Test payslip content ", count: 20)) else {
            XCTFail("Could not create mock PDF")
            return
        }

        // When
        let result = await sut.getInputType(pdfData)

        // Then
        if case .pdfTextBased(let data) = result {
            XCTAssertEqual(data, pdfData)
        } else {
            XCTFail("Expected pdfTextBased, got \(result)")
        }
    }

    func testGetInputType_withScannedPDF_returnsPDFScanned() async {
        // Given: A PDF with minimal text (< 100 chars)
        guard let pdfData = createMockTextPDF(textContent: "123") else {
            XCTFail("Could not create mock PDF")
            return
        }

        // When
        let result = await sut.getInputType(pdfData)

        // Then
        if case .pdfScanned(let data) = result {
            XCTAssertEqual(data, pdfData)
        } else {
            XCTFail("Expected pdfScanned, got \(result)")
        }
    }

    // MARK: - Edge Cases

    func testGetInputType_withEmptyData_returnsImageDirect() async {
        // Given
        let emptyData = Data()

        // When
        let result = await sut.getInputType(emptyData)

        // Then: Should default to imageDirect for unknown data
        if case .imageDirect = result {
            // Pass
        } else {
            XCTFail("Expected imageDirect for empty data, got \(result)")
        }
    }

    func testGetInputType_withCorruptedData_returnsImageDirect() async {
        // Given: Random bytes that don't match any signature
        let corruptedData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05])

        // When
        let result = await sut.getInputType(corruptedData)

        // Then: Should default to imageDirect
        if case .imageDirect = result {
            // Pass
        } else {
            XCTFail("Expected imageDirect for corrupted data, got \(result)")
        }
    }

    func testGetInputType_withVerySmallData_returnsImageDirect() async {
        // Given: Data smaller than minimum size for magic byte detection
        let smallData = Data([0xFF, 0xD8])  // Only 2 bytes

        // When
        let result = await sut.getInputType(smallData)

        // Then
        if case .imageDirect = result {
            // Pass
        } else {
            XCTFail("Expected imageDirect for very small data, got \(result)")
        }
    }

    // MARK: - Helper Methods

    /// Creates a mock PDF with specified text content
    /// - Parameter textContent: The text to include in the PDF
    /// - Returns: PDF data or nil if creation fails
    private func createMockTextPDF(textContent: String) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        return pdfRenderer.pdfData { context in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            textContent.draw(
                in: CGRect(x: 50, y: 50, width: 500, height: 700),
                withAttributes: attributes
            )
        }
    }
}
