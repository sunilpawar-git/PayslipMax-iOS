//
//  LLMUsageTrackerTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Usage Tracker service
//

import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class LLMUsageTrackerTests: XCTestCase {

    var tracker: LLMUsageTracker!
    var costCalculator: LLMCostCalculator!
    var modelContainer: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([LLMUsageRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])

        costCalculator = LLMCostCalculator()
        tracker = LLMUsageTracker(modelContainer: modelContainer, costCalculator: costCalculator)
    }

    override func tearDown() async throws {
        tracker = nil
        costCalculator = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Tracking Tests

    func testTrackSuccessfulUsage() async throws {
        // Given
        let request = LLMRequest(prompt: "Test prompt", systemPrompt: "System", jsonMode: true)
        let response = LLMResponse(
            content: "Test response",
            usage: LLMUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        )

        // When
        try await tracker.trackUsage(
            request: request,
            response: response,
            provider: .gemini,
            model: "gemini-2.5-flash-lite",
            latencyMs: 500,
            error: nil
        )

        // Then
        let records = try await tracker.getUserUsage(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        XCTAssertEqual(records.count, 1)
        let record = try XCTUnwrap(records.first)
        XCTAssertEqual(record.provider, "gemini")
        XCTAssertEqual(record.model, "gemini-2.5-flash-lite")
        XCTAssertEqual(record.inputTokens, 100)
        XCTAssertEqual(record.outputTokens, 50)
        XCTAssertEqual(record.totalTokens, 150)
        XCTAssertEqual(record.latencyMs, 500)
        XCTAssertTrue(record.success)
        XCTAssertNil(record.errorMessage)
        XCTAssertGreaterThan(record.costUSD, 0)
        XCTAssertGreaterThan(record.costINR, 0)
    }

    func testTrackFailedUsage() async throws {
        // Given
        let request = LLMRequest(prompt: "Test", systemPrompt: "System", jsonMode: true)
        let error = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "API Error"])

        // When
        try await tracker.trackUsage(
            request: request,
            response: nil,
            provider: .gemini,
            model: "gemini-2.5-flash-lite",
            latencyMs: 250,
            error: error
        )

        // Then
        let records = try await tracker.getUserUsage(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        XCTAssertEqual(records.count, 1)
        let record = try XCTUnwrap(records.first)
        XCTAssertFalse(record.success)
        XCTAssertEqual(record.errorMessage, "API Error")
        XCTAssertEqual(record.inputTokens, 0)
        XCTAssertEqual(record.outputTokens, 0)
        XCTAssertEqual(record.latencyMs, 250)
    }

    // MARK: - Query Tests

    func testGetUserUsageByDateRange() async throws {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        // Create records at different times
        try await createTestRecord(timestamp: twoDaysAgo, provider: .gemini)
        try await createTestRecord(timestamp: yesterday, provider: .openai)
        try await createTestRecord(timestamp: now, provider: .gemini)

        // When - Query last 24 hours
        let records = try await tracker.getUserUsage(
            from: now.addingTimeInterval(-86400),
            to: now.addingTimeInterval(3600)
        )

        // Then
        XCTAssertEqual(records.count, 2)  // Should only get yesterday and today
    }

    func testGetUserUsageCount() async throws {
        // Given
        try await createTestRecord(provider: .gemini)
        try await createTestRecord(provider: .openai)
        try await createTestRecord(provider: .gemini)

        // When
        let count = try await tracker.getUserUsageCount(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(count, 3)
    }

    func testGetLastUsageTimestamp() async throws {
        // Given
        let firstTime = Date().addingTimeInterval(-3600)
        let lastTime = Date()

        try await createTestRecord(timestamp: firstTime, provider: .gemini)
        try await createTestRecord(timestamp: lastTime, provider: .gemini)

        // When
        let timestamp = try await tracker.getLastUsageTimestamp()

        // Then
        XCTAssertNotNil(timestamp)
        // Should be within 1 second of lastTime
        XCTAssertEqual(timestamp!.timeIntervalSince1970, lastTime.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Analytics Tests

    func testGetTotalCost() async throws {
        // Given
        try await createTestRecord(provider: .gemini, inputTokens: 1000, outputTokens: 500)
        try await createTestRecord(provider: .gemini, inputTokens: 2000, outputTokens: 1000)

        // When
        let totalCostINR = try await tracker.getTotalCost(
            from: Date().addingTimeInterval(-3600),
            to: Date(),
            currency: .inr
        )

        // Then
        XCTAssertGreaterThan(totalCostINR, 0)
    }

    func testGetSuccessRate() async throws {
        // Given - 3 successful, 1 failed
        let request = LLMRequest(prompt: "Test", systemPrompt: "System", jsonMode: true)
        let successResponse = LLMResponse(content: "OK", usage: LLMUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20))

        try await tracker.trackUsage(request: request, response: successResponse, provider: .gemini, model: "test", latencyMs: 100, error: nil)
        try await tracker.trackUsage(request: request, response: successResponse, provider: .gemini, model: "test", latencyMs: 100, error: nil)
        try await tracker.trackUsage(request: request, response: successResponse, provider: .gemini, model: "test", latencyMs: 100, error: nil)
        try await tracker.trackUsage(request: request, response: nil, provider: .gemini, model: "test", latencyMs: 100, error: NSError(domain: "Test", code: 1))

        // When
        let successRate = try await tracker.getSuccessRate(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(successRate, 0.75, accuracy: 0.01)  // 3/4 = 75%
    }

    func testGetAverageLatency() async throws {
        // Given
        let request = LLMRequest(prompt: "Test", systemPrompt: "System", jsonMode: true)
        let response = LLMResponse(content: "OK", usage: LLMUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20))

        try await tracker.trackUsage(request: request, response: response, provider: .gemini, model: "test", latencyMs: 100, error: nil)
        try await tracker.trackUsage(request: request, response: response, provider: .gemini, model: "test", latencyMs: 200, error: nil)
        try await tracker.trackUsage(request: request, response: response, provider: .gemini, model: "test", latencyMs: 300, error: nil)

        // When
        let avgLatency = try await tracker.getAverageLatency(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(avgLatency, 200)  // (100 + 200 + 300) / 3 = 200
    }

    // MARK: - Data Cleanup Tests

    func testDeleteOldRecords() async throws {
        // Given
        let now = Date()
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: now)!
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        try await createTestRecord(timestamp: twoYearsAgo, provider: .gemini)
        try await createTestRecord(timestamp: oneMonthAgo, provider: .gemini)
        try await createTestRecord(timestamp: now, provider: .gemini)

        // When - Delete records older than 365 days
        let deletedCount = try await tracker.deleteOldRecords(olderThanDays: 365)

        // Then
        XCTAssertEqual(deletedCount, 1)  // Only 2-year-old record deleted

        let remainingRecords = try await tracker.getUserUsage(
            from: twoYearsAgo,
            to: now.addingTimeInterval(3600)
        )
        XCTAssertEqual(remainingRecords.count, 2)  // Recent records remain
    }

    // MARK: - Device Identifier Tests

    func testDeviceIdentifierPersistence() async throws {
        // Given
        let firstTracker = tracker!
        try await createTestRecord(provider: .gemini)
        let firstRecords = try await firstTracker.getUserUsage(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )
        let firstDeviceId = firstRecords.first?.deviceIdentifier

        // When - Create new tracker instance
        let secondTracker = LLMUsageTracker(modelContainer: modelContainer, costCalculator: costCalculator)
        try await createTestRecordWithTracker(secondTracker, provider: .gemini)
        let secondRecords = try await secondTracker.getUserUsage(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )
        let secondDeviceId = secondRecords.last?.deviceIdentifier

        // Then - Same device ID should be used
        XCTAssertEqual(firstDeviceId, secondDeviceId)
    }

    // MARK: - Helper Methods

    private func createTestRecord(
        timestamp: Date = Date(),
        provider: LLMProvider,
        inputTokens: Int = 100,
        outputTokens: Int = 50
    ) async throws {
        let request = LLMRequest(prompt: "Test", systemPrompt: "System", jsonMode: true)
        let response = LLMResponse(
            content: "Test response",
            usage: LLMUsage(promptTokens: inputTokens, completionTokens: outputTokens, totalTokens: inputTokens + outputTokens)
        )

        // Manually create record with specific timestamp
        let context = modelContainer.mainContext
        let costUSD = costCalculator.calculateCost(
            provider: provider,
            model: "test-model",
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        let costINR = costCalculator.convertToINR(usd: costUSD)

        let record = LLMUsageRecord(
            timestamp: timestamp,
            deviceIdentifier: UserDefaults.standard.string(forKey: "llm_device_identifier") ?? UUID().uuidString,
            provider: provider.rawValue,
            model: "test-model",
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: costUSD,
            costINR: costINR,
            success: true,
            latencyMs: 100
        )

        context.insert(record)
        try context.save()
    }

    private func createTestRecordWithTracker(
        _ customTracker: LLMUsageTracker,
        provider: LLMProvider
    ) async throws {
        let request = LLMRequest(prompt: "Test", systemPrompt: "System", jsonMode: true)
        let response = LLMResponse(
            content: "Test response",
            usage: LLMUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        )

        try await customTracker.trackUsage(
            request: request,
            response: response,
            provider: provider,
            model: "test-model",
            latencyMs: 100,
            error: nil
        )
    }
}
