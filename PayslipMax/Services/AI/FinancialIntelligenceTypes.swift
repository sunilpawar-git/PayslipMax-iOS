import Foundation

/// Protocol for AI-powered financial intelligence and validation
public protocol FinancialIntelligenceServiceProtocol {
    func validateFinancialData(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> FinancialValidationResult

    func reconcileAmounts(
        credits: [String: Double],
        debits: [String: Double],
        expectedNet: Double?
    ) async throws -> AmountReconciliationResult

    func detectOutliers(
        amounts: [String: Double],
        format: LiteRTDocumentFormatType
    ) async throws -> OutlierDetectionResult

    func calculateConfidenceScore(
        extractedData: [String: Double],
        validationResults: [FinancialValidationIssue]
    ) async -> Double
}

/// Comprehensive result of financial validation
public struct FinancialValidationResult {
    let isValid: Bool
    let confidence: Double
    let issues: [FinancialValidationIssue]
    let outlierAnalysis: OutlierDetectionResult
    let reconciliationSuggestions: [String] // Simplified to avoid type conflicts
}

/// Individual financial validation issue
public struct FinancialValidationIssue {
    let type: ValidationIssueType
    let severity: ValidationSeverity
    let component: String
    let extractedValue: Double?
    let expectedValue: Double?
    let message: String
    let confidence: Double
}

/// Types of validation issues
public enum ValidationIssueType {
    case amountMismatch
    case outlierValue
    case missingComponent
    case invalidFormat
    case constraintViolation
    case crossReferenceFailure
}

/// Severity levels for validation issues
public enum ValidationSeverity {
    case critical
    case warning
    case info
}

/// Amount reconciliation result
public struct AmountReconciliationResult {
    let reconciledCredits: [String: Double]
    let reconciledDebits: [String: Double]
    let netAmount: Double
    let confidence: Double
}



/// Outlier detection result
public struct OutlierDetectionResult {
    let outliers: [String: OutlierAnalysis]
    let overallRisk: OutlierRiskLevel
    let confidence: Double
}

/// Analysis of an individual outlier
public struct OutlierAnalysis {
    let value: Double
    let zScore: Double
    let riskLevel: OutlierRiskLevel
    let expectedRange: ClosedRange<Double>
    let explanation: String
}

/// Risk levels for outliers
public enum OutlierRiskLevel {
    case low
    case medium
    case high
    case extreme
}



/// Military pay scale constraints
public struct MilitaryPayConstraints {
    static let ranges: [String: ClosedRange<Double>] = [
        "BASIC_PAY": 10_000...500_000,
        "DA": 5_000...300_000,
        "HRA": 2_000...200_000,
        "MSP": 1_000...50_000,
        "DSOPF": 1_000...100_000,
        "AGIF": 500...20_000,
        "TOTAL_CREDITS": 20_000...800_000,
        "TOTAL_DEBITS": 2_000...600_000
    ]
}

extension OutlierRiskLevel {
    func numericValue() -> Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        case .extreme: return 4.0
        }
    }
}
