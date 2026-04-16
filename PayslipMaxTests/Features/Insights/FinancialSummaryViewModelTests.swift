import XCTest
@testable import PayslipMax

/// TDD tests for FinancialSummaryViewModel.
/// Each test asserts that a computed property delegates to the injected
/// FinancialCalculationServiceProtocol — NOT to FinancialCalculationUtility.shared.
@MainActor
final class FinancialSummaryViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: FinancialSummaryViewModel!
    private var mockCalc: MockFinancialCalculationService!
    private var mockRepo: MockSendablePayslipRepository!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockCalc = MockFinancialCalculationService()
        mockRepo = MockSendablePayslipRepository()
        sut = FinancialSummaryViewModel(
            calculationService: mockCalc,
            repository: mockRepo
        )
        sut.updatePayslips([makeDTO(credits: 100_000, debits: 30_000)])
    }

    override func tearDown() {
        sut = nil
        mockCalc = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - totalIncome

    func test_totalIncome_delegatesToInjectedService() {
        mockCalc.stubbedTotalIncome = 99_999
        XCTAssertEqual(sut.totalIncome, 99_999)
        XCTAssertTrue(mockCalc.aggregateTotalIncomeCalled)
    }

    // MARK: - totalDeductions

    func test_totalDeductions_delegatesToInjectedService() {
        mockCalc.stubbedTotalDeductions = 12_345
        XCTAssertEqual(sut.totalDeductions, 12_345)
        XCTAssertTrue(mockCalc.aggregateTotalDeductionsCalled)
    }

    // MARK: - netIncome

    func test_netIncome_delegatesToInjectedService() {
        mockCalc.stubbedNetIncome = 55_555
        XCTAssertEqual(sut.netIncome, 55_555)
        XCTAssertTrue(mockCalc.aggregateNetIncomeCalled)
    }

    // MARK: - averageMonthlyIncome

    func test_averageMonthlyIncome_delegatesToInjectedService() {
        mockCalc.stubbedAverageMonthlyIncome = 80_000
        XCTAssertEqual(sut.averageMonthlyIncome, 80_000)
        XCTAssertTrue(mockCalc.calculateAverageMonthlyIncomeCalled)
    }

    // MARK: - averageNetRemittance

    func test_averageNetRemittance_delegatesToInjectedService() {
        mockCalc.stubbedAverageNetRemittance = 70_000
        XCTAssertEqual(sut.averageNetRemittance, 70_000)
        XCTAssertTrue(mockCalc.calculateAverageNetRemittanceCalled)
    }

    // MARK: - topEarnings

    func test_topEarnings_delegatesToInjectedService() {
        mockCalc.stubbedEarningsBreakdown = [
            (category: "BPAY", amount: 50_000, percentage: 80)
        ]
        let result = sut.topEarnings
        XCTAssertEqual(result.first?.category, "BPAY")
        XCTAssertTrue(mockCalc.calculateEarningsBreakdownCalled)
    }

    // MARK: - topDeductions

    func test_topDeductions_delegatesToInjectedService() {
        mockCalc.stubbedDeductionsBreakdown = [
            (category: "ITAX", amount: 10_000, percentage: 33)
        ]
        let result = sut.topDeductions
        XCTAssertEqual(result.first?.category, "ITAX")
        XCTAssertTrue(mockCalc.calculateDeductionsBreakdownCalled)
    }

    // MARK: - incomeTrend

    func test_incomeTrend_delegatesToInjectedService() {
        mockCalc.stubbedIncomeTrend = 5.5
        XCTAssertEqual(sut.incomeTrend, 5.5)
        XCTAssertTrue(mockCalc.calculateIncomeTrendCalled)
    }

    // MARK: - deductionsTrend

    func test_deductionsTrend_delegatesToInjectedService() {
        mockCalc.stubbedDeductionsTrend = -2.3
        XCTAssertEqual(sut.deductionsTrend, -2.3)
        XCTAssertTrue(mockCalc.calculateDeductionsTrendCalled)
    }

    // MARK: - netIncomeTrend

    func test_netIncomeTrend_delegatesToInjectedService() {
        mockCalc.stubbedNetIncomeTrend = 3.7
        XCTAssertEqual(sut.netIncomeTrend, 3.7)
        XCTAssertTrue(mockCalc.calculateNetIncomeTrendCalled)
    }

    // MARK: - updatePayslips propagates correctly

    func test_updatePayslips_nonEmptyData_hasMultiplePayslipsReturnsFalse() {
        sut.updatePayslips([makeDTO(credits: 100_000, debits: 30_000)])
        XCTAssertFalse(sut.hasMultiplePayslips)
    }

    func test_updatePayslips_twoPayslips_hasMultiplePayslipsReturnsTrue() {
        sut.updatePayslips([
            makeDTO(credits: 100_000, debits: 30_000),
            makeDTO(credits: 90_000, debits: 25_000)
        ])
        XCTAssertTrue(sut.hasMultiplePayslips)
    }

    // MARK: - Helpers

    private func makeDTO(credits: Double, debits: Double) -> PayslipDTO {
        PayslipDTO(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2025,
            credits: credits,
            debits: debits,
            dsop: 5_000,
            tax: 8_000,
            earnings: ["BPAY": credits],
            deductions: ["ITAX": debits],
            name: "Test",
            accountNumber: "12345",
            panNumber: "ABCDE1234F"
        )
    }
}

// Uses MockSendablePayslipRepository from PayslipMaxTests/Mocks/MockPayslipDataHandler.swift
