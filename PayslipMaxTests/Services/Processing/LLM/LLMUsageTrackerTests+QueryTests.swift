//
//  LLMUsageTrackerTests+QueryTests.swift
//  PayslipMaxTests
//
//  Query and analytics tests for LLM Usage Tracker
//

import XCTest
import SwiftData
@testable import PayslipMax

// MARK: - Query and Analytics Tests

extension LLMUsageTrackerTests {

    func testGetUserUsageByDateRange() async throws {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        // Create records at different times
        try await createTestRecord(timestamp: twoDaysAgo, provider: .gemini)
        try await createTestRecord(timestamp: yesterday, provider: .gemini)
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
        try await createTestRecord(provider: .gemini)
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
        let successResponse = LLMResponse(
            content: "OK",
            usage: LLMUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20)
        )

        try await tracker.trackUsage(
            request: request, response: successResponse,
            provider: .gemini, model: "test", latencyMs: 100, error: nil
        )
        try await tracker.trackUsage(
            request: request, response: successResponse,
            provider: .gemini, model: "test", latencyMs: 100, error: nil
        )
        try await tracker.trackUsage(
            request: request, response: successResponse,
            provider: .gemini, model: "test", latencyMs: 100, error: nil
        )
        try await tracker.trackUsage(
            request: request, response: nil,
            provider: .gemini, model: "test", latencyMs: 100, error: NSError(domain: "Test", code: 1)
        )

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
        let response = LLMResponse(
            content: "OK",
            usage: LLMUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20)
        )

        try await tracker.trackUsage(
            request: request, response: response,
            provider: .gemini, model: "test", latencyMs: 100, error: nil
        )
        try await tracker.trackUsage(
            request: request, response: response,
            provider: .gemini, model: "test", latencyMs: 200, error: nil
        )
        try await tracker.trackUsage(
            request: request, response: response,
            provider: .gemini, model: "test", latencyMs: 300, error: nil
        )

        // When
        let avgLatency = try await tracker.getAverageLatency(
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        // Then
        XCTAssertEqual(avgLatency, 200)  // (100 + 200 + 300) / 3 = 200
    }

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
}

