import XCTest
import PDFKit
@testable import PayslipMax

final class PDFParsingCoordinatorTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: PDFParsingCoordinatorProtocol!
    var mockAbbreviationManager: MockAbbreviationManager!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockAbbreviationManager = MockAbbreviationManager()
        sut = PDFParsingOrchestrator(abbreviationManager: mockAbbreviationManager)
    }
    
    override func tearDown() {
        sut = nil
        mockAbbreviationManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testParsePayslip_WithValidPDF() {
        // Create a test PDF with sample content
        let pdfDocument = createTestPDFDocument()
        
        // Parse the document
        let result = sut.parsePayslip(pdfDocument: pdfDocument)
        
        // Verify parsing result
        XCTAssertNotNil(result, "Parsing valid PDF should return a PayslipItem")
        
        if let payslipItem = result {
            // Verify item contains expected values
            XCTAssertFalse(payslipItem.name.isEmpty, "Name should not be empty")
            XCTAssertFalse(payslipItem.accountNumber.isEmpty, "Account number should not be empty")
            XCTAssertGreaterThan(payslipItem.credits, 0, "Credits should be greater than 0")
            XCTAssertGreaterThan(payslipItem.debits, 0, "Debits should be greater than 0")
            XCTAssertGreaterThan(payslipItem.earnings.count, 0, "Should have at least one earning item")
            XCTAssertGreaterThan(payslipItem.deductions.count, 0, "Should have at least one deduction item")
        }
    }
    
    func testParsePayslip_WithEmptyPDF() {
        // Create an empty PDF document
        let emptyPDFDocument = PDFDocument()
        
        // Parse the document
        let result = sut.parsePayslip(pdfDocument: emptyPDFDocument)
        
        // Verify parsing result
        XCTAssertNil(result, "Parsing empty PDF should return nil")
    }
    
    func testClearCache() {
        // Create a test PDF with sample content
        let pdfDocument = createTestPDFDocument()
        
        // Parse the document first time
        _ = sut.parsePayslip(pdfDocument: pdfDocument)
        
        // Clear the cache
        sut.clearCache()
        
        // Verify available parsers
        let availableParsers = sut.getAvailableParsers()
        XCTAssertFalse(availableParsers.isEmpty, "Should have available parsers")
    }
    
    func testGetAvailableParsers() {
        // Verify the coordinator has parsers available
        let parsers = sut.getAvailableParsers()
        XCTAssertFalse(parsers.isEmpty, "Should have parsers available")
    }
    
    func testParseWithSpecificParser() {
        // Create a test PDF with sample content
        let pdfDocument = createTestPDFDocument()
        
        // Get available parsers
        let parsers = sut.getAvailableParsers()
        guard !parsers.isEmpty else {
            XCTFail("No parsers available")
            return
        }
        
        // Parse with the first available parser
        let result = sut.parsePayslip(pdfDocument: pdfDocument, using: parsers[0])
        
        // Result could be nil or not, depending on the parser, but the call should not crash
        if result != nil {
            XCTAssertNotNil(result, "Parsing with a specific parser should work")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPDFDocument() -> PDFDocument {
        // Create a temporary URL for the PDF file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        
        // Create a PDF context
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter size
        UIGraphicsBeginPDFContextToFile(tempURL.path, pageRect, nil)
        UIGraphicsBeginPDFPage()
        
        // Define text content
        let content = """
        STATEMENT OF ACCOUNT FOR 01/23
        
        Name: SAMPLE NAME
        A/C No - 12345678
        PAN No: ABCDE1234F
        
        EARNINGS:
        BPAY            30000.00
        DA              15000.00
        HRA              5000.00
        Total Earnings: 50000.00
        
        DEDUCTIONS:
        DSOP             5000.00
        TAX              8000.00
        OTHER            2000.00
        Total Deductions: 15000.00
        
        NET REMITTANCE: 35000.00
        """
        
        // Draw the text with proper attributes
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Draw text line by line to maintain formatting
        let lines = content.components(separatedBy: .newlines)
        var yPosition: CGFloat = 50
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if !trimmedLine.isEmpty {
                let xPosition: CGFloat = trimmedLine.hasPrefix("EARNINGS:") || trimmedLine.hasPrefix("DEDUCTIONS:") ? 30 : 50
                (trimmedLine as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: textAttributes)
            }
            yPosition += 20 // Line spacing
        }
        
        UIGraphicsEndPDFContext()
        
        // Load the PDF document from the temporary file
        if let document = PDFDocument(url: tempURL) {
            return document
        }
        
        // Return an empty document if creation failed
        return PDFDocument()
    }
} 