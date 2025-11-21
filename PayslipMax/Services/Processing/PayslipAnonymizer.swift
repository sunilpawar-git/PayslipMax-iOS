//
//  PayslipAnonymizer.swift
//  PayslipMax
//
//  Privacy-First PII Redaction for LLM Processing
//  Removes all personally identifiable information before sending to cloud LLMs
//

import Foundation
import OSLog

/// Configuration for PII redaction placeholders and limits
struct AnonymizerConfiguration {
    /// Placeholder for redacted sensitive information
    let redactionPlaceholder: String

    /// Placeholder for redacted email addresses
    let emailPlaceholder: String

    /// Placeholder for redacted locations
    let locationPlaceholder: String

    /// Maximum text size to process (safety limit)
    let maxTextSize: Int

    static let `default` = AnonymizerConfiguration(
        redactionPlaceholder: "[REDACTED]",
        emailPlaceholder: "[EMAIL]",
        locationPlaceholder: "[LOCATION]",
        maxTextSize: 1_000_000  // 1MB of text
    )
}

/// Anonymizes payslip text by redacting all PII before LLM processing
/// Ensures zero privacy risk when sending data to cloud-based LLMs
final class PayslipAnonymizer: PayslipAnonymizerProtocol {

    // MARK: - Properties

    /// Logger for anonymization events
    private let logger = os.Logger(subsystem: "com.payslipmax.anonymizer", category: "PII")

    /// Configuration for redaction
    private let configuration: AnonymizerConfiguration

    /// Compiled regex patterns (cached for performance)
    private let compiledPatterns: CompiledPatterns

    /// Statistics tracking
    private(set) var lastRedactionCount: Int = 0

    // MARK: - Initialization

    init(configuration: AnonymizerConfiguration = .default) throws {
        self.configuration = configuration
        self.compiledPatterns = try CompiledPatterns()

        logger.info("PayslipAnonymizer initialized with max text size: \(configuration.maxTextSize)")
    }

    // MARK: - Public Methods

    /// Anonymizes payslip text by removing all PII
    /// - Parameter text: Raw payslip text containing PII
    /// - Returns: Anonymized text safe for LLM processing
    /// - Throws: AnonymizationError if redaction fails
    func anonymize(_ text: String) throws -> String {
        // Validation
        guard !text.isEmpty else {
            throw AnonymizationError.noTextProvided
        }

        guard text.count <= configuration.maxTextSize else {
            throw AnonymizationError.textTooLarge(size: text.count, limit: configuration.maxTextSize)
        }

        var anonymized = text
        var redactionCount = 0

        // 1. Redact names
        let (anonymized1, nameCount) = try redact(
            text: anonymized,
            using: compiledPatterns.name,
            replacement: "Name: \(configuration.redactionPlaceholder)",
            label: "names"
        )
        anonymized = anonymized1
        redactionCount += nameCount

        // 2. Redact account numbers
        let (anonymized2, accountCount) = try redact(
            text: anonymized,
            using: compiledPatterns.accountNumber,
            replacement: "A/C No: \(configuration.redactionPlaceholder)",
            label: "account numbers"
        )
        anonymized = anonymized2
        redactionCount += accountCount

        // 3. Redact PAN numbers
        let (anonymized3, panCount) = try redact(
            text: anonymized,
            using: compiledPatterns.pan,
            replacement: "PAN No: \(configuration.redactionPlaceholder)",
            label: "PAN numbers"
        )
        anonymized = anonymized3
        redactionCount += panCount

        // 4. Redact phone numbers
        let (anonymized4, phoneCount) = try redact(
            text: anonymized,
            using: compiledPatterns.phone,
            replacement: configuration.redactionPlaceholder,
            label: "phone numbers"
        )
        anonymized = anonymized4
        redactionCount += phoneCount

        // 5. Redact email addresses
        let (anonymized5, emailCount) = try redact(
            text: anonymized,
            using: compiledPatterns.email,
            replacement: configuration.emailPlaceholder,
            label: "emails"
        )
        anonymized = anonymized5
        redactionCount += emailCount

        // 6. Redact locations (optional - less critical)
        let (anonymized6, locationCount) = try redact(
            text: anonymized,
            using: compiledPatterns.location,
            replacement: configuration.locationPlaceholder,
            label: "locations"
        )
        anonymized = anonymized6
        redactionCount += locationCount

        lastRedactionCount = redactionCount

        logger.info("Redacted \(redactionCount) PII fields (names: \(nameCount), accounts: \(accountCount), PAN: \(panCount), phones: \(phoneCount), emails: \(emailCount), locations: \(locationCount))")

        return anonymized
    }

