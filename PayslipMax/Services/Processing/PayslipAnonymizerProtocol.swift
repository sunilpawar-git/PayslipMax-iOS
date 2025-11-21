//
//  PayslipAnonymizerProtocol.swift
//  PayslipMax
//
//  Protocol for PII anonymization with dependency injection support
//

import Foundation

/// Protocol for anonymizing payslip text by redacting PII
public protocol PayslipAnonymizerProtocol {
    /// Anonymizes payslip text by removing all PII
    /// - Parameter text: Raw payslip text containing PII
    /// - Returns: Anonymized text safe for LLM processing
    /// - Throws: AnonymizationError if redaction fails
    func anonymize(_ text: String) throws -> String

    /// Validates that text is properly anonymized (no PII remains)
    /// - Parameter text: Text to validate
    /// - Returns: True if text appears anonymized, false if PII detected
    func validate(_ text: String) -> Bool

    /// Returns the number of PII fields redacted in the last anonymization
    var lastRedactionCount: Int { get }
}

/// Errors that can occur during anonymization
enum AnonymizationError: Error, LocalizedError {
    case invalidRegexPattern(pattern: String, underlyingError: Error)
    case textTooLarge(size: Int, limit: Int)
    case noTextProvided

    var errorDescription: String? {
        switch self {
        case .invalidRegexPattern(let pattern, let error):
            return "Invalid regex pattern '\(pattern)': \(error.localizedDescription)"
        case .textTooLarge(let size, let limit):
            return "Text too large (\(size) chars, limit: \(limit))"
        case .noTextProvided:
            return "No text provided for anonymization"
        }
    }
}
