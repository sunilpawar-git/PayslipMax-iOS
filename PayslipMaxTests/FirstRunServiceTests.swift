//
//  FirstRunServiceTests.swift
//  PayslipMaxTests
//
//  Created for Phase 2: Development Infrastructure
//  Tests for FirstRunService
//

import XCTest
@testable import PayslipMax

@MainActor
final class FirstRunServiceTests: XCTestCase {

    var userDefaults: UserDefaults!
    var service: FirstRunService!

    override func setUp() {
        super.setUp()
        // Use a temporary UserDefaults suite for testing
        userDefaults = UserDefaults(suiteName: "FirstRunServiceTests")
        userDefaults.removePersistentDomain(forName: "FirstRunServiceTests")
        service = FirstRunService(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "FirstRunServiceTests")
        userDefaults = nil
        service = nil
        super.tearDown()
    }

    func testPerformFirstRunSetup_FirstLaunch() {
        // Given
        XCTAssertFalse(userDefaults.bool(forKey: "app_has_launched_before"))

        // When
        service.performFirstRunSetupIfNeeded()

        // Then
        XCTAssertTrue(userDefaults.bool(forKey: "app_has_launched_before"))
        XCTAssertNotNil(userDefaults.string(forKey: "app_version_on_first_launch"))
    }

    func testPerformFirstRunSetup_SubsequentLaunch() {
        // Given
        userDefaults.set(true, forKey: "app_has_launched_before")
        userDefaults.set("0.9.0", forKey: "app_version_on_first_launch")

        // When
        service.performFirstRunSetupIfNeeded()

        // Then
        // Version should NOT change (proving it skipped initialization logic)
        XCTAssertEqual(userDefaults.string(forKey: "app_version_on_first_launch"), "0.9.0")
    }
}
