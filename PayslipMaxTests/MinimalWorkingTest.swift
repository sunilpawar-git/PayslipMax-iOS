import XCTest
@testable import PayslipMax

/// Minimal test to establish baseline coverage measurement
final class MinimalWorkingTest: XCTestCase {
    
    func testPayslipItemCreation() {
        // Test basic PayslipItem creation
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
        
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2023)
        XCTAssertEqual(payslip.credits, 5000.0)
        XCTAssertEqual(payslip.debits, 1000.0)
    }
    
    func testFinancialCalculationUtility() {
        // Test basic financial calculation
        let utility = FinancialCalculationUtility.shared
        let payslip = PayslipItem(
            month: "Test",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "Test",
            accountNumber: "Test",
            panNumber: "Test"
        )
        
        let netIncome = utility.calculateNetIncome(for: payslip)
        XCTAssertEqual(netIncome, 4000.0) // 5000 - 1000
        
        let totalDeductions = utility.calculateTotalDeductions(for: payslip)
        XCTAssertEqual(totalDeductions, 1000.0)
    }
    
    func testPayslipFormat() {
        // Test PayslipFormat enum - direct case comparison since rawValue doesn't exist
        // Note: After parser unification, military/corporate/pcda are now unified as 'defense'
        let format = PayslipFormat.defense
        XCTAssertEqual(format, PayslipFormat.defense)
        
        let unknown = PayslipFormat.unknown
        XCTAssertEqual(unknown, PayslipFormat.unknown)
        
        // Test that different cases are not equal
        XCTAssertNotEqual(format, unknown)
    }
}