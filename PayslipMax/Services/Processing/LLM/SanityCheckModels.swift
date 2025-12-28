//
//  SanityCheckModels.swift
//  PayslipMax
//
//  Models for payslip sanity check validation
//

import Foundation

/// Result of sanity check validation
struct SanityCheckResult {
    let issues: [SanityCheckIssue]
    let confidenceAdjustment: Double  // Penalty to apply to confidence score (0.0 to -1.0)
    let severity: SanityCheckSeverity

    var isValid: Bool {
        return severity != .critical
    }

    var hasConcerns: Bool {
        return !issues.isEmpty
    }

    /// Whether reconciliation retry is recommended
    var needsReconciliationRetry: Bool {
        return issues.contains { $0.code == "FUNDAMENTAL_EQUATION_FAILED" }
    }

    /// Whether line item sum retry is recommended
    var needsLineItemRetry: Bool {
        let sumMismatchCodes = ["EARNINGS_SUM_MISMATCH", "DEDUCTIONS_SUM_MISMATCH"]
        return issues.contains { sumMismatchCodes.contains($0.code) }
    }
}

/// Severity levels for sanity check issues
enum SanityCheckSeverity {
    case none       // No issues
    case minor      // Small discrepancies, acceptable
    case warning    // Noticeable issues, should review
    case critical   // Major problems, likely parsing error
}

/// A single sanity check issue
struct SanityCheckIssue {
    let code: String
    let description: String
    let severity: SanityCheckSeverity
    let confidencePenalty: Double
}

