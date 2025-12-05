//
//  ParsingDiagnosticsService.swift
//  PayslipMax
//
//  Created for Universal Parser Enhancement - Instrumentation
//  Tracks parsing gaps and provides diagnostics for improvement
//

import Foundation
import OSLog

/// Service for tracking parsing diagnostics and gaps
/// Helps identify areas for Universal Parser improvement
final class ParsingDiagnosticsService: ParsingDiagnosticsServiceProtocol {

    // MARK: - Singleton

    static let shared = ParsingDiagnosticsService()

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.payslipmax.parsing", category: "Diagnostics")
    private var events: [ParsingDiagnosticEvent] = []
    private var unclassifiedComponents: Set<String> = []
    private var patternFailures: Set<String> = []
    private var mandatoryMissing: Set<String> = []
    private let queue = DispatchQueue(label: "com.payslipmax.diagnostics", qos: .utility)

    // MARK: - Initialization

    private init() {
        logger.info("ParsingDiagnosticsService initialized")
    }

    // MARK: - Public Methods

    func recordUnclassifiedComponent(_ code: String, value: Double, context: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let normalizedCode = code.uppercased()
            self.unclassifiedComponents.insert(normalizedCode)

            let event = ParsingDiagnosticEvent(
                timestamp: Date(),
                eventType: .unclassifiedComponent,
                details: "Component '\(code)' found with value ₹\(value) but not in classification database",
                componentCode: normalizedCode,
                expectedValue: nil,
                actualValue: value,
                percentageError: nil
            )
            self.events.append(event)

            self.logger.warning("📊 Unclassified: \(code) = ₹\(value)")
        }
    }

    func recordNearMissTotals(
        earningsExpected: Double,
        earningsActual: Double,
        deductionsExpected: Double,
        deductionsActual: Double
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let earningsError = abs(earningsActual - earningsExpected) / earningsExpected * 100
            let deductionsError = abs(deductionsActual - deductionsExpected) / deductionsExpected * 100

            // Only record if within 1-5% (near-miss range)
            let isNearMiss = (earningsError > 1 && earningsError <= 5) ||
                             (deductionsError > 1 && deductionsError <= 5)

            guard isNearMiss else { return }

            let event = ParsingDiagnosticEvent(
                timestamp: Date(),
                eventType: .nearMissTotals,
                details: "Near-miss: Earnings \(String(format: "%.2f", earningsError))% off, Deductions \(String(format: "%.2f", deductionsError))% off",
                componentCode: nil,
                expectedValue: earningsExpected,
                actualValue: earningsActual,
                percentageError: max(earningsError, deductionsError)
            )
            self.events.append(event)

            self.logger.info("📊 Near-miss totals: E=\(String(format: "%.2f", earningsError))%, D=\(String(format: "%.2f", deductionsError))%")
        }
    }

    func recordPatternMatchFailure(_ code: String, searchedText: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let normalizedCode = code.uppercased()
            self.patternFailures.insert(normalizedCode)

            let textSample = String(searchedText.prefix(100))

            let event = ParsingDiagnosticEvent(
                timestamp: Date(),
                eventType: .patternMatchFailure,
                details: "Known code '\(code)' not found. Sample: \(textSample)...",
                componentCode: normalizedCode,
                expectedValue: nil,
                actualValue: nil,
                percentageError: nil
            )
            self.events.append(event)

            self.logger.warning("📊 Pattern failure: \(code) not found")
        }
    }

    func recordClassificationOverride(_ code: String, from: String, to: String, reason: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let event = ParsingDiagnosticEvent(
                timestamp: Date(),
                eventType: .classificationOverride,
                details: "'\(code)' reclassified from \(from) to \(to). Reason: \(reason)",
                componentCode: code.uppercased(),
                expectedValue: nil,
                actualValue: nil,
                percentageError: nil
            )
            self.events.append(event)

            self.logger.info("📊 Override: \(code) \(from) → \(to)")
        }
    }

    func recordMandatoryComponentMissing(_ code: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let normalizedCode = code.uppercased()
            self.mandatoryMissing.insert(normalizedCode)

            let event = ParsingDiagnosticEvent(
                timestamp: Date(),
                eventType: .mandatoryComponentMissing,
                details: "Mandatory component '\(code)' not found in payslip",
                componentCode: normalizedCode,
                expectedValue: nil,
                actualValue: nil,
                percentageError: nil
            )
            self.events.append(event)

            self.logger.error("📊 Missing mandatory: \(code)")
        }
    }

    func getSessionSummary() -> ParsingDiagnosticsSummary {
        var summary: ParsingDiagnosticsSummary!

        queue.sync { [weak self] in
            guard let self = self else {
                summary = ParsingDiagnosticsSummary(
                    totalComponents: 0, unclassifiedCount: 0, nearMissCount: 0,
                    patternFailureCount: 0, overallConfidence: 1.0, recommendations: []
                )
                return
            }

            let nearMissCount = self.events.filter { $0.eventType == .nearMissTotals }.count

            // Calculate confidence based on issues found
            var confidence = 1.0
            confidence -= Double(self.unclassifiedComponents.count) * 0.05
            confidence -= Double(nearMissCount) * 0.1
            confidence -= Double(self.patternFailures.count) * 0.03
            confidence -= Double(self.mandatoryMissing.count) * 0.2
            confidence = max(0.0, confidence)

            let recommendations = self.generateRecommendations(nearMissCount: nearMissCount)

            summary = ParsingDiagnosticsSummary(
                totalComponents: self.events.count,
                unclassifiedCount: self.unclassifiedComponents.count,
                nearMissCount: nearMissCount,
                patternFailureCount: self.patternFailures.count,
                overallConfidence: confidence,
                recommendations: recommendations
            )
        }

        return summary
    }

    func resetSession() {
        queue.async { [weak self] in
            self?.events.removeAll()
            self?.unclassifiedComponents.removeAll()
            self?.patternFailures.removeAll()
            self?.mandatoryMissing.removeAll()
            self?.logger.info("📊 Diagnostics session reset")
        }
    }

    func getAllEvents() -> [ParsingDiagnosticEvent] {
        var result: [ParsingDiagnosticEvent] = []
        queue.sync {
            result = self.events
        }
        return result
    }

    // MARK: - Private Methods

    private func generateRecommendations(nearMissCount: Int) -> [String] {
        var recommendations: [String] = []

        if !unclassifiedComponents.isEmpty {
            let codes = Array(unclassifiedComponents.prefix(5)).joined(separator: ", ")
            recommendations.append("Add unclassified codes to database: \(codes)")
        }

        if nearMissCount > 0 {
            recommendations.append("Review pattern accuracy - \(nearMissCount) near-miss totals detected")
        }

        if !patternFailures.isEmpty {
            let codes = Array(patternFailures.prefix(3)).joined(separator: ", ")
            recommendations.append("Review patterns for codes: \(codes)")
        }

        if !mandatoryMissing.isEmpty {
            let codes = Array(mandatoryMissing).joined(separator: ", ")
            recommendations.append("Critical: Missing mandatory codes - \(codes)")
        }

        return recommendations
    }

    // MARK: - Debug Output

    /// Prints a formatted summary to console (for debugging)
    func printSummary() {
        let summary = getSessionSummary()

        print("""

        ═══════════════════════════════════════════════════════════
        📊 PARSING DIAGNOSTICS SUMMARY
        ═══════════════════════════════════════════════════════════
        • Unclassified components: \(summary.unclassifiedCount)
        • Near-miss totals: \(summary.nearMissCount)
        • Pattern failures: \(summary.patternFailureCount)
        • Overall confidence: \(String(format: "%.1f", summary.overallConfidence * 100))%

        Recommendations:
        \(summary.recommendations.map { "  → \($0)" }.joined(separator: "\n"))
        ═══════════════════════════════════════════════════════════

        """)
    }
}
