import Foundation

/// Engine responsible for validating military codes
public class MilitaryCodeValidationEngine {

    // MARK: - Public Methods

    /// Validate military code in context
    func validateCode(_ code: String, context: MilitaryCodeContext) async throws -> MilitaryCodeValidation {
        var issues: [String] = []
        var suggestions: [String] = []

        guard let expansion = try await expandAbbreviation(code) else {
            return MilitaryCodeValidation(
                isValid: false,
                confidence: 0.0,
                issues: ["Unknown military code: \(code)"],
                suggestions: ["Check code spelling", "Verify against PCDA format"]
            )
        }

        var confidence = 0.8
        var isValid = true

        // Validate category consistency
        if let rank = context.rank {
            if let categoryValidation = validateCategoryForRank(expansion.category, rank: rank) {
                issues.append(categoryValidation)
                isValid = false
                confidence -= 0.2
            }
        }

        // Validate mandatory codes
        if expansion.isMandatory {
            confidence += 0.1
        }

        // Validate amount ranges if available
        if let typicalAmount = expansion.typicalAmount {
            if let amountValidation = validateAmountRange(code, expectedRange: typicalAmount) {
                issues.append(amountValidation)
                confidence -= 0.1
            }
        }

        // Generate suggestions
        if confidence < 0.7 {
            suggestions.append("Verify code context and spelling")
            suggestions.append("Check against official PCDA format")
        }

        return MilitaryCodeValidation(
            isValid: isValid,
            confidence: max(0.0, min(1.0, confidence)),
            issues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Private Methods

    /// Expand military code abbreviation (local implementation)
    private func expandAbbreviation(_ code: String) async throws -> MilitaryCodeExpansion? {
        let normalizedCode = normalizeCode(code)

        // Direct lookup
        if let expansion = MilitaryCodePatterns.patterns[normalizedCode] {
            return expansion
        }

        // Fuzzy matching for similar codes
        for (pattern, expansion) in MilitaryCodePatterns.patterns {
            if pattern.contains(normalizedCode) || normalizedCode.contains(pattern) {
                return expansion
            }
        }

        return nil
    }

    /// Normalize military code for consistent processing
    private func normalizeCode(_ code: String) -> String {
        return code.uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    /// Validate category consistency for rank
    private func validateCategoryForRank(_ category: MilitaryCodeCategory, rank: String) -> String? {
        // Basic validation logic - can be expanded based on military regulations
        let officerRanks = ["COLONEL", "MAJOR", "CAPTAIN", "LIEUTENANT"]
        let _ = officerRanks.contains { rank.uppercased().contains($0) }

        switch category {
        case .specialPay:
            // All ranks should have special pay
            return nil
        case .allowance:
            // All ranks should have basic allowances
            return nil
        case .insurance:
            // Insurance is mandatory for most ranks
            return nil
        case .deduction:
            // Deductions can vary by rank and location
            return nil
        case .unknown:
            return "Unknown category for military code"
        }
    }

    /// Validate amount range for code
    private func validateAmountRange(_ code: String, expectedRange: ClosedRange<Double>) -> String? {
        // This is a placeholder for amount validation logic
        // In a real implementation, this would validate against extracted amounts
        // For now, we just check if the range is reasonable
        if expectedRange.lowerBound < 0 {
            return "Invalid amount range for code \(code)"
        }

        return nil
    }
}
