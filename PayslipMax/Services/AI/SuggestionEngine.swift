import Foundation

/// Engine responsible for generating reconciliation suggestions
public class SuggestionEngine {

    // MARK: - Public Methods

    /// Suggest corrections for identified discrepancies
    func suggestCorrections(
        discrepancies: [ReconciliationDiscrepancy],
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        var suggestions: [ReconciliationSuggestion] = []

        for discrepancy in discrepancies {
            switch discrepancy.discrepancyType {
            case .amountMismatch:
                suggestions.append(contentsOf: try await suggestAmountCorrections(discrepancy, context: context))
            case .missingComponent:
                suggestions.append(contentsOf: try await suggestMissingComponentCorrections(discrepancy, context: context))
            case .roundingIssue:
                suggestions.append(contentsOf: try await suggestRoundingCorrections(discrepancy, context: context))
            case .calculationError:
                suggestions.append(contentsOf: try await suggestCalculationCorrections(discrepancy, context: context))
            case .extraComponent:
                suggestions.append(contentsOf: try await suggestExtraComponentCorrections(discrepancy, context: context))
            }
        }

        return suggestions
    }

    // MARK: - Private Methods

    /// Suggest corrections for amount mismatches
    private func suggestAmountCorrections(
        _ discrepancy: ReconciliationDiscrepancy,
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        var suggestions: [ReconciliationSuggestion] = []

        if let expectedValue = discrepancy.expectedValue {
            suggestions.append(ReconciliationSuggestion(
                type: .correction,
                component: discrepancy.component,
                suggestedValue: expectedValue,
                confidence: 0.8,
                explanation: "Align with expected total value"
            ))
        }

        return suggestions
    }

    /// Suggest corrections for missing components
    private func suggestMissingComponentCorrections(
        _ discrepancy: ReconciliationDiscrepancy,
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        return [ReconciliationSuggestion(
            type: .addition,
            component: discrepancy.component,
            suggestedValue: 0.0,
            confidence: 0.6,
            explanation: "Add missing component with zero value"
        )]
    }

    /// Suggest rounding corrections
    private func suggestRoundingCorrections(
        _ discrepancy: ReconciliationDiscrepancy,
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        var suggestions: [ReconciliationSuggestion] = []

        if let roundedValue = applyRoundingCorrection(discrepancy.extractedValue) {
            suggestions.append(ReconciliationSuggestion(
                type: .correction,
                component: discrepancy.component,
                suggestedValue: roundedValue,
                confidence: 0.9,
                explanation: "Apply standard rounding to amount"
            ))
        }

        return suggestions
    }

    /// Suggest calculation corrections
    private func suggestCalculationCorrections(
        _ discrepancy: ReconciliationDiscrepancy,
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        return [ReconciliationSuggestion(
            type: .correction,
            component: discrepancy.component,
            suggestedValue: discrepancy.expectedValue ?? 0.0,
            confidence: 0.7,
            explanation: "Correct calculation error"
        )]
    }

    /// Suggest corrections for extra components
    private func suggestExtraComponentCorrections(
        _ discrepancy: ReconciliationDiscrepancy,
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        return [ReconciliationSuggestion(
            type: .removal,
            component: discrepancy.component,
            suggestedValue: 0.0,
            confidence: 0.6,
            explanation: "Consider removing extra component"
        )]
    }

    /// Apply rounding correction to amount
    private func applyRoundingCorrection(_ value: Double) -> Double? {
        let rounded = round(value)
        return abs(value - rounded) < 0.50 ? nil : rounded
    }
}
