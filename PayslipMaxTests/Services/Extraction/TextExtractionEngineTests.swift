import XCTest
@testable import PayslipMax
import PDFKit
import Combine

class TextExtractionEngineTests: XCTestCase {
    
    private var engine: TextExtractionEngine!
    private var mockParallelExtractor: MockParallelTextExtractor!
    private var mockSequentialExtractor: MockSequentialTextExtractor!
    private var mockStreamingProcessor: MockStreamingPDFProcessor!
    private var mockTextCache: MockPDFProcessingCache!
    private var mockMemoryManager: MockTextExtractionMemoryManager!
    private var mockPDF: PDFDocument!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupEngine()
        setupTestData()
    }
    
    override func tearDown() {
        engine = nil
        mockParallelExtractor = nil
        mockSequentialExtractor = nil
        mockStreamingProcessor = nil
        mockTextCache = nil
        mockMemoryManager = nil
        mockPDF = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Setup Methods
    
    private func setupMocks() {
        let mockQueue = OperationQueue()
        let mockTextPreprocessor = MockTextPreprocessor()
        let mockProgressSubject = PassthroughSubject<(pageIndex: Int, progress: Double), Never>()
        let mockExtractionMemoryManager = MockExtractionMemoryManager()
        
        mockParallelExtractor = MockParallelTextExtractor(
            extractionQueue: mockQueue,
            textPreprocessor: mockTextPreprocessor,
            progressSubject: mockProgressSubject
        )
        mockSequentialExtractor = MockSequentialTextExtractor(
            textPreprocessor: mockTextPreprocessor,
            progressSubject: mockProgressSubject,
            memoryManager: mockExtractionMemoryManager
        )
        mockStreamingProcessor = MockStreamingPDFProcessor()
        mockTextCache = MockPDFProcessingCache()
        mockMemoryManager = MockTextExtractionMemoryManager()
        mockMemoryManager.reset()
    }
    
    private func setupEngine() {
        engine = TextExtractionEngine(
            parallelExtractor: mockParallelExtractor,
            sequentialExtractor: mockSequentialExtractor,
            streamingProcessor: mockStreamingProcessor,
            textCache: mockTextCache,
            memoryManager: mockMemoryManager
        )
    }
    
    private func setupTestData() {
        mockPDF = createMockPDF()
        cancellables = Set<AnyCancellable>()
    }
    
    // MARK: - Test Cases
    
    func testParallelExtractionStrategy() async {
        // Given
        let expectedText = "Extracted text from parallel processing"
        mockParallelExtractor.mockResult = expectedText
        
        let strategy = TextExtractionStrategy.parallel
        let options = ExtractionOptions.default
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, expectedText)
        XCTAssertTrue(mockParallelExtractor.extractTextParallelCalled)
        XCTAssertFalse(mockSequentialExtractor.extractTextSequentialCalled)
    }
    
    func testSequentialExtractionStrategy() async {
        // Given
        let expectedText = "Extracted text from sequential processing"
        mockSequentialExtractor.mockResult = expectedText
        
        let strategy = TextExtractionStrategy.sequential
        let options = ExtractionOptions.default
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, expectedText)
        XCTAssertTrue(mockSequentialExtractor.extractTextSequentialCalled)
        XCTAssertFalse(mockParallelExtractor.extractTextParallelCalled)
    }
    
    func testStreamingExtractionStrategy() async {
        // Given
        let expectedText = "Extracted text from streaming processing"
        mockStreamingProcessor.mockResult = expectedText
        
        let strategy = TextExtractionStrategy.streaming
        let options = ExtractionOptions.default
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, expectedText)
        XCTAssertTrue(mockStreamingProcessor.processDocumentStreamingCalled)
    }
    
    func testAdaptiveStrategyWithLowMemory() async {
        // Given
        let expectedText = "Extracted text from streaming (memory optimized)"
        mockMemoryManager.shouldUseMemoryOptimizationResult = true
        mockStreamingProcessor.mockResult = expectedText
        
        let strategy = TextExtractionStrategy.adaptive
        let options = ExtractionOptions.default
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, expectedText)
        XCTAssertTrue(result.metrics.memoryOptimizationTriggered)
        XCTAssertTrue(mockStreamingProcessor.processDocumentStreamingCalled)
    }
    
    func testAdaptiveStrategyWithHighMemory() async {
        // Given
        let expectedText = "Extracted text from parallel processing"
        mockMemoryManager.shouldUseMemoryOptimizationResult = false
        mockParallelExtractor.mockResult = expectedText
        
        let strategy = TextExtractionStrategy.adaptive
        let options = ExtractionOptions(useParallelProcessing: true)
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, expectedText)
        XCTAssertFalse(result.metrics.memoryOptimizationTriggered)
        XCTAssertTrue(mockParallelExtractor.extractTextParallelCalled)
    }
    
    func testCacheHit() async {
        // Given
        let cachedText = "Cached extracted text"
        mockTextCache.mockCachedResult = cachedText
        
        let strategy = TextExtractionStrategy.parallel
        let options = ExtractionOptions(useCache: true)
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, cachedText)
        XCTAssertEqual(result.metrics.cacheHitRatio, 1.0)
        XCTAssertFalse(mockParallelExtractor.extractTextParallelCalled)
    }
    
    func testCacheMiss() async {
        // Given
        let extractedText = "Newly extracted text"
        mockTextCache.mockCachedResult = nil
        mockParallelExtractor.mockResult = extractedText
        
        let strategy = TextExtractionStrategy.parallel
        let options = ExtractionOptions(useCache: true)
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: strategy,
            options: options
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.text, extractedText)
        XCTAssertEqual(result.metrics.cacheHitRatio, 0.0)
        XCTAssertTrue(mockParallelExtractor.extractTextParallelCalled)
        XCTAssertTrue(mockTextCache.storeCalled)
    }
    
    func testProgressPublisher() async {
        // Given
        var progressUpdates: [ExtractionProgress] = []
        let expectation = XCTestExpectation(description: "Progress updates received")
        expectation.expectedFulfillmentCount = 3 // initialization, processing, completion
        
        engine.getProgressPublisher()
            .sink { progress in
                progressUpdates.append(progress)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let _ = await engine.executeExtraction(
            from: mockPDF,
            using: .parallel,
            options: ExtractionOptions.default
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(progressUpdates.count, 3)
        XCTAssertEqual(progressUpdates.first?.phase, .initialization)
        XCTAssertEqual(progressUpdates.last?.phase, .completed)
    }
    
    func testMetricsCalculation() async {
        // Given
        let expectedText = "Test extraction result"
        mockParallelExtractor.mockResult = expectedText
        mockMemoryManager.mockInitialMemory = 1000
        mockMemoryManager.mockCurrentMemory = 1200
        
        // When
        let result = await engine.executeExtraction(
            from: mockPDF,
            using: .parallel,
            options: ExtractionOptions.default
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.metrics.charactersExtracted, expectedText.count)
        XCTAssertGreaterThan(result.metrics.executionTime, 0)
        XCTAssertEqual(result.metrics.peakMemoryUsage, 200) // 1200 - 1000
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        let pdf = PDFDocument()
        let page = PDFPage()
        pdf.insert(page, at: 0)
        return pdf
    }
}

// MARK: - Mock Classes

class MockParallelTextExtractor: ParallelTextExtractor {
    var mockResult: String = "Mock parallel result"
    var extractTextParallelCalled = false
    
    override func extractTextParallel(
        from document: PDFDocument,
        options: ExtractionOptions,
        metrics: inout ExtractionMetrics
    ) async -> String {
        extractTextParallelCalled = true
        return mockResult
    }
}

class MockSequentialTextExtractor: SequentialTextExtractor {
    var mockResult: String = "Mock sequential result"
    var extractTextSequentialCalled = false
    
    override func extractTextSequential(
        from document: PDFDocument,
        options: ExtractionOptions,
        metrics: inout ExtractionMetrics
    ) async -> String {
        extractTextSequentialCalled = true
        return mockResult
    }
}

class MockStreamingPDFProcessor: StreamingPDFProcessor {
    var mockResult: String = "Mock streaming result"
    var processDocumentStreamingCalled = false
    
    override func processDocumentStreaming(
        _ document: PDFDocument,
        callback: ((Double, String) -> Void)?
    ) async -> String {
        processDocumentStreamingCalled = true
        callback?(0.5, "Processing...")
        callback?(1.0, "Complete")
        return mockResult
    }
}

class MockPDFProcessingCache: PDFProcessingCache {
    var mockCachedResult: String?
    var storeCalled = false
    
    override func retrieve<T>(forKey key: String) -> T? where T: Codable {
        return mockCachedResult as? T
    }
    
    override func store<T>(_ result: T, forKey key: String) -> Bool where T: Codable {
        storeCalled = true
        return true
    }
}

class MockExtractionMemoryManager: ExtractionMemoryManager {
    var mockCurrentMemory: UInt64 = 0
    
    override func getCurrentMemoryUsage() -> UInt64 {
        return mockCurrentMemory
    }
}

class MockTextExtractionMemoryManager: TextExtractionMemoryManager {
    var shouldUseMemoryOptimizationResult = false
    var mockInitialMemory: UInt64 = 0
    var mockCurrentMemory: UInt64 = 0
    private var callCount = 0
    
    func reset() {
        callCount = 0
    }
    
    override func shouldUseMemoryOptimization(for document: PDFDocument, thresholdMB: Int) -> Bool {
        return shouldUseMemoryOptimizationResult
    }
    
    override func getCurrentMemoryUsage() -> UInt64 {
        callCount += 1
        // First call returns initial memory, subsequent calls return current memory
        if callCount == 1 {
            return mockInitialMemory
        } else {
            return mockCurrentMemory > 0 ? mockCurrentMemory : mockInitialMemory
        }
    }
}

class MockTextPreprocessor: TextPreprocessor {
    var mockResult: String = "Mock preprocessed text"
    var preprocessTextCalled = false
    
    override func preprocessText(_ text: String) -> String {
        preprocessTextCalled = true
        return mockResult
    }
}