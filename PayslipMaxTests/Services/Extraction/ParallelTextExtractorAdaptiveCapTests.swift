import XCTest
import PDFKit
import Combine
@testable import PayslipMax

final class ParallelTextExtractorAdaptiveCapTests: XCTestCase {

    func testAdaptiveCapNeverExceeded() async {
        // Given
        let extractionQueue = OperationQueue()
        extractionQueue.maxConcurrentOperationCount = 64 // deliberately large
        let progressSubject = PassthroughSubject<(pageIndex: Int, progress: Double), Never>()
        let extractor = ParallelTextExtractor(
            extractionQueue: extractionQueue,
            textPreprocessor: TextPreprocessor(),
            progressSubject: progressSubject
        )

        // Multi-page PDF
        let pdfData = TestDataGenerator.createMultiPagePDF(pageCount: 16)
        let document = PDFDocument(data: pdfData)!

        var metrics = ExtractionMetrics()

        // When
        _ = await extractor.extractTextParallel(
            from: document,
            options: {
                var opts = ExtractionOptions.default
                opts.maxConcurrentOperations = 64
                return opts
            }(),
            metrics: &metrics
        )

        // Then: queue cap must be bounded by DeviceClass.current.parallelismCap
        XCTAssertLessThanOrEqual(
            extractionQueue.maxConcurrentOperationCount,
            DeviceClass.current.parallelismCap,
            "Extractor must not exceed the device parallelism cap"
        )
    }
}


