//
//  LLMRateLimiterConfigTests.swift
//  PayslipMaxTests
//
//  Unit tests for LLM Rate Limiter configuration and admin override
//

import XCTest
@testable import PayslipMax

final class LLMRateLimiterConfigTests: XCTestCase {

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

    // MARK: - Admin Override Tests

    func testAdminOverrideBypassesLimits() async {
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerYear = 1
        config.maxCallsPerHour = 1
        config.minDelaySeconds = 0
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        await rateLimiter.recordRequest()
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)

        rateLimiter.setAdminOverride(true)

        let allowedOverride = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedOverride)
    }

    func testAdminOverrideCanBeDisabled() async {
        rateLimiter.setAdminOverride(true)
        let allowedOverride = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedOverride)

        rateLimiter.setAdminOverride(false)

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
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 10
        config.maxCallsPerYear = 100
        config.minDelaySeconds = 5

        rateLimiter.updateConfiguration(config)

        let retrieved = rateLimiter.getCurrentConfiguration()
        XCTAssertEqual(retrieved.maxCallsPerHour, 10)
        XCTAssertEqual(retrieved.maxCallsPerYear, 100)
        XCTAssertEqual(retrieved.minDelaySeconds, 5)
    }

    func testConfigurationPersistence() {
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 15
        config.save()

        let newLimiter = LLMRateLimiter(userDefaults: userDefaults)
        let retrievedConfig = newLimiter.getCurrentConfiguration()

        XCTAssertEqual(retrievedConfig.maxCallsPerHour, 15)
    }

    func testDisableRateLimiting() async {
        var config = LLMRateLimitConfiguration.default
        config.isEnabled = false
        config.minDelaySeconds = 0
        rateLimiter.updateConfiguration(config)

        for _ in 0..<10 {
            let allowed = await rateLimiter.canMakeRequest()
            XCTAssertTrue(allowed)
            await rateLimiter.recordRequest()
        }

        let allowedFinal = await rateLimiter.canMakeRequest()
        XCTAssertTrue(allowedFinal)
    }

    // MARK: - Multiple Limit Interaction Tests

    func testMultipleLimitsEnforced() async {
        var config = LLMRateLimitConfiguration.default
        config.maxCallsPerHour = 3
        config.maxCallsPerYear = 5
        config.minDelaySeconds = 1
        config.isEnabled = true
        rateLimiter.updateConfiguration(config)

        for i in 0..<3 {
            if i > 0 {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
            }
            await rateLimiter.recordRequest()
        }

        try? await Task.sleep(nanoseconds: 1_100_000_000)
        let allowed = await rateLimiter.canMakeRequest()
        XCTAssertFalse(allowed)
    }
}

