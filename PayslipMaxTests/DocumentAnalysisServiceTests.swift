import XCTest
import PDFKit
@testable import PayslipMax

class DocumentAnalysisServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    private var mockPDF: PDFDocument!
    private var tempPDFURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
        setupMockPDF()
    }
    
    override func tearDown() {
        analysisService = nil
        mockPDF = nil
        
        // Clean up temp file if it exists
        if let url = tempPDFURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testAnalyzeDocument() throws {
        // Given a PDF document
        XCTAssertNotNil(mockPDF, "Mock PDF should be created successfully")
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockPDF)
        
        // Then analysis should have expected properties
        XCTAssertEqual(analysis.pageCount, 1, "Page count should match the mock PDF")
        XCTAssertFalse(analysis.isLargeDocument, "Mock PDF should not be considered large")
        XCTAssertGreaterThan(analysis.estimatedMemoryRequirement, 0, "Memory requirement should be calculated")
    }
    
    func testAnalyzeDocumentFromURL() throws {
        // Given a PDF document URL
        XCTAssertNotNil(tempPDFURL, "Temp PDF URL should exist")
        
        // When analyzing the document from URL
        let analysis = try analysisService.analyzeDocument(at: tempPDFURL)
        
        // Then analysis should have expected properties
        XCTAssertEqual(analysis.pageCount, 1, "Page count should match the mock PDF")
        XCTAssertFalse(analysis.isLargeDocument, "Mock PDF should not be considered large")
    }
    
    func testDetectScannedContent() throws {
        // Given a mock scanned PDF document
        let mockScannedPDF = createMockPDFWithScannedContent()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockScannedPDF)
        
        // Then analysis should detect scanned content
        XCTAssertTrue(analysis.containsScannedContent, "Should detect scanned content")
        XCTAssertLessThan(analysis.textDensity, 0.3, "Text density should be low for scanned documents")
    }
    
    func testDetectComplexLayout() throws {
        // Given a mock PDF with complex layout
        let mockComplexPDF = createMockPDFWithComplexLayout()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockComplexPDF)
        
        // Then analysis should detect complex layout
        XCTAssertTrue(analysis.hasComplexLayout, "Should detect complex layout")
    }
    
    func testDetectTextHeavyDocument() throws {
        // Given a mock text-heavy PDF
        let mockTextPDF = createMockPDFWithHeavyText()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockTextPDF)
        
        // Then analysis should identify text-heavy document
        XCTAssertTrue(analysis.isTextHeavy, "Should detect text-heavy document")
        XCTAssertGreaterThan(analysis.textDensity, 0.7, "Text density should be high for text-heavy documents")
    }
    
    func testLargeDocumentDetection() throws {
        // Given a mock large PDF
        let mockLargePDF = createMockLargePDF()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockLargePDF)
        
        // Then analysis should identify large document
        XCTAssertTrue(analysis.isLargeDocument, "Should detect large document")
        XCTAssertGreaterThan(analysis.estimatedMemoryRequirement, 100 * 1024 * 1024, "Memory requirement should be high")
    }
    
    func testTableDetection() throws {
        // Given a mock PDF with tables
        let mockTablePDF = createMockPDFWithTables()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockTablePDF)
        
        // Then analysis should detect tables
        XCTAssertTrue(analysis.containsTables, "Should detect tables in document")
    }
    
    func testDifferentiateDocumentTypes() {
        // Test that the service can correctly identify different document types
        
        // Create different document types
        let scannedDoc = createMockPDFWithScannedContent()
        let tableDoc = createMockPDFWithTables()
        let complexDoc = createMockPDFWithComplexLayout()
        let textHeavyDoc = createMockPDFWithHeavyText()
        
        // Analyze each document
        let scannedResult = analysisService.analyzeDocument(scannedDoc)
        let tableResult = analysisService.analyzeDocument(tableDoc)
        let complexResult = analysisService.analyzeDocument(complexDoc)
        let textHeavyResult = analysisService.analyzeDocument(textHeavyDoc)
        
        // Verify scanned document is detected correctly
        XCTAssertTrue(scannedResult.hasScannedContent, "Should detect scanned content")
        XCTAssertFalse(scannedResult.hasTables, "Scanned document should not have tables")
        
        // Verify table document is detected correctly
        XCTAssertTrue(tableResult.hasTables, "Should detect tables")
        XCTAssertFalse(tableResult.hasScannedContent, "Table document should not be detected as scanned")
        
        // Verify complex layout document
        XCTAssertTrue(complexResult.hasComplexLayout, "Should detect complex layout")
        
        // Verify text-heavy document
        XCTAssertTrue(textHeavyResult.isTextHeavy, "Should detect text-heavy document")
        XCTAssertFalse(textHeavyResult.hasScannedContent, "Text-heavy document should not be detected as scanned")
    }
    
    func testMixedContentDocument() {
        // Test that the service can analyze a document with mixed content types
        let mixedDoc = createMockPDFWithMixedContent()
        let analysis = analysisService.analyzeDocument(mixedDoc)
        
        // A mixed document should identify multiple characteristics
        XCTAssertTrue(analysis.hasTables, "Should detect tables in mixed document")
        XCTAssertTrue(analysis.hasComplexLayout, "Should detect complex layout in mixed document")
        XCTAssertTrue(analysis.containsFormElements, "Should detect form elements in mixed document")
        
        // Test the content extraction recommendations
        let strategies = analysis.recommendedExtractionStrategies
        XCTAssertTrue(strategies.contains(.tableExtraction), "Table extraction should be recommended")
        XCTAssertTrue(strategies.contains(.hybridExtraction), "Hybrid extraction should be recommended for mixed content")
    }
    
    func testDetectFormsDocument() throws {
        // Given a PDF with form elements
        let mockFormPDF = createMockPDFWithFormElements()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockFormPDF)
        
        // Then analysis should detect form elements
        XCTAssertTrue(analysis.containsFormElements, "Should detect form elements in the document")
    }
    
    func testComplexFormDocument() throws {
        // Given a PDF with complex layout and form elements
        let mockComplexFormPDF = createMockPDFWithComplexFormLayout()
        
        // When analyzing the document
        let analysis = try analysisService.analyzeDocument(mockComplexFormPDF)
        
        // Then analysis should detect both complex layout and form elements
        XCTAssertTrue(analysis.hasComplexLayout, "Should detect complex layout")
        XCTAssertTrue(analysis.containsFormElements, "Should detect form elements")
        
        // And the appropriate extraction strategies should be recommended
        let strategies = analysis.recommendedExtractionStrategies
        XCTAssertTrue(strategies.contains(.tableExtraction), "Table extraction should be recommended for complex forms")
    }
    
    // MARK: - Helper Methods
    
    private func setupMockPDF() {
        // Create a simple PDF document with one page
        mockPDF = PDFDocument()
        let page = PDFPage()
        mockPDF.insert(page!, at: 0)
        
        // Save to temporary file for URL-based tests
        tempPDFURL = FileManager.default.temporaryDirectory.appendingPathComponent("mockTest.pdf")
        mockPDF.write(to: tempPDFURL)
    }
    
    private func createMockPDFWithScannedContent() -> PDFDocument {
        // Create a PDF that simulates a scanned document with minimal text
        let pdf = PDFDocument()
        
        // Create a PDFPage with a text string that contains minimal extractable text
        let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
        let pdfData = NSMutableAttributedString(string: "This is a scanned document simulation.\nVery little extractable text.", attributes: attributes)
        
        let page = PDFPage(attributedString: pdfData)!
        pdf.insert(page, at: 0)
        
        // Add more "image-like" pages with barely any text
        let imagePage = PDFPage()!
        pdf.insert(imagePage, at: 1)
        
        return pdf
    }
    
    private func createMockPDFWithComplexLayout() -> PDFDocument {
        // Simulate a document with complex layout (multiple columns, sections)
        let pdf = PDFDocument()
        
        // Create content with multiple columns (simulated with tab characters and spacing)
        var complexContent = "Column 1\t\t\tColumn 2\t\t\tColumn 3\n"
        complexContent += "Item 1-1\t\t\tItem 2-1\t\t\tItem 3-1\n"
        complexContent += "Item 1-2\t\t\tItem 2-2\t\t\tItem 3-2\n"
        complexContent += "Item 1-3\t\t\tItem 2-3\t\t\tItem 3-3\n\n"
        
        // Add some sections with different formatting
        complexContent += "SECTION A\n"
        complexContent += "Content for section A goes here with multiple lines\nof text to simulate a complex document structure\n\n"
        complexContent += "SECTION B\n"
        complexContent += "Content for section B with different spacing    and    tab   patterns\n"
        complexContent += "    Indented text to further complicate layout detection\n"
        
        // Create a page with this complex content
        let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
        let pdfData = NSMutableAttributedString(string: complexContent, attributes: attributes)
        
        let page = PDFPage(attributedString: pdfData)!
        pdf.insert(page, at: 0)
        
        return pdf
    }
    
    private func createMockPDFWithHeavyText() -> PDFDocument {
        // Simulate a text-heavy document with high text density
        let pdf = PDFDocument()
        
        // Create a long text string with lots of content
        var heavyText = "This is a text-heavy document with high text density.\n\n"
        
        // Add multiple paragraphs of text to increase density
        for i in 1...10 {
            heavyText += "Paragraph \(i): Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
            heavyText += "Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget "
            heavyText += "aliquam nisl nisl eget nisl. Nullam auctor, nisl eget ultricies tincidunt, "
            heavyText += "nisl nisl aliquam nisl, eget aliquam nisl nisl eget nisl.\n\n"
        }
        
        // Create a page with this heavy text content
        let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
        let pdfData = NSMutableAttributedString(string: heavyText, attributes: attributes)
        
        let page = PDFPage(attributedString: pdfData)!
        pdf.insert(page, at: 0)
        
        return pdf
    }
    
    private func createMockLargePDF() -> PDFDocument {
        // Simulate a large document with many pages
        let pdf = PDFDocument()
        
        // Add multiple pages with content to simulate large document
        for i in 0..<50 {
            let pageContent = "Page \(i+1) of a large document.\n\nThis page contains some sample text to give it size."
            let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
            let pdfData = NSMutableAttributedString(string: pageContent, attributes: attributes)
            
            let page = PDFPage(attributedString: pdfData)!
            pdf.insert(page, at: pdf.pageCount)
        }
        
        return pdf
    }
    
    private func createMockPDFWithTables() -> PDFDocument {
        // Simulate a document with tables using consistent spacing
        let pdf = PDFDocument()
        
        // Create content with table-like structure
        var tableContent = "Employee ID    Employee Name       Department      Salary\n"
        tableContent += "---------------------------------------------------------\n"
        tableContent += "001            John Smith          Engineering     75000\n"
        tableContent += "002            Jane Doe            Marketing       65000\n"
        tableContent += "003            Robert Johnson      Finance         80000\n"
        tableContent += "004            Sarah Williams      Human Resources 70000\n"
        tableContent += "005            Michael Brown       Sales           90000\n\n"
        
        // Add another table with different structure
        tableContent += "Product     Quantity    Unit Price    Total\n"
        tableContent += "------------------------------------------\n"
        tableContent += "Widget A    10          $5.99         $59.90\n"
        tableContent += "Widget B    5           $12.50        $62.50\n"
        tableContent += "Widget C    8           $8.75         $70.00\n"
        
        // Create a page with this table content
        let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
        let pdfData = NSMutableAttributedString(string: tableContent, attributes: attributes)
        
        let page = PDFPage(attributedString: pdfData)!
        pdf.insert(page, at: 0)
        
        return pdf
    }
    
    private func createMockPDFWithMixedContent() -> PDFDocument {
        let pdfDocument = PDFDocument()
        
        // Page 1: Text with a table
        let page1 = PDFPage()
        let tableContent = """
        EMPLOYEE INFORMATION
        
        Name: John Smith                     Employee ID: 12345
        Department: Engineering              Position: Senior Developer
        
        PAYROLL SUMMARY
        
        Period: January 1-15, 2023
        
        | Item               | Amount    | YTD       |
        |--------------------|-----------|-----------|
        | Gross Pay          | $3,500.00 | $7,000.00 |
        | Federal Tax        | $700.00   | $1,400.00 |
        | State Tax          | $250.00   | $500.00   |
        | Social Security    | $217.00   | $434.00   |
        | Medicare           | $50.75    | $101.50   |
        | 401(k)             | $350.00   | $700.00   |
        | Health Insurance   | $125.00   | $250.00   |
        | Net Pay            | $1,807.25 | $3,614.50 |
        """
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        
        let attributedString = NSAttributedString(string: tableContent, attributes: attributes)
        page1.attributedString = attributedString
        pdfDocument.insert(page1, at: 0)
        
        // Page 2: Form-like content
        let page2 = PDFPage()
        let formContent = """
        EMPLOYEE EXPENSE REPORT
        
        Name: _______________________    Date: ______________
        
        Department: ________________    Manager: ___________
        
        □ Business Travel    □ Office Supplies    □ Client Entertainment
        
        Date        Description                Amount      Approved
        __________  _______________________   __________  □
        __________  _______________________   __________  □
        __________  _______________________   __________  □
        __________  _______________________   __________  □
        
        Total Amount: $____________
        
        Employee Signature: ____________________
        
        Manager Approval: ______________________
        """
        
        let formAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        
        let formAttributedString = NSAttributedString(string: formContent, attributes: formAttributes)
        page2.attributedString = formAttributedString
        pdfDocument.insert(page2, at: 1)
        
        // Page 3: Image-like content (simulating a scanned receipt)
        let page3 = PDFPage()
        
        // We simulate an image by creating a mostly blank page with minimal text
        // In a real test, we would insert an actual image, but this is sufficient for testing
        let imageSimulation = """
                    RECEIPT
        
        
        
        
                Store: ACME Office Supplies
        
        
        
                Date: 01/15/2023
        
        
        
                Total: $127.65
        """
        
        let imageAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.darkGray
        ]
        
        let imageAttributedString = NSAttributedString(string: imageSimulation, attributes: imageAttributes)
        page3.attributedString = imageAttributedString
        pdfDocument.insert(page3, at: 2)
        
        return pdfDocument
    }
    
    private func createMockPDFWithFormElements() -> PDFDocument {
        let pdf = PDFDocument()
        
        // Create content that simulates form elements
        let formContent = """
        EMPLOYEE INFORMATION FORM
        
        First Name: _____________________
        Last Name: ______________________
        Employee ID: ____________________
        
        Department:
        □ Engineering    □ Marketing    □ Finance
        □ HR             □ Operations   □ Other: __________
        
        Employment Status:
        □ Full-time      □ Part-time    □ Contractor
        
        Start Date: ___/___/______
        
        Emergency Contact
        Name: _________________________
        Phone: ________________________
        Relationship: _________________
        
        Signature: ____________________    Date: ___/___/______
        """
        
        let attributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)]
        let pdfData = NSMutableAttributedString(string: formContent, attributes: attributes)
        
        let page = PDFPage(attributedString: pdfData)!
        pdf.insert(page, at: 0)
        
        return pdf
    }
    
    private func createMockPDFWithComplexFormLayout() -> PDFDocument {
        let pdfDocument = PDFDocument()
        
        // Create a complex form layout with multiple columns and form elements
        let complexFormContent = """
        EMPLOYEE PERFORMANCE REVIEW
                                                                ID: __________
                                                                Date: ___/___/______
        
        Employee Information                |  Manager Information
        ----------------------------------|----------------------------------
        Name: ________________________    |  Name: ________________________
        Department: ___________________    |  Department: ___________________
        Position: _____________________    |  Position: _____________________
        
        Performance Rating:
        
        Category                    | Below Expectations | Meets Expectations | Exceeds Expectations
        ----------------------------|-------------------|-------------------|--------------------
        Job Knowledge               |        □          |         □         |         □
        Quality of Work             |        □          |         □         |         □
        Communication Skills        |        □          |         □         |         □
        Initiative                  |        □          |         □         |         □
        Teamwork                    |        □          |         □         |         □
        
        Goals for Next Review Period:
        
        1. _________________________________________________________________________
        
        2. _________________________________________________________________________
        
        3. _________________________________________________________________________
        
        Additional Comments:
        ____________________________________________________________________________
        ____________________________________________________________________________
        ____________________________________________________________________________
        
        Signatures:
        
        Employee: _________________________    Date: ___/___/______
        
        Manager: __________________________    Date: ___/___/______
        
        HR Review: ________________________    Date: ___/___/______
        """
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        
        let attributedString = NSAttributedString(string: complexFormContent, attributes: attributes)
        let page = PDFPage()
        page.attributedString = attributedString
        pdfDocument.insert(page, at: 0)
        
        return pdfDocument
    }
} 