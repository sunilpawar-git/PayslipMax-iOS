import XCTest
@testable import PayslipMax

/// Minimal test to verify basic testing infrastructure works
final class BasicWorkingTest: XCTestCase {
    
    func testBasicArithmetic() {
        // Test basic arithmetic - no dependencies
        let result = 2 + 2
        XCTAssertEqual(result, 4)
    }
    
    func testPayslipItemCreation() {
        // Test basic PayslipItem creation with correct parameter order
        let payslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Test basic properties
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2023)
        XCTAssertEqual(payslip.credits, 5000.0)
        XCTAssertEqual(payslip.debits, 1000.0)
        XCTAssertEqual(payslip.dsop, 300.0)
        XCTAssertEqual(payslip.tax, 800.0)
        
        // Test basic calculation
        let netAmount = payslip.credits - payslip.debits
        XCTAssertEqual(netAmount, 4000.0)
    }
}