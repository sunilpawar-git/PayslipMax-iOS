import XCTest
import PDFKit
@testable import PayslipMax

/// Tests for integration between DocumentAnalysisService and ExtractionStrategyService
class DocumentAnalysisIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    private var strategyService: ExtractionStrategyService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
        strategyService = ExtractionStrategyService()
    }
    
    override func tearDown() {
        analysisService = nil
        strategyService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testIntegrationWithExtractionStrategyService() {
        // 1. Test with a standard text document
        let standardPDF = TestPDFGenerator.createPDF(withText: "This is a sample document for testing.")
        let standardAnalysis = analysisService.analyzeDocument(standardPDF)
        let standardStrategy = strategyService.determineStrategy(for: standardAnalysis)
        
        // Standard text document should use native text extraction
        XCTAssertEqual(standardStrategy, .nativeTextExtraction)
        
        // 2. Test with a scanned document
        let scannedPDF = TestPDFGenerator.createPDFWithScannedContent()
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        
        // Scanned document should use OCR extraction
        XCTAssertEqual(scannedStrategy, .ocrExtraction)
        
        // 3. Test with a large document
        let largePDF = TestPDFGenerator.createLargeDocument()
        let largeAnalysis = analysisService.analyzeDocument(largePDF)
        let largeStrategy = strategyService.determineStrategy(for: largeAnalysis)
        
        // Large document should use streaming extraction
        XCTAssertEqual(largeStrategy, .streamingExtraction)
        
        // 4. Test with a table document
        let tablePDF = TestPDFGenerator.createPDFWithTables()
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        
        // Document with tables should use table extraction
        XCTAssertEqual(tableStrategy, .tableExtraction)
    }
    
    func testExtractionParametersMatchDocumentCharacteristics() {
        // 1. Test parameters for text-heavy document
        let textPDF = TestPDFGenerator.createPDFWithHeavyText()
        let textAnalysis = analysisService.analyzeDocument(textPDF)
        let textStrategy = strategyService.determineStrategy(for: textAnalysis)
        let textParams = strategyService.getExtractionParameters(for: textStrategy, with: textAnalysis)
        
        // Text-heavy document should have text formatting preserved
        XCTAssertTrue(textParams.preserveFormatting)
        XCTAssertTrue(textParams.maintainTextOrder)
        
        // 2. Test parameters for document with tables
        let tablePDF = TestPDFGenerator.createPDFWithTables()
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        let tableParams = strategyService.getExtractionParameters(for: tableStrategy, with: tableAnalysis)
        
        // Document with tables should extract tables and use grid detection
        XCTAssertTrue(tableParams.extractTables)
        XCTAssertTrue(tableParams.useGridDetection)
        
        // 3. Test parameters for scanned document
        let scannedPDF = TestPDFGenerator.createPDFWithScannedContent()
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        let scannedParams = strategyService.getExtractionParameters(for: scannedStrategy, with: scannedAnalysis)
        
        // Scanned document should use OCR
        XCTAssertTrue(scannedParams.useOCR)
        XCTAssertTrue(scannedParams.extractImages)
    }
    
    func testEndToEndDocumentProcessing() {
        // Test the full analysis → strategy → parameters pipeline
        
        // Given a complex PDF with mixed content
        let mixedPDF = TestPDFGenerator.createPDFWithMixedContent()
        
        // When running through the full pipeline
        let analysis = analysisService.analyzeDocument(mixedPDF)
        let strategy = strategyService.determineStrategy(for: analysis)
        let params = strategyService.getExtractionParameters(for: strategy, with: analysis)
        
        // Then the pipeline should produce appropriate parameters
        XCTAssertTrue(params.useGridDetection, "Mixed content should enable grid detection")
        XCTAssertTrue(params.extractTables, "Mixed content should extract tables")
        XCTAssertTrue(params.extractImages, "Mixed content should extract images")
        
        // Strategy should be the appropriate one for mixed content
        XCTAssertEqual(strategy, .hybridExtraction, "Mixed content should use hybrid extraction")
    }
} 