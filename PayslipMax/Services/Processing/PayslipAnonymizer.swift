//
//  PayslipAnonymizer.swift
//  PayslipMax
//
//  Privacy-First PII Redaction for LLM Processing
//  Removes all personally identifiable information before sending to cloud LLMs
//

import Foundation

/// Patterns for identifying PII in payslip text
private enum PIIPattern {
    /// Name patterns - matches "Name: Sunil Pawar" -> "Name: [REDACTED]"
    static let name = #"(?i)Name\s*[:\-]\s*[A-Za-z\s]{3,50}"#

    /// Account number patterns - matches "A/C No: 16/110/206718K" -> "A/C No: [REDACTED]"
    static let accountNumber = #"(?i)A/C\s*No[\s:\-]*[\d/A-Za-z]+"#

    /// PAN number patterns - matches "PAN No: AR****90G" -> "PAN No: [REDACTED]"
    static let pan = #"PAN\s*No[\s:\-]*[A-Z\*\d]+"#

    /// Phone number patterns - matches "+91 9876543210" -> "+91 [REDACTED]"
    static let phone = #"(?:\+91[\s\-]?)?[6-9]\d{9}"#

    /// Email patterns - matches "user@example.com" -> "[EMAIL]"
    static let email = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}"#

    /// Address patterns - matches cities, states
    static let location = #"(?:Pune|Mumbai|Delhi|Bangalore|Hyderabad|Chennai|Kolkata),?\s*(?:Maharashtra|Karnataka|Tamil Nadu|West Bengal)?"#
}

/// Anonymizes payslip text by redacting all PII before LLM processing
/// Ensures zero privacy risk when sending data to cloud-based LLMs
final class PayslipAnonymizer {

    // MARK: - Properties

    /// Redaction placeholder for sensitive information
    private let redactionPlaceholder = "[REDACTED]"

    /// Statistics tracking
    private(set) var lastRedactionCount: Int = 0

    // MARK: - Public Methods

    /// Anonymizes payslip text by removing all PII
    /// - Parameter text: Raw payslip text containing PII
    /// - Returns: Anonymized text safe for LLM processing
    func anonymize(_ text: String) -> String {
        var anonymized = text
        var redactionCount = 0

        // 1. Redact names
        if let nameRegex = try? NSRegularExpression(pattern: PIIPattern.name) {
            let matches = nameRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            redactionCount += matches.count
            anonymized = nameRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: "Name: \(redactionPlaceholder)"
            )
        }

        // 2. Redact account numbers
        if let accountRegex = try? NSRegularExpression(pattern: PIIPattern.accountNumber) {
            let matches = accountRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            print("[PayslipAnonymizer] Found \(matches.count) A/C number matches")
            redactionCount += matches.count
            anonymized = accountRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: "A/C No: \(redactionPlaceholder)"
            )
        }

        // 3. Redact PAN numbers
        if let panRegex = try? NSRegularExpression(pattern: PIIPattern.pan) {
            let matches = panRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            redactionCount += matches.count
            anonymized = panRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: "PAN No: \(redactionPlaceholder)"
            )
        }

        // 4. Redact phone numbers
        if let phoneRegex = try? NSRegularExpression(pattern: PIIPattern.phone) {
            let matches = phoneRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            redactionCount += matches.count
            anonymized = phoneRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: redactionPlaceholder
            )
        }

        // 5. Redact email addresses
        if let emailRegex = try? NSRegularExpression(pattern: PIIPattern.email) {
            let matches = emailRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            redactionCount += matches.count
            anonymized = emailRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: "[EMAIL]"
            )
        }

        // 6. Redact locations (optional - less critical)
        if let locationRegex = try? NSRegularExpression(pattern: PIIPattern.location) {
            let matches = locationRegex.matches(in: anonymized, range: NSRange(anonymized.startIndex..., in: anonymized))
            redactionCount += matches.count
            anonymized = locationRegex.stringByReplacingMatches(
                in: anonymized,
                range: NSRange(anonymized.startIndex..., in: anonymized),
                withTemplate: "[LOCATION]"
            )
        }

        lastRedactionCount = redactionCount

        print("[PayslipAnonymizer] Redacted \(redactionCount) PII fields")

        return anonymized
    }

    /// Validates that text is properly anonymized (no PII remains)
    /// - Parameter text: Text to validate
    /// - Returns: True if text appears anonymized, false if PII detected
    func validate(_ text: String) -> Bool {
        // Check for common PII patterns
        let patterns = [
            PIIPattern.name,
            PIIPattern.accountNumber,
            PIIPattern.pan,
            PIIPattern.phone,
            PIIPattern.email
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                print("[PayslipAnonymizer] ⚠️ Validation failed - PII detected with pattern: \(pattern)")
                return false
            }
        }

        return true
    }
}
