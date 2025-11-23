//
//  LLMRateLimiterProtocol.swift
//  PayslipMax
//
//  Protocol for LLM rate limiting service
//

import Foundation

/// Protocol for rate limiting LLM API calls
protocol LLMRateLimiterProtocol: AnyObject {
    /// Check if an LLM API call is allowed at this time
    /// - Returns: True if allowed, false if rate limited
    func canMakeRequest() async -> Bool

    /// Record that a request was made (updates rate limit counters)
    func recordRequest() async

    /// Get time until next request is allowed
    /// - Returns: TimeInterval in seconds, or nil if request is allowed now
    func timeUntilNextRequest() async -> TimeInterval?

    /// Get remaining requests for current hour
    /// - Returns: Number of requests remaining
    func remainingRequestsThisHour() async -> Int

    /// Get remaining requests for current year
    /// - Returns: Number of requests remaining
    func remainingRequestsThisYear() async -> Int

    /// Get current hourly call count
    /// - Returns: Number of calls made this hour
    func getHourlyCallCount() async -> Int

    /// Get current yearly call count
    /// - Returns: Number of calls made this year
    func getYearlyCallCount() async -> Int

    /// Reset all rate limits (admin function)
    func resetLimits() async
}
