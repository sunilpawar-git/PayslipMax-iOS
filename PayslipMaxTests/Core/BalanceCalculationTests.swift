import XCTest
@testable import PayslipMax

/// Tests for payslip balance calculations
@MainActor
final class BalanceCalculationTests: XCTestCase {
    
    func testBalanceCalculation() {
        // Test with various combinations of values
        
        // Case 1: Standard case
        let payslip1 = TestDataGenerator.samplePayslipItem(
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0
        )
        let net1 = payslip1.credits - (payslip1.debits + payslip1.dsop + payslip1.tax)
        XCTAssertEqual(net1, 2900.0, "Standard case balance calculation should be correct")
        
        // Case 2: Zero values
        let payslip2 = TestDataGenerator.samplePayslipItem(
            credits: 5000.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0
        )
        let net2 = payslip2.credits - (payslip2.debits + payslip2.dsop + payslip2.tax)
        XCTAssertEqual(net2, 5000.0, "Zero deductions should result in net equal to credits")
        
        // Case 3: Negative balance (more deductions than credits)
        let payslip3 = TestDataGenerator.samplePayslipItem(
            credits: 1000.0,
            debits: 1500.0,
            dsop: 300.0,
            tax: 200.0
        )
        let net3 = payslip3.credits - (payslip3.debits + payslip3.dsop + payslip3.tax)
        XCTAssertEqual(net3, -1000.0, "Negative balance should be calculated correctly")
        
        // Case 4: Large numbers
        let payslip4 = TestDataGenerator.samplePayslipItem(
            credits: 1000000.0,
            debits: 300000.0,
            dsop: 50000.0,
            tax: 150000.0
        )
        let net4 = payslip4.credits - (payslip4.debits + payslip4.dsop + payslip4.tax)
        XCTAssertEqual(net4, 500000.0, "Large number balance calculation should be correct")
        
        // Case 5: Decimal precision
        let payslip5 = TestDataGenerator.samplePayslipItem(
            credits: 5000.75,
            debits: 1000.25,
            dsop: 300.50,
            tax: 800.33
        )
        let net5 = payslip5.credits - (payslip5.debits + payslip5.dsop + payslip5.tax)
        XCTAssertEqual(net5, 2899.67, accuracy: 0.001, "Decimal precision should be maintained in balance calculation")
    }
    
    func testTwoSamplePayslipComparison() {
        // Test comparing calculations between two payslips
        
        let payslipA = TestDataGenerator.samplePayslipItem(
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0
        )
        
        let payslipB = TestDataGenerator.samplePayslipItem(
            credits: 5500.0,
            debits: 1100.0,
            dsop: 330.0,
            tax: 880.0
        )
        
        // Calculate net amounts
        let netA = payslipA.credits - (payslipA.debits + payslipA.dsop + payslipA.tax)
        let netB = payslipB.credits - (payslipB.debits + payslipB.dsop + payslipB.tax)
        
        // Compare the difference
        XCTAssertGreaterThan(netB, netA, "Higher credits should result in higher net pay")
        XCTAssertEqual(netB - netA, 190.0, "The difference in net pay should be calculated correctly")
        
        // Test percentage increase
        let percentageIncrease = ((netB - netA) / netA) * 100
        XCTAssertEqual(percentageIncrease, 6.55, accuracy: 0.01, "Percentage increase should be calculated correctly")
    }
} 