//
//  MockParsingDiagnosticsService.swift
//  PayslipMaxTests
//
//  Mock implementation of ParsingDiagnosticsServiceProtocol for testing
//

import Foundation
@testable import PayslipMax

final class MockParsingDiagnosticsService: ParsingDiagnosticsServiceProtocol {

    // MARK: - Tracking Properties

    var recordedUnclassifiedComponents: [(code: String, value: Double, context: String)] = []
    var recordedNearMissTotals: [(earningsExpected: Double, earningsActual: Double, deductionsExpected: Double, deductionsActual: Double)] = []
    var recordedPatternFailures: [(code: String, searchedText: String)] = []
    var recordedClassificationOverrides: [(code: String, from: String, to: String, reason: String)] = []
    var recordedMandatoryMissing: [String] = []
    var resetSessionCalled = false

    // MARK: - Configuration

    var summaryToReturn = ParsingDiagnosticsSummary(
        totalComponents: 0,
        unclassifiedCount: 0,
        nearMissCount: 0,
        patternFailureCount: 0,
        overallConfidence: 1.0,
        recommendations: []
    )

    // MARK: - Protocol Implementation

    func recordUnclassifiedComponent(_ code: String, value: Double, context: String) {
        recordedUnclassifiedComponents.append((code, value, context))
    }

    func recordNearMissTotals(
        earningsExpected: Double,
        earningsActual: Double,
        deductionsExpected: Double,
        deductionsActual: Double
    ) {
        recordedNearMissTotals.append((earningsExpected, earningsActual, deductionsExpected, deductionsActual))
    }

    func recordPatternMatchFailure(_ code: String, searchedText: String) {
        recordedPatternFailures.append((code, searchedText))
    }

    func recordClassificationOverride(_ code: String, from: String, to: String, reason: String) {
        recordedClassificationOverrides.append((code, from, to, reason))
    }

    func recordMandatoryComponentMissing(_ code: String) {
        recordedMandatoryMissing.append(code)
    }

    func getSessionSummary() -> ParsingDiagnosticsSummary {
        return summaryToReturn
    }

    func resetSession() {
        resetSessionCalled = true
        recordedUnclassifiedComponents.removeAll()
        recordedNearMissTotals.removeAll()
        recordedPatternFailures.removeAll()
        recordedClassificationOverrides.removeAll()
        recordedMandatoryMissing.removeAll()
    }

    func getAllEvents() -> [ParsingDiagnosticEvent] {
        return []
    }
}

