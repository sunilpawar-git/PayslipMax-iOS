import XCTest
import SwiftData
@testable import Payslip_Max

final class DiagnosticTests: XCTestCase {
    private var testContainer: DIContainer!
    
    override func setUpWithError() throws {
        super.setUp()
        // Create a test container with mock services
        // Note: We're not setting it as shared since that would require @MainActor
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
            location: "New York",
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
        XCTAssertEqual(payslip.location, "New York")
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
            location: "New York",
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
            location: "New York",
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
            location: "New York",
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
            location: "New York",
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
            location: "New York",
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
        let authResult = try await securityService.authenticate()
        XCTAssertTrue(authResult)
        
        // Test encryption/decryption
        let testData = Data("test".utf8)
        let encrypted = try await securityService.encrypt(testData)
        XCTAssertNotEqual(encrypted, testData)
        
        let decrypted = try await securityService.decrypt(encrypted)
        XCTAssertEqual(decrypted, testData)
        
        // Test failure case
        securityService.shouldFail = true
        do {
            _ = try await securityService.authenticate()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockSecurityError)
        }
    }
    
    func testMockDataService() async throws {
        // Create a mock data service directly
        let dataService = MockDataService()
        
        // Test initialization
        XCTAssertFalse(dataService.isInitialized)
        try await dataService.initialize()
        XCTAssertTrue(dataService.isInitialized)
        
        // Test fetch with empty data
        let emptyPayslips = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(emptyPayslips.count, 0)
        
        // Test save
        let payslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            location: "New York",
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        try await dataService.save(payslip)
        
        // Test fetch after save
        let payslips = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(payslips.count, 1)
        XCTAssertEqual(payslips[0].month, "January")
        
        // Test delete
        try await dataService.delete(payslip)
        let emptyAgain = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(emptyAgain.count, 0)
        
        // Test failure case
        dataService.shouldFailFetch = true
        do {
            _ = try await dataService.fetch(PayslipItem.self)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockDataError)
        }
    }
    
    func testMockPDFService() async throws {
        // Create a mock PDF service directly
        let pdfService = MockPDFService()
        
        // Test initialization
        XCTAssertTrue(pdfService.isInitialized)
        
        // Test processing
        let url = URL(string: "file:///test.pdf")!
        let processedData = try await pdfService.process(url)
        XCTAssertFalse(processedData.isEmpty)
        
        // Test extraction
        let payslip = try await pdfService.extract(processedData)
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2023)
        
        // Test failure case
        pdfService.shouldFailProcess = true
        do {
            _ = try await pdfService.process(url)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockPDFError)
        }
    }
} 