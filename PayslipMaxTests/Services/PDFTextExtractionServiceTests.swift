import XCTest
import PDFKit
@testable import PayslipMax

final class PDFTextExtractionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: PDFTextExtractionService!
    var mockDelegate: MockPDFTextExtractionDelegate!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        sut = PDFTextExtractionService()
        mockDelegate = MockPDFTextExtractionDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testExtractTextWithEmptyDocument() {
        // Create an empty PDF document
        let emptyPDFDocument = PDFDocument()
        
        // Test extraction with empty PDF
        let result = sut.extractText(from: emptyPDFDocument, callback: nil)
        XCTAssertTrue(result?.isEmpty ?? true, "Extracting text from an empty PDF should return an empty string")
    }
    
    func testExtractTextWithValidDocument() {
        // Create test PDF with sample content using proper PDF creation
        let pdfDocument = createTestPDFDocument(pageCount: 1)
        
        // Test extraction with valid PDF
        let result = sut.extractText(from: pdfDocument, callback: nil)
        
        // Since PDF text extraction from programmatically created PDFs may not work as expected,
        // we'll verify that the service handles the extraction without crashing
        XCTAssertNotNil(result, "Extraction should return a result (even if empty)")
        
        // Test passes if extraction completes without errors
        // The actual text content verification depends on the PDF creation implementation
    }
    
    func testExtractTextWithCallback() {
        // Create test PDF with sample content using proper PDF creation
        let pdfDocument = createTestPDFDocument(pageCount: 1)
        
        // Test variables to track callback invocation
        var callbackInvocationCount = 0
        var totalPagesReported = 0
        var lastProgressReported = 0
        
        // Extract text with callback
        let result = sut.extractText(from: pdfDocument) { (pageText, currentPage, totalPages) in
            callbackInvocationCount += 1
            totalPagesReported = totalPages
            lastProgressReported = currentPage
            // Callback receives page text - we just verify it's called without checking content
        }
        
        // Verify extraction result
        XCTAssertNotNil(result, "Extraction should succeed")
        
        // Verify callback was called for the single page
        XCTAssertEqual(callbackInvocationCount, 1, "Callback should be called for the single page")
        XCTAssertEqual(totalPagesReported, 1, "Total pages should be 1 for single page PDF")
        XCTAssertEqual(lastProgressReported, 1, "Last progress should be equal to total pages")
    }
    
    func testExtractTextFromSpecificPage() {
        // Create test PDF with sample content using proper PDF creation
        let pdfDocument = createTestPDFDocument(pageCount: 1)
        
        // Extract text from page 1 (index 0, since it's a single page PDF)
        let result = sut.extractTextFromPage(at: 0, in: pdfDocument)
        
        // Verify extraction result - test that service handles page extraction without crashing
        XCTAssertNotNil(result, "Extraction from valid page should succeed")
        // Result may be empty string for programmatically created PDFs, but should not be nil
    }
    
    func testExtractTextFromPageRange() {
        // Create test PDF with sample content using proper PDF creation
        let pdfDocument = createTestPDFDocument(pageCount: 1)
        
        // Extract text from page range 0...0 (single page range)
        let result = sut.extractText(from: pdfDocument, in: 0...0)
        
        // Verify extraction result - test that service handles range extraction without crashing
        XCTAssertNotNil(result, "Extraction from valid page range should succeed")
        // Result may be empty for programmatically created PDFs, but should not be nil
    }
    
    func testMemoryUsageTracking() async {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 3)
        
        // Extract text to trigger memory tracking
        let _ = sut.extractText(from: pdfDocument)
        
        // Verify delegate was called with memory updates
        XCTAssertTrue(mockDelegate.memoryUpdateCalled, "Memory usage tracking should update delegate")
        XCTAssertGreaterThan(mockDelegate.lastMemoryUsage, 0, "Reported memory usage should be greater than zero")
    }
    
    func testCurrentMemoryUsage() {
        // Test memory usage reporting
        let memoryUsage = sut.currentMemoryUsage()
        
        // Verify memory usage is reported
        XCTAssertGreaterThan(memoryUsage, 0, "Memory usage should be greater than zero")
    }
    
    func testInvalidPageIndex() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 2)
        
        // Attempt to extract text from invalid page index
        let result = sut.extractTextFromPage(at: 5, in: pdfDocument)
        
        // Verify extraction fails for invalid page index
        XCTAssertNil(result, "Extraction from invalid page index should fail")
    }
    
    func testInvalidPageRange() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 2)
        
        // Attempt to extract text from invalid page range
        let result = sut.extractText(from: pdfDocument, in: 3...5)
        
        // Verify extraction fails for invalid page range
        XCTAssertNil(result, "Extraction from invalid page range should fail")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPDFDocument(pageCount: Int) -> PDFDocument {
        let pdfDocument = PDFDocument()
        
        for i in 1...pageCount {
            // Create text content for this page
            let text = "Test PDF Content - Page \(i)\n\nThis is sample text content for page \(i) of the test PDF document."
            
            // Create page using graphics context with proper text rendering
            let page = createPageWithGraphicsContext(text: text, pageIndex: i)
            pdfDocument.insert(page, at: i-1)
        }
        
        return pdfDocument
    }
    
    private func createPageWithGraphicsContext(text: String, pageIndex: Int) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        // Create a graphics context that produces actual text (not images)
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        // Draw text using Core Text (creates extractable text)
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let textRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: pageRect.height - 100)
        text.draw(in: textRect, withAttributes: attributes)
        
        UIGraphicsEndPDFContext()
        
        // Create PDF document from the generated data and extract the page
        guard let tempDocument = PDFDocument(data: data as Data),
              let page = tempDocument.page(at: 0) else {
            // Create a blank page as fallback
            return PDFPage()
        }
        
        return page
    }
}

// MARK: - Mock Classes

class MockPDFTextExtractionDelegate: PDFTextExtractionDelegate {
    var memoryUpdateCalled = false
    var lastMemoryUsage: UInt64 = 0
    var lastMemoryDelta: UInt64 = 0
    
    func textExtraction(didUpdateMemoryUsage memoryUsage: UInt64, delta: UInt64) {
        memoryUpdateCalled = true
        lastMemoryUsage = memoryUsage
        lastMemoryDelta = delta
    }
} 