//
//  ParsingDiagnosticsServiceTests.swift
//  PayslipMaxTests
//
//  Tests for ParsingDiagnosticsService
//

import XCTest
@testable import PayslipMax

final class ParsingDiagnosticsServiceTests: XCTestCase {

    var sut: ParsingDiagnosticsService!

    override func setUp() {
        super.setUp()
        sut = ParsingDiagnosticsService.shared
        sut.resetSession()
    }

    override func tearDown() {
        sut.resetSession()
        sut = nil
        super.tearDown()
    }

    // MARK: - Reset Tests

    func testResetSession_ClearsAllData() {
        // Given: Record some events
        sut.recordMandatoryComponentMissing("BPAY")
        sut.recordUnclassifiedComponent("UNKNOWN", value: 100.0, context: "test")

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // When
        sut.resetSession()

        // Wait for reset
        let resetExpectation = XCTestExpectation(description: "Wait for reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resetExpectation.fulfill()
        }
        wait(for: [resetExpectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.unclassifiedCount, 0)
        XCTAssertEqual(summary.patternFailureCount, 0)
        XCTAssertEqual(summary.totalComponents, 0)
    }

    // MARK: - Recording Tests

    func testRecordMandatoryComponentMissing_UpdatesSummary() {
        // When
        sut.recordMandatoryComponentMissing("BPAY")
        sut.recordMandatoryComponentMissing("DSOP")

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.totalComponents, 2)
        XCTAssertTrue(summary.recommendations.contains(where: { $0.contains("BPAY") }))
        XCTAssertTrue(summary.recommendations.contains(where: { $0.contains("DSOP") }))
    }

    func testRecordUnclassifiedComponent_TracksCode() {
        // When
        sut.recordUnclassifiedComponent("NEWCODE", value: 500.0, context: "test context")

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.unclassifiedCount, 1)
        XCTAssertTrue(summary.recommendations.contains(where: { $0.contains("NEWCODE") }))
    }

    func testRecordPatternMatchFailure_TracksCode() {
        // When
        sut.recordPatternMatchFailure("DA", searchedText: "sample text without DA")

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.patternFailureCount, 1)
        XCTAssertTrue(summary.recommendations.contains(where: { $0.contains("DA") }))
    }

    // MARK: - Near Miss Tests

    func testRecordNearMissTotals_WithinRange_RecordsEvent() {
        // When: 2% error is within near-miss range (1-5%)
        sut.recordNearMissTotals(
            earningsExpected: 100000,
            earningsActual: 98000,
            deductionsExpected: 30000,
            deductionsActual: 29400
        )

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.nearMissCount, 1)
    }

    func testRecordNearMissTotals_OutsideRange_DoesNotRecord() {
        // When: 0.5% error is below near-miss range
        sut.recordNearMissTotals(
            earningsExpected: 100000,
            earningsActual: 99500,
            deductionsExpected: 30000,
            deductionsActual: 29850
        )

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.nearMissCount, 0)
    }

    // MARK: - Confidence Calculation Tests

    func testOverallConfidence_NoIssues_Returns1() {
        // Given: Clean session with no issues
        sut.resetSession()

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.overallConfidence, 1.0, accuracy: 0.01)
    }

    func testOverallConfidence_WithMandatoryMissing_DecreasesByExpectedAmount() {
        // When: Record mandatory component missing
        sut.recordMandatoryComponentMissing("BPAY")

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: Confidence should decrease by 0.2 (20%)
        let summary = sut.getSessionSummary()
        XCTAssertEqual(summary.overallConfidence, 0.8, accuracy: 0.01)
    }

    // MARK: - GetAllEvents Tests

    func testGetAllEvents_ReturnsRecordedEvents() {
        // When
        sut.recordMandatoryComponentMissing("BPAY")
        sut.recordUnclassifiedComponent("TEST", value: 100, context: "ctx")

        // Wait for async
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        let events = sut.getAllEvents()
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.contains(where: { $0.eventType == .mandatoryComponentMissing }))
        XCTAssertTrue(events.contains(where: { $0.eventType == .unclassifiedComponent }))
    }
}

