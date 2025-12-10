//
//  SelectiveRedactorProtocol.swift
//  PayslipMax
//
//  Protocol for selective PII redaction that preserves payslip structure
//

import Foundation

/// Configuration for selective redaction
public struct SelectiveRedactionConfiguration {
    /// Placeholder for redacted names
    let namePlaceholder: String

    /// Placeholder for redacted account numbers
    let accountPlaceholder: String

    /// Placeholder for redacted PAN numbers
    let panPlaceholder: String

    /// Placeholder for redacted service/SUS numbers
    let servicePlaceholder: String

    /// Pay codes to always preserve (not redact)
    let preservedPayCodes: Set<String>

    /// Maximum text size to process
    let maxTextSize: Int

    public static let `default` = SelectiveRedactionConfiguration(
        namePlaceholder: "***NAME***",
        accountPlaceholder: "***ACCOUNT***",
        panPlaceholder: "***PAN***",
        servicePlaceholder: "***SERVICE***",
        preservedPayCodes: [
            // Core earnings pay codes
            "BPAY", "Basic Pay", "DA", "Dearness Allowance",
            "MSP", "Military Service Pay", "X Group Pay",
            "TA", "Transport Allowance", "HRA", "House Rent Allowance",
            "CCA", "City Compensatory Allowance",

            // Core deduction codes
            "DSOP", "DSOPP", "AFPP Fund", "AGIF",
            "ITAX", "Income Tax", "CGEGIS", "CGHS",
            "Licence Fee", "Water & Electricity Charges",
            "NPS", "GPF", "TPTL"
        ],
        maxTextSize: 1_000_000
    )
}

/// Protocol for selective redaction of payslip text
/// Redacts PII while preserving structure, pay codes, and amounts
public protocol SelectiveRedactorProtocol {
    /// Selectively redacts PII from payslip text while preserving structure
    /// - Parameter text: Raw payslip text
    /// - Returns: Selectively redacted text safe for LLM with preserved structure
    /// - Throws: AnonymizationError if redaction fails
    func redact(_ text: String) throws -> String

    /// Returns statistics about the last redaction operation
    var lastRedactionReport: RedactionReport? { get }
}

/// Report containing statistics about a redaction operation
public struct RedactionReport {
    /// Fields that were redacted
    let redactedFields: [String]

    /// Pay codes that were preserved
    let preservedPayCodes: [String]

    /// Total number of redactions made
    let redactionCount: Int

    /// Whether the redaction was successful
    let successful: Bool
}
