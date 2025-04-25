import XCTest
import PDFKit
@testable import PayslipMax

/// Tests focusing on basic strategy selection for different document types
class BasicStrategySelectionTests: XCTestCase {
    
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
        let standardPDF = createMockPDF()
        let standardAnalysis = analysisService.analyzeDocument(standardPDF)
        let standardStrategy = strategyService.determineStrategy(for: standardAnalysis)
        
        // Standard text document should use native text extraction
        XCTAssertEqual(standardStrategy, .nativeTextExtraction)
        
        // 2. Test with a scanned document
        let scannedPDF = createMockPDFWithScannedContent()
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        
        // Scanned document should use OCR extraction
        XCTAssertEqual(scannedStrategy, .ocrExtraction)
        
        // 3. Test with a large document
        let largePDF = createMockLargeDocument()
        let largeAnalysis = analysisService.analyzeDocument(largePDF)
        let largeStrategy = strategyService.determineStrategy(for: largeAnalysis)
        
        // Large document should use streaming extraction
        XCTAssertEqual(largeStrategy, .streamingExtraction)
        
        // 4. Test with a table document
        let tablePDF = createMockPDFWithTables()
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        
        // Document with tables should use table extraction
        XCTAssertEqual(tableStrategy, .tableExtraction)
    }
    
    func testFallbackStrategySelection() {
        // Create a basic analysis with no special characteristics
        let basicAnalysis = DocumentAnalysis(
            pageCount: 1,
            containsScannedContent: false,
            hasComplexLayout: false,
            isTextHeavy: false,
            isLargeDocument: false,
            containsTables: false,
            complexityScore: 0.1
        )
        
        // Get the strategy
        let basicStrategy = strategyService.determineStrategy(for: basicAnalysis)
        
        // Should default to native extraction
        XCTAssertEqual(basicStrategy, .nativeTextExtraction)
    }
    
    func testCustomStrategyParameters() {
        // Test customizing strategy parameters based on document analysis
        
        // 1. Create a custom analysis
        let customAnalysis = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            isTextHeavy: true,
            isLargeDocument: false,
            containsTables: true,
            complexityScore: 0.7
        )
        
        // 2. Determine strategy
        let customStrategy = strategyService.determineStrategy(for: customAnalysis)
        
        // Should select table extraction due to tables
        XCTAssertEqual(customStrategy, .tableExtraction)
        
        // 3. Get parameters for this strategy
        let params = strategyService.getExtractionParameters(for: customStrategy, with: customAnalysis)
        
        // 4. Verify parameters are customized appropriately
        XCTAssertTrue(params.extractTables)
        XCTAssertTrue(params.useGridDetection)
        XCTAssertTrue(params.preserveFormatting)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithText("This is a sample document for testing.")
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithScannedContent() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithImage()
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockLargeDocument() -> PDFDocument {
        let pdfData = TestPDFGenerator.createMultiPagePDF(pageCount: 100)
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithTables() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithTable()
        return PDFDocument(data: pdfData)!
    }
} 