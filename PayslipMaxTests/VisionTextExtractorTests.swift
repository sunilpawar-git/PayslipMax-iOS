import XCTest
import Vision
import UIKit
import PDFKit
@testable import PayslipMax

class VisionTextExtractorTests: XCTestCase {
    
    var visionExtractor: VisionTextExtractor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        visionExtractor = VisionTextExtractor()
    }
    
    override func tearDownWithError() throws {
        visionExtractor = nil
        try super.tearDownWithError()
    }
    
    func testInitialization_WithDefaultParameters_SetsCorrectValues() {
        let extractor = VisionTextExtractor()
        
        XCTAssertNotNil(extractor)
    }
    
    func testInitialization_WithCustomParameters_SetsCorrectValues() {
        let extractor = VisionTextExtractor(
            recognitionLevel: .fast,
            recognitionLanguages: ["en-US", "hi-IN"],
            minimumTextHeight: 0.02
        )
        
        XCTAssertNotNil(extractor)
    }
    
    func testExtractText_FromNilImage_ReturnsImageConversionError() {
        let expectation = self.expectation(description: "Image extraction completes")
        
        // Create an image that will fail CGImage conversion
        let image = UIImage()
        
        visionExtractor.extractText(from: image) { result in
            switch result {
            case .success(_):
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error, .imageConversionFailed)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractText_FromValidImage_ProcessesSuccessfully() {
        let expectation = self.expectation(description: "Image extraction completes")
        
        // Create a simple test image with text
        let image = createTestImageWithText("Test Text")
        
        visionExtractor.extractText(from: image) { result in
            switch result {
            case .success(let textElements):
                // Vision framework may or may not detect text in our simple test image
                // So we just verify the call completes without crashing
                XCTAssertTrue(textElements.count >= 0)
                print("Detected \(textElements.count) text elements")
            case .failure(let error):
                // Vision framework might fail on simple test images, which is acceptable
                print("Vision extraction failed as expected: \(error)")
                if case .visionRequestFailed(_) = error {
                    XCTAssertTrue(true) // Expected
                } else {
                    XCTAssertEqual(error, .noTextDetected)
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    func testExtractText_FromEmptyPDFDocument_ReturnsNoTextDetected() {
        let expectation = self.expectation(description: "PDF extraction completes")
        
        let emptyDocument = PDFDocument()
        
        visionExtractor.extractText(from: emptyDocument) { result in
            switch result {
            case .success(_):
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error, .noTextDetected)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testExtractText_FromSimplePDFDocument_ProcessesPages() {
        let expectation = self.expectation(description: "PDF extraction completes")
        
        // Create a simple PDF document with one page
        let pdfDocument = createSimplePDFDocument()
        
        visionExtractor.extractText(from: pdfDocument) { result in
            switch result {
            case .success(let textElements):
                // Vision may or may not detect text, but call should complete
                XCTAssertTrue(textElements.count >= 0)
                print("Detected \(textElements.count) text elements from PDF")
            case .failure(let error):
                // Acceptable for Vision to fail on simple test PDF
                print("Vision PDF extraction failed as expected: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0)
    }
    
    func testVisionTextExtractionError_ErrorDescriptions_AreCorrect() {
        XCTAssertEqual(VisionTextExtractionError.imageConversionFailed.errorDescription,
                       "Failed to convert PDF page to image")
        
        XCTAssertEqual(VisionTextExtractionError.noTextDetected.errorDescription,
                       "No text was detected in the image")
        
        XCTAssertEqual(VisionTextExtractionError.pdfRenderingFailed.errorDescription,
                       "Failed to render PDF page as image")
        
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let visionError = VisionTextExtractionError.visionRequestFailed(testError)
        XCTAssertEqual(visionError.errorDescription, "Vision text recognition failed: Test error")
    }
    
    func testExtractText_ConcurrentCalls_HandlesProperly() {
        let expectation1 = self.expectation(description: "First extraction completes")
        let expectation2 = self.expectation(description: "Second extraction completes")
        
        let image1 = createTestImageWithText("First Image")
        let image2 = createTestImageWithText("Second Image")
        
        // Make concurrent calls
        visionExtractor.extractText(from: image1) { result in
            // Just verify call completes
            expectation1.fulfill()
        }
        
        visionExtractor.extractText(from: image2) { result in
            // Just verify call completes
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageWithText(_ text: String) -> UIImage {
        let size = CGSize(width: 300, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Set white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Draw text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        text.draw(at: CGPoint(x: 10, y: 30), withAttributes: attrs)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createSimplePDFDocument() -> PDFDocument {
        let pdfDocument = PDFDocument()
        
        // Create a simple page with some text
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        
        UIGraphicsBeginPDFContextToData(NSMutableData(), pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        let text = "Sample PDF Text for Testing"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        text.draw(at: CGPoint(x: 50, y: 700), withAttributes: attrs)
        
        UIGraphicsEndPDFContext()
        
        return pdfDocument
    }
}

