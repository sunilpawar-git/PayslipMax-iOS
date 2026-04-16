import XCTest
@testable import PayslipMax

final class LLMCostCalculatorEstimationTests: XCTestCase {

    var calculator: LLMCostCalculator!

    override func setUp() {
        super.setUp()
        calculator = LLMCostCalculator(pricingConfig: .default)
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Percentile Tests

    func testCalculatePercentileP50() {
        let records = createTestRecords()

        let p50 = calculator.calculatePercentile(from: records, percentile: 50, currency: .inr)

        XCTAssertGreaterThan(p50, 0)
    }

    func testCalculatePercentileP90() {
        let records = createTestRecords()

        let p90 = calculator.calculatePercentile(from: records, percentile: 90, currency: .inr)

        XCTAssertGreaterThan(p90, 0)
    }

    func testCalculatePercentileEmptyArray() {
        let records: [LLMUsageRecord] = []

        let p50 = calculator.calculatePercentile(from: records, percentile: 50, currency: .inr)

        XCTAssertEqual(p50, 0.0)
    }

    // MARK: - Configuration Tests

    func testPricingConfigurationPersistence() {
        var config = calculator.getPricingConfiguration()
        config.gemini.inputPer1M = 0.080
        config.lastUpdated = Date()

        calculator.updatePricingConfiguration(config)

        let retrievedConfig = calculator.getPricingConfiguration()
        XCTAssertEqual(retrievedConfig.gemini.inputPer1M, 0.080)
    }

    // MARK: - Estimation Tests

    func testEstimatePayslipParseCost() {
        let estimatedCost = calculator.estimatePayslipParseCost(provider: .gemini)

        XCTAssertGreaterThan(estimatedCost, 0)
        XCTAssertLessThan(estimatedCost, 1.0)
    }

    func testEstimateAnnualCostPerUser() {
        let callsPerYear = 50

        let annualCost = calculator.estimateAnnualCostPerUser(callsPerYear: callsPerYear, provider: .gemini)

        XCTAssertGreaterThan(annualCost, 0)
        XCTAssertLessThan(annualCost, 5.0)
    }

    func testCalculateProfitMargin() {
        let subscriptionPrice = 99.0
        let callsPerYear = 50

        let profitMargin = calculator.calculateProfitMargin(
            subscriptionPriceINR: subscriptionPrice,
            callsPerYear: callsPerYear,
            provider: .gemini
        )

        XCTAssertGreaterThan(profitMargin, 90.0)
        XCTAssertLessThanOrEqual(profitMargin, 100.0)
    }

    // MARK: - Helper Methods

    private func createTestRecords() -> [LLMUsageRecord] {
        return [
            LLMUsageRecord(
                deviceIdentifier: "test-device",
                provider: "gemini",
                model: "test",
                inputTokens: 1000,
                outputTokens: 500,
                costUSD: 0.0001,
                costINR: 0.00835,
                success: true,
                latencyMs: 100
            ),
            LLMUsageRecord(
                deviceIdentifier: "test-device",
                provider: "gemini",
                model: "test",
                inputTokens: 2000,
                outputTokens: 1000,
                costUSD: 0.0002,
                costINR: 0.0167,
                success: true,
                latencyMs: 200
            ),
            LLMUsageRecord(
                deviceIdentifier: "test-device",
                provider: "gemini",
                model: "test",
                inputTokens: 1500,
                outputTokens: 750,
                costUSD: 0.00015,
                costINR: 0.012525,
                success: true,
                latencyMs: 150
            )
        ]
    }
}
