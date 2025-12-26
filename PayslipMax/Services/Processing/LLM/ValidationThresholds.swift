//
//  ValidationThresholds.swift
//  PayslipMax
//
//  Centralized configuration for payslip validation thresholds
//  Extracted from magic numbers in PayslipSanityCheckValidator and VisionLLMVerificationService
//

import Foundation

/// Centralized thresholds for payslip validation logic
enum ValidationThresholds {
    // MARK: - Error Percentages

    /// Minor reconciliation error threshold (1%)
    static let minorErrorPercent: Double = 0.01

    /// Major reconciliation error threshold (5%)
    static let majorErrorPercent: Double = 0.05

    // MARK: - Confidence Penalties

    /// Penalty for minor issues (e.g., small reconciliation errors)
    static let minorConfidencePenalty: Double = -0.05

    /// Penalty for warning-level issues (e.g., totals mismatch)
    static let warningConfidencePenalty: Double = -0.1

    /// Penalty for suspicious deduction keys
    static let suspiciousKeyPenalty: Double = -0.15

    /// Penalty for net reconciliation failures
    static let netReconciliationPenalty: Double = -0.2

    /// Penalty for negative net pay
    static let negativeNetPayPenalty: Double = -0.3

    /// Penalty for critical issues (e.g., deductions > earnings)
    static let criticalPenalty: Double = -0.4

    /// Maximum total confidence penalty (cap)
    static let maxConfidencePenalty: Double = -0.5

    // MARK: - Value Ranges

    /// Minimum expected gross pay for military payslips (₹)
    static let minimumGrossPay: Double = 10_000

    // MARK: - Verification Thresholds

    /// Confidence threshold below which verification is triggered
    static let verificationTriggerThreshold: Double = 0.9

    /// High agreement threshold for verification passes
    static let highAgreementThreshold: Double = 0.9

    /// Moderate agreement threshold for verification passes
    static let moderateAgreementThreshold: Double = 0.8

    /// Low agreement threshold for verification passes
    static let lowAgreementThreshold: Double = 0.5

    /// Line item comparison tolerance (5%)
    static let lineItemComparisonTolerance: Double = 0.05

    // MARK: - Confidence Adjustments for Verification

    /// Confidence boost for high agreement
    static let highAgreementConfidenceBoost: Double = 0.1

    /// Confidence multiplier for moderate agreement (50-80%)
    static let moderateAgreementMultiplier: Double = 0.95

    /// Confidence multiplier for low agreement (<50%)
    static let lowAgreementMultiplier: Double = 0.8

    /// Confidence multiplier for moderate agreement display (line 70)
    static let moderateAgreementDisplayMultiplier: Double = 0.9
}

