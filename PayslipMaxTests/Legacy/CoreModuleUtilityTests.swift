import XCTest
import Foundation
@testable import PayslipMax

/// Tests for Core module utility classes and performance
final class CoreModuleUtilityTests: XCTestCase {

    // MARK: - Utility Classes Coverage

    func testTestDataGenerator_EdgeCases() {
        let zeroMSP = TestDataGenerator.edgeCasePayslipItem(type: .zeroMSP)
        XCTAssertEqual(zeroMSP.earnings["Military Service Pay"], 0)
        XCTAssertEqual(zeroMSP.credits, 56100.0 + 5610.0)
        XCTAssertEqual(zeroMSP.debits, 1200.0 + 150.0 + 2800.0)
        XCTAssertEqual(zeroMSP.dsop, 1200.0)
        XCTAssertEqual(zeroMSP.tax, 2800.0)

        let negativeValues = TestDataGenerator.edgeCasePayslipItem(type: .negativeValues)
        XCTAssertTrue(negativeValues.dsop < 0, "DSOP should be negative for negative values case")

        let highDSOP = TestDataGenerator.edgeCasePayslipItem(type: .highDSOP)
        XCTAssertTrue(highDSOP.dsop >= 5000)

        let arrearsPay = TestDataGenerator.edgeCasePayslipItem(type: .arrearsPay)
        XCTAssertTrue(arrearsPay.earnings["Arrears DA"] != nil)

        let transportAllowance = TestDataGenerator.edgeCasePayslipItem(type: .transportAllowance)
        XCTAssertTrue(transportAllowance.earnings["Transport Allowance"] != nil)

        let payslips = TestDataGenerator.samplePayslipItems(count: 24)
        XCTAssertEqual(payslips.count, 24)

        let firstYear = payslips[0].year
        let lastYear = payslips[23].year
        XCTAssertTrue(lastYear >= firstYear)

        let months = Set(payslips.map { $0.month })
        XCTAssertTrue(months.count > 1)
    }

    func testTestDataGenerator_PDFGeneration() {
        let basicPDF = TestDataGenerator.samplePDFDocument()
        XCTAssertNotNil(basicPDF)
        XCTAssertTrue(basicPDF.pageCount > 0)

        let customText = "Custom payslip content for testing"
        let customPDF = TestDataGenerator.samplePDFDocument(withText: customText)
        XCTAssertNotNil(customPDF)
        XCTAssertTrue(customPDF.pageCount > 0)

        let payslipPDF = TestDataGenerator.samplePayslipPDF(
            params: DefensePayslipPDFParams(
                serviceBranch: .army,
                name: "PDF Test User",
                rank: "Major",
                serviceNumber: "PDF123",
                month: "August",
                year: 2023,
                basicPay: 9000.0,
                msp: 0.0,
                da: 0.0,
                dsop: 450.0,
                agif: 0.0,
                incomeTax: 1350.0
            )
        )

        XCTAssertNotNil(payslipPDF)
        XCTAssertTrue(payslipPDF.pageCount > 0)

        if let page = payslipPDF.page(at: 0) {
            let pageString = page.string
            XCTAssertTrue(pageString?.contains("PDF Test User") ?? false)
            XCTAssertTrue(pageString?.contains("August 2023") ?? false)
        }
    }

    // MARK: - Integration and Performance

    func testCoreIntegration_CrossModule() {
        let utility = FinancialCalculationUtility.shared
        let testPayslips = TestDataGenerator.samplePayslipItems(count: 12)

        let totalIncome = utility.aggregateTotalIncome(for: testPayslips)
        XCTAssertTrue(totalIncome > 0)

        let totalDeductions = utility.aggregateTotalDeductions(for: testPayslips)
        XCTAssertTrue(totalDeductions > 0)

        let netIncome = utility.aggregateNetIncome(for: testPayslips)
        XCTAssertEqual(netIncome, totalIncome - totalDeductions, accuracy: 0.01)

        let incomeTrend = utility.calculateIncomeTrend(for: testPayslips)
        let deductionsTrend = utility.calculateDeductionsTrend(for: testPayslips)

        XCTAssertTrue(incomeTrend.isFinite)
        XCTAssertTrue(deductionsTrend.isFinite)

        let earningsBreakdown = utility.calculateEarningsBreakdown(for: testPayslips)
        let deductionsBreakdown = utility.calculateDeductionsBreakdown(for: testPayslips)

        XCTAssertNotNil(earningsBreakdown)
        XCTAssertNotNil(deductionsBreakdown)

        for payslip in testPayslips {
            let issues = utility.validateFinancialConsistency(for: payslip)
            XCTAssertNotNil(issues)
        }
    }

    func testPerformanceBaseline_CoreOperations() {
        let largePayslipSet = TestDataGenerator.samplePayslipItems(count: 500)
        let utility = FinancialCalculationUtility.shared

        measure {
            _ = utility.aggregateTotalIncome(for: largePayslipSet)
            _ = utility.aggregateTotalDeductions(for: largePayslipSet)
            _ = utility.aggregateNetIncome(for: largePayslipSet)
        }

        let start = Date()
        _ = utility.calculateEarningsBreakdown(for: largePayslipSet)
        _ = utility.calculateDeductionsBreakdown(for: largePayslipSet)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertTrue(elapsed < 10.0, "Core operations should complete within 10 seconds")
    }
}

