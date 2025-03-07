import XCTest
@testable import Payslip_Max

@MainActor
final class PayslipDetailViewModelTests: XCTestCase {
    
    var sut: PayslipDetailViewModel!
    var mockSecurityService: MockSecurityService!
    var testPayslip: PayslipItem!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockSecurityService = MockSecurityService()
        
        // Set up the DI container with mock services
        let testContainer = DIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        // Create a test payslip with known values
        testPayslip = PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000,
            debits: 1000,
            dspof: 500,
            tax: 800,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Create the view model with the test payslip and mock security service
        sut = PayslipDetailViewModel(payslip: testPayslip, securityService: mockSecurityService)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockSecurityService = nil
        testPayslip = nil
        DIContainer.resetToDefault()
        try await super.tearDown()
    }
    
    func testInitialization() {
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.netAmount, 2700.0) // 5000 - (1000 + 500 + 800)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.decryptedPayslip)
    }
    
    func testLoadDecryptedData() async {
        // When
        await sut.loadDecryptedData()
        
        // Then
        XCTAssertNotNil(sut.decryptedPayslip)
        XCTAssertEqual(sut.decryptedPayslip?.name, "Test User")
        XCTAssertEqual(sut.decryptedPayslip?.month, "January")
        XCTAssertEqual(sut.decryptedPayslip?.year, 2025)
        XCTAssertEqual(sut.decryptedPayslip?.credits, 5000)
        XCTAssertEqual(sut.netAmount, 2700.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFormatCurrency() {
        // When
        let formatted = sut.formatCurrency(1234.56)
        
        // Then
        // The exact format might depend on the locale, but we can check for basic formatting
        XCTAssertTrue(formatted.contains("1,234.56") || formatted.contains("1234.56"))
    }
    
    func testGetShareText() async {
        // Given
        await sut.loadDecryptedData()
        
        // When
        let shareText = sut.getShareText()
        
        // Then
        XCTAssertTrue(shareText.contains("Test User"))
        XCTAssertTrue(shareText.contains("January"))
        XCTAssertTrue(shareText.contains("2025"))
        XCTAssertTrue(shareText.contains("Net Amount"))
    }
    
    func testCalculateNetAmount() {
        // Given
        let expectedNet = testPayslip.credits - (testPayslip.debits + testPayslip.dspof + testPayslip.tax)
        
        // Then
        XCTAssertEqual(sut.netAmount, expectedNet)
        XCTAssertEqual(sut.netAmount, 2700.0)
    }
    
    func testLoadingState() async {
        // Create a task that will check the loading state during execution
        let expectation = XCTestExpectation(description: "Loading state changes")
        
        // Create a task to monitor loading state
        Task {
            // Check initial state
            XCTAssertFalse(sut.isLoading)
            
            // Start a task that will call loadDecryptedData
            Task {
                await sut.loadDecryptedData()
                expectation.fulfill()
            }
            
            // Give the task a moment to start
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Check final state
            XCTAssertFalse(sut.isLoading)
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
} 