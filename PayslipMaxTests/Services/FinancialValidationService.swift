//
//  FinancialValidationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for financial validation services
protocol FinancialValidationServiceProtocol {
    /// Validates financial values in a payslip
    func validateFinancialValues(_ payslip: PayslipItem) throws -> ValidationResult

    /// Validates total calculations
    func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult

    /// Generates warnings for financial edge cases
    func generateFinancialWarnings(_ payslip: PayslipItem) -> [ValidationWarning]
}

/// Service responsible for validating financial data and calculations
class FinancialValidationService: FinancialValidationServiceProtocol {

    // MARK: - FinancialValidationServiceProtocol Implementation

    func validateFinancialValues(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check for negative values in credits
        if payslip.credits < 0 {
            errors.append(ValidationError(field: "credits", message: "Credits cannot be negative", severity: .error))
        }

        // Check for negative values in individual debits
        if payslip.debits < 0 {
            errors.append(ValidationError(field: "debits", message: "Debits cannot be negative", severity: .error))
        }

        if payslip.dsop < 0 {
            errors.append(ValidationError(field: "dsop", message: "DSOP cannot be negative", severity: .error))
        }

        if payslip.tax < 0 {
            errors.append(ValidationError(field: "tax", message: "Tax cannot be negative", severity: .error))
        }

        // Check for unrealistically large values
        let maxReasonableAmount = 10_000_000.0 // 1 crore
        if payslip.credits > maxReasonableAmount {
            warnings.append(ValidationWarning(field: "credits", message: "Credits value is unusually large"))
        }

        if payslip.debits > maxReasonableAmount {
            warnings.append(ValidationWarning(field: "debits", message: "Debits value is unusually large"))
        }

        // Check for zero credits with non-zero debits
        if payslip.credits == 0 && (payslip.debits > 0 || payslip.dsop > 0 || payslip.tax > 0) {
            warnings.append(ValidationWarning(field: "financial", message: "Zero credits with non-zero debits may indicate an edge case"))
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult {
        let calculatedCredits = payslips.reduce(0) { $0 + $1.credits }
        let calculatedDebits = payslips.reduce(0) { $0 + $1.debits + $1.dsop + $1.tax }

        var errors: [ValidationError] = []
        let tolerance = 0.01

        if abs(calculatedCredits - expectedCredits) > tolerance {
            errors.append(ValidationError(
                field: "totalCredits",
                message: "Calculated credits \(calculatedCredits) doesn't match expected \(expectedCredits)",
                severity: .error
            ))
        }

        if abs(calculatedDebits - expectedDebits) > tolerance {
            errors.append(ValidationError(
                field: "totalDebits",
                message: "Calculated debits \(calculatedDebits) doesn't match expected \(expectedDebits)",
                severity: .error
            ))
        }

        return errors.isEmpty ? .success() : .failure(errors: errors)
    }

    func generateFinancialWarnings(_ payslip: PayslipItem) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []

        // Warn about very small amounts
        if payslip.credits > 0 && payslip.credits < 100 {
            warnings.append(ValidationWarning(field: "credits", message: "Credits amount is very small"))
        }

        // Warn about round numbers (might indicate test data)
        if payslip.credits.truncatingRemainder(dividingBy: 1000) == 0 && payslip.credits > 0 {
            warnings.append(ValidationWarning(field: "credits", message: "Credits is a round thousand"))
        }

        return warnings
    }
}
