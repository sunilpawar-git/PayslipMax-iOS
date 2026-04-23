import Foundation

/// Number extraction utilities for UniversalPayCodeSearchEngine.
/// Separated from Helpers to keep each file under 300 lines.
extension UniversalPayCodeSearchEngine {

    /// Finds the nearest numeric value after the label on the same line,
    /// then falls back to lookahead lines.
    /// Prefers values that appear *after* the label text to avoid binding
    /// to page numbers or dates that precede the label.
    func extractNearestNumber(from lines: [String], startingAt index: Int, lookahead: Int) -> Double? {
        guard index < lines.count else { return nil }

        let startLine = lines[index]
        if let postLabelValue = extractNumberAfterLabel(from: startLine) {
            return postLabelValue
        }

        for offset in 1...max(1, lookahead) {
            let i = index + offset
            if i < lines.count, let amount = extractNumber(from: lines[i]) {
                return amount
            }
        }
        return nil
    }

    /// Extracts the last numeric token on a line (the value that typically follows the label).
    func extractNumberAfterLabel(from line: String) -> Double? {
        let pattern = #".*\s+([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)[\s]*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        if let match = regex.firstMatch(in: line, options: [], range: range),
           let amountRange = Range(match.range(at: 1), in: line) {
            let raw = String(line[amountRange])
            let clean = raw.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            return Double(clean)
        }
        return nil
    }

    /// Extracts the first numeric token from a string (any position).
    func extractNumber(from text: String) -> Double? {
        let pattern = #"([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let amountRange = Range(match.range(at: 1), in: text) {
            let raw = String(text[amountRange])
            let clean = raw.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            return Double(clean)
        }
        return nil
    }
}
