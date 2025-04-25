import XCTest
import PDFKit
@testable import PayslipMax

/// Tests for basic document analysis functionality
class DocumentAnalysisBasicTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    private var mockPDF: PDFDocument!
    private var mockPDFURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
        
        // Create a mock PDF for testing
        mockPDF = TestPDFGenerator.createPDF(withText: "This is a sample document for testing.")
        
        // Create a temporary PDF URL
        mockPDFURL = FileManager.default.temporaryDirectory.appendingPathComponent("mockTest.pdf")
        try? mockPDF.write(to: mockPDFURL)
    }
    
    override func tearDown() {
        analysisService = nil
        mockPDF = nil
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: mockPDFURL)
        mockPDFURL = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testAnalyzeDocument() {
        // When: Analyzing a mock PDF
        let analysis = analysisService.analyzeDocument(mockPDF)
        
        // Then: Should return valid analysis
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.pageCount, mockPDF.pageCount)
        XCTAssertFalse(analysis.containsScannedContent)
    }
    
    func testAnalyzeDocumentFromURL() {
        // When: Analyzing a mock PDF from URL
        let analysis = analysisService.analyzeDocument(at: mockPDFURL)
        
        // Then: Should return valid analysis
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.pageCount, mockPDF.pageCount)
    }
    
    func testDetectScannedContent() {
        // Given: A PDF with scanned content
        let scannedPDF = TestPDFGenerator.createPDFWithScannedContent()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(scannedPDF)
        
        // Then: Should detect scanned content
        XCTAssertTrue(analysis.containsScannedContent)
    }
    
    func testDetectComplexLayout() {
        // Given: A PDF with complex layout
        let complexPDF = TestPDFGenerator.createPDFWithComplexLayout()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(complexPDF)
        
        // Then: Should detect complex layout
        XCTAssertTrue(analysis.hasComplexLayout)
    }
    
    func testDetectTextHeavyDocument() {
        // Given: A text-heavy PDF
        let textHeavyPDF = TestPDFGenerator.createPDFWithHeavyText()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(textHeavyPDF)
        
        // Then: Should detect text-heavy content
        XCTAssertTrue(analysis.isTextHeavy)
    }
    
    func testLargeDocumentDetection() {
        // Given: A large PDF document
        let largePDF = TestPDFGenerator.createLargeDocument()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(largePDF)
        
        // Then: Should detect large document
        XCTAssertTrue(analysis.isLargeDocument)
    }
} 