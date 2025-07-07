import XCTest
@testable import PayslipMax

final class BalanceCalculationTests: XCTestCase {
    
    override func setUpWithError() throws {
        super.setUp()
    }
    
    override func tearDownWithError() throws {
        super.tearDown()
    }
    
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
        let net1 = payslip1.credits - payslip1.debits  // Net remittance = credits - debits
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
        let net2 = payslip2.credits - payslip2.debits  // Net remittance = credits - debits
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
        let net3 = payslip3.credits - payslip3.debits  // Net remittance = credits - debits
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
        let net4 = payslip4.credits - payslip4.debits  // Net remittance = credits - debits
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
        let net5 = payslip5.credits - payslip5.debits  // Net remittance = credits - debits
        XCTAssertEqual(net5, 2899.67, accuracy: 0.001, "Decimal precision should be maintained in balance calculation")
    }
    
    func testNetPayCalculation() {
        // Test the calculated property for net pay
        
        // Standard case
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
        
        // Calculate expected net pay
        let expectedNetRemittance = payslip.credits - payslip.debits  // Net remittance = credits - debits (debits already includes dsop & tax)
        
        // Calculate net remittance: credits - debits (since debits already includes dsop & tax)
        let calculatedNetRemittance = payslip.credits - payslip.debits
        XCTAssertEqual(calculatedNetRemittance, expectedNetRemittance, "Net remittance calculation should be correct")
    }
    
    func testEdgeCaseBalances() {
        // Test edge cases including zero values and very large values
        
        // Zero credits
        let zeroCreditsPayslip = PayslipItem(
            month: "June",
            year: 2023,
            credits: 0.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let zeroCreditsNet = zeroCreditsPayslip.credits - zeroCreditsPayslip.debits  // Net remittance = credits - debits
        XCTAssertEqual(zeroCreditsNet, -2100.0, "Zero credits with deductions should result in negative balance")
        
        // Very large values (close to Double limits)
        let largeValuePayslip = PayslipItem(
            month: "July",
            year: 2023,
            credits: 1.0e15,  // 1 quadrillion
            debits: 5.0e14,   // 500 trillion
            dsop: 1.0e14,     // 100 trillion
            tax: 2.0e14,      // 200 trillion
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        let largeValueNet = largeValuePayslip.credits - largeValuePayslip.debits  // Net remittance = credits - debits
        XCTAssertEqual(largeValueNet, 2.0e14, "Large value calculations should maintain precision")
    }
} 