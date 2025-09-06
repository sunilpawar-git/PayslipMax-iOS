import Foundation

/// Utility service for spatial data extraction operations
/// Extracted from SpatialDataExtractionService to maintain 300-line compliance
final class SpatialExtractionUtilities {

    // MARK: - Public Interface

    /// Extracts financial amount from text using pattern matching
    /// - Parameter text: Text to extract amount from
    /// - Returns: Extracted amount or nil if not found
    func extractFinancialAmount(from text: String) -> Double? {
        let amountPattern = "(\\d{1,3}(?:,\\d{3})*(?:\\.\\d{2})?)"
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: []) else {
            return nil
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let amountText = String(text[range])
                let cleanAmount = amountText.replacingOccurrences(of: ",", with: "")
                return Double(cleanAmount)
            }
        }

        return nil
    }

    /// Cleans and normalizes financial codes
    /// - Parameter text: Raw text containing financial code
    /// - Returns: Cleaned financial code
    func cleanFinancialCode(_ text: String) -> String {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .uppercased()

        // Extract code patterns (typically 2-6 uppercase letters)
        if let codeMatch = cleaned.range(of: "\\b[A-Z]{2,6}\\b", options: .regularExpression) {
            return String(cleaned[codeMatch])
        }

        return cleaned
    }

    /// Validates if a string represents a valid financial code
    /// - Parameter code: Code to validate
    /// - Returns: True if valid financial code
    func isValidFinancialCode(_ code: String) -> Bool {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for 2-6 uppercase letters (typical military pay codes)
        let codePattern = "^[A-Z]{2,6}$"
        guard let regex = try? NSRegularExpression(pattern: codePattern, options: []) else {
            return false
        }

        let range = NSRange(cleanCode.startIndex..., in: cleanCode)
        return regex.firstMatch(in: cleanCode, options: [], range: range) != nil
    }

    /// Checks if a financial code belongs to a specific type
    /// - Parameters:
    ///   - code: Financial code to check
    ///   - type: Financial data type to match against
    /// - Returns: True if code matches the type
    func isCodeForType(_ code: String, type: FinancialDataType) -> Bool {
        let cleanCode = cleanFinancialCode(code)

        switch type {
        case .earnings:
            // Common earnings codes (BPAY, DA, TPTA, etc.)
            return ["BPAY", "DA", "TPTA", "HRA", "CONVEYANCE", "LTC", "MEDICAL"].contains(cleanCode)
        case .deductions:
            // Common deduction codes (MSP, RH12, TPTADA, etc.)
            return ["MSP", "RH12", "TPTADA", "CGHS", "CGEGIS", "PLI"].contains(cleanCode)
        case .allowances:
            // Allowance codes
            return ["CONVEYANCE", "HRA", "LTC", "MEDICAL"].contains(cleanCode)
        }
    }
}

/// Types of financial data for classification
enum FinancialDataType {
    case earnings
    case deductions
    case allowances
}
