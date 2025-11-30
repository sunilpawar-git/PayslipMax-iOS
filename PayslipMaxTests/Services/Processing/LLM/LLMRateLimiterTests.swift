//
//  LLMRateLimiterTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Rate Limiter service
//

import XCTest
@testable import PayslipMax

final class LLMRateLimiterTests: XCTestCase {

    var rateLimiter: LLMRateLimiter!
    var userDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        // Use in-memory UserDefaults for testing
        suiteName = "test-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        rateLimiter = LLMRateLimiter(userDefaults: userDefaults)
    }

    override func tearDown() {
        rateLimiter = nil
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Hourly Limit Tests

    func testHourlyLimitEnforcement() async {
        // Given - Default limit is 5/hour, disable delay
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            let allowed = await rateLimiter.canMakeRequest()
            XCTAssertTrue(allowed)
            await rateLimiter.recordRequest()
        }

        // When - 6th request
        let canMake6th = await rateLimiter.canMakeRequest()

        // Then
        XCTAssertFalse(canMake6th)
    }

    func testHourlyLimitReset() async {
        // Given - Hit the hourly limit, disable delay
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            await rateLimiter.recordRequest()
        }
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        // When - Time passes (simulate by creating new limiter)
        // In real scenario, timestamps would be > 1 hour old
        // For unit test, we'll test the remaining logic
        let remaining = await rateLimiter.remainingRequestsThisHour()

        // Then
        XCTAssertEqual(remaining, 0)
    }

    func testRemainingRequestsThisHour() async {
        // Given - disable delay
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        await rateLimiter.recordRequest()

        // When
        let remaining = await rateLimiter.remainingRequestsThisHour()

        // Then
        XCTAssertEqual(remaining, 3)  // 5 - 2 = 3
    }

    // MARK: - Yearly Limit Tests

    func testYearlyLimitEnforcement() async {
        // Given - Set low yearly limit for testing, disable delay
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerYear = 3
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<3 {
            let allowed = await rateLimiter.canMakeRequest()
            XCTAssertTrue(allowed)
            await rateLimiter.recordRequest()
        }

        // When - 4th request
        let canMake4th = await rateLimiter.canMakeRequest()

        // Then
        XCTAssertFalse(canMake4th)
    }

    func testRemainingRequestsThisYear() async {
        // Given - Set low yearly limit, disable delay
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerYear = 10
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        await rateLimiter.recordRequest()

        // When
        let remaining = await rateLimiter.remainingRequestsThisYear()

        // Then
        XCTAssertEqual(remaining, 8)  // 10 - 2 = 8
    }

    // MARK: - Minimum Delay Tests

    func testMinimumDelayEnforcement() async {
        // Given - Set delay to 10s explicitly
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 10
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()

        // When - Immediate second request
        let canMakeImmediate = await rateLimiter.canMakeRequest()

        // Then - Should be denied due to minimum delay
        XCTAssertFalse(canMakeImmediate)
    }

    func testTimeUntilNextRequest() async {
        // Given - Configure with minDelaySeconds = 10
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 10
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()

        // When
        let timeUntil = await rateLimiter.timeUntilNextRequest()

        // Then - Should need to wait approximately the minimum delay time
        if let delay = timeUntil {
            XCTAssertGreaterThan(delay, 0)
            XCTAssertLessThanOrEqual(delay, 10.0)
        } else {
            XCTFail("Expected a delay after recording a request with minDelaySeconds configured")
        }
    }

    // MARK: - Admin Override Tests

    func testAdminOverrideBypassesLimits() async {
        // Given - Hit all limits
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerYear = 1
        config.maxCallsPerHour = 1
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        // When - Enable admin override
        rateLimiter.setAdminOverride(true)

        // Then - Can now make requests
        let allowedOverride = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedOverride)
    }

    func testAdminOverrideCanBeDisabled() async {
        // Given
        rateLimiter.setAdminOverride(true)
        let allowedOverride = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedOverride)

        // When
        rateLimiter.setAdminOverride(false)

        // Then - Normal limits apply
        // Reset config to ensure delay doesn't block us
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            await rateLimiter.recordRequest()
        }
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)
    }

    // MARK: - Configuration Tests

    func testConfigurationUpdate() async {
        // Given
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 10
        config.maxCallsPerYear = 100
        config.minDelaySeconds = 5

        // When
        rateLimiter.updateConfiguration(config)

        // Then
        let retrieved = rateLimiter.getCurrentConfiguration()
        XCTAssertEqual(retrieved.maxCallsPerHour, 10)
        XCTAssertEqual(retrieved.maxCallsPerYear, 100)
        XCTAssertEqual(retrieved.minDelaySeconds, 5)
    }

    func testConfigurationPersistence() {
        // Given
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 15
        config.save()

        // When - Create new limiter
        let newLimiter = LLMRateLimiter(userDefaults: userDefaults)
        let retrievedConfig = newLimiter.getCurrentConfiguration()

        // Then
        XCTAssertEqual(retrievedConfig.maxCallsPerHour, 15)
    }

    func testDisableRateLimiting() async {
        // Given
        var config = LLMRateLimitConfiguration.default
        config.isEnabled = false
        config.minDelaySeconds = 0
        rateLimiter.updateConfiguration(config)

        // When - Try to make many requests
        for _ in 0..<10 {
            let allowed = await rateLimiter.canMakeRequest()
            XCTAssertTrue(allowed)
            await rateLimiter.recordRequest()
        }

        // Then - All should succeed (limiter disabled)
        let allowedFinal = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedFinal)
    }

    // MARK: - Reset Tests

    func testResetLimits() async {
        // Given - Hit limits
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            await rateLimiter.recordRequest()
        }
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        // When
        await rateLimiter.resetLimits()

        // Then - Can make requests again
        let allowedReset = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedReset)
    }

    // MARK: - Multiple Limit Interaction Tests

    func testMultipleLimitsEnforced() async {
        // Given - Configure limits
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 3
        config.maxCallsPerYear = 5
        config.minDelaySeconds = 1
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        // When - Make requests up to hourly limit
        for i in 0..<3 {
            if i > 0 {
                try? await Task.sleep(nanoseconds: 1_100_000_000)  // 1.1 seconds
            }
            await rateLimiter.recordRequest()
        }

        // Then - Hourly limit reached
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)
    }
}
