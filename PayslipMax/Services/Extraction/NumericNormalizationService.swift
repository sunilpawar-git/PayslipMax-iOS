import Foundation

/// Protocol for numeric and currency normalization (Phase 16)
protocol NumericNormalizationServiceProtocol {
    /// Normalizes a raw amount string into a Double with robust handling
    /// - Parameter raw: Raw OCR/text token possibly containing currency, commas, spaces, Hindi numerals, or parentheses for negatives
    /// - Returns: Parsed Double if valid; nil if the token is not a plausible amount
    func normalizeAmount(_ raw: String) -> Double?
    /// Checks if a token looks like a plausible monetary amount (after cleanup)
    func isPlausibleAmountToken(_ raw: String) -> Bool
}

/// Default implementation of Phase 16 numeric normalization
/// Handles: parentheses negatives, Indian numbering, currency symbols, and common OCR confusions
final class NumericNormalizationService: NumericNormalizationServiceProtocol {
    // Character confusion mappings common in OCR for amounts
    private let ocrConfusions: [Character: Character] = [
        "O": "0", "o": "0", // O -> 0
        "I": "1", "l": "1", // I/l -> 1
        "S": "5"               // S -> 5
    ]

    // Hindi/Devanagari numerals to Western
    private let devanagariToWestern: [Character: Character] = [
        "०": "0", "१": "1", "२": "2", "३": "3", "४": "4",
        "५": "5", "६": "6", "७": "7", "८": "8", "९": "9"
    ]

    func normalizeAmount(_ raw: String) -> Double? {
        let cleaned = clean(raw)
        guard !cleaned.isEmpty else { return nil }

        // Handle parentheses negatives
        let isNegative = cleaned.hasPrefix("(") && cleaned.hasSuffix(")")
        let withoutParens = isNegative ? String(cleaned.dropFirst().dropLast()) : cleaned

        // Remove currency and spaces; keep digits, comma, dot, and minus
        var filtered = withoutParens.replacingOccurrences(of: "[^0-9,.-]", with: "", options: .regularExpression)

        // Handle edge-case where a leading '.' from tokens like "Rs." remains
        while filtered.first == "." { filtered.removeFirst() }

        // If multiple dots, keep first; if multiple minus, keep leading only
        if filtered.filter({ $0 == "." }).count > 1 {
            if let firstDot = filtered.firstIndex(of: ".") {
                filtered = filtered.enumerated().filter { idx, ch in
                    ch != "." || filtered.index(filtered.startIndex, offsetBy: idx) == firstDot
                }.map { $0.element }.reduce("") { $0 + String($1) }
            }
        }
        if filtered.dropFirst().contains("-") {
            filtered = filtered.replacingOccurrences(of: "-", with: "")
            filtered = "-" + filtered
        }

        // Remove thousands separators (commas). Assume dot is decimal separator.
        let noCommas = filtered.replacingOccurrences(of: ",", with: "")
        let finalString = (isNegative ? "-" : "") + noCommas

        // Reject alpha-heavy tokens
        if finalString.range(of: "[A-Za-z]", options: .regularExpression) != nil { return nil }

        // Basic plausibility: must contain at least one digit
        guard finalString.range(of: "[0-9]", options: .regularExpression) != nil else { return nil }

        return Double(finalString)
    }

    func isPlausibleAmountToken(_ raw: String) -> Bool {
        let cleaned = clean(raw)
        if cleaned.isEmpty { return false }
        // Quick reject: too many letters vs digits
        let letters = cleaned.filter { $0.isLetter }.count
        let digits = cleaned.filter { $0.isNumber }.count
        if letters > 2 && digits == 0 { return false }
        // Must have at least one digit after normalization
        return digits > 0
    }

    // MARK: - Helpers
    private func clean(_ input: String) -> String {
        if input.isEmpty { return input }
        var s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // Map Devanagari numerals
        s = String(s.map { devanagariToWestern[$0] ?? $0 })
        // Fix common OCR confusions
        s = String(s.map { ocrConfusions[$0] ?? $0 })
        return s
    }
}