    /// Validates that text is properly anonymized (no PII remains)
    /// - Parameter text: Text to validate
    /// - Returns: True if text appears anonymized, false if PII detected
    func validate(_ text: String) -> Bool {
        // Check for common PII patterns
        let patternsToCheck: [(NSRegularExpression, String)] = [
            (compiledPatterns.name, "name"),
            (compiledPatterns.accountNumber, "account"),
            (compiledPatterns.pan, "PAN"),
            (compiledPatterns.phone, "phone"),
            (compiledPatterns.email, "email")
        ]

        for (regex, label) in patternsToCheck {
            if regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                logger.warning("Validation failed - \(label) PII detected")
                return false
            }
        }

        logger.debug("Validation passed - no PII detected")
        return true
    }

    // MARK: - Private Methods

    /// Redacts text using a compiled regex pattern
    /// - Parameters:
    ///   - text: Text to redact
    ///   - regex: Compiled regex pattern
    ///   - replacement: Replacement string
    ///   - label: Human-readable label for logging
    /// - Returns: Tuple of (redacted text, match count)
    private func redact(
        text: String,
        using regex: NSRegularExpression,
        replacement: String,
        label: String
    ) throws -> (String, Int) {
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        let count = matches.count

        if count > 0 {
            let redacted = regex.stringByReplacingMatches(
                in: text,
                range: range,
                withTemplate: replacement
            )
            return (redacted, count)
        }

        return (text, 0)
    }
}

// MARK: - Compiled Patterns

/// Pre-compiled regex patterns for PII detection (performance optimization)
private struct CompiledPatterns {
    let name: NSRegularExpression
    let accountNumber: NSRegularExpression
    let pan: NSRegularExpression
    let phone: NSRegularExpression
    let email: NSRegularExpression
    let location: NSRegularExpression

    init() throws {
        // FIXED: Using standard string escaping instead of raw string literals
        // Name pattern - matches "Name: Sunil Pawar" -> "Name: [REDACTED]"
        // FIXED: Changed \\s to space to avoid matching newlines and consuming subsequent lines
        name = try NSRegularExpression(pattern: "(?i)Name\\s*[:\\-]\\s*[A-Za-z .]{3,50}")

        // Account number - matches "A/C No: 16/110/206718K" -> "A/C No: [REDACTED]"
        // FIXED: Improved pattern to more reliably match A/C numbers
        accountNumber = try NSRegularExpression(pattern: "(?i)A/C\\s*No\\.?[\\s:\\-]*[\\d/A-Za-z]+")

        // PAN - matches "PAN No: AR****90G" -> "PAN No: [REDACTED]"
        pan = try NSRegularExpression(pattern: "(?i)PAN\\s*No\\.?[\\s:\\-]*[A-Z\\*\\d]+")

        // Phone - matches "+91 9876543210" -> "[REDACTED]"
        phone = try NSRegularExpression(pattern: "(?:\\+91[\\s\\-]?)?[6-9]\\d{9}")

        // Email - matches "user@example.com" -> "[EMAIL]"
        email = try NSRegularExpression(pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}")

        // Location - matches cities and states (extensible pattern)
        location = try NSRegularExpression(pattern: "(?:Pune|Mumbai|Delhi|Bangalore|Hyderabad|Chennai|Kolkata|Bengaluru|Ahmedabad),?\\s*(?:Maharashtra|Karnataka|Tamil Nadu|West Bengal|Gujarat)?")
    }
}
