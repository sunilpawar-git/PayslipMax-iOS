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
    
    func testExtractTextWithEmptyDocument() async {
        // Create an empty PDF document
        let emptyPDFDocument = PDFDocument()
        
        // Test extraction with empty PDF
        let result = await sut.extractText(from: emptyPDFDocument)
        XCTAssertTrue(result.isEmpty, "Extracting text from an empty PDF should return an empty string")
    }
    
    func testExtractTextWithValidDocument() async {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 2)
        
        // Test extraction with valid PDF
        let result = await sut.extractText(from: pdfDocument)
        XCTAssertFalse(result.isEmpty, "Extracting text from a valid PDF should return non-empty text")
        
        // Verify extracted text contains expected content
        XCTAssertTrue(result.contains("Test PDF Content"), "Extracted text should contain expected content")
        XCTAssertTrue(result.contains("Page 1"), "Extracted text should contain page 1 marker")
        XCTAssertTrue(result.contains("Page 2"), "Extracted text should contain page 2 marker")
    }
    
    func testExtractTextWithCallback() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 3)
        
        // Test variables to track callback invocation
        var callbackInvocationCount = 0
        var totalPagesReported = 0
        var lastProgressReported = 0
        
        // Extract text with callback
        let result = sut.extractText(from: pdfDocument) { (pageText, currentPage, totalPages) in
            callbackInvocationCount += 1
            totalPagesReported = totalPages
            lastProgressReported = currentPage
            XCTAssertTrue(pageText.contains("Page \(currentPage)"), "Page text should contain page number")
        }
        
        // Verify extraction result
        XCTAssertNotNil(result, "Extraction should succeed")
        
        // Verify callback was called for each page
        XCTAssertEqual(callbackInvocationCount, 3, "Callback should be called for each page")
        XCTAssertEqual(totalPagesReported, 3, "Total pages should be reported correctly")
        XCTAssertEqual(lastProgressReported, 3, "Last progress should be equal to total pages")
    }
    
    func testExtractTextFromSpecificPage() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 3)
        
        // Extract text from page 2 (index 1)
        let result = sut.extractTextFromPage(at: 1, in: pdfDocument)
        
        // Verify extraction result
        XCTAssertNotNil(result, "Extraction from valid page should succeed")
        if let pageText = result {
            XCTAssertTrue(pageText.contains("Page 2"), "Extracted text should be from page 2")
            XCTAssertFalse(pageText.contains("Page 1"), "Extracted text should not contain page 1 content")
            XCTAssertFalse(pageText.contains("Page 3"), "Extracted text should not contain page 3 content")
        }
    }
    
    func testExtractTextFromPageRange() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 5)
        
        // Extract text from page range 2-4 (indices 1-3)
        let result = sut.extractText(from: pdfDocument, in: 1...3)
        
        // Verify extraction result
        XCTAssertNotNil(result, "Extraction from valid page range should succeed")
        if let rangeText = result {
            XCTAssertTrue(rangeText.contains("Page 2"), "Range text should contain page 2")
            XCTAssertTrue(rangeText.contains("Page 3"), "Range text should contain page 3")
            XCTAssertTrue(rangeText.contains("Page 4"), "Range text should contain page 4")
            XCTAssertFalse(rangeText.contains("Page 1"), "Range text should not contain page 1")
            XCTAssertFalse(rangeText.contains("Page 5"), "Range text should not contain page 5")
        }
    }
    
    func testMemoryUsageTracking() async {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument(pageCount: 3)
        
        // Extract text to trigger memory tracking
        let _ = await sut.extractText(from: pdfDocument)
        
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
            // Create a PDF page with test content
            let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
            
            let page = PDFPage(image: UIGraphicsImageRenderer(bounds: pageRect).image { context in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                
                let text = "Test PDF Content - Page \(i)\n\nThis is sample text content for page \(i) of the test PDF document."
                
                text.draw(
                    with: CGRect(x: 50, y: 50, width: 500, height: 700),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle],
                    context: nil
                )
            })
            
            pdfDocument.insert(page!, at: i-1)
        }
        
        return pdfDocument
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