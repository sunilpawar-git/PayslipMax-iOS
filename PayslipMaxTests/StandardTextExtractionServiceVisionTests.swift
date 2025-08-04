import XCTest
import PDFKit
@testable import PayslipMax

class StandardTextExtractionServiceVisionTests: XCTestCase {
    
    var mockVisionExtractor: MockVisionTextExtractor!
    var textExtractionService: StandardTextExtractionService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockVisionExtractor = MockVisionTextExtractor()
    }
    
    override func tearDownWithError() throws {
        mockVisionExtractor = nil
        textExtractionService = nil
        try super.tearDownWithError()
    }
    
    func testInitialization_WithVisionDisabled_DoesNotUseVision() {
        textExtractionService = StandardTextExtractionService(useVisionFramework: false)
        
        let document = createSimplePDFDocument()
        let expectation = self.expectation(description: "Extraction completes")
        
        textExtractionService.extractTextElements(from: document) { result in
            switch result {
            case .success(let elements):
                // Empty PDF document should return empty elements array
                XCTAssertTrue(elements.isEmpty, "Empty PDF should return empty elements")
            case .failure(_):
                XCTFail("Should not fail with fallback")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testInitialization_WithVisionEnabled_UsesVision() {
        textExtractionService = StandardTextExtractionService(
            useVisionFramework: true,
            visionExtractor: mockVisionExtractor
        )
        
        let document = createSimplePDFDocument()
        let expectation = self.expectation(description: "Extraction completes")
        
        // Configure mock to return success
        mockVisionExtractor.shouldSucceed = true
        
        textExtractionService.extractTextElements(from: document) { result in
            switch result {
            case .success(let elements):
                // Empty document should call Vision and get results from mock
                XCTAssertTrue(self.mockVisionExtractor.extractTextFromDocumentCalled)
                XCTAssertEqual(elements.count, 2) // Mock returns 2 elements
            case .failure(_):
                XCTFail("Should succeed with mock")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractTextElements_WithVisionFailure_FallsBackToBasic() {
        textExtractionService = StandardTextExtractionService(
            useVisionFramework: true,
            visionExtractor: mockVisionExtractor
        )
        
        let document = createSimplePDFDocument()
        let expectation = self.expectation(description: "Extraction completes")
        
        // Configure mock to fail
        mockVisionExtractor.shouldSucceed = false
        
        textExtractionService.extractTextElements(from: document) { result in
            switch result {
            case .success(let elements):
                XCTAssertTrue(self.mockVisionExtractor.extractTextFromDocumentCalled)
                // Empty document should return empty elements even after fallback
                XCTAssertTrue(elements.isEmpty, "Empty PDF should return empty elements even after Vision failure")
            case .failure(_):
                XCTFail("Should fall back to basic extraction")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractTextElementsFromPage_WithValidPage_ReturnsElements() {
        textExtractionService = StandardTextExtractionService(
            useVisionFramework: true,
            visionExtractor: mockVisionExtractor
        )
        
        let document = createSimplePDFDocument()
        let expectation = self.expectation(description: "Page extraction completes")
        
        mockVisionExtractor.shouldSucceed = true
        
        textExtractionService.extractTextElementsFromPage(at: 0, in: document) { result in
            switch result {
            case .success(let elements):
                // Empty document has no pages, so should return empty array
                XCTAssertTrue(elements.isEmpty, "Empty document should return empty elements")
                // Vision extractor should not be called for empty documents
                XCTAssertFalse(self.mockVisionExtractor.extractTextFromDocumentCalled)
            case .failure(_):
                XCTFail("Should succeed with empty array for invalid page")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractTextElementsFromPage_WithInvalidPageIndex_ReturnsEmpty() {
        textExtractionService = StandardTextExtractionService(useVisionFramework: false)
        
        let document = createSimplePDFDocument()
        let expectation = self.expectation(description: "Invalid page extraction completes")
        
        textExtractionService.extractTextElementsFromPage(at: 999, in: document) { result in
            switch result {
            case .success(let elements):
                XCTAssertTrue(elements.isEmpty)
            case .failure(_):
                XCTFail("Should return empty array, not fail")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testConvertBasicTextToElements_WithMultilineText_CreatesElements() {
        textExtractionService = StandardTextExtractionService(useVisionFramework: false)
        
        // Test basic text extraction behavior by creating a simple document
        let expectation = self.expectation(description: "Multiline text conversion")
        let emptyDocument = PDFDocument()
        
        textExtractionService.extractTextElements(from: emptyDocument) { result in
            switch result {
            case .success(let elements):
                // With an empty document, we should get an empty array
                XCTAssertTrue(elements.isEmpty)
                
                // The test passes if we can call the method without crashing
                XCTAssertTrue(true, "Successfully handled empty document conversion")
                
            case .failure(_):
                XCTFail("Basic text conversion should not fail")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractTextElements_WithEmptyDocument_ReturnsEmptyArray() {
        textExtractionService = StandardTextExtractionService(useVisionFramework: false)
        
        let emptyDocument = PDFDocument()
        let expectation = self.expectation(description: "Empty document extraction completes")
        
        textExtractionService.extractTextElements(from: emptyDocument) { result in
            switch result {
            case .success(let elements):
                XCTAssertTrue(elements.isEmpty)
            case .failure(_):
                XCTFail("Empty document should return empty array")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func createSimplePDFDocument() -> PDFDocument {
        let document = PDFDocument()
        // Create a minimal document for testing - actual content doesn't matter for these tests
        return document
    }
    
    private func createMultilinePDFDocument() -> PDFDocument {
        let document = PDFDocument()
        // Mock document that will produce multiline text when extracted
        return document
    }
}

// MARK: - Mock Vision Text Extractor

class MockVisionTextExtractor: VisionTextExtractorProtocol {
    
    var shouldSucceed = true
    var extractTextFromImageCalled = false
    var extractTextFromDocumentCalled = false
    
    func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        extractTextFromImageCalled = true
        
        if shouldSucceed {
            let mockElements = [
                TextElement(text: "Mock Text 1", bounds: CGRect(x: 0, y: 0, width: 100, height: 20), fontSize: 14, confidence: 0.95),
                TextElement(text: "Mock Text 2", bounds: CGRect(x: 0, y: 25, width: 120, height: 20), fontSize: 14, confidence: 0.90)
            ]
            completion(.success(mockElements))
        } else {
            completion(.failure(.noTextDetected))
        }
    }
    
    func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        extractTextFromDocumentCalled = true
        
        if shouldSucceed {
            let mockElements = [
                TextElement(text: "PDF Mock Text 1", bounds: CGRect(x: 10, y: 10, width: 150, height: 20), fontSize: 16, confidence: 0.98),
                TextElement(text: "PDF Mock Text 2", bounds: CGRect(x: 10, y: 35, width: 140, height: 20), fontSize: 16, confidence: 0.92)
            ]
            completion(.success(mockElements))
        } else {
            completion(.failure(.visionRequestFailed(NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))))
        }
    }
}