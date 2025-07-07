import XCTest
import PDFKit
@testable import PayslipMax

/// Tests for advanced document analysis functionality including table detection and content differentiation
class DocumentAnalysisAdvancedTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
    }
    
    override func tearDown() {
        analysisService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testTableDetection() {
        // Given: A PDF with tables
        let tablePDF = TestPDFGenerator.createPDFWithTables()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(tablePDF)
        
        // Then: Should detect tables
        XCTAssertTrue(analysis.containsTables)
    }
    
    func testDifferentiateDocumentTypes() {
        // Given: Different types of PDFs
        let scannedPDF = TestPDFGenerator.createPDFWithScannedContent()
        let tablePDF = TestPDFGenerator.createPDFWithTables()
        let complexPDF = TestPDFGenerator.createPDFWithComplexLayout()
        let textHeavyPDF = TestPDFGenerator.createPDFWithHeavyText()
        
        // When: Analyzing each document
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let complexAnalysis = analysisService.analyzeDocument(complexPDF)
        let textAnalysis = analysisService.analyzeDocument(textHeavyPDF)
        
        // Then: Each document should have the expected characteristics
        XCTAssertTrue(scannedAnalysis.containsScannedContent)
        XCTAssertTrue(tableAnalysis.containsTables)
        XCTAssertTrue(complexAnalysis.hasComplexLayout)
        XCTAssertTrue(textAnalysis.isTextHeavy)
    }
    
    func testMixedContentDocument() {
        // Given: A PDF with mixed content
        let mixedPDF = TestPDFGenerator.createPDFWithMixedContent()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(mixedPDF)
        
        // Then: Should detect multiple characteristics
        XCTAssertTrue(analysis.containsScannedContent)
        XCTAssertTrue(analysis.hasComplexLayout)
        XCTAssertTrue(analysis.containsTables)
    }
    
    func testAnalysisOfMultipleDocumentVersions() {
        // Given: Multiple versions of similar documents
        let simpleText = TestPDFGenerator.createPDF(withText: "Simple document")
        let complexText = TestPDFGenerator.createPDFWithHeavyText()
        
        // When: Analyzing both documents
        let simpleAnalysis = analysisService.analyzeDocument(simpleText)
        let complexAnalysis = analysisService.analyzeDocument(complexText)
        
        // Then: Should distinguish between simple and complex text documents
        XCTAssertFalse(simpleAnalysis.isTextHeavy)
        XCTAssertTrue(complexAnalysis.isTextHeavy)
        
        // Complexity metrics should differ
        XCTAssertLessThan(simpleAnalysis.complexityScore, complexAnalysis.complexityScore)
    }
    
    func testPerformanceOfAnalysisOnLargeDocument() {
        // Given: A large document
        let largePDF = TestPDFGenerator.createLargeDocument(pageCount: 50)
        
        // When/Then: Measure the performance of analysis
        measure {
            _ = self.analysisService.analyzeDocument(largePDF)
        }
    }
} 