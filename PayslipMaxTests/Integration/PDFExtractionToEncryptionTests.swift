import XCTest
import PDFKit
@testable import Payslip_Max
import PayslipMaxTestMocks

@MainActor
final class PDFExtractionToEncryptionTests: XCTestCase {
    
    // System under test
    var pdfExtractor: DefaultPDFExtractor!
    var mockEncryptionService: MockEncryptionService!
    var mockDataService: MockDataServiceHelper!
    var testContainer: TestDIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockEncryptionService = MockEncryptionService()
        mockDataService = MockDataServiceHelper()
        
        // Set up the factory to use our mock
        PayslipItem.setEncryptionServiceFactory { [unowned self] in
            return self.mockEncryptionService! as EncryptionServiceProtocolInternal
        }
        
        // Set up the DI container with mock services
        testContainer = TestDIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        // Create the PDF extractor
        pdfExtractor = DefaultPDFExtractor()
    }
    
    override func tearDown() async throws {
        // Reset the factory to default implementation
        PayslipItem.resetEncryptionServiceFactory()
        
        pdfExtractor = nil
        mockEncryptionService = nil
        mockDataService = nil
        TestDIContainer.resetToDefault()
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testCompleteFlowFromPDFExtractionToEncryption() async throws {
        // Given
        let sampleText = """
        Employee Name: John Doe
        Pay Date: 15/04/2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Account No: 1234567890
        PAN: ABCDE1234F
        """
        
        let pdfDocument = createPDFDocument(from: sampleText)
        
        // Reset the counts before testing
        mockEncryptionService.encryptionCount = 0
        mockEncryptionService.decryptionCount = 0
        
        // When - Extract data from PDF
        let extractedPayslip = pdfExtractor.extractPayslipData(from: pdfDocument)!
        
        // Then - Verify extraction was successful
        XCTAssertEqual(extractedPayslip.name, "John Doe")
        XCTAssertEqual(extractedPayslip.month, "April")
        XCTAssertEqual(extractedPayslip.year, 2023)
        XCTAssertEqual(extractedPayslip.credits, 5000.00)
        XCTAssertEqual(extractedPayslip.debits, 1000.00)
        XCTAssertEqual(extractedPayslip.tax, 800.00)
        XCTAssertEqual(extractedPayslip.dsop, 500.00)
        XCTAssertEqual(extractedPayslip.accountNumber, "1234567890")
        XCTAssertEqual(extractedPayslip.panNumber, "ABCDE1234F")
        
        // When - Encrypt sensitive data
        try extractedPayslip.encryptSensitiveData()
        
        // Then - Verify encryption was called for sensitive fields
        XCTAssertEqual(mockEncryptionService.encryptionCount, 3, "Encryption should be called 3 times (name, accountNumber, panNumber)")
        
        // Verify the sensitive data was encrypted
        XCTAssertNotEqual(extractedPayslip.name, "John Doe")
        XCTAssertNotEqual(extractedPayslip.accountNumber, "1234567890")
        XCTAssertNotEqual(extractedPayslip.panNumber, "ABCDE1234F")
        
        // When - Save to data service
        try await mockDataService.save(extractedPayslip)
        
        // Then - Verify save was called
        XCTAssertEqual(mockDataService.saveCount, 1, "Save should be called once")
        XCTAssertEqual(mockDataService.testPayslips.count, 1, "One payslip should be saved")
        
        // When - Fetch from data service
        let fetchedPayslips = try await mockDataService.fetch(PayslipItem.self)
        
        // Then - Verify fetch was successful
        XCTAssertEqual(fetchedPayslips.count, 1, "One payslip should be fetched")
        
        let fetchedPayslip = fetchedPayslips[0]
        
        // Verify the fetched payslip has encrypted data
        XCTAssertNotEqual(fetchedPayslip.name, "John Doe")
        XCTAssertNotEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertNotEqual(fetchedPayslip.panNumber, "ABCDE1234F")
        
        // Reset the counts before testing decryption
        mockEncryptionService.encryptionCount = 0
        mockEncryptionService.decryptionCount = 0
        
        // When - Decrypt sensitive data
        try fetchedPayslip.decryptSensitiveData()
        
        // Then - Verify decryption was called for sensitive fields
        XCTAssertEqual(mockEncryptionService.decryptionCount, 3, "Decryption should be called 3 times (name, accountNumber, panNumber)")
        
        // Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(fetchedPayslip.name, "John Doe")
        XCTAssertEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertEqual(fetchedPayslip.panNumber, "ABCDE1234F")
    }
    
    func testErrorHandlingInCompleteFlow() async throws {
        // Given
        let sampleText = """
        Employee Name: John Doe
        Pay Date: 15/04/2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Account No: 1234567890
        PAN: ABCDE1234F
        """
        
        let pdfDocument = createPDFDocument(from: sampleText)
        
        // When - Extract data from PDF
        let extractedPayslip = pdfExtractor.extractPayslipData(from: pdfDocument)!
        
        // Set the mock to fail
        mockEncryptionService.shouldFailEncryption = true
        
        // Then - Verify that encryption throws an error
        XCTAssertThrowsError(try extractedPayslip.encryptSensitiveData()) { error in
            // Print the actual error type for debugging
            print("Actual error type: \(type(of: error)), error: \(error)")
            
            // Verify that the error is of the expected type
            XCTAssertTrue(error is EncryptionService.EncryptionError, "Error should be an EncryptionService.EncryptionError")
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .encryptionFailed, "Error should be encryptionFailed")
            }
        }
        
        // Set the data service to fail
        mockDataService.shouldFailSave = true
        
        // Then - Verify that saving throws an error
        do {
            try await mockDataService.save(extractedPayslip)
            XCTFail("Save should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError, "Error should be a MockError")
            if let mockError = error as? MockError {
                XCTAssertEqual(mockError, MockError.saveFailed, "Error should be saveFailed")
            }
        }
    }
    
    func testAlternativeFormatExtraction() async throws {
        // Given
        let sampleText = """
        Name: Jane Smith
        Date: 2023-05-20
        Total Earnings: $6,500.50
        Deductions: $1,200.75
        Tax Deducted: $950.25
        PF: $600.50
        Office: Mumbai
        Account Number: 9876543210
        PAN No: ZYXWV9876G
        """
        
        let pdfDocument = createPDFDocument(from: sampleText)
        
        // When - Extract data from PDF
        let extractedPayslip = pdfExtractor.extractPayslipData(from: pdfDocument)!
        
        // Then - Verify extraction was successful with alternative format
        XCTAssertEqual(extractedPayslip.name, "Jane Smith")
        XCTAssertEqual(extractedPayslip.month, "May")
        XCTAssertEqual(extractedPayslip.year, 2023)
        XCTAssertEqual(extractedPayslip.credits, 6500.50)
        XCTAssertEqual(extractedPayslip.debits, 1200.75)
        XCTAssertEqual(extractedPayslip.tax, 950.25)
        XCTAssertEqual(extractedPayslip.dsop, 600.50)
        XCTAssertEqual(extractedPayslip.accountNumber, "9876543210")
        XCTAssertEqual(extractedPayslip.panNumber, "ZYXWV9876G")
        
        // When - Encrypt sensitive data
        try extractedPayslip.encryptSensitiveData()
        
        // Then - Verify the sensitive data was encrypted
        XCTAssertNotEqual(extractedPayslip.name, "Jane Smith")
        XCTAssertNotEqual(extractedPayslip.accountNumber, "9876543210")
        XCTAssertNotEqual(extractedPayslip.panNumber, "ZYXWV9876G")
        
        // When - Save to data service
        try await mockDataService.save(extractedPayslip)
        
        // Then - Verify save was called
        XCTAssertEqual(mockDataService.saveCount, 1, "Save should be called once")
        
        // When - Decrypt sensitive data
        try extractedPayslip.decryptSensitiveData()
        
        // Then - Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(extractedPayslip.name, "Jane Smith")
        XCTAssertEqual(extractedPayslip.accountNumber, "9876543210")
        XCTAssertEqual(extractedPayslip.panNumber, "ZYXWV9876G")
    }
    
    func testMinimalInfoExtraction() async throws {
        // Given
        let sampleText = """
        Some random text
        Name: Minimal Info
        Amount: 3000
        """
        
        let pdfDocument = createPDFDocument(from: sampleText)
        
        // When - Extract data from PDF
        let extractedPayslip = pdfExtractor.extractPayslipData(from: pdfDocument)!
        
        // Then - Verify extraction was successful with minimal info
        XCTAssertEqual(extractedPayslip.name, "Minimal Info")
        XCTAssertEqual(extractedPayslip.credits, 3000.0)
        // Other fields should have default values
        XCTAssertEqual(extractedPayslip.debits, 0.0)
        XCTAssertEqual(extractedPayslip.tax, 0.0)
        XCTAssertEqual(extractedPayslip.dsop, 0.0)
        
        // When - Encrypt sensitive data
        try extractedPayslip.encryptSensitiveData()
        
        // Then - Verify the sensitive data was encrypted
        XCTAssertNotEqual(extractedPayslip.name, "Minimal Info")
        
        // When - Save to data service
        try await mockDataService.save(extractedPayslip)
        
        // Then - Verify save was called
        XCTAssertEqual(mockDataService.saveCount, 1, "Save should be called once")
        
        // When - Decrypt sensitive data
        try extractedPayslip.decryptSensitiveData()
        
        // Then - Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(extractedPayslip.name, "Minimal Info")
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