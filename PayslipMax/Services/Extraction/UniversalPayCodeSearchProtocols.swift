//
//  UniversalPayCodeSearchProtocols.swift
//  PayslipMax
//
//  Protocol definitions and result structures for pay code search operations
//

import Foundation

/// Protocol for universal pay code search operations
protocol UniversalPayCodeSearchEngineProtocol {
    /// Searches for all known pay codes in the entire text regardless of section
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their found values and sections
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult]

    /// Validates if a pay code is a known military component
    /// - Parameter code: The pay code to validate
    /// - Returns: True if it's a valid military pay code
    func isKnownMilitaryPayCode(_ code: String) -> Bool
}

/// Result structure for pay code search operations
struct PayCodeSearchResult {
    let value: Double
    let section: PayslipSection
    let confidence: Double
    let context: String
    let isDualSection: Bool
}

/// Result structure for intelligent component classification
struct PayCodeClassificationResult {
    let section: PayslipSection
    let confidence: Double
    let reasoning: String
    let isDualSection: Bool
}
