//
//  ValidationModels.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation

/// Protocol for validating test data integrity and consistency
protocol TestDataValidatorProtocol {
    /// Validates a single PayslipItem for data integrity
    func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult

    /// Validates an array of PayslipItems
    func validatePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult

    /// Validates a TestScenario for completeness
    func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult

    /// Validates PDF data for basic integrity
    func validatePDFData(_ data: Data) -> ValidationResult

    /// Validates that calculated totals match expected values
    func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult
}

/// Result of validation operations
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]

    static func success() -> ValidationResult {
        return ValidationResult(isValid: true, errors: [], warnings: [])
    }

    static func failure(errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors, warnings: [])
    }

    static func successWithWarnings(warnings: [ValidationWarning]) -> ValidationResult {
        return ValidationResult(isValid: true, errors: [], warnings: warnings)
    }
}

/// Represents a validation error
struct ValidationError {
    let field: String
    let message: String
    let severity: ValidationSeverity
}

/// Represents a validation warning
struct ValidationWarning {
    let field: String
    let message: String
}

/// Severity levels for validation issues
enum ValidationSeverity {
    case error
    case warning
    case info
}
