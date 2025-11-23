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

    private let logger = os.Logger(subsystem: "com.payslipmax.redaction", category: "Selective")
    private let configuration: SelectiveRedactionConfiguration
    private let compiledPatterns: CompiledPatterns

    private(set) var lastRedactionReport: RedactionReport?

    // MARK: - Initialization

    init(configuration: SelectiveRedactionConfiguration = .default) throws {
        self.configuration = configuration
        self.compiledPatterns = try CompiledPatterns()

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
        var preservedPayCodes: [String] = []
        var totalRedactions = 0

        // Step 1: Redact names while preserving pay code context
        let (redacted1, nameCount) = redactNames(from: redacted)
        redacted = redacted1
        if nameCount > 0 {
            redactedFields.append("Name")
            totalRedactions += nameCount
        }

        // Step 2: Redact account numbers
        let (redacted2, accountCount) = redactAccountNumbers(from: redacted)
        redacted = redacted2
        if accountCount > 0 {
            redactedFields.append("Account Number")
            totalRedactions += accountCount
        }

        // Step 3: Redact PAN numbers
        let (redacted3, panCount) = redactPANNumbers(from: redacted)
        redacted = redacted3
        if panCount > 0 {
            redactedFields.append("PAN")
            totalRedactions += panCount
        }

        // Step 4: Redact phone numbers (less common in payslips)
        let (redacted4, phoneCount) = redactPhoneNumbers(from: redacted)
        redacted = redacted4
        if phoneCount > 0 {
            redactedFields.append("Phone")
            totalRedactions += phoneCount
        }

        // Step 5: Redact email addresses (rare in payslips)
        let (redacted5, emailCount) = redactEmails(from: redacted)
        redacted = redacted5
        if emailCount > 0 {
            redactedFields.append("Email")
            totalRedactions += emailCount
        }

        // Step 6: Identify preserved pay codes (for reporting only)
        preservedPayCodes = identifyPreservedPayCodes(in: redacted)

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

    private func redactNames(from text: String) -> (String, Int) {
        // Pattern: "Name: John Doe" -> "Name: ***NAME***"
        // More conservative than full anonymizer - only redacts explicit name fields
        let pattern = compiledPatterns.name
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "Name: \(configuration.namePlaceholder)"
        )

        return (redacted, matches.count)
    }

    private func redactAccountNumbers(from text: String) -> (String, Int) {
        // Pattern: "A/C No: 16/110/206718K" -> "A/C No: ***ACCOUNT***"
        let pattern = compiledPatterns.accountNumber
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "A/C No: \(configuration.accountPlaceholder)"
        )

        return (redacted, matches.count)
    }

    private func redactPANNumbers(from text: String) -> (String, Int) {
        // Pattern: "PAN No: AR****90G" -> "PAN No: ***PAN***"
        let pattern = compiledPatterns.pan
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "PAN No: \(configuration.panPlaceholder)"
        )

        return (redacted, matches.count)
    }

    private func redactPhoneNumbers(from text: String) -> (String, Int) {
        // Pattern: "+91 9876543210" -> "***PHONE***"
        let pattern = compiledPatterns.phone
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "***PHONE***"
        )

        return (redacted, matches.count)
    }

    private func redactEmails(from text: String) -> (String, Int) {
        // Pattern: "user@example.com" -> "***EMAIL***"
        let pattern = compiledPatterns.email
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern.matches(in: text, range: range)

        if matches.isEmpty {
            return (text, 0)
        }

        let redacted = pattern.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "***EMAIL***"
        )

        return (redacted, matches.count)
    }

    private func identifyPreservedPayCodes(in text: String) -> [String] {
        var found: [String] = []

        for payCode in configuration.preservedPayCodes {
            // Simple check if pay code appears in text
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
