import Foundation

/// Protocol for dynamic validation with AI-powered thresholds
public protocol PCDADynamicValidatorProtocol {
    func applyDynamicThresholds(
        extractedData: [String: Double],
        aiResult: FinancialValidationResult
    ) async throws -> EnhancedValidationResult

    func calculateDynamicThreshold(
        for component: String,
        extractedValue: Double,
        outlierRisk: OutlierRiskLevel
    ) -> ClosedRange<Double>

    func validateContextAwareness(extractedData: [String: Double]) async throws -> (isValid: Bool, issues: [String], suggestions: [String])
}

/// Service responsible for dynamic validation with AI-powered thresholds
public final class PCDADynamicValidator: PCDADynamicValidatorProtocol {
    public init() {}

    // MARK: - Public Methods

    /// Apply dynamic thresholds based on AI analysis and document context
    public func applyDynamicThresholds(
        extractedData: [String: Double],
        aiResult: FinancialValidationResult
    ) async throws -> EnhancedValidationResult {

        var issues: [String] = []
        var suggestions: [String] = []
        var confidence = 0.8
        var isValid = true

        // Adjust thresholds based on outlier analysis
        let outlierAnalysis = aiResult.outlierAnalysis
        for (component, outlier) in outlierAnalysis.outliers {
            if let extractedValue = extractedData[component] {
                let dynamicThreshold = calculateDynamicThreshold(
                    for: component,
                    extractedValue: extractedValue,
                    outlierRisk: outlier.riskLevel
                )

                if extractedValue > dynamicThreshold.upperBound || extractedValue < dynamicThreshold.lowerBound {
                    issues.append("Dynamic threshold violation for \(component): \(extractedValue) outside \(dynamicThreshold)")
                    confidence -= 0.1
                    isValid = false

                    suggestions.append("Consider \(component) value of \(dynamicThreshold.lowerBound)-\(dynamicThreshold.upperBound)")
                }
            }
        }

        // Context-aware validation based on document format
        let contextValidation = try await validateContextAwareness(extractedData: extractedData)
        issues.append(contentsOf: contextValidation.issues)
        suggestions.append(contentsOf: contextValidation.suggestions)

        if !contextValidation.isValid {
            confidence -= 0.1
            isValid = false
        }

        return EnhancedValidationResult(
            isValid: isValid,
            confidence: max(0.0, min(1.0, confidence)),
            primaryIssue: issues.first,
            secondaryIssues: Array(issues.dropFirst()),
            suggestions: suggestions,
            outlierAnalysis: nil // Already included in AI result
        )
    }

    /// Calculate dynamic threshold based on outlier risk and component type
    public func calculateDynamicThreshold(
        for component: String,
        extractedValue: Double,
        outlierRisk: OutlierRiskLevel
    ) -> ClosedRange<Double> {

        let baseRange = MilitaryPayConstraints.ranges[component] ??
                        (extractedValue * 0.5)...(extractedValue * 1.5)

        let adjustmentFactor: Double
        switch outlierRisk {
        case .low:
            adjustmentFactor = 1.0
        case .medium:
            adjustmentFactor = 1.2
        case .high:
            adjustmentFactor = 1.5
        case .extreme:
            adjustmentFactor = 2.0
        }

        let rangeSize = baseRange.upperBound - baseRange.lowerBound
        let adjustedSize = rangeSize * adjustmentFactor
        let center = (baseRange.lowerBound + baseRange.upperBound) / 2

        return (center - adjustedSize/2)...(center + adjustedSize/2)
    }

    /// Validate context awareness for military pay components
    public func validateContextAwareness(extractedData: [String: Double]) async throws -> (isValid: Bool, issues: [String], suggestions: [String]) {
        var issues: [String] = []
        var suggestions: [String] = []
        var isValid = true

        // Check for logical relationships between components
        if let basicPay = extractedData["BASIC_PAY"] ?? extractedData["BPAY"],
           let da = extractedData["DA"] ?? extractedData["Dearness Allowance"] {

            let daRatio = da / basicPay
            if daRatio > 2.0 {
                issues.append("DA (\(da)) seems excessively high relative to Basic Pay (\(basicPay))")
                suggestions.append("Verify DA calculation - typically 50-100% of Basic Pay")
                isValid = false
            } else if daRatio < 0.3 {
                issues.append("DA (\(da)) seems low relative to Basic Pay (\(basicPay))")
                suggestions.append("Check if DA extraction is complete")
                isValid = false
            }
        }

        // Validate presence of mandatory components
        let mandatoryComponents = ["BASIC_PAY", "TOTAL_CREDITS", "TOTAL_DEBITS"]
        for component in mandatoryComponents {
            if extractedData[component] == nil && extractedData.values.filter({ $0 > 0 }).count > 3 {
                issues.append("Missing mandatory component: \(component)")
                suggestions.append("Ensure \(component) is properly extracted")
                isValid = false
            }
        }

        return (isValid, issues, suggestions)
    }
}
