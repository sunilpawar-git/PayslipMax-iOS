import Foundation
@testable import PayslipMax

/// Spy mock for FinancialCalculationServiceProtocol.
/// All methods are stubbable and call-tracked for TDD assertions.
final class MockFinancialCalculationService: FinancialCalculationServiceProtocol {

    // MARK: - Stubs

    var stubbedTotalIncome: Double = 0
    var stubbedTotalDeductions: Double = 0
    var stubbedNetIncome: Double = 0
    var stubbedAverageMonthlyIncome: Double = 0
    var stubbedAverageNetRemittance: Double = 0
    var stubbedEarningsBreakdown: [(category: String, amount: Double, percentage: Double)] = []
    var stubbedDeductionsBreakdown: [(category: String, amount: Double, percentage: Double)] = []
    var stubbedIncomeTrend: Double = 0
    var stubbedDeductionsTrend: Double = 0
    var stubbedNetIncomeTrend: Double = 0
    var stubbedPercentageChange: Double = 0
    var stubbedGrowthRate: Double = 0
    var stubbedValidationIssues: [String] = []

    // MARK: - Call Tracking

    var aggregateTotalIncomeCalled = false
    var aggregateTotalDeductionsCalled = false
    var aggregateNetIncomeCalled = false
    var calculateAverageMonthlyIncomeCalled = false
    var calculateAverageNetRemittanceCalled = false
    var calculateEarningsBreakdownCalled = false
    var calculateDeductionsBreakdownCalled = false
    var calculateIncomeTrendCalled = false
    var calculateDeductionsTrendCalled = false
    var calculateNetIncomeTrendCalled = false

    // MARK: - Protocol Conformance

    func calculateTotalDeductions(for payslip: any PayslipDataProtocol) -> Double {
        return stubbedTotalDeductions
    }

    func calculateNetIncome(for payslip: any PayslipDataProtocol) -> Double {
        return stubbedNetIncome
    }

    func aggregateTotalIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        aggregateTotalIncomeCalled = true
        return stubbedTotalIncome
    }

    func aggregateTotalDeductions(for payslips: [any PayslipDataProtocol]) -> Double {
        aggregateTotalDeductionsCalled = true
        return stubbedTotalDeductions
    }

    func aggregateNetIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        aggregateNetIncomeCalled = true
        return stubbedNetIncome
    }

    func calculateAverageMonthlyIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        calculateAverageMonthlyIncomeCalled = true
        return stubbedAverageMonthlyIncome
    }

    func calculateAverageNetRemittance(for payslips: [any PayslipDataProtocol]) -> Double {
        calculateAverageNetRemittanceCalled = true
        return stubbedAverageNetRemittance
    }

    func calculateEarningsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        calculateEarningsBreakdownCalled = true
        return stubbedEarningsBreakdown
    }

    func calculateDeductionsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        calculateDeductionsBreakdownCalled = true
        return stubbedDeductionsBreakdown
    }

    func calculatePercentageChange(from: Double, to: Double) -> Double {
        return stubbedPercentageChange
    }

    func calculateIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        calculateIncomeTrendCalled = true
        return stubbedIncomeTrend
    }

    func calculateDeductionsTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        calculateDeductionsTrendCalled = true
        return stubbedDeductionsTrend
    }

    func calculateNetIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        calculateNetIncomeTrendCalled = true
        return stubbedNetIncomeTrend
    }

    func calculateGrowthRate(current: Double, previous: Double) -> Double {
        return stubbedGrowthRate
    }

    func validateFinancialConsistency(for payslip: any PayslipDataProtocol) -> [String] {
        return stubbedValidationIssues
    }
}
