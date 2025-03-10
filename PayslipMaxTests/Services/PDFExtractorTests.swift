import XCTest
import PDFKit
@testable import Payslip_Max

final class PDFExtractorTests: XCTestCase {
    
    var sut: DefaultPDFExtractor!
    
    override func setUp() {
        super.setUp()
        sut = DefaultPDFExtractor()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testParsePayslipData() throws {
        // Given
        let sampleText = """
        Employee Name: John Doe
        Pay Date: 15/04/2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Location: New Delhi
        """
        
        // When
        let result = try sut.parsePayslipData(from: sampleText) as? PayslipItem
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "John Doe")
        XCTAssertEqual(result?.month, "April")
        XCTAssertEqual(result?.year, 2023)
        XCTAssertEqual(result?.credits, 5000.00)
        XCTAssertEqual(result?.debits, 1000.00)
        XCTAssertEqual(result?.tax, 800.00)
        XCTAssertEqual(result?.dsop, 500.00)
        XCTAssertEqual(result?.location, "New Delhi")
    }
    
    func testParsePayslipDataWithAlternativeFormat() throws {
        // Given
        let sampleText = """
        Name: Jane Smith
        Date: 2023-05-20
        Total Earnings: $6,500.50
        Deductions: $1,200.75
        Tax Deducted: $950.25
        PF: $600.50
        Office: Mumbai
        """
        
        // When
        let result = try sut.parsePayslipData(from: sampleText) as? PayslipItem
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Jane Smith")
        XCTAssertEqual(result?.month, "May")
        XCTAssertEqual(result?.year, 2023)
        XCTAssertEqual(result?.credits, 6500.50)
        XCTAssertEqual(result?.debits, 1200.75)
        XCTAssertEqual(result?.tax, 950.25)
        XCTAssertEqual(result?.dsop, 600.50)
        XCTAssertEqual(result?.location, "Mumbai")
    }
    
    func testParsePayslipDataWithMinimalInfo() throws {
        // Given
        let sampleText = """
        Some random text
        Name: Minimal Info
        Amount: 3000
        """
        
        // When
        let result = try sut.parsePayslipData(from: sampleText) as? PayslipItem
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Minimal Info")
        XCTAssertEqual(result?.credits, 3000.0)
        // Other fields should have default values
        XCTAssertEqual(result?.debits, 0.0)
        XCTAssertEqual(result?.tax, 0.0)
        XCTAssertEqual(result?.dsop, 0.0)
        XCTAssertEqual(result?.location, "")
    }
    
    func testExtractValue() throws {
        // This is a private method, so we'll test it indirectly through parsePayslipData
        
        // Given
        let sampleText = """
        Name: Test Name
        Employee Name: Should Not Extract This
        """
        
        // When
        let result = try sut.parsePayslipData(from: sampleText) as? PayslipItem
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test Name") // Should extract the first match
    }
    
    func testParseAmount() throws {
        // Test with various currency formats
        
        // Given
        let sampleText = """
        Amount: $1,234.56
        Deductions: €789.10
        Tax: ₹456.78
        """
        
        // When
        let result = try sut.parsePayslipData(from: sampleText) as? PayslipItem
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.credits, 1234.56)
        XCTAssertEqual(result?.debits, 789.10)
        XCTAssertEqual(result?.tax, 456.78)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a PDF document from text for testing.
    ///
    /// - Parameter text: The text to include in the PDF.
    /// - Returns: A PDF document.
    private func createPDFDocument(from text: String) -> PDFDocument {
        let pdfData = createPDFData(from: text)
        return PDFDocument(data: pdfData)!
    }
    
    /// Creates PDF data from text for testing.
    ///
    /// - Parameter text: The text to include in the PDF.
    /// - Returns: PDF data.
    private func createPDFData(from text: String) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(at: CGPoint(x: 10, y: 10), withAttributes: attributes)
        }
        
        return data
    }
} 