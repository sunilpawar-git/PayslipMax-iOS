//
//  LLMRateLimiterTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Rate Limiter service - Core Tests
//

import XCTest
@testable import PayslipMax

final class LLMRateLimiterTests: XCTestCase {

    var rateLimiter: LLMRateLimiter!
    var userDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
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
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            let allowed = await rateLimiter.canMakeRequest()
            XCTAssertTrue(allowed)
            await rateLimiter.recordRequest()
        }

        let canMake6th = await rateLimiter.canMakeRequest()
        XCTAssertFalse(canMake6th)
    }

    func testHourlyLimitReset() async {
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            await rateLimiter.recordRequest()
        }
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        let remaining = await rateLimiter.remainingRequestsThisHour()
        XCTAssertEqual(remaining, 0)
    }

    func testRemainingRequestsThisHour() async {
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        await rateLimiter.recordRequest()

        let remaining = await rateLimiter.remainingRequestsThisHour()
        XCTAssertEqual(remaining, 3)
    }

    // MARK: - Yearly Limit Tests

    func testYearlyLimitEnforcement() async {
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

        let canMake4th = await rateLimiter.canMakeRequest()
        XCTAssertFalse(canMake4th)
    }

    func testRemainingRequestsThisYear() async {
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerYear = 10
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        await rateLimiter.recordRequest()

        let remaining = await rateLimiter.remainingRequestsThisYear()
        XCTAssertEqual(remaining, 8)
    }

    // MARK: - Minimum Delay Tests

    func testMinimumDelayEnforcement() async {
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 10
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()

        let canMakeImmediate = await rateLimiter.canMakeRequest()
        XCTAssertFalse(canMakeImmediate)
    }

    func testTimeUntilNextRequest() async {
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 10
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()

        let timeUntil = await rateLimiter.timeUntilNextRequest()

        if let delay = timeUntil {
            XCTAssertGreaterThan(delay, 0)
            XCTAssertLessThanOrEqual(delay, 10.0)
        } else {
            XCTFail("Expected a delay after recording a request with minDelaySeconds configured")
        }
    }

    // MARK: - Reset Tests

    func testResetLimits() async {
        var config = LLMRateLimitConfiguration.default
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for _ in 0..<5 {
            await rateLimiter.recordRequest()
        }
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        await rateLimiter.resetLimits()

        let allowedReset = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedReset)
    }
}
