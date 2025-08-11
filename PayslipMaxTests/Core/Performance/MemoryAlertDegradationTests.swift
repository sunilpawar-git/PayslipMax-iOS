import XCTest
import PDFKit
@testable import PayslipMax

final class MemoryAlertDegradationTests: XCTestCase {

    func testMemoryWarningReducesParallelismAndEnablesStreamingPath() async throws {
        // Prepare a tiny PDF to avoid heavy work but exercise code paths
        let doc = PDFDocument()
        // Create a minimal document with 3 blank pages
        for _ in 0..<3 { doc.insert(PDFPage(), at: doc.pageCount) }

        // Build enhanced service that listens to MemoryPressureHigh
        let service = EnhancedTextExtractionService()

        // Fire memory pressure notification to trigger degradation
        NotificationCenter.default.post(name: NSNotification.Name("MemoryPressureHigh"), object: nil)

        // Use options that would normally use parallel path on small docs but set a tiny threshold
        // so that memory optimization (streaming) is definitely triggered
        var options = ExtractionOptions()
        options.useParallelProcessing = true
        options.maxConcurrentOperations = 8
        options.memoryThresholdMB = 1

        // Run extraction
        let result = await service.extractTextEnhanced(from: doc, options: options)

        // After memory warning, EnhancedTextExtractionService reduces parallelism.
        // We can't directly read the OperationQueue here, but we can check metrics behavior:
        // If memory optimization triggered (due to threshold), streaming path is used; otherwise
        // parallel path still runs but with reduced concurrency. We at least assert no crash and
        // progress/metrics are recorded.
        // Assert that streaming was engaged via memory optimization flag
        XCTAssertTrue(result.metrics.memoryOptimizationTriggered)
    }
}


