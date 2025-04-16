import XCTest
import PDFKit
@testable import PayslipMax

class ExtractionStrategyServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var strategyService: ExtractionStrategyService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        strategyService = ExtractionStrategyService()
    }
    
    override func tearDown() {
        strategyService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testNativeTextExtractionForTextBasedDocument() {
        // Given: A text-based PDF document analysis
        let analysis = createMockAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: false,
            isTextHeavy: true,
            containsGraphics: false,
            isLargeDocument: false,
            textDensity: 0.8,
            estimatedMemoryRequirement: 10 * 1024 * 1024 // 10 MB
        )
        
        // When: Determining the strategy for full extraction
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .fullExtraction)
        
        // Then: Should select native text extraction
        XCTAssertEqual(strategy, .nativeTextExtraction, "Should select native text extraction for text-based PDFs")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertTrue(parameters.extractText)
        XCTAssertFalse(parameters.useOCR)
        XCTAssertEqual(parameters.quality, .high)
    }
    
    func testOCRExtractionForScannedDocument() {
        // Given: A scanned PDF document analysis
        let analysis = createMockAnalysis(
            pageCount: 3,
            containsScannedContent: true,
            hasComplexLayout: false,
            isTextHeavy: false,
            containsGraphics: true,
            isLargeDocument: false,
            textDensity: 0.1,
            estimatedMemoryRequirement: 15 * 1024 * 1024 // 15 MB
        )
        
        // When: Determining the strategy for full extraction
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .fullExtraction)
        
        // Then: Should select OCR extraction
        XCTAssertEqual(strategy, .ocrExtraction, "Should select OCR extraction for scanned documents")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertTrue(parameters.extractText)
        XCTAssertTrue(parameters.useOCR)
        XCTAssertEqual(parameters.quality, .high)
    }
    
    func testHybridExtractionForMixedDocument() {
        // Given: A document with both scanned and text content
        let analysis = createMockAnalysis(
            pageCount: 7,
            containsScannedContent: true,
            hasComplexLayout: true,
            isTextHeavy: true,
            containsGraphics: true,
            isLargeDocument: false,
            textDensity: 0.5,
            estimatedMemoryRequirement: 20 * 1024 * 1024 // 20 MB
        )
        
        // When: Determining the strategy for full extraction
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .fullExtraction)
        
        // Then: Should select hybrid extraction
        XCTAssertEqual(strategy, .hybridExtraction, "Should select hybrid extraction for mixed content documents")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertTrue(parameters.extractText)
        XCTAssertTrue(parameters.useOCR)
        XCTAssertTrue(parameters.preferNativeTextWhenAvailable)
    }
    
    func testStreamingExtractionForLargeDocument() {
        // Given: A very large document
        let analysis = createMockAnalysis(
            pageCount: 100,
            containsScannedContent: false,
            hasComplexLayout: false,
            isTextHeavy: true,
            containsGraphics: true,
            isLargeDocument: true,
            textDensity: 0.7,
            estimatedMemoryRequirement: 200 * 1024 * 1024 // 200 MB
        )
        
        // When: Determining the strategy for full extraction
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .fullExtraction)
        
        // Then: Should select streaming extraction
        XCTAssertEqual(strategy, .streamingExtraction, "Should select streaming extraction for large documents")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertTrue(parameters.useStreaming)
        XCTAssertGreaterThan(parameters.batchSize, 0)
    }
    
    func testPreviewExtractionForPreviewPurpose() {
        // Given: Any document analysis with preview purpose
        let analysis = createMockAnalysis(
            pageCount: 10,
            containsScannedContent: false,
            hasComplexLayout: true,
            isTextHeavy: true,
            containsGraphics: true,
            isLargeDocument: false,
            textDensity: 0.6,
            estimatedMemoryRequirement: 25 * 1024 * 1024 // 25 MB
        )
        
        // When: Determining the strategy for preview purpose
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .preview)
        
        // Then: Should select preview extraction
        XCTAssertEqual(strategy, .previewExtraction, "Should select preview extraction for preview purpose")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertEqual(parameters.quality, .medium)
        XCTAssertTrue(parameters.extractText)
        XCTAssertNotNil(parameters.pagesToProcess)
        XCTAssertLessThanOrEqual(parameters.pagesToProcess?.count ?? 0, 3)
    }
    
    func testTableExtractionForDocumentWithTables() {
        // Given: A document analysis with tables
        let analysis = createMockAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            isTextHeavy: true,
            containsGraphics: true,
            isLargeDocument: false,
            textDensity: 0.6,
            estimatedMemoryRequirement: 18 * 1024 * 1024, // 18 MB
            containsTables: true
        )
        
        // When: Determining the strategy for full extraction
        let strategy = strategyService.determineStrategy(for: analysis, purpose: .fullExtraction)
        
        // Then: Should select table extraction
        XCTAssertEqual(strategy, .tableExtraction, "Should select table extraction for documents with tables")
        
        // And: Parameters should match the strategy
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        XCTAssertTrue(parameters.extractTables)
        XCTAssertTrue(parameters.extractText)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAnalysis(
        pageCount: Int,
        containsScannedContent: Bool,
        hasComplexLayout: Bool,
        isTextHeavy: Bool,
        containsGraphics: Bool,
        isLargeDocument: Bool,
        textDensity: Double,
        estimatedMemoryRequirement: Int64,
        containsTables: Bool = false
    ) -> DocumentAnalysis {
        return DocumentAnalysis(
            pageCount: pageCount,
            containsScannedContent: containsScannedContent,
            hasComplexLayout: hasComplexLayout,
            isTextHeavy: isTextHeavy,
            containsGraphics: containsGraphics,
            isLargeDocument: isLargeDocument,
            textDensity: textDensity,
            estimatedMemoryRequirement: estimatedMemoryRequirement,
            containsTables: containsTables
        )
    }
} 