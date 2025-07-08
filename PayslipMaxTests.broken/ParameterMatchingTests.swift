import XCTest
import PDFKit
@testable import PayslipMax

/// Tests focusing on how extraction parameters match document characteristics
class ParameterMatchingTests: XCTestCase {
    
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
    
    func testExtractionParametersMatchDocumentCharacteristics() async throws {
        // 1. Test parameters for text-heavy document
        let textPDF = createMockPDFWithHeavyText()
        let textAnalysis = try analysisService.analyzeDocument(textPDF)
        let textStrategy = strategyService.determineStrategy(for: textAnalysis)
        let textParams = strategyService.getExtractionParameters(for: textStrategy, with: textAnalysis)
        
        // Text-heavy document should have text formatting preserved
        XCTAssertTrue(textParams.preserveFormatting)
        XCTAssertTrue(textParams.maintainTextOrder)
        
        // 2. Test parameters for document with tables
        let tablePDF = createMockPDFWithTables()
        let tableAnalysis = try analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        let tableParams = strategyService.getExtractionParameters(for: tableStrategy, with: tableAnalysis)
        
        // Document with tables should extract tables and use grid detection
        XCTAssertTrue(tableParams.extractTables)
        XCTAssertTrue(tableParams.useGridDetection)
        
        // 3. Test parameters for scanned document
        let scannedPDF = createMockPDFWithScannedContent()
        let scannedAnalysis = try analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        let scannedParams = strategyService.getExtractionParameters(for: scannedStrategy, with: scannedAnalysis)
        
        // Scanned document should use OCR
        XCTAssertTrue(scannedParams.useOCR)
        XCTAssertTrue(scannedParams.extractImages)
    }
    
    func testParametersForComplexLayout() async throws {
        // Test parameters for complex layout documents
        let complexPDF = createMockPDFWithComplexLayout()
        let complexAnalysis = try analysisService.analyzeDocument(complexPDF)
        
        // Verify the document is detected as having complex layout
        XCTAssertTrue(complexAnalysis.hasComplexLayout)
        
        let complexStrategy = strategyService.determineStrategy(for: complexAnalysis)
        XCTAssertEqual(complexStrategy, .hybridExtraction)  // Use hybrid extraction for complex layouts
        
        let complexParams = strategyService.getExtractionParameters(for: complexStrategy, with: complexAnalysis)
        
        // Complex layout should preserve formatting and maintain text order
        XCTAssertTrue(complexParams.preserveFormatting)
        XCTAssertTrue(complexParams.maintainTextOrder)
        
        // Should not use OCR if not scanned content
        XCTAssertFalse(complexParams.useOCR)
    }
    
    func testParametersForLargeDocument() async throws {
        // Test parameters for large documents
        let largePDF = createMockLargeDocument()
        let largeAnalysis = try analysisService.analyzeDocument(largePDF)
        
        // Verify the document is detected as large
        XCTAssertTrue(largeAnalysis.isLargeDocument)
        
        let largeStrategy = strategyService.determineStrategy(for: largeAnalysis)
        XCTAssertEqual(largeStrategy, .streamingExtraction)
        
        let largeParams = strategyService.getExtractionParameters(for: largeStrategy, with: largeAnalysis)
        
        // Large document may sacrifice formatting for performance
        XCTAssertFalse(largeParams.preserveFormatting)
        // But should still maintain text order for coherence
        XCTAssertTrue(largeParams.maintainTextOrder)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDFWithHeavyText() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithText(String(repeating: "This is a text-heavy document. ", count: 100))
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithTables() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithTable()
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithScannedContent() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithImage()
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithComplexLayout() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithColumns(columnCount: 3)
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockLargeDocument() -> PDFDocument {
        let pdfData = TestPDFGenerator.createMultiPagePDF(pageCount: 100)
        return PDFDocument(data: pdfData)!
    }
} 