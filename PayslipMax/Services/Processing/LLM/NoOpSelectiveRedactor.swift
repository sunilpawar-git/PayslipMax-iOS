import Foundation

/// No-op redactor used when input is already PII-trimmed.
final class NoOpSelectiveRedactor: SelectiveRedactorProtocol {
    private(set) var lastRedactionReport: RedactionReport?

    func redact(_ text: String) throws -> String {
        lastRedactionReport = RedactionReport(
            redactedFields: [],
            preservedPayCodes: [],
            redactionCount: 0,
            successful: true
        )
        return text
    }
}

