import Foundation

/// Lightweight, PII-safe diagnostics payloads used for offline debugging/export.
/// Intentionally excludes raw text, names, account numbers, and any user-identifiable data.
struct DiagnosticsBundle: Codable {
    let version: String
    let createdAt: Date
    let events: [DiagnosticsEvent]
}

/// Top-level diagnostics event wrapper with minimal schema and stable keys.
struct DiagnosticsEvent: Codable {
    enum EventType: String, Codable {
        case extractionDecision
        case parseTelemetryAggregate
    }

    let type: EventType
    let timestamp: Date
    let payload: Payload

    enum Payload: Codable {
        case extractionDecision(ExtractionDecision)
        case parseTelemetryAggregate(ParseTelemetryAggregate)

        private enum CodingKeys: String, CodingKey { case kind, value }

        private enum Kind: String, Codable { case extractionDecision, parseTelemetryAggregate }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .extractionDecision(let v):
                try container.encode(Kind.extractionDecision, forKey: .kind)
                try container.encode(v, forKey: .value)
            case .parseTelemetryAggregate(let v):
                try container.encode(Kind.parseTelemetryAggregate, forKey: .kind)
                try container.encode(v, forKey: .value)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .kind)
            switch kind {
            case .extractionDecision:
                self = .extractionDecision(try container.decode(ExtractionDecision.self, forKey: .value))
            case .parseTelemetryAggregate:
                self = .parseTelemetryAggregate(try container.decode(ParseTelemetryAggregate.self, forKey: .value))
            }
        }
    }
}

/// Structured, PII-safe log of how extraction strategy was selected.
struct ExtractionDecision: Codable {
    // Document characteristics
    let pageCount: Int
    let estimatedSizeBytes: UInt64
    let contentComplexity: String
    let hasScannedContent: Bool

    // Resources
    let availableMemoryMB: UInt64
    let estimatedMemoryNeedMB: UInt64
    let memoryPressureRatio: Double
    let processorCoreCount: Int

    // Decision
    let selectedStrategy: String
    let confidence: Double
    let reasoning: String

    // Options (subset, PII-safe)
    let useParallelProcessing: Bool
    let useAdaptiveBatching: Bool
    let maxConcurrentOperations: Int
    let memoryThresholdMB: Int
    let preprocessText: Bool
}

/// Aggregated telemetry summary for a parsing session, without raw content.
struct ParseTelemetryAggregate: Codable {
    let attempts: Int
    let successRate: Double
    let averageProcessingTimeSec: Double
    let fastestParserName: String?
    let fastestParserTimeSec: Double?
    let mostReliableParserName: String?
    let mostReliableParserSuccessRate: Double?
}


