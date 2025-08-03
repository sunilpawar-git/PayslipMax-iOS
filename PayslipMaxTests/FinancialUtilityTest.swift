import XCTest
@testable import PayslipMax

/// Test for FinancialCalculationUtility core functionality
final class FinancialUtilityTest: XCTestCase {
    
    var utility: FinancialCalculationUtility!
    
    override func setUp() {
        super.setUp()
        utility = FinancialCalculationUtility.shared
    }
    
    func testCalculateNetIncome() {
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
        
        let netIncome = utility.calculateNetIncome(for: payslip)
        XCTAssertEqual(netIncome, 4000.0) // 5000 - 1000
    }
    
    func testCalculateTotalDeductions() {
        let payslip = PayslipItem(
            month: "February",
            year: 2023,
            credits: 6000.0,
            debits: 1500.0,
            dsop: 400.0,
            tax: 900.0,
            name: "Test User",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        let totalDeductions = utility.calculateTotalDeductions(for: payslip)
        XCTAssertEqual(totalDeductions, 1500.0) // Uses debits as authoritative total
    }
    
    func testAggregateTotalIncome() {
        let payslip1 = PayslipItem(
            month: "January", year: 2023, credits: 5000.0, debits: 1000.0,
            dsop: 300.0, tax: 800.0, name: "Test", accountNumber: "Test", panNumber: "Test"
        )
        let payslip2 = PayslipItem(
            month: "February", year: 2023, credits: 6000.0, debits: 1200.0,
            dsop: 400.0, tax: 900.0, name: "Test", accountNumber: "Test", panNumber: "Test"
        )
        
        let totalIncome = utility.aggregateTotalIncome(for: [payslip1, payslip2])
        XCTAssertEqual(totalIncome, 11000.0) // 5000 + 6000
    }
    
    func testCalculateAverageMonthlyIncome() {
        let payslips = [
            PayslipItem(month: "Jan", year: 2023, credits: 4000.0, debits: 800.0, dsop: 200.0, tax: 600.0, name: "Test", accountNumber: "Test", panNumber: "Test"),
            PayslipItem(month: "Feb", year: 2023, credits: 6000.0, debits: 1200.0, dsop: 300.0, tax: 900.0, name: "Test", accountNumber: "Test", panNumber: "Test")
        ]
        
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)
        XCTAssertEqual(averageIncome, 5000.0) // (4000 + 6000) / 2
    }
    
    func testCalculatePercentageChange() {
        // Test increase
        let increaseChange = utility.calculatePercentageChange(from: 100, to: 150)
        XCTAssertEqual(increaseChange, 50.0)
        
        // Test decrease
        let decreaseChange = utility.calculatePercentageChange(from: 200, to: 150)
        XCTAssertEqual(decreaseChange, -25.0)
        
        // Test zero base
        let zeroBaseChange = utility.calculatePercentageChange(from: 0, to: 100)
        XCTAssertEqual(zeroBaseChange, 0.0)
    }
    
    func testCalculateGrowthRate() {
        let growthRate = utility.calculateGrowthRate(current: 120, previous: 100)
        XCTAssertEqual(growthRate, 20.0)
    }
    
    func testEmptyArrayHandling() {
        let emptyPayslips: [PayslipItem] = []
        
        let totalIncome = utility.aggregateTotalIncome(for: emptyPayslips)
        XCTAssertEqual(totalIncome, 0.0)
        
        let averageIncome = utility.calculateAverageMonthlyIncome(for: emptyPayslips)
        XCTAssertEqual(averageIncome, 0.0)
    }
}