import XCTest
import PDFKit
@testable import Payslip_Max

class PDFProcessingServiceTests: XCTestCase {
    var pdfProcessingService: PDFProcessingServiceProtocol!
    var mockPDFService: MockPDFService!
    var mockPDFExtractor: MockPDFExtractor!
    var mockAbbreviationManager: AbbreviationManager!
    var mockParsingCoordinator: PDFParsingCoordinator!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockPDFService = MockPDFService()
        mockPDFExtractor = MockPDFExtractor()
        mockAbbreviationManager = AbbreviationManager()
        mockParsingCoordinator = PDFParsingCoordinator(abbreviationManager: mockAbbreviationManager)
        
        // Create the service with mocks
        pdfProcessingService = PDFProcessingService(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            parsingCoordinator: mockParsingCoordinator
        )
    }
    
    override func tearDown() {
        pdfProcessingService = nil
        mockPDFService = nil
        mockPDFExtractor = nil
        mockAbbreviationManager = nil
        mockParsingCoordinator = nil
        super.tearDown()
    }
    
    // MARK: - Test Initialization
    
    func testInitialization() async {
        // Test that initialization works
        XCTAssertFalse(pdfProcessingService.isInitialized, "Service should start uninitialized")
        
        // Initialize the service
        do {
            try await pdfProcessingService.initialize()
            XCTAssertTrue(pdfProcessingService.isInitialized, "Service should be initialized after initialize() call")
            XCTAssertEqual(mockPDFService.initializeCallCount, 1, "PDF service initialize should be called once")
        } catch {
            XCTFail("Initialization should not throw an error: \(error)")
        }
    }
    
    // MARK: - Test Processing from URL
    
    func testProcessPDFFromURL() async {
        // Create a test file URL
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let testFileURL = tempDirectoryURL.appendingPathComponent("test.pdf")
        
        // Create test PDF data
        let testData = "Test PDF data".data(using: .utf8)!
        
        // Write test data to file
        try? testData.write(to: testFileURL)
        
        // Mock successful result
        mockPDFService.shouldFail = false
        mockPDFService.mockPDFData = testData
        
        // Process the PDF
        let result = await pdfProcessingService.processPDF(from: testFileURL)
        
        // Verify result
        switch result {
        case .success(let data):
            XCTAssertEqual(data, testData, "Processed data should match test data")
        case .failure(let error):
            XCTFail("Processing should not fail: \(error)")
        }
        
        // Clean up
        try? fileManager.removeItem(at: testFileURL)
    }
    
    func testProcessPDFFromURLWithNonExistentFile() async {
        // Create a non-existent file URL
        let nonExistentURL = URL(fileURLWithPath: "/non/existent/path.pdf")
        
        // Process the PDF
        let result = await pdfProcessingService.processPDF(from: nonExistentURL)
        
        // Verify result
        switch result {
        case .success:
            XCTFail("Processing should fail for non-existent file")
        case .failure(let error):
            switch error {
            case .fileAccessError:
                // Expected error
                break
            default:
                XCTFail("Expected fileAccessError but got \(error)")
            }
        }
    }
    
    // MARK: - Test PDF Data Processing
    
    func testProcessPDFData() async {
        // Create test PDF data
        let testData = "Test PDF data".data(using: .utf8)!
        
        // Setup mock extractor with test response
        let testPayslip = PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000,
            debits: 1000,
            dsop: 500,
            tax: 800,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            timestamp: Date(),
            pdfData: testData
        )
        
        mockPDFExtractor.shouldFail = false
        mockPDFExtractor.parsePayslipDataFromTextResult = testPayslip
        
        // Mock service extract result
        mockPDFService.extractResult = ["page_1": "Test PDF content"]
        
        // Process the PDF data
        let result = await pdfProcessingService.processPDFData(testData)
        
        // Verify result
        switch result {
        case .success(let payslip):
            XCTAssertEqual(payslip.month, testPayslip.month, "Month should match")
            XCTAssertEqual(payslip.year, testPayslip.year, "Year should match")
            XCTAssertEqual(payslip.credits, testPayslip.credits, "Credits should match")
            XCTAssertEqual(payslip.pdfData, testData, "PDF data should match")
        case .failure(let error):
            XCTFail("Processing should not fail: \(error)")
        }
    }
    
    func testProcessPDFDataWithFailure() async {
        // Create test PDF data
        let testData = "Test PDF data".data(using: .utf8)!
        
        // Setup mocks to fail
        mockPDFExtractor.shouldFail = true
        mockPDFService.shouldFail = true
        mockPDFService.extractResult = [:]
        
        // Process the PDF data
        let result = await pdfProcessingService.processPDFData(testData)
        
        // Verify result
        switch result {
        case .success:
            XCTFail("Processing should fail when extractor and service fail")
        case .failure:
            // Expected failure
            break
        }
    }
    
    // MARK: - Test Password Protection
    
    func testIsPasswordProtected() {
        // This test would require a real PDF document for accurate testing
        // For now, we'll use mock logic to test the function
        
        // Create mock PDF data with special signature
        let passwordProtectedData = "PWDPDF:test".data(using: .utf8)!
        
        // Test the method
        let isProtected = pdfProcessingService.isPasswordProtected(passwordProtectedData)
        
        // Verify result - will be false in this case since our mock doesn't create a real PDFDocument
        XCTAssertFalse(isProtected, "Mock data should not be detected as password protected")
    }
    
    func testUnlockPDF() async {
        // Create test PDF data
        let testData = "Test PDF data".data(using: .utf8)!
        let password = "test123"
        
        // Setup mock unlock result
        mockPDFService.unlockResult = testData
        
        // Unlock the PDF
        let result = await pdfProcessingService.unlockPDF(testData, password: password)
        
        // Verify result
        switch result {
        case .success(let unlockedData):
            XCTAssertEqual(unlockedData, testData, "Unlocked data should match test data")
            XCTAssertEqual(mockPDFService.unlockCallCount, 1, "Unlock should be called once")
        case .failure(let error):
            XCTFail("Unlocking should not fail: \(error)")
        }
    }
    
    func testUnlockPDFWithIncorrectPassword() async {
        // Create test PDF data
        let testData = "Test PDF data".data(using: .utf8)!
        let password = "wrong_password"
        
        // Setup mock to fail
        mockPDFService.shouldFail = true
        
        // Unlock the PDF
        let result = await pdfProcessingService.unlockPDF(testData, password: password)
        
        // Verify result
        switch result {
        case .success:
            XCTFail("Unlocking should fail with incorrect password")
        case .failure(let error):
            XCTAssertEqual(error, .incorrectPassword, "Should return incorrectPassword error")
            XCTAssertEqual(mockPDFService.unlockCallCount, 1, "Unlock should be called once")
        }
    }
    
    // MARK: - Test Format Detection
    
    func testDetectPayslipFormat() {
        // Create test PDF data
        let militaryPDFText = "This is a test PDF for the Ministry of Defence"
        let pcdaPDFText = "This is a test PDF for the Principal Controller of Defence Accounts"
        let standardPDFText = "This is a standard PDF"
        
        // This test would require a real PDF document for accurate testing
        // For now, we'll use the internal implementation to simulate the functionality
        
        XCTAssertEqual(pdfProcessingService.detectPayslipFormat(Data()), .standard, "Empty data should return standard format")
    }
    
    // MARK: - Test Content Validation
    
    func testValidatePayslipContent() {
        // Create test PDF data
        let validPayslipText = """
        Name: Test User
        Month: January
        Year: 2024
        Earnings: 5000
        Deductions: 1000
        """
        
        let invalidPayslipText = "This is not a valid payslip"
        
        // This test would require a real PDF document for accurate testing
        // For now, we'll use mock logic to test the function
        
        let validationResult = pdfProcessingService.validatePayslipContent(Data())
        
        // Verify basic structure of the result
        XCTAssertFalse(validationResult.isValid, "Empty data should not be valid")
        XCTAssertEqual(validationResult.confidence, 0.0, "Confidence should be 0.0 for empty data")
        XCTAssertTrue(validationResult.detectedFields.isEmpty, "No fields should be detected in empty data")
        XCTAssertFalse(validationResult.missingRequiredFields.isEmpty, "Missing fields should be reported for empty data")
    }
} 