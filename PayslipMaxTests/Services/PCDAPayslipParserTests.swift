import XCTest
import PDFKit
@testable import Payslip_Max

final class PCDAPayslipParserTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: PCDAPayslipParser!
    var mockAbbreviationManager: MockAbbreviationManager!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockAbbreviationManager = MockAbbreviationManager()
        sut = PCDAPayslipParser(abbreviationManager: mockAbbreviationManager)
    }
    
    override func tearDown() {
        sut = nil
        mockAbbreviationManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testParserName() {
        XCTAssertEqual(sut.name, "PCDAPayslipParser")
    }
    
    func testParsePayslipWithEmptyPDF() {
        // Create an empty PDF document
        let emptyPDFDocument = PDFDocument()
        
        // Test parsing with empty PDF
        let result = sut.parsePayslip(pdfDocument: emptyPDFDocument)
        XCTAssertNil(result, "Parsing an empty PDF should return nil")
    }
    
    func testParsePayslipWithValidPDF() {
        // Create test PDF with sample content
        let pdfDocument = createTestPDFDocument()
        
        // Test parsing with valid PDF
        let result = sut.parsePayslip(pdfDocument: pdfDocument)
        XCTAssertNotNil(result, "Parsing a valid PDF should return a PayslipItem")
        
        // Verify extracted data
        if let payslipItem = result {
            XCTAssertEqual(payslipItem.name, "SAMPLE NAME")
            XCTAssertEqual(payslipItem.accountNumber, "12345678")
            XCTAssertEqual(payslipItem.panNumber, "ABCDE1234F")
            XCTAssertEqual(payslipItem.month, "January")
            XCTAssertEqual(payslipItem.year, 2023)
            
            // Check earnings
            XCTAssertGreaterThan(payslipItem.earnings.count, 0, "Should have parsed at least one earning")
            XCTAssertNotNil(payslipItem.earnings["BPAY"], "Basic Pay should be extracted")
            
            // Check deductions
            XCTAssertGreaterThan(payslipItem.deductions.count, 0, "Should have parsed at least one deduction")
            XCTAssertNotNil(payslipItem.deductions["DSOP"], "DSOP should be extracted")
            
            // Check totals
            XCTAssertGreaterThan(payslipItem.credits, 0, "Credits should be greater than 0")
            XCTAssertGreaterThan(payslipItem.debits, 0, "Debits should be greater than 0")
        }
    }
    
    func testEvaluateConfidenceHighConfidence() {
        let payslipItem = createSamplePayslipItem(
            name: "SAMPLE NAME",
            accountNumber: "12345678",
            credits: 50000.0,
            debits: 15000.0,
            earningsCount: 5,
            deductionsCount: 5
        )
        
        let confidence = sut.evaluateConfidence(for: payslipItem)
        XCTAssertEqual(confidence, .high, "Should have high confidence for a complete payslip")
    }
    
    func testEvaluateConfidenceMediumConfidence() {
        let payslipItem = createSamplePayslipItem(
            name: "SAMPLE NAME",
            accountNumber: "12345678",
            credits: 50000.0,
            debits: 15000.0,
            earningsCount: 1,
            deductionsCount: 1
        )
        
        let confidence = sut.evaluateConfidence(for: payslipItem)
        XCTAssertEqual(confidence, .medium, "Should have medium confidence for a partial payslip")
    }
    
    func testEvaluateConfidenceLowConfidence() {
        let payslipItem = createSamplePayslipItem(
            name: "",
            accountNumber: "",
            credits: 0.0,
            debits: 0.0,
            earningsCount: 0,
            deductionsCount: 0
        )
        
        let confidence = sut.evaluateConfidence(for: payslipItem)
        XCTAssertEqual(confidence, .low, "Should have low confidence for an incomplete payslip")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPDFDocument() -> PDFDocument {
        // Create a PDF page with test content
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let textContent = """
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
            
            let textFont = UIFont.systemFont(ofSize: 12)
            let textAttributes = [NSAttributedString.Key.font: textFont]
            
            textContent.draw(at: CGPoint(x: 50, y: 50), withAttributes: textAttributes)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        do {
            try pdfData.write(to: tempURL)
            print("Test PDF created successfully at: \(tempURL.path)")
            if let pdfDocument = PDFDocument(url: tempURL) {
                print("PDF document created with \(pdfDocument.pageCount) pages")
                return pdfDocument
            } else {
                print("Failed to create PDF document from URL")
            }
        } catch {
            print("Error creating test PDF: \(error)")
        }
        
        print("Falling back to creating an empty PDF document")
        // If we get here, something went wrong, create a direct PDF document
        let emptyDoc = PDFDocument()
        let page = PDFPage(image: UIGraphicsImageRenderer(bounds: pageRect).image { _ in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            "STATEMENT OF ACCOUNT FOR 01/23\n\nName: SAMPLE NAME\nA/C No - 12345678".draw(
                with: CGRect(x: 50, y: 50, width: 500, height: 700),
                options: .usesLineFragmentOrigin,
                attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle],
                context: nil
            )
        })
        
        emptyDoc.insert(page!, at: 0)
        print("Created fallback PDF with \(emptyDoc.pageCount) pages")
        return emptyDoc
    }
    
    private func createSamplePayslipItem(
        name: String,
        accountNumber: String,
        credits: Double,
        debits: Double,
        earningsCount: Int,
        deductionsCount: Int
    ) -> PayslipItem {
        let payslipItem = PayslipItem(
            id: UUID(),
            month: "January",
            year: 2023,
            credits: credits,
            debits: debits,
            dsop: 5000.0,
            tax: 8000.0,
            name: name,
            accountNumber: accountNumber,
            panNumber: "ABCDE1234F",
            timestamp: Date(),
            pdfData: nil
        )
        
        // Add earnings
        var earnings = [String: Double]()
        if earningsCount > 0 {
            earnings["BPAY"] = 30000.0
        }
        if earningsCount > 1 {
            earnings["DA"] = 15000.0
        }
        if earningsCount > 2 {
            earnings["HRA"] = 5000.0
        }
        if earningsCount > 3 {
            earnings["TA"] = 3000.0
        }
        if earningsCount > 4 {
            earnings["OTHER"] = 2000.0
        }
        payslipItem.earnings = earnings
        
        // Add deductions
        var deductions = [String: Double]()
        if deductionsCount > 0 {
            deductions["DSOP"] = 5000.0
        }
        if deductionsCount > 1 {
            deductions["TAX"] = 8000.0
        }
        if deductionsCount > 2 {
            deductions["OTHER"] = 2000.0
        }
        if deductionsCount > 3 {
            deductions["CGHS"] = 500.0
        }
        if deductionsCount > 4 {
            deductions["CGEIS"] = 500.0
        }
        payslipItem.deductions = deductions
        
        return payslipItem
    }
}

// MARK: - Mock Classes

// Removed duplicate MockAbbreviationManager as it's already defined in Mocks directory
// ... existing code ... 