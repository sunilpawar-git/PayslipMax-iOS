import XCTest
@testable import PayslipMax
import PDFKit

class OptimizedTextExtractionServiceTests: XCTestCase {
    
    private var service: OptimizedTextExtractionService!
    private var mockPDF: PDFDocument!
    private var mockDocumentAnalysis: DocumentAnalysis!
    
    override func setUp() {
        super.setUp()
        service = OptimizedTextExtractionService()
        mockPDF = createMockPDF()
        mockDocumentAnalysis = createMockDocumentAnalysis()
    }
    
    override func tearDown() {
        service = nil
        mockPDF = nil
        mockDocumentAnalysis = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testExtractOptimizedText() async {
        let result = await service.extractOptimizedText(from: mockPDF)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testExtractOptimizedTextWithCallback() {
        let expectation = expectation(description: "Extraction completed")
        
        var receivedText: String?
        
        service.extractOptimizedText(from: mockPDF) { text in
            receivedText = text
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        
        XCTAssertNotNil(receivedText)
        XCTAssertFalse(receivedText!.isEmpty)
    }
    
    func testExtractTextWithStrategy() async {
        // Test each strategy type
        let strategies: [PDFExtractionStrategy] = [
            .standard,
            .vision,
            .layoutAware,
            .fastText
        ]
        
        for strategy in strategies {
            let result = await service.extractText(from: mockPDF, using: strategy)
            
            XCTAssertNotNil(result, "Text extraction failed for strategy: \(strategy.rawValue)")
            XCTAssertFalse(result.isEmpty, "Extracted text is empty for strategy: \(strategy.rawValue)")
        }
    }
    
    func testDetermineOptimalStrategy() {
        // Standard text-based document
        var analysis = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.4,
            estimatedMemoryRequirement: 10 * 1024 * 1024,
            containsTables: false
        )
        
        var strategy = service.determineOptimalStrategy(for: analysis)
        XCTAssertEqual(strategy, .standard, "Should use standard strategy for basic text document")
        
        // Document with complex layout
        analysis = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.4,
            estimatedMemoryRequirement: 10 * 1024 * 1024,
            containsTables: false
        )
        
        strategy = service.determineOptimalStrategy(for: analysis)
        XCTAssertEqual(strategy, .layoutAware, "Should use layoutAware strategy for complex layout")
        
        // Large document with simple content
        analysis = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.4,
            estimatedMemoryRequirement: 100 * 1024 * 1024,
            containsTables: false
        )
        
        strategy = service.determineOptimalStrategy(for: analysis)
        XCTAssertEqual(strategy, .fastText, "Should use fastText strategy for large document")
        
        // Document with scanned content
        analysis = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: true,
            hasComplexLayout: false,
            textDensity: 0.2,
            estimatedMemoryRequirement: 10 * 1024 * 1024,
            containsTables: false
        )
        
        strategy = service.determineOptimalStrategy(for: analysis)
        XCTAssertEqual(strategy, .vision, "Should use vision strategy for scanned content")
    }
    
    func testExtractTextFromPageRange() async {
        let pageRange = 0..<min(2, mockPDF.pageCount)
        
        let result = await service.extractText(from: mockPDF, pageRange: pageRange)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testExtractTextFromPage() async {
        guard let firstPage = mockPDF.page(at: 0) else {
            XCTFail("Failed to get first page from mock PDF")
            return
        }
        
        let text = await service.extractTextFromPage(at: 0, in: mockPDF)
        let textFromPage = await service.extractTextFromPage(firstPage)
        
        XCTAssertFalse(text.isEmpty)
        XCTAssertFalse(textFromPage.isEmpty)
        XCTAssertEqual(text, textFromPage, "Both methods should extract the same text")
    }
    
    func testExtractTextWithSpecificStrategy() async {
        let text = await service.extractText(from: mockPDF, using: .vision)
        
        XCTAssertNotNil(text)
        XCTAssertFalse(text.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        let pdfData = createPDFWithText("""
        This is a test PDF document.
        It contains multiple lines of text.
        This document is used for testing the Optimized Text Extraction Service.
        We need to ensure that the service can correctly extract text from PDFs.
        The extraction should be efficient and accurate.
        """)
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create mock PDF document")
            return PDFDocument()
        }
        
        return pdfDocument
    }
    
    private func createMockDocumentAnalysis() -> DocumentAnalysis {
        return DocumentAnalysis(
            pageCount: 1,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.5,
            estimatedMemoryRequirement: 5 * 1024 * 1024,
            containsTables: false
        )
    }
    
    private func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "OptimizedTextExtractionServiceTests",
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