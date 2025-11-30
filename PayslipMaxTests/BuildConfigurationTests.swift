//
//  BuildConfigurationTests.swift
//  PayslipMaxTests
//
//  Created for Phase 2: Development Infrastructure
//  Verifies BuildConfiguration values
//

import XCTest
@testable import PayslipMax

final class BuildConfigurationTests: XCTestCase {

    func testBuildConfigurationDefaults() {
        // These tests verify the configuration based on the CURRENT build settings (Debug)
        // Note: When running tests in Xcode, DEBUG flag is usually set

        #if DEBUG
        XCTAssertTrue(BuildConfiguration.isDebug, "isDebug should be true in Debug builds")
        XCTAssertTrue(BuildConfiguration.llmEnabledByDefault, "LLM should be enabled by default in Debug")
        XCTAssertFalse(BuildConfiguration.rateLimitEnabled, "Rate limiting should be disabled in Debug")
        XCTAssertEqual(BuildConfiguration.maxCallsPerYear, 999999, "Max calls should be unlimited in Debug")
        XCTAssertEqual(BuildConfiguration.logLevel, .verbose, "Log level should be verbose in Debug")
        XCTAssertFalse(BuildConfiguration.useBackendProxy, "Backend proxy should be disabled in Debug")
        #else
        XCTAssertFalse(BuildConfiguration.isDebug, "isDebug should be false in Release builds")
        XCTAssertFalse(BuildConfiguration.llmEnabledByDefault, "LLM should be disabled by default in Release")
        XCTAssertTrue(BuildConfiguration.rateLimitEnabled, "Rate limiting should be enabled in Release")
        XCTAssertEqual(BuildConfiguration.maxCallsPerYear, 50, "Max calls should be limited in Release")
        XCTAssertEqual(BuildConfiguration.logLevel, .info, "Log level should be info in Release")
        XCTAssertTrue(BuildConfiguration.useBackendProxy, "Backend proxy should be enabled in Release")
        #endif
    }
}
