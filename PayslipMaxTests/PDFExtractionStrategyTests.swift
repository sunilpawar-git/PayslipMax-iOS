import XCTest
@testable import PayslipMax
import PDFKit

class PDFExtractionStrategyTests: XCTestCase {
    
    private var mockDocumentWithoutScannedContent: DocumentAnalysis!
    private var mockDocumentWithScannedContent: DocumentAnalysis!
    private var mockComplexLayoutDocument: DocumentAnalysis!
    private var mockLargeDocument: DocumentAnalysis!
    private var mockDocumentWithTables: DocumentAnalysis!
    private var extractionStrategyService: ExtractionStrategyService!
    
    override func setUp() {
        super.setUp()
        
        // Create mock document analysis instances
        mockDocumentWithoutScannedContent = DocumentAnalysis(
            pageCount: 10,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.8,
            estimatedMemoryRequirement: 50 * 1024 * 1024, // 50MB
            containsTables: false
        )
        
        mockDocumentWithScannedContent = DocumentAnalysis(
            pageCount: 10,
            containsScannedContent: true,
            hasComplexLayout: false,
            textDensity: 0.3,
            estimatedMemoryRequirement: 80 * 1024 * 1024, // 80MB
            containsTables: false
        )
        
        mockComplexLayoutDocument = DocumentAnalysis(
            pageCount: 15,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.6,
            estimatedMemoryRequirement: 70 * 1024 * 1024, // 70MB
            containsTables: false
        )
        
        mockLargeDocument = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.7,
            estimatedMemoryRequirement: 300 * 1024 * 1024, // 300MB
            containsTables: false
        )
        
        mockDocumentWithTables = DocumentAnalysis(
            pageCount: 20,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.5,
            estimatedMemoryRequirement: 100 * 1024 * 1024, // 100MB
            containsTables: true
        )
        
        extractionStrategyService = ExtractionStrategyService()
    }
    
    override func tearDown() {
        mockDocumentWithoutScannedContent = nil
        mockDocumentWithScannedContent = nil
        mockComplexLayoutDocument = nil
        mockLargeDocument = nil
        mockDocumentWithTables = nil
        extractionStrategyService = nil
        super.tearDown()
    }
    
    func testNativeStrategyForStandardDocument() {
        let strategy = extractionStrategyService.determineStrategy(for: mockDocumentWithoutScannedContent, purpose: .fullExtraction)
        XCTAssertEqual(strategy, .nativeTextExtraction, "Standard document should use native extraction")
    }
    
    func testOCRStrategyForScannedDocument() {
        let strategy = extractionStrategyService.determineStrategy(for: mockDocumentWithScannedContent, purpose: .fullExtraction)
        XCTAssertEqual(strategy, .ocrExtraction, "Scanned document should use OCR extraction")
    }
    
    func testHybridStrategyForMixedContent() {
        // Create a mock document with mixed content (both text and scanned)
        let mockMixedDocument = DocumentAnalysis(
            pageCount: 12,
            containsScannedContent: true,
            hasComplexLayout: true,
            textDensity: 0.5,
            estimatedMemoryRequirement: 90 * 1024 * 1024, // 90MB
            containsTables: false
        )
        
        let strategy = extractionStrategyService.determineStrategy(for: mockMixedDocument, purpose: .fullExtraction)
        XCTAssertEqual(strategy, .hybridExtraction, "Mixed content document should use hybrid extraction")
    }
    
    func testTableStrategyForTableDocument() {
        let strategy = extractionStrategyService.determineStrategy(for: mockDocumentWithTables, purpose: .fullExtraction)
        XCTAssertEqual(strategy, .tableExtraction, "Document with tables should use table extraction")
    }
    
    func testStreamingStrategyForLargeDocument() {
        let strategy = extractionStrategyService.determineStrategy(for: mockLargeDocument, purpose: .fullExtraction)
        XCTAssertEqual(strategy, .streamingExtraction, "Large document should use streaming extraction")
    }
    
    func testPreviewStrategyForPreviewPurpose() {
        // Test that preview purpose overrides other factors
        let strategy = extractionStrategyService.determineStrategy(for: mockLargeDocument, purpose: .preview)
        XCTAssertEqual(strategy, .previewExtraction, "Preview purpose should use preview strategy regardless of document type")
    }
    
    func testExtractionParametersForNativeStrategy() {
        let parameters = extractionStrategyService.getExtractionParameters(for: .nativeTextExtraction, with: mockDocumentWithoutScannedContent)
        
        XCTAssertNotNil(parameters)
        XCTAssertEqual(parameters.useVisionFramework, false)
        XCTAssertEqual(parameters.processInBatches, false)
        XCTAssertEqual(parameters.useOCR, false)
    }
    
    func testExtractionParametersForOCRStrategy() {
        let parameters = extractionStrategyService.getExtractionParameters(for: .ocrExtraction, with: mockDocumentWithScannedContent)
        
        XCTAssertNotNil(parameters)
        XCTAssertEqual(parameters.useVisionFramework, true)
        XCTAssertEqual(parameters.useOCR, true)
    }
    
    func testExtractionParametersForHybridStrategy() {
        let parameters = extractionStrategyService.getExtractionParameters(for: .hybridExtraction, with: mockDocumentWithScannedContent)
        
        XCTAssertNotNil(parameters)
        XCTAssertEqual(parameters.useVisionFramework, true)
        XCTAssertEqual(parameters.useOCR, true)
        XCTAssertEqual(parameters.processInBatches, false)
    }
    
    func testExtractionParametersForStreamingStrategy() {
        let parameters = extractionStrategyService.getExtractionParameters(for: .streamingExtraction, with: mockLargeDocument)
        
        XCTAssertNotNil(parameters)
        XCTAssertEqual(parameters.processInBatches, true)
        XCTAssertGreaterThan(parameters.maxBatchSize, 0)
    }
} 