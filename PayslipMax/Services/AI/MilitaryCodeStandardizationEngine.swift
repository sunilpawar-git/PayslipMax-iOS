import Foundation

/// Engine responsible for standardizing military codes
public class MilitaryCodeStandardizationEngine {

    // MARK: - Public Methods

    /// Standardize military codes
    func standardizeCodes(_ codes: [String]) async throws -> [MilitaryCodeStandardization] {
        var standardizations: [MilitaryCodeStandardization] = []

        for code in codes {
            let normalizedCode = normalizeCode(code)
            var changes: [String] = []

            // Check if standardization is needed
            if normalizedCode != code {
                changes.append("Normalized case: \(code) → \(normalizedCode)")
            }

            // Check for common variations
            if let standardized = getStandardizedVariation(of: normalizedCode) {
                if standardized != normalizedCode {
                    changes.append("Standardized variation: \(normalizedCode) → \(standardized)")
                }
            }

            let confidence = changes.isEmpty ? 1.0 : 0.9

            let standardization = MilitaryCodeStandardization(
                originalCode: code,
                standardizedCode: getStandardizedVariation(of: normalizedCode) ?? normalizedCode,
                confidence: confidence,
                changes: changes
            )

            standardizations.append(standardization)
        }

        return standardizations
    }

    // MARK: - Private Methods

    /// Normalize military code for consistent processing
    private func normalizeCode(_ code: String) -> String {
        return code.uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    /// Get standardized variation of a code
    private func getStandardizedVariation(of code: String) -> String? {
        return MilitaryCodePatterns.variations[code]
    }
}
