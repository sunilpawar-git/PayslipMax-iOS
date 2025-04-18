import XCTest
@testable import PayslipMax
import PDFKit

class EnhancedTextExtractionServiceTests: XCTestCase {
    
    private var service: EnhancedTextExtractionService!
    private var mockPDF: PDFDocument!
    
    override func setUp() {
        super.setUp()
        service = EnhancedTextExtractionService()
        mockPDF = createMockPDF()
    }
    
    override func tearDown() {
        service = nil
        mockPDF = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testExtractTextWithDefaultOptions() async {
        let options = ExtractionOptions.default
        
        let result = await service.extractText(from: mockPDF, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
        XCTAssertGreaterThan(result.metrics.extractionTime, 0)
        XCTAssertGreaterThan(result.metrics.characterCount, 0)
    }
    
    func testExtractTextWithSpeedOptions() async {
        let options = ExtractionOptions.speed
        
        let result = await service.extractText(from: mockPDF, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
        XCTAssertTrue(options.useParallelProcessing)
        XCTAssertGreaterThan(options.maxConcurrentOperations, 1)
    }
    
    func testExtractTextWithQualityOptions() async {
        let options = ExtractionOptions.quality
        
        let result = await service.extractText(from: mockPDF, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
        XCTAssertTrue(options.preprocessText)
        XCTAssertTrue(options.collectDetailedMetrics)
    }
    
    func testExtractTextWithMemoryEfficientOptions() async {
        let options = ExtractionOptions.memoryEfficient
        
        let result = await service.extractText(from: mockPDF, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
        XCTAssertTrue(options.useAdaptiveBatching)
        XCTAssertLessThanOrEqual(options.maxConcurrentOperations, 2)
    }
    
    func testCustomExtractionOptions() async {
        let customOptions = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 4,
            preprocessText: true,
            useAdaptiveBatching: true,
            maxBatchSize: 3 * 1024 * 1024, // 3MB
            collectDetailedMetrics: true,
            useCache: false,
            memoryThresholdMB: 200
        )
        
        let result = await service.extractText(from: mockPDF, with: customOptions)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
        XCTAssertGreaterThan(result.metrics.extractionTime, 0)
    }
    
    func testExtractionWithCallback() {
        let options = ExtractionOptions.default
        let expectation = expectation(description: "Extraction completed")
        
        var receivedResult: ExtractionResult?
        
        service.extractText(from: mockPDF, with: options) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        
        XCTAssertNotNil(receivedResult)
        XCTAssertFalse(receivedResult!.extractedText.isEmpty)
        XCTAssertNotNil(receivedResult!.metrics)
    }
    
    func testExtractTextFromPage() async {
        guard let firstPage = mockPDF.page(at: 0) else {
            XCTFail("Failed to get first page from mock PDF")
            return
        }
        
        let options = ExtractionOptions.default
        let text = await service.extractTextFromPage(firstPage, with: options)
        
        XCTAssertFalse(text.isEmpty)
    }
    
    func testExtractTextFromPageRange() async {
        let options = ExtractionOptions.default
        let pageRange = 0..<min(2, mockPDF.pageCount)
        
        let result = await service.extractText(from: mockPDF, pageRange: pageRange, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        XCTAssertNotNil(result.metrics)
    }
    
    func testMemoryUsageAndCleanup() async {
        // Set a very low memory threshold to trigger cleanup
        let options = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 4,
            preprocessText: true,
            useAdaptiveBatching: true,
            maxBatchSize: 1 * 1024 * 1024, // 1MB
            collectDetailedMetrics: true,
            useCache: true,
            memoryThresholdMB: 1 // Very low threshold to trigger cleanup
        )
        
        let result = await service.extractText(from: mockPDF, with: options)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.extractedText.isEmpty)
        
        // Note: We can't really assert on memory cleanup directly as it's implementation-dependent,
        // but we can verify the extraction completes successfully even with a low threshold
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        let pdfData = createPDFWithText("""
        This is a test PDF document.
        It contains multiple lines of text.
        This document is used for testing the Enhanced Text Extraction Service.
        We need to ensure that the service can correctly extract text from PDFs.
        The extraction should be efficient and accurate.
        """)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create mock PDF document")
            return PDFDocument()
        }
        
        return pdfDocument
    }
    
    private func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "EnhancedTextExtractionServiceTests",
            kCGPDFContextAuthor: "Test Suite"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let textFont = UIFont.systemFont(ofSize: 12)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let textAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            attributedText.draw(in: CGRect(x: 50, y: 50, width: 512, height: 692))
        }
        
        return data
    }
} 