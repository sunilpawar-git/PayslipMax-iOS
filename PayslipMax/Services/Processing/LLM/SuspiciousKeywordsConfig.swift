//
//  SuspiciousKeywordsConfig.swift
//  PayslipMax
//
//  Configurable suspicious keywords for payslip validation
//  Supports localization and easy updates
//

import Foundation

/// Configuration for suspicious keywords detected during payslip validation
enum SuspiciousKeywordsConfig {
    /// Keywords that indicate a deduction may be incorrectly categorized
    /// (e.g., totals, balances, or adjustments that shouldn't be deductions)
    /// Note: Be specific to avoid filtering valid deductions like "LOANS & ADVANCES"
    static let deductionKeywords: [String] = [
        "total debit",
        "total credit",
        "balance released",
        "credit balance released",
        "fund refund",           // "AFPP FUND REFUND" is not a deduction
        "dsop refund",
        "afpp refund",
        "previous balance",
        "carried forward",
        "credited to bank",
        "amount credited to bank",
        "net remittance",
        "net pay",
        "take home"
        // Removed: "advance" - "LOANS & ADVANCES" is a valid deduction
        // Removed: "recovery" - too broad, many valid deductions have this
        // Removed: "refund" - too broad, need specific patterns like "fund refund"
        // Removed: "total" - too broad, need specific patterns
        // Removed: "balance" - too broad
    ]

    /// Keywords that indicate potential earnings miscategorization
    static let earningsKeywords: [String] = [
        "deduction",
        "recovery",
        "refund",
        "adjustment"
    ]

    /// Returns suspicious keywords for a given locale
    /// - Parameter locale: The locale for which to return keywords
    /// - Returns: Array of suspicious keywords in the appropriate language
    static func keywords(for locale: Locale = .current) -> [String] {
        // Currently only English is supported
        // Future: Add support for Hindi and other languages
        return deductionKeywords
    }

    /// Checks if a key contains any suspicious keywords
    /// - Parameter key: The key to check
    /// - Returns: The matching suspicious word, if any
    static func findSuspiciousWord(in key: String) -> String? {
        let lowercaseKey = key.lowercased()
        return deductionKeywords.first { lowercaseKey.contains($0) }
    }
}

