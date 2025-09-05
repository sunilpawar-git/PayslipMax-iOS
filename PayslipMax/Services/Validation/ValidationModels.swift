//
//  ValidationModels.swift
//  PayslipMax
//
//  Created for payslip validation data models
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Result of payslip extraction validation
struct ExtractionValidationResult {
    let isValid: Bool
    let confidenceScore: Double
    let warnings: [ExtractionValidationWarning]
    let correctedEarnings: [String: Double]
    let correctedDeductions: [String: Double]
    let summary: ValidationSummary
}

/// Individual validation warning
struct ExtractionValidationWarning {
    let component: String
    let issue: ValidationIssue
    let severity: ValidationSeverity
    let message: String
    let suggestedValue: Double?
}

/// Types of validation issues
enum ValidationIssue {
    case unrealisticAmount
    case falsePositive
    case missingComponent
    case totalMismatch
    case ratioViolation
}

/// Severity levels for validation warnings
enum ValidationSeverity {
    case low, medium, high, critical
}

/// Summary of validation results
struct ValidationSummary {
    let totalVariancePercent: Double
    let earningsAccuracy: Double
    let deductionsAccuracy: Double
    let componentsDetected: Int
    let componentsValidated: Int
}

/// Container for extraction data
struct ExtractionData {
    let earnings: [String: Double]
    let deductions: [String: Double]
    let statedCredits: Double
    let statedDebits: Double
    let payslipType: String
}

/// Validation threshold constants
struct ValidationThresholds {
    static let maxVariancePercent: Double = 15.0
    static let maxHRAToBasicRatio: Double = 2.5
    static let maxDAToBasicRatio: Double = 1.0
    static let minBasicPayForMilitary: Double = 50000.0
    static let maxBasicPayForMilitary: Double = 500000.0
    static let minConfidenceForAcceptance: Double = 0.7
}
