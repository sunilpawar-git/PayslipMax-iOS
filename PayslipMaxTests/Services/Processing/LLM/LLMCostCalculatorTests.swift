//
//  LLMCostCalculatorTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Cost Calculator service
//

import XCTest
@testable import PayslipMax

final class LLMCostCalculatorTests: XCTestCase {

    var calculator: LLMCostCalculator!

    override func setUp() {
        super.setUp()
        // Use default configuration to ensure deterministic tests
        calculator = LLMCostCalculator(pricingConfig: .default)
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Cost Calculation Tests

    func testGeminiCostCalculation() {
        // Given
        let inputTokens = 1_000_000  // 1M tokens
        let outputTokens = 1_000_000  // 1M tokens

        // When
        let cost = calculator.calculateCost(
            provider: .gemini,
            model: "gemini-2.5-flash-lite",
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )

        // Then
        // $0.10/1M input + $0.40/1M output = $0.50 (Gemini 2.5 Flash Lite pricing)
        XCTAssertEqual(cost, 0.50, accuracy: 0.001)
    }

    func testOpenAICostCalculation() {
        // Given
        let inputTokens = 1_000_000  // 1M tokens
        let outputTokens = 1_000_000  // 1M tokens

        // When
        let cost = calculator.calculateCost(
            provider: .openai,
            model: "gpt-4o-mini",
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )

        // Then
        // $0.15/1M input + $0.60/1M output = $0.75
        XCTAssertEqual(cost, 0.75, accuracy: 0.001)
    }

    func testSmallTokenCounts() {
        // Given
        let inputTokens = 2000
        let outputTokens = 500

        // When
        let cost = calculator.calculateCost(
            provider: .gemini,
            model: "gemini-2.5-flash-lite",
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )

        // Then
        // (2000 * 0.10 / 1M) + (500 * 0.40 / 1M) = 0.0002 + 0.0002 = 0.0004
        XCTAssertEqual(cost, 0.0004, accuracy: 0.000001)
    }

    func testMockProviderCost() {
        // Given/When
        let cost = calculator.calculateCost(
            provider: .mock,
            model: "mock",
            inputTokens: 1000,
            outputTokens: 1000
        )

        // Then
        XCTAssertEqual(cost, 0.0)
    }

    // MARK: - Currency Conversion Tests

    func testUSDToINRConversion() {
        // Given
        let usd = 1.0

        // When
        let inr = calculator.convertToINR(usd: usd)

        // Then
        XCTAssertEqual(inr, 83.5, accuracy: 0.1)  // Default rate
    }

    func testINRToUSDConversion() {
        // Given
        let inr = 835.0

        // When
        let usd = calculator.convertToUSD(inr: inr)

        // Then
        XCTAssertEqual(usd, 10.0, accuracy: 0.1)
    }

    // MARK: - Aggregate Calculation Tests

    func testCalculateTotalCostINR() {
        // Given
        let records = createTestRecords()

        // When
        let totalCost = calculator.calculateTotalCost(from: records, currency: .inr)

        // Then
        let expectedTotal = records.reduce(0.0) { $0 + $1.costINR }
        XCTAssertEqual(totalCost, expectedTotal, accuracy: 0.01)
    }

    func testCalculateTotalCostUSD() {
        // Given
        let records = createTestRecords()

        // When
        let totalCost = calculator.calculateTotalCost(from: records, currency: .usd)

        // Then
        let expectedTotal = records.reduce(0.0) { $0 + $1.costUSD }
        XCTAssertEqual(totalCost, expectedTotal, accuracy: 0.01)
    }

    func testCalculateAverageCost() {
        // Given
        let records = createTestRecords()

        // When
        let avgCost = calculator.calculateAverageCost(from: records, currency: .inr)

        // Then
        let expectedAvg = records.reduce(0.0) { $0 + $1.costINR } / Double(records.count)
        XCTAssertEqual(avgCost, expectedAvg, accuracy: 0.01)
    }

    func testCalculateAverageCostEmptyArray() {
        // Given
        let records: [LLMUsageRecord] = []

        // When
        let avgCost = calculator.calculateAverageCost(from: records, currency: .inr)

        // Then
        XCTAssertEqual(avgCost, 0.0)
    }

    // MARK: - Percentile Tests

    func testCalculatePercentileP50() {
        // Given
        let records = createTestRecords()

        // When
        let p50 = calculator.calculatePercentile(from: records, percentile: 50, currency: .inr)

        // Then
        XCTAssertGreaterThan(p50, 0)
    }

    func testCalculatePercentileP90() {
        // Given
        let records = createTestRecords()

        // When
        let p90 = calculator.calculatePercentile(from: records, percentile: 90, currency: .inr)

        // Then
        XCTAssertGreaterThan(p90, 0)
    }

    func testCalculatePercentileEmptyArray() {
        // Given
        let records: [LLMUsageRecord] = []

        // When
        let p50 = calculator.calculatePercentile(from: records, percentile: 50, currency: .inr)

        // Then
        XCTAssertEqual(p50, 0.0)
    }

    // MARK: - Configuration Tests

    func testPricingConfigurationPersistence() {
        // Given
        var config = calculator.getPricingConfiguration()
        config.gemini.inputPer1M = 0.080  // New rate
        config.lastUpdated = Date()

        // When
        calculator.updatePricingConfiguration(config)

        // Then
        let retrievedConfig = calculator.getPricingConfiguration()
        XCTAssertEqual(retrievedConfig.gemini.inputPer1M, 0.080)
    }

    // MARK: - Estimation Tests

    func testEstimatePayslipParseCost() {
        // When
        let estimatedCost = calculator.estimatePayslipParseCost(provider: .gemini)

        // Then
        XCTAssertGreaterThan(estimatedCost, 0)
        XCTAssertLessThan(estimatedCost, 1.0)  // Should be less than ₹1
    }

    func testEstimateAnnualCostPerUser() {
        // Given
        let callsPerYear = 50

        // When
        let annualCost = calculator.estimateAnnualCostPerUser(callsPerYear: callsPerYear, provider: .gemini)

        // Then
        XCTAssertGreaterThan(annualCost, 0)
        XCTAssertLessThan(annualCost, 5.0)  // Should be less than ₹5 for 50 calls
    }

    func testCalculateProfitMargin() {
        // Given
        let subscriptionPrice = 99.0  // ₹99/year
        let callsPerYear = 50

        // When
        let profitMargin = calculator.calculateProfitMargin(
            subscriptionPriceINR: subscriptionPrice,
            callsPerYear: callsPerYear,
            provider: .gemini
        )

        // Then
        XCTAssertGreaterThan(profitMargin, 90.0)  // Should be >90% margin
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
                provider: "openai",
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
