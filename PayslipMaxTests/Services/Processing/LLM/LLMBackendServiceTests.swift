//
//  LLMBackendServiceTests.swift
//  PayslipMaxTests
//
//  Created for Phase 4: Quality & Verification
//  Tests for LLMBackendService
//

import XCTest
@testable import PayslipMax
import FirebaseFunctions

final class LLMBackendServiceTests: XCTestCase {

    var service: LLMBackendService!

    override func setUp() {
        super.setUp()
        service = LLMBackendService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(service)
    }

    // Note: Detailed testing of parsePayslip requires running against the Firebase Emulator
    // or extensive mocking of the Firebase SDK which is not easily mockable (final classes).
    // We rely on integration tests for the actual network calls.
}
