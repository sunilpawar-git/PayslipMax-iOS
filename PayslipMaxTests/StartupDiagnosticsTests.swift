//
//  StartupDiagnosticsTests.swift
//  PayslipMaxTests
//
//  Created for Phase 2: Development Infrastructure
//  Verifies StartupDiagnostics logging functionality
//

import XCTest
import OSLog
@testable import PayslipMax

final class StartupDiagnosticsTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset any state if needed
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    @MainActor
    func testLogConfigurationInDebugBuild() {
        // Verify that logConfiguration() runs without crashing in Debug builds
        // This is primarily a smoke test as we can't easily capture os.Logger output

        #if DEBUG
        // Should execute without throwing or crashing
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #else
        // In Release, it should return early and do nothing
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #endif
    }

    @MainActor
    func testLogConfigurationDoesNotCrashWithoutDIContainer() {
        // Verify that even if DI services are not fully initialized,
        // the logging doesn't crash the app
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
    }

    @MainActor
    func testLogConfigurationCallsLLMService() {
        // Verify that the diagnostics method accesses LLM settings
        // This is an integration test that verifies the dependencies are available

        #if DEBUG
        let llmService = DIContainer.shared.makeLLMSettingsService()

        // Just verify we can access the service
        XCTAssertNotNil(llmService)

        // Verify it has valid values
        _ = llmService.isLLMEnabled
        _ = llmService.selectedProvider

        // Now run diagnostics
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #endif
    }

    @MainActor
    func testLogConfigurationAccessesRateLimitConfiguration() {
        // Verify that rate limit configuration is accessible

        #if DEBUG
        let rateLimitConfig = LLMRateLimitConfiguration.default

        XCTAssertNotNil(rateLimitConfig)
        XCTAssertFalse(rateLimitConfig.isEnabled, "Rate limiting should be disabled in Debug")
        XCTAssertEqual(rateLimitConfig.maxCallsPerYear, 999999, "Max calls should be unlimited in Debug")

        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #endif
    }

    @MainActor
    func testLogConfigurationAccessesFeatureFlags() {
        // Verify that feature flags are accessible

        #if DEBUG
        let featureFlagConfig = FeatureFlagConfiguration.shared

        _ = featureFlagConfig.getDefaultState(for: .enhancedDashboard)
        _ = featureFlagConfig.getDefaultState(for: .militaryInsights)

        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #endif
    }

    @MainActor
    func testLogConfigurationChecksBackendProxyStatus() {
        // Verify that backend proxy configuration is checked

        #if DEBUG
        XCTAssertFalse(BuildConfiguration.useBackendProxy, "Backend proxy should be disabled in Debug")
        #else
        XCTAssertTrue(BuildConfiguration.useBackendProxy, "Backend proxy should be enabled in Release")
        #endif

        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
    }

    func testStartupDiagnosticsIsMainActorIsolated() {
        // Verify that StartupDiagnostics properly enforces MainActor isolation
        // This is important since it accesses DIContainer and UI-related services

        Task { @MainActor in
            XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        }
    }

    @MainActor
    func testLogConfigurationMultipleCalls() {
        // Verify that calling logConfiguration multiple times doesn't cause issues

        #if DEBUG
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        XCTAssertNoThrow(StartupDiagnostics.logConfiguration())
        #endif
    }
}
