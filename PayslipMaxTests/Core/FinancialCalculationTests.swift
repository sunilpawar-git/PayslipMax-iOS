import XCTest
@testable import PayslipMax

final class FinancialCalculationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var utility: FinancialCalculationUtility!
    var testPayslips: [PayslipItem]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        utility = FinancialCalculationUtility.shared
        testPayslips = createTestPayslips()
    }
    
    override func tearDown() {
        utility = nil
        testPayslips = nil
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
        let expectedTotal = payslip.deductions.values.reduce(0, +)
        XCTAssertEqual(totalDeductions, expectedTotal, accuracy: 0.01)
        XCTAssertEqual(totalDeductions, 12000.0, accuracy: 0.01)
    }
    
    // MARK: - Net Income Calculation Tests
    
    func testAggregateNetIncome_SinglePayslip() {
        // Given
        let payslips = [testPayslips[0]]
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        let expectedNet = 50000.0 - 12000.0 // credits - total deductions
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }
    
    func testAggregateNetIncome_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        let totalIncome = 50000.0 + 52000.0 + 51000.0
        let totalDeductions = 12000.0 + 13000.0 + 12500.0
        let expectedNet = totalIncome - totalDeductions
        XCTAssertEqual(netIncome, expectedNet, accuracy: 0.01)
    }
    
    // MARK: - Average Calculation Tests
    
    func testCalculateAverageMonthlyIncome_MultiplePayslips() {
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
    
    func testCalculateAverageNetRemittance_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let averageNetRemittance = utility.calculateAverageNetRemittance(for: payslips)
        
        // Then
        let expectedAverage = (38000.0 + 39000.0 + 38500.0) / 3.0
        XCTAssertEqual(averageNetRemittance, expectedAverage, accuracy: 0.01)
    }
    
    // MARK: - Growth Rate Calculation Tests
    
    func testCalculateIncomeGrowthRate() {
        // Given
        let currentMonthIncome = 52000.0
        let previousMonthIncome = 50000.0
        
        // When
        let growthRate = utility.calculateGrowthRate(current: currentMonthIncome, previous: previousMonthIncome)
        
        // Then
        let expectedGrowthRate = ((52000.0 - 50000.0) / 50000.0) * 100
        XCTAssertEqual(growthRate, expectedGrowthRate, accuracy: 0.01)
        XCTAssertEqual(growthRate, 4.0, accuracy: 0.01)
    }
    
    func testCalculateGrowthRate_NegativeGrowth() {
        // Given
        let currentMonthIncome = 48000.0
        let previousMonthIncome = 50000.0
        
        // When
        let growthRate = utility.calculateGrowthRate(current: currentMonthIncome, previous: previousMonthIncome)
        
        // Then
        let expectedGrowthRate = ((48000.0 - 50000.0) / 50000.0) * 100
        XCTAssertEqual(growthRate, expectedGrowthRate, accuracy: 0.01)
        XCTAssertEqual(growthRate, -4.0, accuracy: 0.01)
    }
    
    func testCalculateGrowthRate_ZeroPrevious() {
        // Given
        let currentMonthIncome = 50000.0
        let previousMonthIncome = 0.0
        
        // When
        let growthRate = utility.calculateGrowthRate(current: currentMonthIncome, previous: previousMonthIncome)
        
        // Then
        XCTAssertEqual(growthRate, 0.0) // Should handle division by zero gracefully
    }
    
    // MARK: - Tax Calculation Tests
    
    func testCalculateTotalTax_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let totalTax = payslips.reduce(0) { $0 + $1.tax }
        
        // Then
        let expectedTax = 8000.0 + 8500.0 + 8200.0 // Jan + Feb + Mar
        XCTAssertEqual(totalTax, expectedTax, accuracy: 0.01)
    }
    
    func testCalculateEffectiveTaxRate() {
        // Given
        let grossIncome = 50000.0
        let taxAmount = 8000.0
        
        // When
        let effectiveTaxRate = (taxAmount / grossIncome) * 100
        
        // Then
        XCTAssertEqual(effectiveTaxRate, 16.0, accuracy: 0.01)
    }
    
    // MARK: - DSOP Calculation Tests
    
    func testCalculateTotalDSOP_MultiplePayslips() {
        // Given
        let payslips = testPayslips
        
        // When
        let totalDSOP = payslips.reduce(0) { $0 + $1.dsop }
        
        // Then
        let expectedDSOP = 4000.0 + 4200.0 + 4100.0 // Jan + Feb + Mar
        XCTAssertEqual(totalDSOP, expectedDSOP, accuracy: 0.01)
    }
    
    // MARK: - Component Analysis Tests
    
    func testCalculateEarningsBreakdown_SinglePayslip() {
        // Given
        let payslip = testPayslips[0]
        
        // When
        let basicPayPercentage = (payslip.earnings["BPAY"] ?? 0) / payslip.credits * 100
        let allowancesPercentage = ((payslip.earnings["DA"] ?? 0) + (payslip.earnings["HRA"] ?? 0)) / payslip.credits * 100
        
        // Then
        XCTAssertEqual(basicPayPercentage, 60.0, accuracy: 0.1) // 30000/50000 * 100
        XCTAssertEqual(allowancesPercentage, 40.0, accuracy: 0.1) // (15000+5000)/50000 * 100
    }
    
    func testCalculateDeductionsBreakdown_SinglePayslip() {
        // Given
        let payslip = testPayslips[0]
        let totalDeductions = utility.calculateTotalDeductions(for: payslip)
        
        // When
        let dsopPercentage = payslip.dsop / totalDeductions * 100
        let taxPercentage = payslip.tax / totalDeductions * 100
        
        // Then
        XCTAssertEqual(dsopPercentage, 33.33, accuracy: 0.1) // 4000/12000 * 100
        XCTAssertEqual(taxPercentage, 66.67, accuracy: 0.1) // 8000/12000 * 100
    }
    
    // MARK: - Edge Cases Tests
    
    func testFinancialCalculations_WithZeroValues() {
        // Given
        let zeroPayslip = PayslipItem(
            name: "Zero User",
            accountNumber: "000000000",
            panNumber: "ZERO00000Z",
            month: "January",
            year: 2024,
            credits: 0.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            netRemittance: 0.0,
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
    
    func testFinancialCalculations_WithNegativeValues() {
        // Given
        let negativePayslip = PayslipItem(
            name: "Negative User",
            accountNumber: "111111111",
            panNumber: "NEG1111N",
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 60000.0, // More debits than credits
            dsop: 5000.0,
            tax: 10000.0,
            netRemittance: -10000.0, // Negative net
            earnings: ["BPAY": 50000.0],
            deductions: ["ITAX": 10000.0, "DSOP": 5000.0, "OTHER": 45000.0]
        )
        let payslips = [negativePayslip]
        
        // When
        let netIncome = utility.aggregateNetIncome(for: payslips)
        
        // Then
        XCTAssertLessThan(netIncome, 0.0) // Should handle negative net income
        XCTAssertEqual(netIncome, -10000.0, accuracy: 0.01)
    }
    
    // MARK: - Performance Tests
    
    func testFinancialCalculations_Performance() {
        // Given
        let largePayslipArray = Array(repeating: testPayslips, count: 100).flatMap { $0 }
        
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
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                month: "January",
                year: 2024,
                credits: 50000.0,
                debits: 12000.0,
                dsop: 4000.0,
                tax: 8000.0,
                netRemittance: 38000.0,
                earnings: [
                    "BPAY": 30000.0,
                    "DA": 15000.0,
                    "HRA": 5000.0
                ],
                deductions: [
                    "DSOP": 4000.0,
                    "ITAX": 8000.0
                ]
            ),
            
            // February 2024
            PayslipItem(
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                month: "February",
                year: 2024,
                credits: 52000.0,
                debits: 13000.0,
                dsop: 4200.0,
                tax: 8500.0,
                netRemittance: 39000.0,
                earnings: [
                    "BPAY": 31000.0,
                    "DA": 15500.0,
                    "HRA": 5500.0
                ],
                deductions: [
                    "DSOP": 4200.0,
                    "ITAX": 8500.0,
                    "OTHER": 300.0
                ]
            ),
            
            // March 2024
            PayslipItem(
                name: "Test User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                month: "March",
                year: 2024,
                credits: 51000.0,
                debits: 12500.0,
                dsop: 4100.0,
                tax: 8200.0,
                netRemittance: 38500.0,
                earnings: [
                    "BPAY": 30500.0,
                    "DA": 15250.0,
                    "HRA": 5250.0
                ],
                deductions: [
                    "DSOP": 4100.0,
                    "ITAX": 8200.0,
                    "OTHER": 200.0
                ]
            )
        ]
    }
} 