import XCTest
@testable import PayslipMax

final class FinancialCalculationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var utility: FinancialCalculationUtility!
    var testPayslips: [PayslipItem] = []
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        utility = FinancialCalculationUtility.shared
        testPayslips = createTestPayslips()
    }
    
    override func tearDown() {
        utility = nil
        testPayslips = []
        super.tearDown()
    }
    
    // MARK: - Income Calculation Tests
    
    func testAggregateTotalIncome_SinglePayslip() {
        // Given
        let payslips = [testPayslips[0]] // January payslip
        
        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)
        
        // Then
        XCTAssertEqual(totalIncome, 50000.0, accuracy: 0.01)
    }
    
    func testAggregateTotalIncome_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)
        
        // Then
        let expectedTotal = 50000.0 + 52000.0 + 51000.0 // Jan + Feb + Mar
        XCTAssertEqual(totalIncome, expectedTotal, accuracy: 0.01)
    }
    
    func testAggregateTotalIncome_EmptyArray() {
        // Given
        let payslips: [PayslipItem] = []
        
        // When
        let totalIncome = utility.aggregateTotalIncome(for: payslips)
        
        // Then
        XCTAssertEqual(totalIncome, 0.0)
    }
    
    // MARK: - Deductions Calculation Tests
    
    func testAggregateTotalDeductions_SinglePayslip() {
        // Given
        let payslips = [testPayslips[0]]
        
        // When
        let totalDeductions = utility.aggregateTotalDeductions(for: payslips)
        
        // Then
        XCTAssertEqual(totalDeductions, 12000.0, accuracy: 0.01)
    }
    
    func testAggregateTotalDeductions_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let totalDeductions = utility.aggregateTotalDeductions(for: payslips)
        
        // Then
        let expectedTotal = 12000.0 + 13000.0 + 12500.0 // Jan + Feb + Mar
        XCTAssertEqual(totalDeductions, expectedTotal, accuracy: 0.01)
    }
    
    func testCalculateTotalDeductions_IndividualPayslip() {
        // Given
        let payslip = testPayslips[0]
        
        // When
        let totalDeductions = utility.calculateTotalDeductions(for: payslip)
        
        // Then
        // Should use debits field as authoritative total
        XCTAssertEqual(totalDeductions, payslip.debits, accuracy: 0.01)
        XCTAssertEqual(totalDeductions, 12000.0, accuracy: 0.01)
    }
    
    // MARK: - Net Income Calculation Tests
    
    func testAggregateNetIncome_SinglePayslip() {
        // Given
        let payslips = [testPayslips[0]]
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        let expectedNet = 50000.0 - 12000.0 // credits - debits
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }
    
    func testAggregateNetIncome_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        let expectedTotalIncome = 50000.0 + 52000.0 + 51000.0
        let expectedTotalDeductions = 12000.0 + 13000.0 + 12500.0
        let expectedNet = expectedTotalIncome - expectedTotalDeductions
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }
    
    func testCalculateNetIncome_IndividualPayslip() {
        // Given
        let payslip = testPayslips[0]
        
        // When
        let netIncome = utility.calculateNetIncome(for: payslip)
        
        // Then
        let expectedNet = payslip.credits - payslip.debits
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
        XCTAssertEqual(netIncome, 38000.0, accuracy: 0.01) // 50000 - 12000
    }
    
    // MARK: - Average Calculation Tests
    
    func testCalculateAverageMonthlyIncome() {
        // Given
        let payslips = testPayslips
        
        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)
        
        // Then
        let expectedAverage = (50000.0 + 52000.0 + 51000.0) / 3.0
        XCTAssertEqual(averageIncome, expectedAverage, accuracy: 0.01)
    }
    
    func testCalculateAverageMonthlyIncome_SinglePayslip() {
        // Given
        let payslips = [testPayslips[0]]
        
        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)
        
        // Then
        XCTAssertEqual(averageIncome, 50000.0, accuracy: 0.01)
    }
    
    func testCalculateAverageMonthlyIncome_EmptyArray() {
        // Given
        let payslips: [PayslipItem] = []
        
        // When
        let averageIncome = utility.calculateAverageMonthlyIncome(for: payslips)
        
        // Then
        XCTAssertEqual(averageIncome, 0.0)
    }
    
    func testCalculateAverageNetRemittance() {
        // Given
        let payslips = testPayslips
        
        // When
        let averageNet = utility.calculateAverageNetRemittance(for: payslips)
        
        // Then
        let totalIncome = 50000.0 + 52000.0 + 51000.0
        let totalDeductions = 12000.0 + 13000.0 + 12500.0
        let expectedAverage = (totalIncome - totalDeductions) / 3.0
        XCTAssertEqual(averageNet, expectedAverage, accuracy: 0.01)
    }
    
    // MARK: - Breakdown Calculation Tests
    
    func testCalculateEarningsBreakdown() {
        // Given
        let payslips = testPayslips
        
        // When
        let breakdown = utility.calculateEarningsBreakdown(for: payslips)
        
        // Then
        XCTAssertFalse(breakdown.isEmpty)
        
        // Find BPAY category
        if let bpayBreakdown = breakdown.first(where: { $0.category == "BPAY" }) {
            let expectedBpayTotal = 30000.0 + 31000.0 + 30500.0 // Jan + Feb + Mar
            XCTAssertEqual(bpayBreakdown.amount, expectedBpayTotal, accuracy: 0.01)
            XCTAssertGreaterThan(bpayBreakdown.percentage, 0)
        } else {
            XCTFail("BPAY category should be in earnings breakdown")
        }
    }
    
    func testCalculateDeductionsBreakdown() {
        // Given
        let payslips = testPayslips
        
        // When
        let breakdown = utility.calculateDeductionsBreakdown(for: payslips)
        
        // Then
        XCTAssertFalse(breakdown.isEmpty)
        
        // Find DSOP category
        if let dsopBreakdown = breakdown.first(where: { $0.category == "DSOP" }) {
            let expectedDsopTotal = 4000.0 + 4500.0 + 4100.0 // Jan + Feb + Mar
            XCTAssertEqual(dsopBreakdown.amount, expectedDsopTotal, accuracy: 0.01)
            XCTAssertGreaterThan(dsopBreakdown.percentage, 0)
        } else {
            XCTFail("DSOP category should be in deductions breakdown")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testFinancialCalculations_WithZeroValues() {
        // Given
        let zeroPayslip = PayslipItem(
            month: "January",
            year: 2024,
            credits: 0.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            earnings: [:],
            deductions: [:]
        )
        let payslips = [zeroPayslip]
        
        // When & Then
        XCTAssertEqual(utility.aggregateTotalIncome(for: payslips), 0.0)
        XCTAssertEqual(utility.aggregateTotalDeductions(for: payslips), 0.0)
        XCTAssertEqual(utility.aggregateNetIncome(for: payslips), 0.0)
        XCTAssertEqual(utility.calculateAverageMonthlyIncome(for: payslips), 0.0)
    }
    
    func testFinancialCalculations_WithNegativeNetIncome() {
        // Given
        let negativePayslip = PayslipItem(
            month: "January",
            year: 2024,
            credits: 30000.0,
            debits: 35000.0, // More debits than credits
            dsop: 5000.0,
            tax: 10000.0,
            earnings: ["BPAY": 30000.0],
            deductions: ["ITAX": 10000.0, "DSOP": 5000.0, "OTHER": 20000.0]
        )
        let payslips = [negativePayslip]
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        XCTAssertLessThan(netIncome, 0.0) // Should handle negative net income
        XCTAssertEqual(netIncome, -5000.0, accuracy: 0.01) // 30000 - 35000
    }
    
    // MARK: - Performance Tests
    
    func testFinancialCalculations_Performance() {
        // Given - Create a larger array by repeating individual payslips
        var largePayslipArray: [PayslipItem] = []
        for _ in 0..<300 {
            largePayslipArray.append(contentsOf: testPayslips)
        }
        
        // When & Then
        measure {
            _ = utility.aggregateTotalIncome(for: largePayslipArray)
            _ = utility.aggregateTotalDeductions(for: largePayslipArray)
            _ = utility.aggregateNetIncome(for: largePayslipArray)
            _ = utility.calculateAverageMonthlyIncome(for: largePayslipArray)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPayslips() -> [PayslipItem] {
        return [
            // January 2024
            PayslipItem(
                month: "January",
                year: 2024,
                credits: 50000.0,
                debits: 12000.0,
                dsop: 4000.0,
                tax: 8000.0,
                earnings: [
                    "BPAY": 30000.0,
                    "DA": 15000.0,
                    "HRA": 5000.0
                ],
                deductions: [
                    "DSOP": 4000.0,
                    "ITAX": 8000.0
                ],
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F"
            ),
            
            // February 2024
            PayslipItem(
                month: "February",
                year: 2024,
                credits: 52000.0,
                debits: 13000.0,
                dsop: 4500.0,
                tax: 8500.0,
                earnings: [
                    "BPAY": 31000.0,
                    "DA": 15500.0,
                    "HRA": 5500.0
                ],
                deductions: [
                    "DSOP": 4500.0,
                    "ITAX": 8500.0,
                    "OTHER": 300.0
                ],
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F"
            ),
            
            // March 2024
            PayslipItem(
                month: "March",
                year: 2024,
                credits: 51000.0,
                debits: 12500.0,
                dsop: 4100.0,
                tax: 8200.0,
                earnings: [
                    "BPAY": 30500.0,
                    "DA": 15250.0,
                    "HRA": 5250.0
                ],
                deductions: [
                    "DSOP": 4100.0,
                    "ITAX": 8200.0,
                    "OTHER": 200.0
                ],
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F"
            )
        ]
    }
} 