//
//  ConfidenceProtocol.swift
//  PayslipMax
//
//  Unified confidence scoring protocol and types
//  Eliminates tech debt from fragmented calculator ecosystem
//

import Foundation

// MARK: - Confidence Result

/// Standardized confidence result returned by all calculators
/// Ensures consistent output format across LLM, Universal, and Simplified parsers
struct ConfidenceResult {
    /// Overall confidence score (0.0 to 1.0)
    /// - 0.85-1.0: Excellent
    /// - 0.70-0.85: Good
    /// - 0.50-0.70: Review Recommended
    /// - 0.0-0.50: Manual Verification Required
    let overall: Double

    /// Field-level confidence breakdown
    /// Provides transparency about which fields were extracted reliably
    let fieldLevel: [String: Double]

    /// Calculator methodology identifier
    /// Examples: "LLM", "Universal", "Simplified"
    let methodology: String

    /// Optional metadata for debugging and analysis
    let metadata: [String: String]

    init(overall: Double, fieldLevel: [String: Double], methodology: String, metadata: [String: String] = [:]) {
        self.overall = min(1.0, max(0.0, overall)) // Clamp to 0.0-1.0
        self.fieldLevel = fieldLevel
        self.methodology = methodology
        self.metadata = metadata
    }
}

// MARK: - Confidence Protocol

/// Unified protocol for all payslip confidence calculators
/// Ensures consistent interface across different parsing strategies
protocol PayslipConfidenceCalculatorProtocol {
    /// The methodology identifier for this calculator
    var methodology: String { get }

    /// Calculate confidence for a parsed payslip
    /// All implementations must return normalized scores (0.0-1.0)
    /// - Returns: ConfidenceResult with overall and field-level scores
    func calculateConfidence() -> ConfidenceResult
}

// MARK: - Confidence Level

/// Semantic confidence levels for user-facing displays
enum ConfidenceLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case reviewRecommended = "Review Recommended"
    case manualVerificationRequired = "Manual Verification Required"

    var description: String {
        return self.rawValue
    }

    /// Derive confidence level from score
    static func from(score: Double) -> ConfidenceLevel {
        switch score {
        case ConfidenceThresholds.excellent...1.0:
            return .excellent
        case ConfidenceThresholds.good..<ConfidenceThresholds.excellent:
            return .good
        case ConfidenceThresholds.acceptable..<ConfidenceThresholds.good:
            return .reviewRecommended
        default:
            return .manualVerificationRequired
        }
    }

    /// Color for UI display
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "yellow"
        case .reviewRecommended:
            return "orange"
        case .manualVerificationRequired:
            return "red"
        }
    }
}

// MARK: - Confidence Thresholds

/// Centralized confidence thresholds
/// Single source of truth for all confidence calculations
struct ConfidenceThresholds {
    /// Excellent quality threshold (85%)
    static let excellent: Double = 0.85

    /// Good quality threshold (70%)
    static let good: Double = 0.70

    /// Acceptable quality threshold (50%)
    static let acceptable: Double = 0.50

    /// Year validation range
    static let minimumYear: Int = 2015
    static let maximumYearOffset: Int = 3 // Years into future

    /// Amount validation
    static let maximumReasonableAmount: Double = 1_00_00_000 // 1 crore

    /// Percentage difference tolerance for totals validation
    static let perfectMatchTolerance: Double = 0.01  // ±1%
    static let goodMatchTolerance: Double = 0.05     // ±5%
    static let acceptableMatchTolerance: Double = 0.10 // ±10%
}
