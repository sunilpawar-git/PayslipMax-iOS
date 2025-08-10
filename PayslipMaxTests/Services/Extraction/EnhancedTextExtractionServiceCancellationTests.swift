import XCTest
import PDFKit
@testable import PayslipMax

final class EnhancedTextExtractionServiceCancellationTests: XCTestCase {

    private var service: EnhancedTextExtractionService!
    
    override func setUp() {
        super.setUp()
        service = EnhancedTextExtractionService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCancellationDoesNotCrashAndTaskMarkedCancelled() async {
        // Given a large multi-page document to allow time to cancel
        let pdfData = TestDataGenerator.createMultiPagePDF(pageCount: 120)
        guard let document = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create PDFDocument for test")
            return
        }

        // When: start extraction in a Task and cancel shortly after
        let started = Date()
        let task = Task { () -> (String, ExtractionMetrics) in
            return await service.extractTextEnhanced(from: document)
        }

        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        task.cancel()

        let result = await task.value

        // Then: task should be marked cancelled and extraction should have returned without crashing
        XCTAssertTrue(task.isCancelled, "Parent task should be marked as cancelled")
        XCTAssertNotNil(result.0, "Extraction should return text (possibly partial)")

        // Heuristic: ensure it returned reasonably quickly (< 5s) even on CI
        XCTAssertLessThan(Date().timeIntervalSince(started), 5.0, "Cancellation path should complete promptly")
    }
}


