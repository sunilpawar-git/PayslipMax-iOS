import XCTest
import SwiftData
@testable import PayslipMax

/// Basic diagnostic tests for core functionality
@MainActor
final class DiagnosticBasicTests: BaseTestCase {
    
    private var testContainer: TestDIContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = TestDIContainer.forTesting()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        try super.tearDownWithError()
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
        let payslip = TestDataGenerator.samplePayslipItem()
        
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
        
        // Calculate net remittance (credits - debits, since debits already includes dsop & tax)
        let expectedNet = payslip.credits - payslip.debits
        XCTAssertEqual(expectedNet, 4000.0)
    }
} 