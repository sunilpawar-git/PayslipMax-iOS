//
//  PayCodePatternGenerator.swift
//  PayslipMax
//
//  Created for Phase 4: Universal Pay Code Search - Pattern Generation
//  Generates search patterns for all known military pay codes
//

import Foundation

/// Generator for pay code search patterns
final class PayCodePatternGenerator {

    // MARK: - Properties

    /// Database of all known military pay codes
    private let knownPayCodes: Set<String>

    // MARK: - Initialization

    init() {
        self.knownPayCodes = Self.loadKnownMilitaryPayCodes()
        print("[PayCodePatternGenerator] Initialized with \(knownPayCodes.count) known pay codes")
    }


    // MARK: - Public Methods

    /// Priority patterns for critical components that need flexible matching
    /// These override the standard pattern generation for specific codes
    private func priorityPatterns() -> [String: [String]] {
        return [
            "BPAY": [
                // Flexible BPAY pattern matching ALL variants (Level 1-16, optional suffix A-Z)
                // Matches: BPAY, BPAY (12A), BPAY(12A), BPAY (1), BPAY (16), etc.
                #"(?:BPAY|Basic\s*Pay|BASIC\s*PAY)\s*(?:\((?:1[0-6]|[1-9])(?:[A-Z])?\))?\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{2})?)"#,

                // Tabular format
                #"(?:BPAY|Basic\s*Pay)\s*(?:\((?:1[0-6]|[1-9])(?:[A-Z])?\))?\s+(?:Rs\.?|₹)?\s*([0-9,]+)"#,

                // Colon separated
                #"(?:BPAY|Basic\s*Pay)\s*(?:\((?:1[0-6]|[1-9])(?:[A-Z])?\))?\s*:\s*(?:Rs\.?|₹)?\s*([0-9,]+)"#
            ]
        ]
    }

    /// Generates pattern variations for a specific pay code
    /// - Parameter code: The pay code to generate patterns for
    /// - Returns: Array of regex patterns for the pay code
    func generatePayCodePatterns(for code: String) -> [String] {
        // Check for priority patterns first (e.g., BPAY needs flexible matching)
        if let specialPatterns = priorityPatterns()[code] {
            print("[PayCodePatternGenerator] Using priority pattern for \(code)")
            return specialPatterns
        }

        // Escape regex special characters for standard codes
        let escapedCode = NSRegularExpression.escapedPattern(for: code)

        return [
            // Direct code patterns
            "(?:\(escapedCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",

            // Spaced variations
            "(?:\(code.map { String($0) }.joined(separator: "\\s*")))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",

            // Tabular format
            "\(escapedCode)\\s+(?:Rs\\.?|₹)?\\s*([0-9,.]+)",

            // Colon separated
            "\(escapedCode)\\s*:\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+)",

            // Amount first patterns (for reverse order tables)
            "(?:Rs\\.?|₹)?\\s*([0-9,.]+)\\s+\(escapedCode)(?:\\s|$)"
        ]
    }

    /// Generates universal arrears patterns for dynamic matching
    /// - Returns: Array of universal arrears regex patterns
    func generateUniversalArrearsPatterns() -> [String] {
        return [
            "(?:ARR-|ARREARS\\s+)([A-Z][A-Z0-9\\-]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:Arr-|Arrears\\s+)([A-Z][A-Z0-9\\-]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]
    }

    /// Validates if a pay code is known
    /// - Parameter code: The pay code to validate
    /// - Returns: True if it's a valid military pay code
    func isKnownMilitaryPayCode(_ code: String) -> Bool {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespaces)
        return knownPayCodes.contains(normalizedCode)
    }

    /// Gets all known pay codes for iteration
    /// - Returns: Set of all known military pay codes
    func getAllKnownPayCodes() -> Set<String> {
        return knownPayCodes
    }

    // MARK: - Static Helper Methods

    /// Loads all known military pay codes from resources and hardcoded lists
    private static func loadKnownMilitaryPayCodes() -> Set<String> {
        var codes: Set<String> = []

        // Load from military abbreviations if available
        if let url = Bundle.main.url(forResource: "military_abbreviations", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let jsonRoot = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let abbreviationsArray = jsonRoot["abbreviations"] as? [[String: Any]] {

            for abbreviation in abbreviationsArray {
                if let code = abbreviation["code"] as? String {
                    codes.insert(code.uppercased())
                }
            }
            print("[PayCodePatternGenerator] Loaded \(abbreviationsArray.count) codes from JSON")
        } else {
            print("[PayCodePatternGenerator] Warning: Could not load military_abbreviations.json")
        }

        // Add hardcoded essential military pay codes
        let essentialCodes = [
            // Basic Pay - Flexible pattern handles ALL variants (1-16, A-Z suffix)
            "BPAY", "BP", "BASICPAY",

            // Risk & Hardship Allowances
            "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",

            // Military Service Pay & Allowances
            "MSP", "DA", "TPTA", "CEA", "CLA", "HRA", "TPTADA",

            // Special Allowances
            "KIT", "UNIFM", "WASHG", "RSHNA", "FIELD",

            // Deductions
            "DSOP", "AGIF", "AFPF", "ITAX", "IT", "EHCESS", "GPF", "PF"
        ]

        for code in essentialCodes {
            codes.insert(code.uppercased())
        }

        return codes
    }
}
