import Foundation

/// Feature flag extension for local diagnostics.
private enum DiagnosticsFeatureFlag {
    static var isEnabled: Bool {
        FeatureFlagManager.shared.isEnabled(.enhancedAnalytics)
    }
}

/// A local-only diagnostics recorder that stores PII-safe events in memory
/// and produces an anonymized JSON bundle on demand.
final class DiagnosticsService {
    static let shared = DiagnosticsService()

    private let encoder: JSONEncoder
    private let queue = DispatchQueue(label: "com.payslipmax.diagnostics", qos: .utility)
    private var events: [DiagnosticsEvent] = []

    private init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
    }

    func recordExtractionDecision(_ decision: ExtractionDecision) {
        guard DiagnosticsFeatureFlag.isEnabled else { return }
        let event = DiagnosticsEvent(
            type: .extractionDecision,
            timestamp: Date(),
            payload: .extractionDecision(decision)
        )
        queue.async { self.events.append(event) }
    }

    func recordParseTelemetryAggregate(_ agg: ParseTelemetryAggregate) {
        guard DiagnosticsFeatureFlag.isEnabled else { return }
        let event = DiagnosticsEvent(
            type: .parseTelemetryAggregate,
            timestamp: Date(),
            payload: .parseTelemetryAggregate(agg)
        )
        queue.async { self.events.append(event) }
    }

    /// Produces a JSON data blob for export. No PII is included by design.
    func exportBundle() -> Data? {
        var snapshot: [DiagnosticsEvent] = []
        queue.sync { snapshot = self.events }
        let bundle = DiagnosticsBundle(version: "1.0", createdAt: Date(), events: snapshot)
        return try? encoder.encode(bundle)
    }

    /// Clears in-memory events. Callers should export first.
    func reset() {
        queue.async { self.events.removeAll() }
    }
}


