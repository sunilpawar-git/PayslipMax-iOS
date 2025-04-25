import XCTest
import PDFKit
@testable import PayslipMax

/// Tests focusing on extraction parameter customization for mixed content and specialized document types
class ParameterCustomizationTests: XCTestCase {
    
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
    
    func testParametersForMixedContent() {
        // Test parameters for documents with mixed content types
        let mixedPDF = createMockPDFWithMixedContent()
        let mixedAnalysis = analysisService.analyzeDocument(mixedPDF)
        
        // Document should have multiple characteristics
        XCTAssertTrue(mixedAnalysis.containsScannedContent)
        XCTAssertTrue(mixedAnalysis.containsTables)
        
        let mixedStrategy = strategyService.determineStrategy(for: mixedAnalysis)
        // Strategy should prioritize scanned content
        XCTAssertEqual(mixedStrategy, .ocrExtraction)
        
        let mixedParams = strategyService.getExtractionParameters(for: mixedStrategy, with: mixedAnalysis)
        
        // Should use OCR for scanned content
        XCTAssertTrue(mixedParams.useOCR)
        // Should also extract tables since they're present
        XCTAssertTrue(mixedParams.extractTables)
        // Should extract images from scanned content
        XCTAssertTrue(mixedParams.extractImages)
    }
    
    func testParameterAdaptationForMixedStrategies() {
        // Test parameter adaptation for different mixed content scenarios
        
        // 1. Mixed content with tables and complex layout but no scanned content
        let tablesAndLayout = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            isTextHeavy: false,
            isLargeDocument: false,
            containsTables: true,
            complexityScore: 0.7
        )
        
        let tablesLayoutStrategy = strategyService.determineStrategy(for: tablesAndLayout)
        let tablesLayoutParams = strategyService.getExtractionParameters(for: tablesLayoutStrategy, with: tablesAndLayout)
        
        // Should prioritize tables over complex layout
        XCTAssertEqual(tablesLayoutStrategy, .tableExtraction)
        XCTAssertTrue(tablesLayoutParams.extractTables)
        XCTAssertTrue(tablesLayoutParams.useGridDetection)
        // Should preserve formatting from complex layout
        XCTAssertTrue(tablesLayoutParams.preserveFormatting)
        
        // 2. Mixed content with scanned content and large document size
        let scannedAndLarge = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: true,
            hasComplexLayout: false,
            isTextHeavy: false,
            isLargeDocument: true,
            containsTables: false,
            complexityScore: 0.6
        )
        
        let scannedLargeStrategy = strategyService.determineStrategy(for: scannedAndLarge)
        let scannedLargeParams = strategyService.getExtractionParameters(for: scannedLargeStrategy, with: scannedAndLarge)
        
        // Should prioritize scanned content over large document
        XCTAssertEqual(scannedLargeStrategy, .ocrExtraction)
        XCTAssertTrue(scannedLargeParams.useOCR)
        // Should incorporate some streaming optimizations for large document
        XCTAssertTrue(scannedLargeParams.extractImages)
    }
    
    func testConflictingParameterResolution() {
        // Test how conflicting parameter requirements are resolved
        
        // Document that is both large (prefers no formatting preservation) 
        // and has complex layout (prefers formatting preservation)
        let conflictingNeeds = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: false,
            hasComplexLayout: true,
            isTextHeavy: true,
            isLargeDocument: true,
            containsTables: false,
            complexityScore: 0.5
        )
        
        let conflictStrategy = strategyService.determineStrategy(for: conflictingNeeds)
        let conflictParams = strategyService.getExtractionParameters(for: conflictStrategy, with: conflictingNeeds)
        
        // According to priority rules, large document should win
        XCTAssertEqual(conflictStrategy, .streamingExtraction)
        
        // Check if the parameter system makes a reasonable compromise
        // (The actual compromise depends on implementation specifics)
        if conflictParams.preserveFormatting {
            // If it preserves formatting, it should have some optimization
            XCTAssertFalse(conflictParams.extractImages, "Should limit expensive operations")
        } else {
            // If it doesn't preserve formatting, it should maintain text order
            XCTAssertTrue(conflictParams.maintainTextOrder, "Should at least maintain text order")
        }
    }
    
    func testParameterOverrides() {
        // Test when specific document characteristics force parameter overrides
        
        // 1. Document with tables should always extract tables regardless of other settings
        let tableDocument = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: false,
            isTextHeavy: false,
            isLargeDocument: false,
            containsTables: true,
            complexityScore: 0.3
        )
        
        let tableStrategy = strategyService.determineStrategy(for: tableDocument)
        let tableParams = strategyService.getExtractionParameters(for: tableStrategy, with: tableDocument)
        
        XCTAssertTrue(tableParams.extractTables, "Tables should always be extracted when present")
        
        // 2. Scanned content should always use OCR
        let scannedDocument = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: true,
            hasComplexLayout: false,
            isTextHeavy: false,
            isLargeDocument: false,
            containsTables: false,
            complexityScore: 0.3
        )
        
        let scannedStrategy = strategyService.determineStrategy(for: scannedDocument)
        let scannedParams = strategyService.getExtractionParameters(for: scannedStrategy, with: scannedDocument)
        
        XCTAssertTrue(scannedParams.useOCR, "OCR should always be used for scanned content")
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDFWithMixedContent() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithMixedContent()
        return PDFDocument(data: pdfData)!
    }
} 