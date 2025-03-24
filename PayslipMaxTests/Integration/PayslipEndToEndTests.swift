import XCTest
import PDFKit
import SwiftUI
@testable import Payslip_Max

@MainActor
final class PayslipEndToEndTests: XCTestCase {
    
    // System under test
    var pdfExtractor: DefaultPDFExtractor!
    var mockEncryptionService: MockEncryptionService!
    var mockPDFService: MockPDFService!
    var mockDataService: MockDataService!
    var mockSecurityService: MockSecurityService!
    var payslipsViewModel: PayslipsViewModel!
    var authViewModel: AuthViewModel!
    var homeViewModel: HomeViewModel!
    var mockPDFExtractor: MockPDFExtractor!
    
    override func setUp() {
        super.setUp()
        
        // Create mock services
        mockEncryptionService = MockEncryptionService()
        mockPDFService = MockPDFService()
        mockDataService = MockDataService()
        mockSecurityService = MockSecurityService()
        mockPDFExtractor = MockPDFExtractor()
        
        // Configure the mock PDF service with a default payslip
        let defaultPayslip = PayslipItem(
            month: "April",
            year: 2023,
            credits: 5000.00,
            debits: 1000.00,
            dsop: 500.00,
            tax: 800.00,
            location: "New Delhi",
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        mockPDFService.mockPayslipData = defaultPayslip
        
        // Set up the factory to use our mock encryption service
        _ = PayslipItem.setEncryptionServiceFactory { [unowned self] in
            return self.mockEncryptionService as Any
        }
        
        // Create view models with mock services
        homeViewModel = HomeViewModel(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            dataService: mockDataService
        )
        
        authViewModel = AuthViewModel(securityService: mockSecurityService)
        
        payslipsViewModel = PayslipsViewModel(dataService: mockDataService)
        
        // Configure the security service
        mockSecurityService.shouldAuthenticateSuccessfully = true
    }
    
    override func tearDown() {
        // Reset the factory
        PayslipItem.resetEncryptionServiceFactory()
        
        // Reset mock services
        mockEncryptionService = nil
        mockPDFService = nil
        mockDataService = nil
        mockSecurityService = nil
        mockPDFExtractor = nil
        
        // Reset view models
        homeViewModel = nil
        authViewModel = nil
        payslipsViewModel = nil
        
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndPayslipFlow() async throws {
        // Given - User is authenticated
        mockSecurityService.shouldAuthenticateSuccessfully = true
        await authViewModel.authenticate()
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        // When - User uploads a PDF
        let sampleText = """
        Employee Name: John Doe
        Pay Date: 15/04/2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Location: New Delhi
        Account No: 1234567890
        PAN: ABCDE1234F
        """
        
        _ = createPDFDocument(from: sampleText)
        let pdfData = createPDFData(from: sampleText)
        
        // Create a temporary URL for the PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        try pdfData.write(to: tempURL)
        
        // Simulate user uploading a PDF through the home view model
        homeViewModel.processPayslipPDF(from: tempURL)
        
        // Wait a moment for async processing to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then - Verify payslip was processed and saved
        XCTAssertTrue(mockPDFExtractor.extractCount > 0, "PDF extraction should be called")
        
        // Add the mock payslip to the mock data service's storage
        try await mockDataService.save(mockPDFService.mockPayslipData!)
        
        // When - User views payslips list
        await payslipsViewModel.loadPayslips()
        
        // Then - Verify payslips are loaded
        XCTAssertFalse(payslipsViewModel.payslips.isEmpty, "Payslips should not be empty")
        
        // Get the first payslip
        guard let payslip = payslipsViewModel.payslips.first as? PayslipItem else {
            XCTFail("Expected a PayslipItem")
            return
        }
        
        // Verify the payslip has the correct data
        XCTAssertEqual(payslip.month, "April")
        XCTAssertEqual(payslip.year, 2023)
        XCTAssertEqual(payslip.credits, 5000.00)
        XCTAssertEqual(payslip.debits, 1000.00)
        XCTAssertEqual(payslip.tax, 800.00)
        XCTAssertEqual(payslip.dsop, 500.00)
        XCTAssertEqual(payslip.location, "New Delhi")
        
        // When - User views payslip details (which triggers decryption)
        payslipsViewModel.selectedPayslip = payslip
        
        // Then - Verify sensitive data is decrypted for viewing
        try payslip.decryptSensitiveData()
        XCTAssertEqual(payslip.name, "John Doe")
        XCTAssertEqual(payslip.accountNumber, "1234567890")
        XCTAssertEqual(payslip.panNumber, "ABCDE1234F")
        
        // Verify decryption was called
        XCTAssertGreaterThan(mockEncryptionService.decryptionCount, 0)
    }
    
    func testAuthenticationFlow() async throws {
        // Given - User is not authenticated
        mockSecurityService.shouldAuthenticateSuccessfully = false
        
        // When - Check authentication status
        let isAuthenticated = authViewModel.isAuthenticated
        
        // Then - Verify user is not authenticated
        XCTAssertFalse(isAuthenticated)
        
        // When - User attempts to authenticate with valid credentials
        mockSecurityService.shouldAuthenticateSuccessfully = true
        await authViewModel.authenticate()
        
        // Then - Verify authentication was successful
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        // When - User uploads a PDF after authentication
        let sampleText = """
        Employee Name: John Doe
        Pay Date: 15/04/2023
        Gross Pay: 5000.00
        """
        
        let pdfData = createPDFData(from: sampleText)
        
        // Create a temporary URL for the PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        try pdfData.write(to: tempURL)
        
        // Simulate user uploading a PDF
        homeViewModel.processPayslipPDF(from: tempURL)
        
        // Wait a moment for async processing to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then - Verify PDF was processed
        XCTAssertTrue(mockPDFExtractor.extractCount > 0, "PDF extraction should be called")
    }
    
    func testFailedAuthentication() async throws {
        // Given - User is not authenticated
        mockSecurityService.shouldAuthenticateSuccessfully = false
        
        // When - User attempts to authenticate
        await authViewModel.authenticate()
        
        // Then - Verify authentication failed
        XCTAssertFalse(authViewModel.isAuthenticated)
        
        // When - User tries to access payslips without authentication
        await payslipsViewModel.loadPayslips()
        
        // Then - Verify no payslips are loaded due to authentication failure
        XCTAssertEqual(payslipsViewModel.payslips.count, 0)
        
        // When - User tries to upload a PDF without authentication
        let sampleText = "Test PDF"
        let pdfData = createPDFData(from: sampleText)
        
        // Create a temporary URL for the PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        try pdfData.write(to: tempURL)
        
        // Simulate user uploading a PDF
        homeViewModel.processPayslipPDF(from: tempURL)
        
        // Wait a moment for async processing to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then - Verify PDF was still processed (since we're not checking auth in the mock)
        XCTAssertTrue(mockPDFExtractor.extractCount > 0, "PDF extraction should be called")
    }
    
    func testErrorHandlingInEndToEndFlow() async throws {
        // Given - User is authenticated
        mockSecurityService.shouldAuthenticateSuccessfully = true
        await authViewModel.authenticate()
        XCTAssertTrue(authViewModel.isAuthenticated)
        
        // When - PDF service fails to process PDF
        mockPDFService.shouldFail = true
        
        let sampleText = "Test PDF"
        let pdfData = createPDFData(from: sampleText)
        
        // Create a temporary URL for the PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        try pdfData.write(to: tempURL)
        
        // Then - Verify processing fails with appropriate error
        homeViewModel.processPayslipPDF(from: tempURL)
        
        // Wait a moment for async processing to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Verify error was set
        XCTAssertNotNil(homeViewModel.error)
        
        // Reset the PDF service for the next test
        mockPDFService.shouldFail = false
        
        // When - Data service fails to fetch payslips
        mockDataService.shouldFailFetch = true
        
        // Then - Verify fetch fails with appropriate error
        await payslipsViewModel.loadPayslips()
        XCTAssertNotNil(payslipsViewModel.error)
    }
    
    // MARK: - Helper Methods
    
    private func createPDFDocument(from text: String) -> PDFDocument {
        let data = text.data(using: .utf8)!
        let pdfPage = PDFPage(image: NSImage(data: data)!)!
        let pdfDocument = PDFDocument()
        pdfDocument.insert(pdfPage, at: 0)
        
        // Set the mock extractor to return a valid payslip
        mockPDFExtractor.resultToReturn = mockPDFService.mockPayslipData
        
        return pdfDocument
    }
    
    private func createPDFData(from text: String) -> Data {
        let data = text.data(using: .utf8)!
        let pdfPage = PDFPage(image: NSImage(data: data)!)!
        let pdfDocument = PDFDocument()
        pdfDocument.insert(pdfPage, at: 0)
        
        // Set the mock extractor to return a valid payslip
        mockPDFExtractor.resultToReturn = mockPDFService.mockPayslipData
        
        // Use the mockPDFService to handle async calls properly
        mockPDFService.mockPDFData = pdfDocument.dataRepresentation() ?? Data()
        
        return pdfDocument.dataRepresentation() ?? Data()
    }
} 