//
//  LLMUsageTrackerProtocol.swift
//  PayslipMax
//
//  Protocol for LLM usage tracking service
//

import Foundation

/// Protocol for tracking LLM API usage
@MainActor
protocol LLMUsageTrackerProtocol: AnyObject {
    /// Track a single LLM API call
    /// - Parameters:
    ///   - request: The LLM request that was sent
    ///   - response: The LLM response received (nil if failed)
    ///   - provider: The LLM provider used
    ///   - model: The model name
    ///   - latencyMs: Latency in milliseconds
    ///   - error: Error if the call failed
    func trackUsage(
        request: LLMRequest,
        response: LLMResponse?,
        provider: LLMProvider,
        model: String,
        latencyMs: Int,
        error: Error?
    ) async throws

    /// Get usage records for the current device within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of usage records
    func getUserUsage(from startDate: Date, to endDate: Date) async throws -> [LLMUsageRecord]

    /// Get total usage count for the current device within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Count of API calls
    func getUserUsageCount(from startDate: Date, to endDate: Date) async throws -> Int

    /// Get the last usage timestamp for the current device
    /// - Returns: Date of last API call, or nil if no usage
    func getLastUsageTimestamp() async throws -> Date?
}
