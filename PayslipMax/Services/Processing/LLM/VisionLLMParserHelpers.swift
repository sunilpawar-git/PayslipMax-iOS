//
//  VisionLLMParserHelpers.swift
//  PayslipMax
//
//  Helper methods for Vision LLM payslip parsing - extracted for modularity
//

import Foundation
import OSLog

/// Helpers for Vision LLM payslip parsing operations
enum VisionLLMParserHelpers {

    /// Checks if JSON is complete (balanced braces)
    /// - Parameter json: JSON string to check
    /// - Returns: True if JSON appears complete
    static func isCompleteJSON(_ json: String) -> Bool {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else {
            return false
        }

        var braceCount = 0
        for char in trimmed {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
            }
        }

        return braceCount == 0
    }

    /// Cleans JSON response by removing markdown code blocks
    /// - Parameter content: Raw response content
    /// - Returns: Clean JSON string
    static func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        return cleaned
    }

    /// Filters out suspicious deduction keys that are likely extraction errors
    /// - Parameters:
    ///   - deductions: Raw deductions dictionary
    ///   - logger: Logger for recording filtered entries
    /// - Returns: Filtered deductions dictionary
    static func filterSuspiciousDeductions(
        _ deductions: [String: Double],
        logger: os.Logger? = nil
    ) -> [String: Double] {
        // Use single source of truth for suspicious keywords
        let suspiciousKeywords = SuspiciousKeywordsConfig.deductionKeywords

        var filtered: [String: Double] = [:]
        var removedEntries: [String] = []

        for (key, value) in deductions {
            let lowercaseKey = key.lowercased()
            let isSuspicious = suspiciousKeywords.contains { keyword in
                lowercaseKey.contains(keyword)
            }

            if isSuspicious {
                removedEntries.append("\(key): \(value)")
            } else {
                filtered[key] = value
            }
        }

        if !removedEntries.isEmpty {
            logger?.info("🧹 Filtered suspicious deductions: \(removedEntries.joined(separator: ", "))")
        }

        return filtered
    }

    /// Removes duplicate entries (placeholder for future enhancement)
    static func removeDuplicates(_ deductions: [String: Double]) -> [String: Double] {
        return deductions
    }

    // MARK: - Code Normalization

    /// Normalizes pay code names to standard abbreviations
    /// - Parameter code: Raw code name from LLM
    /// - Returns: Normalized code name
    static func normalizeCodeName(_ code: String) -> String {
        let mapping: [String: String] = [
            "BAND PAY": "BPAY",
            "BASIC PAY": "BPAY",
            "GP-X PAY": "MSP",
            "MS PAY": "MSP",
            "MILITARY SERVICE PAY": "MSP",
            "AFPP FUND SUBSCRIPTION": "DSOP",
            "DSOP FUND SUBSCRIPTION": "DSOP",
            "AFPP SUBSCRIPTION": "DSOP",
            "DEARNESS ALLOWANCE": "DA",
            "TRANSPORT ALLOWANCE": "TPAL",
            "HOUSE RENT ALLOWANCE": "HRA"
        ]

        let uppercaseCode = code.uppercased()
        return mapping[uppercaseCode] ?? code
    }

    /// Normalizes all codes in an earnings/deductions dictionary
    /// - Parameter items: Dictionary of code:amount pairs
    /// - Returns: Normalized dictionary
    static func normalizeCodeNames(_ items: [String: Double]) -> [String: Double] {
        var normalized: [String: Double] = [:]
        for (code, amount) in items {
            let normalizedCode = normalizeCodeName(code)
            // If same normalized code exists, sum the amounts
            normalized[normalizedCode] = (normalized[normalizedCode] ?? 0) + amount
        }
        return normalized
    }

    // MARK: - Earnings Filtering

    /// Keywords that should NOT appear in earnings (from FUND/LOAN sections)
    private static let invalidEarningsKeywords: [String] = [
        "opening balance",
        "closing balance",
        "bonus on cr",
        "credit balance",
        "balance released"
    ]

    /// Filters out invalid earnings that came from FUND/LOAN sections
    /// - Parameters:
    ///   - earnings: Raw earnings dictionary
    ///   - logger: Logger for recording filtered entries
    /// - Returns: Filtered earnings dictionary
    static func filterInvalidEarnings(
        _ earnings: [String: Double],
        logger: os.Logger? = nil
    ) -> [String: Double] {
        var filtered: [String: Double] = [:]
        var removedEntries: [String] = []

        for (key, value) in earnings {
            let lowercaseKey = key.lowercased()
            let isInvalid = invalidEarningsKeywords.contains { keyword in
                lowercaseKey.contains(keyword)
            }

            if isInvalid {
                removedEntries.append("\(key): \(value)")
            } else {
                filtered[key] = value
            }
        }

        if !removedEntries.isEmpty {
            logger?.info("🧹 Filtered invalid earnings: \(removedEntries.joined(separator: ", "))")
        }

        return filtered
    }

    /// Filters deductions that have suspicious values (e.g., FAMO with netRemittance value)
    /// - Parameters:
    ///   - deductions: Raw deductions dictionary
    ///   - netRemittance: The net remittance value to check against
    ///   - logger: Logger for recording filtered entries
    /// - Returns: Filtered deductions dictionary
    static func filterMisassignedDeductions(
        _ deductions: [String: Double],
        netRemittance: Double,
        logger: os.Logger? = nil
    ) -> [String: Double] {
        var filtered: [String: Double] = [:]
        var removedEntries: [String] = []

        for (key, value) in deductions {
            // If FAMO has a value equal to netRemittance, it's misassigned
            if key.uppercased() == "FAMO" && abs(value - netRemittance) < 1.0 {
                removedEntries.append("\(key): \(value) (equals netRemittance)")
                continue
            }
            filtered[key] = value
        }

        if !removedEntries.isEmpty {
            logger?.info("🧹 Filtered misassigned deductions: \(removedEntries.joined(separator: ", "))")
        }

        return filtered
    }

    // MARK: - Full Sanitization Pipeline

    /// Applies full sanitization pipeline to LLM response
    /// - Parameters:
    ///   - response: Raw LLM response
    ///   - logger: Logger for recording operations
    /// - Returns: Sanitized response with corrected values
    static func sanitizeResponse(
        _ response: LLMPayslipResponse,
        logger: os.Logger? = nil
    ) -> LLMPayslipResponse {
        // Step 1: Filter invalid earnings (OPENING BALANCE, etc. from FUND section)
        let filteredEarnings = filterInvalidEarnings(response.earnings ?? [:], logger: logger)

        // Step 2: Normalize code names (BAND PAY → BPAY, etc.)
        let normalizedEarnings = normalizeCodeNames(filteredEarnings)

        // Step 3: Filter suspicious deductions (keywords like "balance", "refund")
        let filteredDeductions = filterSuspiciousDeductions(response.deductions ?? [:], logger: logger)

        // Step 4: Filter misassigned deductions (FAMO with netRemittance value)
        let netRemittance = response.netRemittance ?? 0
        let cleanedDeductions = filterMisassignedDeductions(
            filteredDeductions,
            netRemittance: netRemittance,
            logger: logger
        )

        // Step 5: Normalize deduction code names and remove duplicates
        let normalizedDeductions = normalizeCodeNames(cleanedDeductions)
        let deduplicatedDeductions = removeDuplicates(normalizedDeductions)

        let earningsTotal = normalizedEarnings.values.reduce(0, +)
        let deductionsTotal = deduplicatedDeductions.values.reduce(0, +)

        let gross = response.grossPay ?? earningsTotal
        let providedNet = response.netRemittance ?? 0

        // Calculate totalDeductions from grossPay - netRemittance if available
        var deductions = response.totalDeductions ?? deductionsTotal
        if providedNet > 0 && gross > providedNet {
            let calculatedDeductions = gross - providedNet
            // If LLM's totalDeductions equals grossPay (balancing figure), use calculated
            if abs(deductions - gross) < 1.0 {
                logger?.info("🔧 Correcting totalDeductions: \(deductions) → \(calculatedDeductions)")
                deductions = calculatedDeductions
            }
        }

        // Sanity check: deductions should be less than earnings
        if deductionsTotal > earningsTotal && earningsTotal > 0 {
            logger?.warning("⚠️ Deductions exceed earnings - using filtered deductions")
            let recalculatedNet = gross - deductionsTotal
            return LLMPayslipResponse(
                earnings: normalizedEarnings,
                deductions: deduplicatedDeductions,
                grossPay: gross > 0 ? gross : earningsTotal,
                totalDeductions: deductionsTotal,
                netRemittance: recalculatedNet,
                month: response.month,
                year: response.year
            )
        }

        return LLMPayslipResponse(
            earnings: normalizedEarnings,
            deductions: deduplicatedDeductions,
            grossPay: gross > 0 ? gross : earningsTotal,
            totalDeductions: deductions > 0 ? deductions : deductionsTotal,
            netRemittance: providedNet,
            month: response.month,
            year: response.year
        )
    }
}

