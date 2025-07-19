import XCTest
@testable import PayslipMax


/// Tests for mock services used in the application
@MainActor
final class MockServiceTests: XCTestCase {
    private var testContainer: TestDIContainer!
    
    override func setUpWithError() throws {
        super.setUp()
        testContainer = TestDIContainer.testShared
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        super.tearDown()
    }
    
    // MARK: - Security Service Tests
    
    func testMockSecurityService() async throws {
        // Create a mock security service directly
        let securityService = CoreMockSecurityService()
        
        // Test initialization
        XCTAssertFalse(securityService.isInitialized)
        try await securityService.initialize()
        XCTAssertTrue(securityService.isInitialized)
        
        // Test authentication success
        let authResult = try await securityService.authenticateWithBiometrics()
        XCTAssertTrue(authResult)
        
        // Test encryption/decryption
        let testData = Data("test".utf8)
        let encrypted = try await securityService.encryptData(testData)
        XCTAssertNotEqual(encrypted, testData)
        
        let decrypted = try await securityService.decryptData(encrypted)
        XCTAssertEqual(decrypted, testData)
        
        // Test failure case
        securityService.shouldFail = true
        do {
            _ = try await securityService.authenticateWithBiometrics()
            XCTFail("Should have thrown an error")
        } catch {
            print("Authentication Error type: \(type(of: error)), description: \(error.localizedDescription)")
            
            if let e = error as? PayslipMax.MockError {
                XCTAssertEqual(e, PayslipMax.MockError.authenticationFailed, "Expected authenticationFailed error")
            } else if let e = error as? MockError {
                XCTAssertEqual(e, MockError.authenticationFailed, "Expected authenticationFailed error")
            } else {
                XCTFail("Error should be a MockError, but got \(type(of: error))")
            }
        }
    }
    
    // MARK: - Data Service Tests
    
    func testMockDataService() async throws {
        // Create a brand new instance of MockDataService instead of using the shared one
        let dataService = MockDataService()
        
        print("🔍 BEFORE RESET: initializeCallCount = \(dataService.initializeCallCount)")
        
        // Reset the service to ensure a clean state
        dataService.reset()
        
        print("🔍 AFTER RESET: initializeCallCount = \(dataService.initializeCallCount)")
        
        // Verify the service is now in a clean state with initializeCallCount = 0
        XCTAssertEqual(dataService.initializeCallCount, 0, "After reset(), initializeCallCount should be 0")
        
        // Initialize should increment the counter from 0 to 1
        try await dataService.initialize()
        
        print("🔍 AFTER INITIALIZE: initializeCallCount = \(dataService.initializeCallCount)")
        
        // Verify the call count was incremented to exactly 1
        XCTAssertEqual(dataService.initializeCallCount, 1, "After initialize(), initializeCallCount should be 1")
        
        // Test fetch empty result
        let emptyItems = try await dataService.fetch(PayslipItem.self)
        print("🔍 EMPTY ITEMS COUNT: \(emptyItems.count)")
        XCTAssertTrue(emptyItems.isEmpty)
        
        // Test save
        let testPayslip = TestPayslipItem.sample()
        let payslip = testPayslip.toPayslipItem()
        try await dataService.save(payslip)
        
        // Test fetch after save - should find the item we saved
        let items = try await dataService.fetch(PayslipItem.self)
        print("🔍 ITEMS AFTER SAVE COUNT: \(items.count)")
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, payslip.id)
        
        // Test delete
        try await dataService.delete(payslip)
        let emptyAgain = try await dataService.fetch(PayslipItem.self)
        print("🔍 ITEMS AFTER DELETE COUNT: \(emptyAgain.count)")
        XCTAssertTrue(emptyAgain.isEmpty)
        
