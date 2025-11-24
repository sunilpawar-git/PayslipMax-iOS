//
//  LLMAnalyticsServiceTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Analytics Service
//

import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class LLMAnalyticsServiceTests: XCTestCase {

    var analyticsService: LLMAnalyticsService!
    var modelContainer: ModelContainer!
    var costCalculator: LLMCostCalculator!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container
        let schema = Schema([LLMUsageRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])

        costCalculator = LLMCostCalculator()
        analyticsService = LLMAnalyticsService(modelContainer: modelContainer, costCalculator: costCalculator)
    }

    override func tearDown() async throws {
        analyticsService = nil
        costCalculator = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Usage Statistics Tests

    func testGetUsageStatistics() async throws {
        // Given
        try await createTestRecord(provider: .gemini, success: true)
        try await createTestRecord(provider: .gemini, success: true)
        try await createTestRecord(provider: .gemini, success: false)

        // When
        let stats = try await analyticsService.getUsageStatistics(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(stats.totalCalls, 3)
        XCTAssertEqual(stats.successfulCalls, 2)
        XCTAssertEqual(stats.failedCalls, 1)
        XCTAssertEqual(stats.successRate, 66.67, accuracy: 1.0)  // Success rate is a percentage (2/3 * 100 = 66.67%)
        XCTAssertGreaterThan(stats.totalCostINR, 0)
    }

    func testGetUsageStatisticsEmpty() async throws {
        // When
        let stats = try await analyticsService.getUsageStatistics(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(stats.totalCalls, 0)
        XCTAssertEqual(stats.totalCostINR, 0)
    }

    // MARK: - Cost Breakdown Tests

    func testGetCostBreakdownByProvider() async throws {
        // Given
        try await createTestRecord(provider: .gemini, inputTokens: 1000, outputTokens: 500)
        try await createTestRecord(provider: .gemini, inputTokens: 2000, outputTokens: 1000)

        // When
        let breakdown = try await analyticsService.getCostBreakdownByProvider(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertNotNil(breakdown["gemini"])
        XCTAssertGreaterThan(breakdown["gemini"]!, 0)
    }

    // MARK: - High Usage Tests

    func testGetHighUsageUsers() async throws {
        // Given
        try await createTestRecord(provider: .gemini, inputTokens: 1000, outputTokens: 500)

        // When
        let highUsers = try await analyticsService.getHighUsageUsers(
            from: Date().addingTimeInterval(-3600),
            to: Date(),
            threshold: 1
        )

        // Then
        XCTAssertEqual(highUsers.count, 1)
        XCTAssertEqual(highUsers.first?.callCount, 1)
    }

    // MARK: - Export Tests

    func testExportToCSV() async throws {
        // Given
        try await createTestRecord(provider: .gemini)
        try await createTestRecord(provider: .gemini)

        // When
        let csv = try await analyticsService.exportToCSV(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        let lines = csv.components(separatedBy: "\n")
        XCTAssertGreaterThan(lines.count, 1) // Header + 1 record
        XCTAssertTrue(lines[0].contains("Timestamp"))
        XCTAssertNotNil(csv.range(of: "gemini"))
    }

    func testExportToJSON() async throws {
        // Given
        try await createTestRecord(provider: .gemini)

        // When
        let jsonData = try await analyticsService.exportToJSON(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Then
        XCTAssertNotNil(jsonString.range(of: "gemini"))
        XCTAssertNotNil(jsonString.range(of: "costUSD"))

        // Verify valid JSON
        let objects = try JSONSerialization.jsonObject(with: jsonData) as? [Any]
        XCTAssertNotNil(objects)
        XCTAssertEqual(objects?.count, 1)
    }

    // MARK: - Helper Methods

    private func createTestRecord(
        provider: LLMProvider,
        inputTokens: Int = 100,
        outputTokens: Int = 50,
        success: Bool = true
    ) async throws {
        let context = modelContainer.mainContext
        let costUSD = costCalculator.calculateCost(
            provider: provider,
            model: "test-model",
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        let costINR = costCalculator.convertToINR(usd: costUSD)

        let record = LLMUsageRecord(
            timestamp: Date(),
            deviceIdentifier: "test-device",
            provider: provider.rawValue,
            model: "test-model",
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: costUSD,
            costINR: costINR,
            success: success,
            latencyMs: 100
        )

        context.insert(record)
        try context.save()
    }
}
