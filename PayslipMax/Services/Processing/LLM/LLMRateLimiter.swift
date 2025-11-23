//
//  LLMRateLimiter.swift
//  PayslipMax
//
//  Service for rate limiting LLM API calls
//

import Foundation
import OSLog

/// Service to enforce rate limits on LLM API usage
final class LLMRateLimiter: LLMRateLimiterProtocol {

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "RateLimiter")
    private let userDefaults: UserDefaults

    /// Configuration
    private(set) var maxCallsPerHour: Int
    private(set) var maxCallsPerYear: Int
    private(set) var minDelaySeconds: TimeInterval
    private(set) var isEnabled: Bool

    // UserDefaults keys
    private enum Keys {
        static let hourlyCallTimestamps = "llm_hourly_call_timestamps"
        static let yearlyCallCount = "llm_yearly_call_count"
        static let yearlyCallCountYear = "llm_yearly_call_count_year"
        static let lastRequestTimestamp = "llm_last_request_timestamp"
        static let rateLimiterEnabled = "llm_rate_limiter_enabled"
        static let adminOverride = "llm_rate_limiter_admin_override"
    }

    // MARK: - Initialization

    /// Initialize rate limiter with configuration
    /// - Parameters:
    ///   - configuration: Rate limit configuration (defaults to stored or default config)
    ///   - userDefaults: UserDefaults instance for persistence
    init(configuration: LLMRateLimitConfiguration? = nil,
         userDefaults: UserDefaults = .standard) {

        let config = configuration ?? LLMRateLimitConfiguration.load()

        self.maxCallsPerHour = config.maxCallsPerHour
        self.maxCallsPerYear = config.maxCallsPerYear
        self.minDelaySeconds = config.minDelaySeconds
        self.isEnabled = config.isEnabled
        self.userDefaults = userDefaults
    }

    // MARK: - LLMRateLimiterProtocol

    func canMakeRequest() async -> Bool {
        // Check admin override
        if userDefaults.bool(forKey: Keys.adminOverride) {
            logger.info("Rate limiter bypassed (admin override)")
            return true
        }

        // Check if rate limiting is enabled
        guard isEnabled else {
            return true
        }

        // Check minimum delay
        if let lastTimestamp = getLastRequestTimestamp() {
            let timeSinceLast = Date().timeIntervalSince(lastTimestamp)
            if timeSinceLast < minDelaySeconds {
                logger.info("Rate limited: minimum delay not met (\(timeSinceLast)s < \(self.minDelaySeconds)s)")
                return false
            }
        }

        // Check hourly limit
        let hourlyCount = fetchHourlyCallCount()
        if hourlyCount >= maxCallsPerHour {
            logger.info("Rate limited: hourly limit reached (\(hourlyCount)/\(self.maxCallsPerHour))")
            return false
        }

        // Check yearly limit
        let yearlyCount = fetchYearlyCallCount()
        if yearlyCount >= maxCallsPerYear {
            logger.info("Rate limited: yearly limit reached (\(yearlyCount)/\(self.maxCallsPerYear))")
            return false
        }

        return true
    }

    func recordRequest() async {
        let now = Date()

        // Update last request timestamp
        userDefaults.set(now.timeIntervalSince1970, forKey: Keys.lastRequestTimestamp)

        // Update hourly timestamps
        var timestamps = getHourlyCallTimestamps()
        timestamps.append(now)
        saveHourlyCallTimestamps(timestamps)

        // Update yearly count
        incrementYearlyCallCount()

        logger.debug("Recorded LLM request at \(now)")
    }

    func timeUntilNextRequest() async -> TimeInterval? {
        guard isEnabled else { return nil }

        // Check minimum delay
        if let lastTimestamp = getLastRequestTimestamp() {
            let timeSinceLast = Date().timeIntervalSince(lastTimestamp)
            if timeSinceLast < minDelaySeconds {
                return minDelaySeconds - timeSinceLast
            }
        }

        // Check hourly limit
        let timestamps = getHourlyCallTimestamps()
        if timestamps.count >= maxCallsPerHour {
            // Find oldest timestamp in current hour
            if let oldest = timestamps.first {
                let oneHourLater = oldest.addingTimeInterval(3600)
                let timeUntil = oneHourLater.timeIntervalSince(Date())
                if timeUntil > 0 {
                    return timeUntil
                }
            }
        }

        // No restriction
        return nil
    }

    func remainingRequestsThisHour() async -> Int {
        let count = fetchHourlyCallCount()
        return max(0, maxCallsPerHour - count)
    }

    func remainingRequestsThisYear() async -> Int {
        let count = fetchYearlyCallCount()
        return max(0, maxCallsPerYear - count)
    }

    func resetLimits() async {
        userDefaults.removeObject(forKey: Keys.hourlyCallTimestamps)
        userDefaults.removeObject(forKey: Keys.yearlyCallCount)
        userDefaults.removeObject(forKey: Keys.yearlyCallCountYear)
        userDefaults.removeObject(forKey: Keys.lastRequestTimestamp)

        logger.info("Rate limits reset")
    }

    func getHourlyCallCount() async -> Int {
        return fetchHourlyCallCount()
    }

    func getYearlyCallCount() async -> Int {
        return fetchYearlyCallCount()
    }

    // MARK: - Private Helpers

    private func getLastRequestTimestamp() -> Date? {
        let interval = userDefaults.double(forKey: Keys.lastRequestTimestamp)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private func getHourlyCallTimestamps() -> [Date] {
        guard let data = userDefaults.data(forKey: Keys.hourlyCallTimestamps),
              let timestamps = try? JSONDecoder().decode([TimeInterval].self, from: data) else {
            return []
        }

        let oneHourAgo = Date().addingTimeInterval(-3600)
        let dates = timestamps.map { Date(timeIntervalSince1970: $0) }

        // Filter to only timestamps within the last hour
        return dates.filter { $0 > oneHourAgo }
    }

    private func saveHourlyCallTimestamps(_ dates: [Date]) {
        let intervals = dates.map { $0.timeIntervalSince1970 }
        if let data = try? JSONEncoder().encode(intervals) {
            userDefaults.set(data, forKey: Keys.hourlyCallTimestamps)
        }
    }

    private func fetchHourlyCallCount() -> Int {
        return getHourlyCallTimestamps().count
    }

    private func fetchYearlyCallCount() -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        let storedYear = userDefaults.integer(forKey: Keys.yearlyCallCountYear)

        // Reset if year has changed
        if storedYear != currentYear {
            userDefaults.set(0, forKey: Keys.yearlyCallCount)
            userDefaults.set(currentYear, forKey: Keys.yearlyCallCountYear)
            return 0
        }

        return userDefaults.integer(forKey: Keys.yearlyCallCount)
    }

    private func incrementYearlyCallCount() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let storedYear = userDefaults.integer(forKey: Keys.yearlyCallCountYear)

        // Reset if year has changed
        if storedYear != currentYear {
            userDefaults.set(1, forKey: Keys.yearlyCallCount)
            userDefaults.set(currentYear, forKey: Keys.yearlyCallCountYear)
        } else {
            let count = userDefaults.integer(forKey: Keys.yearlyCallCount)
            userDefaults.set(count + 1, forKey: Keys.yearlyCallCount)
        }
    }
}

// MARK: - Configuration Methods

extension LLMRateLimiter {
    /// Update rate limiter configuration
    /// - Parameter config: New rate limit configuration
    func updateConfiguration(_ config: LLMRateLimitConfiguration) {
        self.maxCallsPerHour = config.maxCallsPerHour
        self.maxCallsPerYear = config.maxCallsPerYear
        self.minDelaySeconds = config.minDelaySeconds
        self.isEnabled = config.isEnabled

        config.save()
        logger.info("Updated rate limit configuration")
    }

    /// Get current configuration
    /// - Returns: Current rate limit configuration
    func getCurrentConfiguration() -> LLMRateLimitConfiguration {
        return LLMRateLimitConfiguration(
            maxCallsPerHour: maxCallsPerHour,
            maxCallsPerYear: maxCallsPerYear,
            minDelaySeconds: minDelaySeconds,
            isEnabled: isEnabled
        )
    }

    /// Enable admin override (bypasses all rate limits)
    func setAdminOverride(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.adminOverride)
        logger.info("Admin override \(enabled ? "enabled" : "disabled")")
    }
}
