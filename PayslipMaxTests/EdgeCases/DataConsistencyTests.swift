import XCTest
@testable import Payslip_Max

@MainActor
final class DataConsistencyTests: XCTestCase {
    
    // Systems under test
    var pdfProcessingService: PDFProcessingService!
    var mockPDFService: MockPDFService!
    var mockDataService: MockDataService!
    var mockSecurityService: MockSecurityService!
    var mockPDFExtractor: MockPDFExtractor!
    var mockParsingCoordinator: MockParsingCoordinator!
    var payslipViewModel: PayslipsViewModel!
    var testContainer: TestDIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockPDFService = MockPDFService()
        try await mockPDFService.initialize()
        
        mockDataService = MockDataService()
        try await mockDataService.initialize()
        
        mockSecurityService = MockSecurityService()
        try await mockSecurityService.initialize()
        
        mockPDFExtractor = MockPDFExtractor()
        mockParsingCoordinator = MockParsingCoordinator()
        
        // Set up the DI container with mock services
        testContainer = TestDIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        // Create services and view models
        pdfProcessingService = PDFProcessingService(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            parsingCoordinator: mockParsingCoordinator
        )
        
        payslipViewModel = PayslipsViewModel(
            dataService: mockDataService
        )
    }
    
    override func tearDown() async throws {
        payslipViewModel = nil
        pdfProcessingService = nil
        mockPDFService = nil
        mockDataService = nil
        mockSecurityService = nil
        mockPDFExtractor = nil
        mockParsingCoordinator = nil
        TestDIContainer.resetToDefault()
        try await super.tearDown()
    }
    
    // MARK: - Data Consistency Tests
    
    /// Tests that PDF data extracted from PDF service is consistent with the data saved by data service
    func testPDFDataConsistencyAcrossServices() async throws {
        // Given - Set up PDF data with specific content
        let originalPayslip = createTestPayslip()
        
        // Configure mock PDF service to extract specific data
        mockPDFService.extractResult = [
            "name": originalPayslip.name,
            "month": originalPayslip.month,
            "year": String(originalPayslip.year),
            "credits": String(originalPayslip.credits),
            "debits": String(originalPayslip.debits),
            "tax": String(originalPayslip.tax),
            "dsop": String(originalPayslip.dsop),
            "accountNumber": originalPayslip.accountNumber,
            "panNumber": originalPayslip.panNumber
        ]
        
        // When - Process a PDF and extract data
        let pdfData = createTestPDFData()
        let processingResult = await pdfProcessingService.processPDFData(pdfData)
        
        // Verify processing was successful
        switch processingResult {
        case .success(let data):
            // Extract data using the mock service (data is a PayslipItem, not Data)
            // Instead of calling extract, we'll use the data directly
            let payslipItem = data
            
            // Save the payslip
            try await mockDataService.save(payslipItem)
            
            // Fetch the saved payslip
            let savedPayslips = try await mockDataService.fetch(PayslipItem.self)
            XCTAssertEqual(savedPayslips.count, 1, "Should save one payslip item")
            
            let savedPayslip = savedPayslips[0]
            
            // Then - Verify data consistency
            XCTAssertEqual(savedPayslip.name, originalPayslip.name, "Name should be consistent")
            XCTAssertEqual(savedPayslip.month, originalPayslip.month, "Month should be consistent")
            XCTAssertEqual(savedPayslip.year, originalPayslip.year, "Year should be consistent")
            XCTAssertEqual(savedPayslip.credits, originalPayslip.credits, "Credits should be consistent")
            XCTAssertEqual(savedPayslip.debits, originalPayslip.debits, "Debits should be consistent")
            XCTAssertEqual(savedPayslip.tax, originalPayslip.tax, "Tax should be consistent")
            XCTAssertEqual(savedPayslip.dsop, originalPayslip.dsop, "DSOP should be consistent")
            XCTAssertEqual(savedPayslip.accountNumber, originalPayslip.accountNumber, "Account number should be consistent")
            XCTAssertEqual(savedPayslip.panNumber, originalPayslip.panNumber, "PAN should be consistent")
            
        case .failure(let error):
            XCTFail("PDF processing failed with error: \(error)")
        }
    }
    
    /// Tests data consistency through encryption and decryption operations
    func testDataConsistencyThroughEncryptionDecryption() async throws {
        // Given
        let originalPayslip = createTestPayslip()
        
        // When - Encrypt sensitive data
        try originalPayslip.encryptSensitiveData()
        
        // Verify encryption changed the sensitive fields
        XCTAssertNotEqual(originalPayslip.name, "John Doe", "Name should be encrypted")
        XCTAssertNotEqual(originalPayslip.accountNumber, "1234567890", "Account number should be encrypted")
        XCTAssertNotEqual(originalPayslip.panNumber, "ABCDE1234F", "PAN should be encrypted")
        
        // Save the encrypted payslip
        try await mockDataService.save(originalPayslip)
        
        // Fetch the saved payslip
        let savedPayslips = try await mockDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1, "Should save one payslip item")
        
        let savedPayslip = savedPayslips[0]
        
        // Verify non-sensitive fields remain consistent
        XCTAssertEqual(savedPayslip.month, "January", "Month should be consistent")
        XCTAssertEqual(savedPayslip.year, 2023, "Year should be consistent")
        XCTAssertEqual(savedPayslip.credits, 5000.0, "Credits should be consistent")
        XCTAssertEqual(savedPayslip.debits, 1000.0, "Debits should be consistent")
        XCTAssertEqual(savedPayslip.tax, 800.0, "Tax should be consistent")
        XCTAssertEqual(savedPayslip.dsop, 300.0, "DSOP should be consistent")
        
        // Decrypt the sensitive data
        try savedPayslip.decryptSensitiveData()
        
        // Then - Verify data consistency after decryption
        XCTAssertEqual(savedPayslip.name, "John Doe", "Name should be decrypted correctly")
        XCTAssertEqual(savedPayslip.accountNumber, "1234567890", "Account number should be decrypted correctly")
        XCTAssertEqual(savedPayslip.panNumber, "ABCDE1234F", "PAN should be decrypted correctly")
    }
    
    /// Tests data consistency between ViewModel and Model layers
    func testDataConsistencyBetweenViewModelAndModel() async throws {
        // Given
        let originalPayslip = createTestPayslip()
        
        // Save the payslip directly using data service
        try await mockDataService.save(originalPayslip)
        
        // When - Load payslips through view model
        await payslipViewModel.loadPayslips()
        
        // Then - Verify consistency between VM and model
        XCTAssertEqual(payslipViewModel.payslips.count, 1, "ViewModel should have one payslip")
        
        let viewModelPayslip = payslipViewModel.payslips[0]
        XCTAssertEqual(viewModelPayslip.id, originalPayslip.id, "ID should be consistent")
        XCTAssertEqual(viewModelPayslip.name, originalPayslip.name, "Name should be consistent")
        XCTAssertEqual(viewModelPayslip.month, originalPayslip.month, "Month should be consistent")
        XCTAssertEqual(viewModelPayslip.year, originalPayslip.year, "Year should be consistent")
        XCTAssertEqual(viewModelPayslip.credits, originalPayslip.credits, "Credits should be consistent")
        XCTAssertEqual(viewModelPayslip.debits, originalPayslip.debits, "Debits should be consistent")
        XCTAssertEqual(viewModelPayslip.tax, originalPayslip.tax, "Tax should be consistent")
        XCTAssertEqual(viewModelPayslip.dsop, originalPayslip.dsop, "DSOP should be consistent")
        XCTAssertEqual(viewModelPayslip.accountNumber, originalPayslip.accountNumber, "Account number should be consistent")
        XCTAssertEqual(viewModelPayslip.panNumber, originalPayslip.panNumber, "PAN should be consistent")
    }
    
    /// Tests data consistency through round trip flow: extract->encrypt->save->load->decrypt
    func testDataConsistencyThroughFullRoundTrip() async throws {
        // Given - Set up PDF extraction
        let originalPayslip = createTestPayslip()
        
        // Configure mock services
        mockPDFService.extractResult = [
            "name": originalPayslip.name,
            "month": originalPayslip.month,
            "year": String(originalPayslip.year),
            "credits": String(originalPayslip.credits),
            "debits": String(originalPayslip.debits),
            "tax": String(originalPayslip.tax),
            "dsop": String(originalPayslip.dsop),
            "accountNumber": originalPayslip.accountNumber,
            "panNumber": originalPayslip.panNumber
        ]
        
        // When - Process a PDF
        let pdfData = createTestPDFData()
        let processingResult = await pdfProcessingService.processPDFData(pdfData)
        
        // Verify processing was successful
        switch processingResult {
        case .success(let payslipItem):
            // 2. Encrypt sensitive data
            try payslipItem.encryptSensitiveData()
            
            // 3. Save the encrypted payslip
            try await mockDataService.save(payslipItem)
            
            // 4. Load payslips through view model
            await payslipViewModel.loadPayslips()
            
            // Verify view model has the payslip
            XCTAssertEqual(payslipViewModel.payslips.count, 1, "ViewModel should have one payslip")
            
            let viewModelPayslip = payslipViewModel.payslips[0]
            
            // 5. Decrypt the sensitive data
            try viewModelPayslip.decryptSensitiveData()
            
            // Then - Verify consistency through the full round trip
            XCTAssertEqual(viewModelPayslip.name, originalPayslip.name, "Name should be consistent")
            XCTAssertEqual(viewModelPayslip.month, originalPayslip.month, "Month should be consistent")
            XCTAssertEqual(viewModelPayslip.year, originalPayslip.year, "Year should be consistent")
            XCTAssertEqual(viewModelPayslip.credits, originalPayslip.credits, "Credits should be consistent")
            XCTAssertEqual(viewModelPayslip.debits, originalPayslip.debits, "Debits should be consistent")
            XCTAssertEqual(viewModelPayslip.tax, originalPayslip.tax, "Tax should be consistent")
            XCTAssertEqual(viewModelPayslip.dsop, originalPayslip.dsop, "DSOP should be consistent")
            XCTAssertEqual(viewModelPayslip.accountNumber, originalPayslip.accountNumber, "Account number should be consistent")
            XCTAssertEqual(viewModelPayslip.panNumber, originalPayslip.panNumber, "PAN should be consistent")
            
        case .failure(let error):
            XCTFail("PDF processing failed with error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test payslip for consistent testing
    private func createTestPayslip() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            timestamp: Date(),
            pdfData: nil
        )
    }
    
    /// Creates test PDF data
    private func createTestPDFData() -> Data {
        let sampleText = """
        Employee Name: John Doe
        Month: January
        Year: 2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 300.00
        Account No: 1234567890
        PAN: ABCDE1234F
        """
        
        return createPDFData(from: sampleText)
    }
    
    /// Creates a PDF data from text
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