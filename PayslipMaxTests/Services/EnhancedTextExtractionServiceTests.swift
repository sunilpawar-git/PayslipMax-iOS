import XCTest
import PDFKit
@testable import PayslipMax

final class EnhancedTextExtractionServiceTests: XCTestCase {
    
    var pdfURL: URL!
    var pdfDocument: PDFDocument!
    var extractionService: EnhancedTextExtractionService!
    var textExtractionService: TextExtractionService!
    var pdfTextExtractionService: PDFTextExtractionService!
    var streamingProcessor: StreamingPDFProcessor!
    var textCache: PDFProcessingCache!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test dependencies
        textExtractionService = TextExtractionService()
        pdfTextExtractionService = PDFTextExtractionService()
        streamingProcessor = StreamingPDFProcessor()
        textCache = PDFProcessingCache()
        
        // Create enhanced extraction service
        extractionService = EnhancedTextExtractionService(
            textExtractionService: textExtractionService,
            pdfTextExtractionService: pdfTextExtractionService,
            streamingProcessor: streamingProcessor,
            textCache: textCache
        )
        
        // Create test PDF
        pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("testExtraction.pdf")
        pdfDocument = createMockPDFDocument()
    }
    
    override func tearDownWithError() throws {
        // Clean up resources
        if let url = pdfURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        extractionService = nil
        textExtractionService = nil
        pdfTextExtractionService = nil
        streamingProcessor = nil
        textCache = nil
        pdfDocument = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - ExtractionOptions Tests
    
    func testDefaultExtractionOptions() async throws {
        // Test with default extraction options
        let result = await extractionService.extractTextEnhanced(from: pdfDocument)
        
        // Verify the extraction was successful
        XCTAssertFalse(result.text.isEmpty, "Extracted text should not be empty")
        XCTAssertTrue(result.text.contains("Sample Document"), "Extracted text should contain document title")
        
        // Verify metrics with default options
        let metrics = result.metrics
        XCTAssertGreaterThan(metrics.executionTime, 0, "Execution time should be recorded")
        XCTAssertEqual(metrics.pagesProcessed, pdfDocument.pageCount, "All pages should be processed")
        XCTAssertTrue(metrics.usedParallelProcessing, "Default options should use parallel processing")
        XCTAssertTrue(metrics.usedTextPreprocessing, "Default options should use text preprocessing")
    }
    
    func testSpeedOptimizedExtractionOptions() async throws {
        // Create speed-optimized options
        let speedOptions = ExtractionOptions.speed
        
        // Verify speed options properties
        XCTAssertFalse(speedOptions.preprocessText, "Speed options should disable text preprocessing")
        XCTAssertGreaterThan(speedOptions.maxConcurrentOperations, 4, "Speed options should increase concurrency")
        
        // Test extraction with speed options
        let result = await extractionService.extractTextEnhanced(from: pdfDocument, options: speedOptions)
        
        // Verify metrics reflect speed options
        let metrics = result.metrics
        XCTAssertFalse(metrics.usedTextPreprocessing, "Speed extraction should not use text preprocessing")
        XCTAssertTrue(metrics.usedParallelProcessing, "Speed extraction should use parallel processing")
    }
    
    func testQualityOptimizedExtractionOptions() async throws {
        // Create quality-optimized options
        let qualityOptions = ExtractionOptions.quality
        
        // Verify quality options properties
        XCTAssertTrue(qualityOptions.preprocessText, "Quality options should enable text preprocessing")
        XCTAssertFalse(qualityOptions.useParallelProcessing, "Quality options should disable parallel processing")
        
        // Test extraction with quality options
        let result = await extractionService.extractTextEnhanced(from: pdfDocument, options: qualityOptions)
        
        // Verify metrics reflect quality options
        let metrics = result.metrics
        XCTAssertTrue(metrics.usedTextPreprocessing, "Quality extraction should use text preprocessing")
        XCTAssertFalse(metrics.usedParallelProcessing, "Quality extraction should not use parallel processing")
    }
    
    func testMemoryEfficientExtractionOptions() async throws {
        // Create memory-efficient options
        let memoryOptions = ExtractionOptions.memoryEfficient
        
        // Verify memory options properties
        XCTAssertFalse(memoryOptions.useParallelProcessing, "Memory-efficient options should disable parallel processing")
        XCTAssertTrue(memoryOptions.useAdaptiveBatching, "Memory-efficient options should enable adaptive batching")
        XCTAssertLessThan(memoryOptions.memoryThresholdMB, 200, "Memory threshold should be lower")
        
        // Test extraction with memory options
        let result = await extractionService.extractTextEnhanced(from: pdfDocument, options: memoryOptions)
        
        // Verify metrics reflect memory-efficient options
        let metrics = result.metrics
        XCTAssertFalse(metrics.usedParallelProcessing, "Memory-efficient extraction should not use parallel processing")
    }
    
    func testCustomExtractionOptions() async throws {
        // Create custom extraction options
        let customOptions = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 2,
            preprocessText: true,
            useAdaptiveBatching: true,
            maxBatchSize: 2 * 1024 * 1024, // 2MB
            collectDetailedMetrics: true,
            useCache: false,
            memoryThresholdMB: 100
        )
        
        // Test extraction with custom options
        let result = await extractionService.extractTextEnhanced(from: pdfDocument, options: customOptions)
        
        // Verify metrics reflect custom options
        let metrics = result.metrics
        XCTAssertTrue(metrics.usedParallelProcessing, "Custom extraction should use parallel processing")
        XCTAssertTrue(metrics.usedTextPreprocessing, "Custom extraction should use text preprocessing")
        XCTAssertEqual(metrics.cacheHitRatio, 0.0, "Cache hit ratio should be 0 when cache is disabled")
    }
    
    func testCachingBehavior() async throws {
        // First extraction to populate cache
        let options = ExtractionOptions(useCache: true)
        let firstResult = await extractionService.extractTextEnhanced(from: pdfDocument, options: options)
        
        // Second extraction should use cache
        let secondResult = await extractionService.extractTextEnhanced(from: pdfDocument, options: options)
        
        // Verify cache was used
        XCTAssertEqual(secondResult.metrics.cacheHitRatio, 1.0, "Second extraction should have full cache hit")
        XCTAssertLessThan(secondResult.metrics.executionTime, firstResult.metrics.executionTime, 
                         "Cached extraction should be faster")
    }
    
    func testExtractionWithLargeDocument() async throws {
        // Create a larger mock document
        let largePDF = createLargeMockPDFDocument()
        
        // Use memory-efficient options
        let memoryOptions = ExtractionOptions.memoryEfficient
        
        // Test extraction with large document
        let result = await extractionService.extractTextEnhanced(from: largePDF, options: memoryOptions)
        
        // Verify memory optimization was triggered
        XCTAssertTrue(result.metrics.memoryOptimizationTriggered, 
                     "Memory optimization should be triggered for large documents")
    }
    
    func testExtractTextWithVaryingConcurrency() async throws {
        // Test with different concurrency levels
        let concurrencyLevels = [1, 2, 4, 8]
        var executionTimes: [Int: TimeInterval] = [:]
        
        for concurrency in concurrencyLevels {
            let options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: concurrency,
                preprocessText: false
            )
            
            let result = await extractionService.extractTextEnhanced(from: pdfDocument, options: options)
            executionTimes[concurrency] = result.metrics.executionTime
        }
        
        // Higher concurrency should generally be faster than single-threaded for multi-page documents
        // This might not always be true due to overhead, but it's a reasonable assumption for testing
        if pdfDocument.pageCount > 2 {
            XCTAssertLessThanOrEqual(
                executionTimes[8] ?? 0, 
                executionTimes[1] ?? .infinity,
                "Higher concurrency should generally be faster for multi-page documents"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDFDocument() -> PDFDocument {
        // Create a simple PDF document for testing
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let pdfContext = CGContext(pdfURL as CFURL, mediaBox: &CGRect(pageRect), nil) else {
            fatalError("Failed to create PDF context")
        }
        
        // Add a page
        pdfContext.beginPage(mediaBox: &CGRect(pageRect))
        
        // Add some text
        let font = CTFontCreateWithName("Helvetica" as CFString, 24, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let attributedString = NSAttributedString(string: "Sample Document", attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        pdfContext.textPosition = CGPoint(x: 50, y: 700)
        CTLineDraw(line, pdfContext)
        
        // Add more text
        let bodyFont = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black
        ]
        
        let bodyText = """
        This is a test document for the Enhanced Text Extraction Service.
        It contains multiple paragraphs of text to test the extraction capabilities.
        
        The service should be able to extract this text with different options settings.
        """
        
        let bodyAttributedString = NSAttributedString(string: bodyText, attributes: bodyAttributes)
        let bodyLine = CTLineCreateWithAttributedString(bodyAttributedString)
        
        pdfContext.textPosition = CGPoint(x: 50, y: 650)
        CTLineDraw(bodyLine, pdfContext)
        
        // Finish the page and close the PDF
        pdfContext.endPage()
        pdfContext.closePDF()
        
        // Create PDFDocument from the generated file
        guard let document = PDFDocument(url: pdfURL) else {
            fatalError("Failed to create PDF document from URL")
        }
        
        return document
    }
    
    private func createLargeMockPDFDocument() -> PDFDocument {
        // Create a larger PDF document with multiple pages
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let pdfContext = CGContext(pdfURL as CFURL, mediaBox: &CGRect(pageRect), nil) else {
            fatalError("Failed to create PDF context")
        }
        
        // Create multiple pages
        for pageNum in 1...10 {
            pdfContext.beginPage(mediaBox: &CGRect(pageRect))
            
            // Add page title
            let font = CTFontCreateWithName("Helvetica" as CFString, 24, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let attributedString = NSAttributedString(string: "Page \(pageNum)", attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributedString)
            
            pdfContext.textPosition = CGPoint(x: 50, y: 700)
            CTLineDraw(line, pdfContext)
            
            // Add content with Lorem Ipsum text to make it larger
            let bodyFont = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black
            ]
            
            let loremIpsum = """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
            
            Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.
            """
            
            // Repeat text to make document larger
            var pageContent = ""
            for _ in 1...5 {
                pageContent += loremIpsum + "\n\n"
            }
            
            let bodyAttributedString = NSAttributedString(string: pageContent, attributes: bodyAttributes)
            
            // Draw text in a frame
            let textRect = CGRect(x: 50, y: 50, width: 500, height: 600)
            let frameSetter = CTFramesetterCreateWithAttributedString(bodyAttributedString)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: bodyAttributedString.length), path, nil)
            
            CTFrameDraw(frame, pdfContext)
            
            pdfContext.endPage()
        }
        
        pdfContext.closePDF()
        
        // Create PDFDocument from the generated file
        guard let document = PDFDocument(url: pdfURL) else {
            fatalError("Failed to create PDF document from URL")
        }
        
        return document
    }
} 