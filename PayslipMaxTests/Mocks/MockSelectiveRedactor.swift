//
//  MockSelectiveRedactor.swift
//  PayslipMaxTests
//
//  Mock implementation of SelectiveRedactorProtocol for testing
//

import Foundation
@testable import PayslipMax

final class MockSelectiveRedactor: SelectiveRedactorProtocol {

    // MARK: - Mock Configuration

    var shouldThrowError: Bool = false
    var errorToThrow: Error?
    var mockRedactedText: String?
    var mockReport: RedactionReport?

    // MARK: - Call Tracking

    private(set) var redactCallCount = 0
    private(set) var lastRedactedText: String?

    // MARK: - SelectiveRedactorProtocol

    var lastRedactionReport: RedactionReport?

    func redact(_ text: String) throws -> String {
        redactCallCount += 1
        lastRedactedText = text

        if shouldThrowError {
            throw errorToThrow ?? AnonymizationError.noTextProvided
        }

        // Generate a reasonable mock redaction if not specified
        if let mockText = mockRedactedText {
            lastRedactionReport = mockReport ?? RedactionReport(
                redactedFields: ["Name"],
                preservedPayCodes: ["BPAY", "DSOP"],
                redactionCount: 1,
                successful: true
            )
            return mockText
        }

        // Simple default: just replace obvious PII patterns
        var redacted = text
        redacted = redacted.replacingOccurrences(of: #"Name:\s*[A-Za-z .]+"#, with: "Name: ***NAME***", options: .regularExpression)
        redacted = redacted.replacingOccurrences(of: #"A/C No:\s*[\d/A-Za-z]+"#, with: "A/C No: ***ACCOUNT***", options: .regularExpression)

        lastRedactionReport = RedactionReport(
            redactedFields: ["Name", "Account Number"],
            preservedPayCodes: [],
            redactionCount: 2,
            successful: true
        )

        return redacted
    }

    // MARK: - Helper Methods

    func reset() {
        redactCallCount = 0
        lastRedactedText = nil
        lastRedactionReport = nil
        shouldThrowError = false
        errorToThrow = nil
        mockRedactedText = nil
        mockReport = nil
    }
}