        // Test failure case
        dataService.shouldFailFetch = true
        do {
            _ = try await dataService.fetch(PayslipItem.self)
            XCTFail("Should have thrown an error")
        } catch {
            print("Fetch Error type: \(type(of: error)), description: \(error.localizedDescription)")
            
            if let e = error as? PayslipMax.MockError {
                XCTAssertEqual(e, PayslipMax.MockError.fetchFailed, "Expected fetchFailed error")
            } else if let e = error as? MockError {
                XCTAssertEqual(e, MockError.fetchFailed, "Expected fetchFailed error")
            } else {
                XCTFail("Error should be a MockError, but got \(type(of: error))")
            }
        }
    }
    
    func testMockPDFService() async throws {
        // Create a mock PDF service directly
        let pdfService = testContainer.pdfService
        guard let mockPDFService = pdfService as? MockPDFService else {
            XCTFail("Expected MockPDFService")
            return
        }
        
        // Test initialization
        XCTAssertFalse(mockPDFService.isInitialized)
        try await mockPDFService.initialize()
        XCTAssertTrue(mockPDFService.isInitialized)
        
        // Test PDF extraction
        let sampleURL = URL(fileURLWithPath: "/path/to/sample.pdf")
        let extractionResult = try await mockPDFService.extractText(from: sampleURL)
        XCTAssertEqual(extractionResult, "Mock PDF Content")
        
        // Test PDF metadata extraction
        let metadata = try await mockPDFService.extractMetadata(from: sampleURL)
        XCTAssertEqual(metadata["title"] as? String, "Mock PDF")
        XCTAssertEqual(metadata["pageCount"] as? Int, 5)
        
        // Test failure case
        mockPDFService.shouldFail = true
        do {
            _ = try await mockPDFService.extractText(from: sampleURL)
            XCTFail("Should have thrown an error")
        } catch {
            print("PDF Error type: \(type(of: error)), description: \(error.localizedDescription)")
            
            if let e = error as? PayslipMax.MockError {
                XCTAssertEqual(e, PayslipMax.MockError.extractionFailed, "Expected extractionFailed error")
            } else if let e = error as? MockError {
                XCTAssertEqual(e, MockError.extractionFailed, "Expected extractionFailed error")
            } else {
                XCTFail("Error should be a MockError, but got \(type(of: error))")
            }
        }
    }
    
    func testResetBehavior() async throws {
        // Test that all mocks properly reset their state
        
        // Reset all services at the start to ensure clean state
        MockServiceRegistry.shared.resetAllServices()
        testContainer.mockSecurityService.reset()
        testContainer.mockPDFService.reset()
        
        // Test SecurityService reset
        let securityService = CoreMockSecurityService()
        try await securityService.initialize()
        XCTAssertTrue(securityService.isInitialized)
        securityService.reset()
        XCTAssertFalse(securityService.isInitialized)
        
        // Test DataService reset
        let dataService = MockDataService()
        try await dataService.initialize()
        XCTAssertEqual(dataService.initializeCallCount, 1)
        
        let testPayslip = TestPayslipItem.sample()
        let payslip = testPayslip.toPayslipItem()
        try await dataService.save(payslip)
        
        let itemsBeforeReset = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(itemsBeforeReset.count, 1)
        
        dataService.reset()
        XCTAssertEqual(dataService.initializeCallCount, 0)
        
        let itemsAfterReset = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(itemsAfterReset.count, 0)
        
        // Test PDFService reset
        let pdfService = testContainer.pdfService
        guard let mockPDFService = pdfService as? MockPDFService else {
            XCTFail("Expected MockPDFService")
            return
        }
        
        // Ensure the mock service is in a clean state before testing
        mockPDFService.reset()
        XCTAssertFalse(mockPDFService.shouldFail, "MockPDFService should not be set to fail after reset")
        
        try await mockPDFService.initialize()
        XCTAssertTrue(mockPDFService.isInitialized)
        mockPDFService.reset()
        XCTAssertFalse(mockPDFService.isInitialized)
    }
} 