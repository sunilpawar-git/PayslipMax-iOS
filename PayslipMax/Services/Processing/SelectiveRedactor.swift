//
//  SelectiveRedactor.swift
//  PayslipMax
//
//  Selective PII Redaction for LLM Processing
//  Redacts only PII while preserving pay codes, amounts, and structure
//

import Foundation
import OSLog

/// Selectively redacts PII from payslip text while preserving structure
/// Uses smarter redaction than full anonymization to improve LLM parsing accuracy
final class SelectiveRedactor: SelectiveRedactorProtocol {

    // MARK: - Properties

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.payslipmax.redaction", category: "Selective")
    private let configuration: SelectiveRedactionConfiguration

    // Use static patterns to avoid recompilation overhead
    private static let patterns: CompiledPatterns = {
        do {
            return try CompiledPatterns()
        } catch {
            fatalError("Failed to compile regex patterns: \(error)")
        }
    }()

    private(set) var lastRedactionReport: RedactionReport?

    // MARK: - Initialization

    init(configuration: SelectiveRedactionConfiguration = .default) {
        self.configuration = configuration
        logger.info("SelectiveRedactor initialized with \(configuration.preservedPayCodes.count) preserved pay codes")
    }

    // MARK: - Public Methods

    func redact(_ text: String) throws -> String {
        guard !text.isEmpty else {
            throw AnonymizationError.noTextProvided
        }

        guard text.count <= configuration.maxTextSize else {
            throw AnonymizationError.textTooLarge(size: text.count, limit: configuration.maxTextSize)
        }

        var redacted = text
        var redactedFields: [String] = []
        var totalRedactions = 0

        // Step 1: Redact names
        let (redacted1, nameCount) = redactField(
            in: redacted,
            pattern: Self.patterns.name,
            template: "Name: \(configuration.namePlaceholder)"
        )
        redacted = redacted1
        if nameCount > 0 {
            redactedFields.append("Name")
            totalRedactions += nameCount
        }

        // Step 2: Redact account numbers
        let (redacted2, accountCount) = redactField(
            in: redacted,
            pattern: Self.patterns.accountNumber,
            template: "A/C No: \(configuration.accountPlaceholder)"
        )
        redacted = redacted2
        if accountCount > 0 {
            redactedFields.append("Account Number")
            totalRedactions += accountCount
        }

        // Step 3: Redact PAN numbers
        let (redacted3, panCount) = redactField(
            in: redacted,
            pattern: Self.patterns.pan,
            template: "PAN No: \(configuration.panPlaceholder)"
        )
        redacted = redacted3
        if panCount > 0 {
            redactedFields.append("PAN")
            totalRedactions += panCount
        }

        // Step 4: Redact phone numbers
        let (redacted4, phoneCount) = redactField(
            in: redacted,
            pattern: Self.patterns.phone,
            template: "***PHONE***"
        )
        redacted = redacted4
        if phoneCount > 0 {
            redactedFields.append("Phone")
            totalRedactions += phoneCount
        }

        // Step 5: Redact email addresses
        let (redacted5, emailCount) = redactField(
            in: redacted,
            pattern: Self.patterns.email,
            template: "***EMAIL***"
        )
        redacted = redacted5
        if emailCount > 0 {
            redactedFields.append("Email")
            totalRedactions += emailCount
        }

        // Step 6: Identify preserved pay codes
        let preservedPayCodes = identifyPreservedPayCodes(in: redacted)

        // Create report
        lastRedactionReport = RedactionReport(
            redactedFields: redactedFields,
            preservedPayCodes: preservedPayCodes,
            redactionCount: totalRedactions,
            successful: true
        )

        logger.info("Selective redaction complete: \(totalRedactions) PII items redacted, \(preservedPayCodes.count) pay codes preserved")

        return redacted
    }

    // MARK: - Private Redaction Methods

    private func redactField(in text: String, pattern: NSRegularExpression, template: String) -> (String, Int) {
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: template
        )

        return (redacted, matches.count)
    }

    private func identifyPreservedPayCodes(in text: String) -> [String] {
        var found: [String] = []

        for payCode in configuration.preservedPayCodes {
            if text.range(of: payCode, options: .caseInsensitive) != nil {
                found.append(payCode)
            }
        }

        return found
    }
}

// MARK: - Compiled Patterns

/// Pre-compiled regex patterns for selective PII detection
private struct CompiledPatterns {
    let name: NSRegularExpression
    let accountNumber: NSRegularExpression
    let pan: NSRegularExpression
    let phone: NSRegularExpression
    let email: NSRegularExpression

    init() throws {
        // Name pattern - more conservative, only explicit "Name:" fields
        name = try NSRegularExpression(pattern: "(?i)Name\\s*[:\\-]\\s*[A-Za-z .]{3,50}")

        // Account number - matches Indian military account formats
        accountNumber = try NSRegularExpression(pattern: "(?i)A/C\\s*No\\.?[\\s:\\-]*[\\d/A-Za-z]+")

        // PAN - Indian PAN format
        pan = try NSRegularExpression(pattern: "(?i)PAN\\s*No\\.?[\\s:\\-]*[A-Z\\*\\d]+")

        // Phone - Indian phone numbers
        phone = try NSRegularExpression(pattern: "(?:\\+91[\\s\\-]?)?[6-9]\\d{9}")

        // Email
        email = try NSRegularExpression(pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}")
    }
}
