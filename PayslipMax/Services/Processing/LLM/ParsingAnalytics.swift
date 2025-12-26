//
//  ParsingAnalytics.swift
//  PayslipMax
//
//  Analytics and logging for payslip parsing operations
//

import Foundation
import OSLog

/// Analytics events for parsing operations
enum ParsingEvent {
    case parsingStarted
    case extractionComplete(duration: TimeInterval)
    case validationComplete(issues: Int, confidence: Double)
    case verificationTriggered(initialConfidence: Double)
    case verificationComplete(agreement: Double, finalConfidence: Double)
    case parsingComplete(confidence: Double, duration: TimeInterval, source: String)
    case parsingFailed(error: String, duration: TimeInterval)

    /// Event name for logging
    var eventName: String {
        switch self {
        case .parsingStarted:
            return "parsing_started"
        case .extractionComplete:
            return "extraction_complete"
        case .validationComplete:
            return "validation_complete"
        case .verificationTriggered:
            return "verification_triggered"
        case .verificationComplete:
            return "verification_complete"
        case .parsingComplete:
            return "parsing_complete"
        case .parsingFailed:
            return "parsing_failed"
        }
    }

    /// Event parameters for structured logging
    var parameters: [String: Any] {
        switch self {
        case .parsingStarted:
            return [:]

        case .extractionComplete(let duration):
            return [
                "duration_ms": Int(duration * 1000)
            ]

        case .validationComplete(let issues, let confidence):
            return [
                "issues_count": issues,
                "confidence": String(format: "%.2f", confidence)
            ]

        case .verificationTriggered(let initialConfidence):
            return [
                "initial_confidence": String(format: "%.2f", initialConfidence)
            ]

        case .verificationComplete(let agreement, let finalConfidence):
            return [
                "agreement": String(format: "%.2f", agreement),
                "final_confidence": String(format: "%.2f", finalConfidence)
            ]

        case .parsingComplete(let confidence, let duration, let source):
            return [
                "confidence": String(format: "%.2f", confidence),
                "duration_ms": Int(duration * 1000),
                "source": source
            ]

        case .parsingFailed(let error, let duration):
            return [
                "error": error,
                "duration_ms": Int(duration * 1000)
            ]
        }
    }
}

/// Analytics service for parsing operations
final class ParsingAnalytics {
    private static let logger = os.Logger(subsystem: "com.payslipmax.analytics", category: "Parsing")

    /// Log a parsing event with structured parameters
    /// - Parameter event: The parsing event to log
    static func log(_ event: ParsingEvent) {
        let eventName = event.eventName
        let params = event.parameters

        // Format parameters for logging
        let paramsString = params.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")

        if paramsString.isEmpty {
            logger.info("📊 \(eventName)")
        } else {
            logger.info("📊 \(eventName): \(paramsString)")
        }

        // Future: Send to analytics service (Firebase Analytics, etc.)
        // Analytics.logEvent(eventName, parameters: params)
    }

    /// Track parsing session metrics
    static func trackSession(
        startTime: Date,
        endTime: Date,
        success: Bool,
        confidence: Double?,
        verificationUsed: Bool
    ) {
        let duration = endTime.timeIntervalSince(startTime)

        logger.info("""
            📊 Parsing Session Summary:
              • Duration: \(String(format: "%.2f", duration))s
              • Success: \(success)
              • Confidence: \(confidence.map { String(format: "%.2f", $0) } ?? "N/A")
              • Verification: \(verificationUsed ? "Yes" : "No")
            """)
    }
}

