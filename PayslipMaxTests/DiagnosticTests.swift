import XCTest
import SwiftData
@testable import Payslip_Max

@MainActor
final class DiagnosticTests: XCTestCase {
    private var testContainer: TestDIContainer!
    
    override func setUpWithError() throws {
        super.setUp()
        testContainer = TestDIContainer.testShared
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        super.tearDown()
    }
    
    func testBasicFunctionality() {
        // Basic math test
        XCTAssertEqual(2 + 2, 4, "Basic math should work")
        
        // Async test
        let expectation = expectation(description: "Async operation")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPayslipItemWithMocks() {
        // Create a test payslip
        let payslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Verify properties
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2023)
        XCTAssertEqual(payslip.credits, 5000.0)
        XCTAssertEqual(payslip.debits, 1000.0)
        XCTAssertEqual(payslip.dsop, 300.0)
        XCTAssertEqual(payslip.tax, 800.0)
        XCTAssertEqual(payslip.name, "John Doe")
        XCTAssertEqual(payslip.accountNumber, "XXXX1234")
        XCTAssertEqual(payslip.panNumber, "ABCDE1234F")
        
        // Calculate net amount (credits - (debits + dsop + tax))
        let expectedNet = payslip.credits - (payslip.debits + payslip.dsop + payslip.tax)
        XCTAssertEqual(expectedNet, 2900.0)
    }
    
    // MARK: - Balance Testing
    func testBalanceCalculation() {
        // Test with various combinations of values
        
        // Case 1: Standard case
        let payslip1 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let net1 = payslip1.credits - (payslip1.debits + payslip1.dsop + payslip1.tax)
        XCTAssertEqual(net1, 2900.0, "Standard case balance calculation should be correct")
        
        // Case 2: Zero values
        let payslip2 = PayslipItem(
            month: "February",
            year: 2023,
            credits: 5000.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let net2 = payslip2.credits - (payslip2.debits + payslip2.dsop + payslip2.tax)
        XCTAssertEqual(net2, 5000.0, "Zero deductions should result in net equal to credits")
        
        // Case 3: Negative balance (more deductions than credits)
        let payslip3 = PayslipItem(
            month: "March",
            year: 2023,
            credits: 1000.0,
            debits: 1500.0,
            dsop: 300.0,
            tax: 200.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let net3 = payslip3.credits - (payslip3.debits + payslip3.dsop + payslip3.tax)
        XCTAssertEqual(net3, -1000.0, "Negative balance should be calculated correctly")
        
        // Case 4: Large numbers
        let payslip4 = PayslipItem(
            month: "April",
            year: 2023,
            credits: 1000000.0,
            debits: 300000.0,
            dsop: 50000.0,
            tax: 150000.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let net4 = payslip4.credits - (payslip4.debits + payslip4.dsop + payslip4.tax)
        XCTAssertEqual(net4, 500000.0, "Large number balance calculation should be correct")
        
        // Case 5: Decimal precision
        let payslip5 = PayslipItem(
            month: "May",
            year: 2023,
            credits: 5000.75,
            debits: 1000.25,
            dsop: 300.50,
            tax: 800.33,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let net5 = payslip5.credits - (payslip5.debits + payslip5.dsop + payslip5.tax)
        XCTAssertEqual(net5, 2899.67, accuracy: 0.001, "Decimal precision should be maintained in balance calculation")
    }
    
    func testMockSecurityService() async throws {
        // Create a mock security service directly
        let securityService = MockSecurityService()
        
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
            XCTAssertTrue(error is MockError)
        }
    }
    
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
        let payslip = TestPayslipItem.sample()
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
            XCTAssertTrue(error is MockDataError, "Error should be a MockDataError")
            if let mockError = error as? MockDataError {
                XCTAssertEqual(mockError, MockDataError.fetchFailed, "Expected fetchFailed error")
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
        
        // Test initialization - need to initialize first
        try await pdfService.initialize()
        XCTAssertTrue(mockPDFService.isInitialized)
        XCTAssertEqual(mockPDFService.initializeCallCount, 1, "initialize() should be called once")
        
        // Test processing
        let url = URL(string: "file:///test.pdf")!
        let processedData = try await pdfService.process(url)
        XCTAssertEqual(mockPDFService.processCallCount, 1, "process() should be called once")
        // MockPDFService returns empty data by default
        XCTAssertEqual(processedData.count, 0)
        
        // Test extraction - specify a sample return value first
        mockPDFService.extractResult = ["month": "January", "year": "2025"]
        let extractedData = mockPDFService.extract(processedData)
        XCTAssertEqual(mockPDFService.extractCallCount, 1, "extract() should be called once")
        XCTAssertFalse(extractedData.isEmpty)
        
        // Verify the extracted data matches what we set
        XCTAssertEqual(extractedData["month"], "January")
        XCTAssertEqual(extractedData["year"], "2025")
        
        // Test failure case
        mockPDFService.shouldFail = true
        do {
            _ = try await pdfService.process(url)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockPDFError, "Error should be a MockPDFError")
            if let mockError = error as? MockPDFError {
                XCTAssertEqual(mockError, MockPDFError.processingFailed, "Expected processingFailed error")
            }
        }
    }
} 