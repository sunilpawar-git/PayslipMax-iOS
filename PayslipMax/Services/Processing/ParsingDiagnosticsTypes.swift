//
//  ParsingDiagnosticsTypes.swift
//  PayslipMax
//
//  Data types for parsing diagnostics
//  Extracted from ParsingDiagnosticsService for SOLID compliance
//

import Foundation

// MARK: - Diagnostic Data Types

/// Represents a parsing diagnostic event
struct ParsingDiagnosticEvent: Codable {
    let timestamp: Date
    let eventType: DiagnosticEventType
    let details: String
    let componentCode: String?
    let expectedValue: Double?
    let actualValue: Double?
    let percentageError: Double?
}

/// Types of diagnostic events
enum DiagnosticEventType: String, Codable {
    case unclassifiedComponent      // Component found but not in database
    case nearMissTotals             // Totals within 1-5% of anchors
    case patternMatchFailure        // Known code not found
    case classificationOverride     // Context-based classification override
    case anchorExtractionFailure    // Failed to extract anchor values
    case mandatoryComponentMissing  // BPAY or DSOP missing
}

/// Summary of parsing diagnostics for a session
struct ParsingDiagnosticsSummary {
    let totalComponents: Int
    let unclassifiedCount: Int
    let nearMissCount: Int
    let patternFailureCount: Int
    let overallConfidence: Double
    let recommendations: [String]
}

// MARK: - Protocol Definition

/// Protocol for parsing diagnostics service
protocol ParsingDiagnosticsServiceProtocol {
    /// Records an unclassified component
    func recordUnclassifiedComponent(_ code: String, value: Double, context: String)

    /// Records near-miss totals
    func recordNearMissTotals(
        earningsExpected: Double,
        earningsActual: Double,
        deductionsExpected: Double,
        deductionsActual: Double
    )

    /// Records a pattern match failure
    func recordPatternMatchFailure(_ code: String, searchedText: String)

    /// Records a classification override
    func recordClassificationOverride(_ code: String, from: String, to: String, reason: String)

    /// Records mandatory component missing
    func recordMandatoryComponentMissing(_ code: String)

    /// Gets current session summary
    func getSessionSummary() -> ParsingDiagnosticsSummary

    /// Resets session diagnostics
    func resetSession()

    /// Gets all diagnostic events
    func getAllEvents() -> [ParsingDiagnosticEvent]
}

