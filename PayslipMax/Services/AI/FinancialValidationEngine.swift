import Foundation

/// Engine responsible for financial validation and constraint checking
public class FinancialValidationEngine {

    // MARK: - Properties

    private let amountTolerance: Double = 1.0

    // MARK: - Public Methods

    /// Validate amounts against format-specific constraints
    func validateConstraints(
        extractedData: [String: Double],
        format: LiteRTDocumentFormatType
    ) async throws -> [FinancialValidationIssue] {

        var issues: [FinancialValidationIssue] = []

        for (component, value) in extractedData {
            if let expectedRange = getExpectedRange(for: component, format: format) {
                if !expectedRange.contains(value) {
                    let issue = FinancialValidationIssue(
                        type: .constraintViolation,
                        severity: value <= 0 ? .critical : .warning,
                        component: component,
                        extractedValue: value,
                        expectedValue: expectedRange.lowerBound,
                        message: "\(component) value \(value) is outside expected range \(expectedRange)",
                        confidence: 0.9
                    )
                    issues.append(issue)
                }
            }
        }

        return issues
    }

    /// Validate cross-references between extracted and printed data
    func validateCrossReferences(
        extractedData: [String: Double],
        printedTotals: [String: Double]
    ) async throws -> [FinancialValidationIssue] {

        var issues: [FinancialValidationIssue] = []

        for (key, printedValue) in printedTotals {
            if let extractedValue = extractedData[key] {
                let difference = abs(extractedValue - printedValue)
                if difference > amountTolerance {
                    let issue = FinancialValidationIssue(
                        type: .crossReferenceFailure,
                        severity: .critical,
                        component: key,
                        extractedValue: extractedValue,
                        expectedValue: printedValue,
                        message: "Extracted \(key) (\(extractedValue)) doesn't match printed total (\(printedValue))",
                        confidence: 0.95
                    )
                    issues.append(issue)
                }
            }
        }

        return issues
    }

    /// Generate reconciliation suggestions
    func generateReconciliationSuggestions(
        extractedData: [String: Double],
        printedTotals: [String: Double]
    ) async throws -> [ReconciliationSuggestion] {

        var suggestions: [ReconciliationSuggestion] = []

        for (key, printedValue) in printedTotals {
            if let extractedValue = extractedData[key] {
                let difference = abs(extractedValue - printedValue)
                if difference <= amountTolerance * 5 { // Within reasonable tolerance
                    let suggestion = ReconciliationSuggestion(
                        type: ReconciliationSuggestionType.correction,
                        component: key,
                        suggestedValue: printedValue,
                        confidence: 0.8,
                        explanation: "Align with printed total for consistency"
                    )
                    suggestions.append(suggestion)
                }
            }
        }

        return suggestions
    }

    /// Calculate data completeness score
    func calculateDataCompleteness(_ data: [String: Double]) -> Double {
        let requiredComponents = ["BASIC_PAY", "TOTAL_CREDITS", "TOTAL_DEBITS"]
        let presentComponents = requiredComponents.filter { data.keys.contains($0) }
        return Double(presentComponents.count) / Double(requiredComponents.count)
    }

    /// Calculate amount reasonableness score
    func calculateAmountReasonableness(_ data: [String: Double]) -> Double {
        var reasonableCount = 0
        var totalCount = 0

        for (component, value) in data {
            if let range = MilitaryPayConstraints.ranges[component] {
                if range.contains(value) {
                    reasonableCount += 1
                }
            }
            totalCount += 1
        }

        return totalCount > 0 ? Double(reasonableCount) / Double(totalCount) : 0
    }

    // MARK: - Private Methods

    /// Get expected range for a component based on format
    private func getExpectedRange(for component: String, format: LiteRTDocumentFormatType) -> ClosedRange<Double>? {
        // Use military constraints as default, can be extended for other formats
        return MilitaryPayConstraints.ranges[component]
    }
}
