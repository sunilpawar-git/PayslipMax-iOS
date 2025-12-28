//
//  LLMResponsePIIScrubber.swift
//  PayslipMax
//
//  Post-processes LLM responses to detect and remove accidentally leaked PII
//

import Foundation
import OSLog

/// Protocol for PII scrubbing functionality
protocol PIIScrubbingProtocol {
    func scrub(_ text: String) -> LLMResponsePIIScrubber.ScrubResult
}

/// Post-processes LLM responses to detect and remove accidentally leaked PII.
///
/// This service provides a **double-check layer** to ensure LLM responses
/// don't contain sensitive information like PAN numbers, account numbers,
/// phone numbers, or emails.
///
/// **Usage**:
/// ```swift
/// let scrubber = LLMResponsePIIScrubber()
/// let result = scrubber.scrub(llmResponse)
///
/// switch result.severity {
/// case .critical:
///     throw LLMError.piiDetectedInResponse
/// case .warning:
///     logger.warning("PII scrubbed: \(result.detectedPII)")
///     return result.cleanedText
/// case .clean:
///     return result.cleanedText
/// }
/// ```
///
/// **Detection Patterns**:
/// - PAN: `[A-Z]{5}[0-9]{4}[A-Z]`
/// - Account: `\d{10,}`
/// - Phone: `[6-9]\d{9}`
/// - Email: Standard RFC 5322
/// - Name: After "Name:" or "Employee:" keywords
///
/// **Thread Safety**: Safe to call from any thread
final class LLMResponsePIIScrubber: PIIScrubbingProtocol {
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "PIIScrubber")

    /// PII patterns to detect in LLM responses
    private let piiPatterns: [PIIPattern]

    /// Known pay codes to avoid false positives
    private let knownPayCodes = [
        "BPAY", "DA", "MSP", "TA", "HRA", "CCA", "NPS", "GPF", "TPTA",
        "DSOP", "DSOPP", "AGIF", "ITAX", "CGHS", "AFPP", "MISC"
    ]

    init() {
        // Initialize PII detection patterns
        self.piiPatterns = [
            // Indian PAN: ABCDE1234F
            PIIPattern(
                name: "PAN",
                regex: try! NSRegularExpression(pattern: "[A-Z]{5}[0-9]{4}[A-Z]", options: [])
            ),
            // Account number: 11+ digits (to avoid matching 10-digit phone numbers)
            PIIPattern(
                name: "Account",
                regex: try! NSRegularExpression(pattern: "\\b\\d{11,}\\b", options: [])
            ),
            // Phone: Indian format
            PIIPattern(
                name: "Phone",
                regex: try! NSRegularExpression(pattern: "\\b[6-9]\\d{9}\\b", options: [])
            ),
            // Email
            PIIPattern(
                name: "Email",
                regex: try! NSRegularExpression(
                    pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}",
                    options: []
                )
            ),
            // Common name patterns (risky, may false positive)
            PIIPattern(
                name: "PossibleName",
                regex: try! NSRegularExpression(
                    pattern: "(?i)\\b(name|employee|rank)\\s*:?\\s*[A-Z][a-z]+(\\s+[A-Z][a-z]+)+",
                    options: []
                )
            )
        ]
    }

    /// Scrubs LLM response for accidentally leaked PII
    /// - Parameter llmResponse: Raw LLM response (JSON or text)
    /// - Returns: Scrub result with cleaned text and detected PII
    func scrub(_ llmResponse: String) -> ScrubResult {
        var detectedPII: [DetectedPII] = []
        var cleanedText = llmResponse

        for pattern in piiPatterns {
            let nsRange = NSRange(llmResponse.startIndex..<llmResponse.endIndex, in: llmResponse)
            let matches = pattern.regex.matches(in: llmResponse, options: [], range: nsRange)

            for match in matches {
                if let range = Range(match.range, in: llmResponse) {
                    let matchedText = String(llmResponse[range])

                    // Skip known pay codes (avoid false positives)
                    if isKnownPayCode(matchedText) {
                        continue
                    }

                    detectedPII.append(DetectedPII(pattern: pattern, match: matchedText, range: range))

                    // Redact from cleaned text
                    cleanedText = cleanedText.replacingOccurrences(
                        of: matchedText,
                        with: "***\(pattern.name)***"
                    )
                }
            }
        }

        if !detectedPII.isEmpty {
            let piiSummary = detectedPII.map { "\($0.pattern.name): \($0.match)" }.joined(separator: ", ")
            logger.warning("⚠️ PII detected in LLM response: \(piiSummary)")
        }

        return ScrubResult(
            cleanedText: cleanedText,
            detectedPII: detectedPII,
            isClean: detectedPII.isEmpty
        )
    }

    /// Checks if a string is a known pay code (to avoid false positives)
    private func isKnownPayCode(_ text: String) -> Bool {
        return knownPayCodes.contains(text.uppercased())
    }
}

// MARK: - Supporting Types

extension LLMResponsePIIScrubber {
    /// Result of PII scrubbing operation
    struct ScrubResult {
        let cleanedText: String
        let detectedPII: [DetectedPII]
        let isClean: Bool

        var severity: Severity {
            if detectedPII.isEmpty {
                return .clean
            }

            // Critical: PAN, Account, Phone detected
            if detectedPII.contains(where: { pattern in
                pattern.pattern.name == "PAN" ||
                pattern.pattern.name == "Account" ||
                pattern.pattern.name == "Phone"
            }) {
                return .critical
            }

            // Warning: Possible names, emails
            return .warning
        }

        enum Severity {
            case clean      // No PII detected
            case warning    // Possible names, low confidence
            case critical   // PAN, account, phone detected
        }
    }

    /// Detected PII instance
    struct DetectedPII {
        let pattern: PIIPattern
        let match: String
        let range: Range<String.Index>
    }

    /// PII detection pattern
    struct PIIPattern {
        let name: String
        let regex: NSRegularExpression
    }
}
