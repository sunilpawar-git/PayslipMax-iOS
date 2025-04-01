import XCTest
import PDFKit
@testable import Payslip_Max

@MainActor
final class PDFProcessingEdgeCaseTests: XCTestCase {
    
    // System under test
    var pdfProcessingService: PDFProcessingService!
    var mockPDFService: MockPDFService!
    var mockPDFExtractor: MockPDFExtractor!
    var mockParsingCoordinator: MockParsingCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockPDFService = MockPDFService()
        try await mockPDFService.initialize()
        
        mockPDFExtractor = MockPDFExtractor()
        mockParsingCoordinator = MockParsingCoordinator()
        
        // Create the PDF processing service
        pdfProcessingService = PDFProcessingService(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            parsingCoordinator: mockParsingCoordinator
        )
    }
    
    override func tearDown() async throws {
        pdfProcessingService = nil
        mockPDFService = nil
        mockPDFExtractor = nil
        mockParsingCoordinator = nil
        try await super.tearDown()
    }
    
    // MARK: - Edge Case Tests
    
    /// Tests handling of a PDF with zero-byte content but still valid PDF structure
    func testProcessingMinimalValidPDF() async {
        // Create a minimal valid PDF structure
        // %PDF-1.4 header and %%EOF trailer are minimal requirements
        let minimalPDF = "%PDF-1.4\n%%EOF".data(using: .utf8)!
        mockPDFService.mockPDFData = minimalPDF
        
        // Setup a mock PayslipItem to return
        let mockPayslip = PayslipItem(
            id: UUID(),
            month: "Jan",
            year: 2023,
            credits: 100, 
            debits: 50,
            dsop: 5,
            tax: 10,
            name: "Test",
            accountNumber: "123",
            panNumber: "ABC"
        )
        mockParsingCoordinator.parsePayslipResult = mockPayslip
        
        let result = await pdfProcessingService.processPDFData(minimalPDF)
        
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.name, mockPayslip.name, "Should return the mock payslip item")
        case .failure:
            XCTFail("Should process a minimal valid PDF structure")
        }
    }
    
    /// Tests handling of a PDF with binary corruption in the middle
    func testProcessingPartiallyCorruptPDF() async {
        // Start with valid PDF structure but corrupt the middle
        let validStart = "%PDF-1.4\n1 0 obj\n<<>>\nendobj\n"
        let validEnd = "trailer\n<<>>\n%%EOF"
        let corruption = Data([0xFF, 0x00, 0xAA, 0xBB]) // Binary corruption
        
        var corruptData = validStart.data(using: .utf8)!
        corruptData.append(corruption)
        corruptData.append(validEnd.data(using: .utf8)!)
        
        mockPDFService.mockPDFData = corruptData
        mockPDFService.shouldFail = true
        
        let result = await pdfProcessingService.processPDFData(corruptData)
        
        switch result {
        case .success:
            XCTFail("Should fail with corrupted PDF")
        case .failure(let error):
            XCTAssertEqual(error, .invalidPDFData, "Should return invalidPDFData error for corrupted PDF")
        }
    }
    
    /// Tests handling of a very large PDF that might strain system resources
    func testProcessingVeryLargePDF() async {
        // Simulate a large PDF by creating a large string
        let pageContent = String(repeating: "Large content for stress testing. ", count: 1000)
        let fullContent = "%PDF-1.4\n" + pageContent + "\n%%EOF"
        let largeData = fullContent.data(using: .utf8)!
        
        mockPDFService.mockPDFData = largeData
        
        // Setup a mock PayslipItem to return
        let mockPayslip = PayslipItem(
            id: UUID(),
            month: "Feb",
            year: 2023,
            credits: 200, 
            debits: 100,
            dsop: 10,
            tax: 20,
            name: "Large Test",
            accountNumber: "456",
            panNumber: "DEF"
        )
        mockParsingCoordinator.parsePayslipResult = mockPayslip
        
        let result = await pdfProcessingService.processPDFData(largeData)
        
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.name, mockPayslip.name, "Should handle large PDF data")
        case .failure:
            XCTFail("Should process large PDF data")
        }
    }
    
    /// Tests handling of PDF with unusual or special characters
    func testProcessingPDFWithSpecialCharacters() async {
        // PDF with special/non-ASCII characters
        let specialChars = "%PDF-1.4\nName: Jöhn Dœ\nAmount: €5000\nSymbol: ™®©\n%%EOF"
        let specialData = specialChars.data(using: .utf8)!
        
        mockPDFService.mockPDFData = specialData
        
        // Setup a mock PayslipItem to return
        let mockPayslip = PayslipItem(
            id: UUID(),
            month: "Mar",
            year: 2023,
            credits: 5000, 
            debits: 1000,
            dsop: 300,
            tax: 800,
            name: "Jöhn Dœ",
            accountNumber: "789",
            panNumber: "GHI"
        )
        mockParsingCoordinator.parsePayslipResult = mockPayslip
        
        let result = await pdfProcessingService.processPDFData(specialData)
        
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.name, mockPayslip.name, "Should handle special characters")
        case .failure:
            XCTFail("Should process PDF with special characters")
        }
    }
    
    /// Tests handling of PDF with malformed internal structure but valid header/footer
    func testProcessingMalformedInternalStructure() async {
        // PDF with valid header/footer but invalid internal structure
        let malformedPDF = "%PDF-1.4\nThis is not valid PDF object structure\n%%EOF"
        let malformedData = malformedPDF.data(using: .utf8)!
        
        mockPDFService.mockPDFData = malformedData
        mockPDFService.shouldFail = true
        
        let result = await pdfProcessingService.processPDFData(malformedData)
        
        switch result {
        case .success:
            XCTFail("Should fail with malformed PDF internal structure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidPDFData, "Should return invalidPDFData error for malformed internal structure")
        }
    }
    
    /// Tests handling of PDF with multiple embedded unexpected file formats
    func testProcessingPDFWithEmbeddedFormats() async {
        // PDF with embedded formats (like XML inside PDF)
        let mixedFormatPDF = """
        %PDF-1.4
        <xml>
            <data>Test</data>
        </xml>
        {
            "json": "test"
        }
        %%EOF
        """
        let mixedData = mixedFormatPDF.data(using: .utf8)!
        
        mockPDFService.mockPDFData = mixedData
        
        // Setup a mock PayslipItem to return
        let mockPayslip = PayslipItem(
            id: UUID(),
            month: "Apr",
            year: 2023,
            credits: 300, 
            debits: 150,
            dsop: 15,
            tax: 30,
            name: "Mixed Format",
            accountNumber: "101",
            panNumber: "JKL"
        )
        mockParsingCoordinator.parsePayslipResult = mockPayslip
        
        let result = await pdfProcessingService.processPDFData(mixedData)
        
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.name, mockPayslip.name, "Should handle PDF with embedded formats")
        case .failure:
            XCTFail("Should process PDF with embedded formats")
        }
    }
    
    /// Tests handling of PDF with potential security exploits
    func testProcessingPDFWithPotentialExploits() async {
        // PDF with content that might be seen as security exploits
        let exploitPDF = """
        %PDF-1.4
        %javascript code
        <script>
        alert('test');
        </script>
        %SQL injection attempt
        ' OR 1=1; --
        %%EOF
        """
        let exploitData = exploitPDF.data(using: .utf8)!
        
        mockPDFService.mockPDFData = exploitData
        
        // Setup a mock PayslipItem to return
        let mockPayslip = PayslipItem(
            id: UUID(),
            month: "May",
            year: 2023,
            credits: 400, 
            debits: 200,
            dsop: 20,
            tax: 40,
            name: "Security Test",
            accountNumber: "202",
            panNumber: "MNO"
        )
        mockParsingCoordinator.parsePayslipResult = mockPayslip
        
        let result = await pdfProcessingService.processPDFData(exploitData)
        
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.name, mockPayslip.name, "Should handle PDF with potential exploit content")
        case .failure:
            XCTFail("Should process PDF with potential exploit content")
        }
    }
    
    // Helper method to create a PDF document from text for testing
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