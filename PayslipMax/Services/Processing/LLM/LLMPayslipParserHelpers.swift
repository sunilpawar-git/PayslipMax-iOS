//
//  LLMPayslipParserHelpers.swift
//  PayslipMax
//
//  Helper methods for LLM payslip parsing - extracted for modularity
//

import Foundation

/// Helpers for LLM payslip parsing operations
enum LLMPayslipParserHelpers {

    /// Creates a prompt from redacted text with reconciliation hints
    /// - Parameters:
    ///   - text: The redacted payslip text
    ///   - reconciliationHint: Hint for totals reconciliation
    /// - Returns: Formatted prompt string
    static func createPrompt(from text: String, reconciliationHint: String) -> String {
        return """
        \(reconciliationHint)

        Payslip Text (anonymized):
        \(text)
        """
    }

    /// Cleans JSON response by removing markdown code blocks
    /// - Parameter content: Raw response content
    /// - Returns: Clean JSON string
    static func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        } else if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extra safety: trim to the outermost JSON braces
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        return cleaned
    }

    /// Calculates reconciliation error between totals
    /// - Parameters:
    ///   - gross: Gross pay amount
    ///   - deductions: Total deductions
    ///   - net: Net remittance
    /// - Returns: Error percentage (0.0 to 1.0)
    static func reconciliationError(gross: Double, deductions: Double, net: Double) -> Double {
        guard gross > 0 else { return 0 }
        return abs((gross - deductions) - net) / gross
    }

    /// Returns model name for a given provider
    /// - Parameter provider: The LLM provider
    /// - Returns: Model name string
    static func getModelName(for provider: LLMProvider) -> String {
        switch provider {
        case .gemini:
            return "gemini-2.5-flash-lite"
        case .mock:
            return "mock"
        }
    }
}

