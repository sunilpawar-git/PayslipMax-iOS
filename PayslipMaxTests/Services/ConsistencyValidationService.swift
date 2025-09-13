//
//  ConsistencyValidationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for consistency validation services
protocol ConsistencyValidationServiceProtocol {
    /// Validates consistency across multiple payslips
    func validatePayslipConsistency(_ payslips: [PayslipItem]) throws -> ValidationResult

    /// Validates test scenario for completeness
    func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult
}

/// Service responsible for validating consistency across payslips and scenarios
class ConsistencyValidationService: ConsistencyValidationServiceProtocol {

    // MARK: - ConsistencyValidationServiceProtocol Implementation

    func validatePayslipConsistency(_ payslips: [PayslipItem]) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check for duplicate IDs
        let ids = payslips.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            errors.append(ValidationError(field: "ids", message: "Duplicate payslip IDs found", severity: .error))
        }

        // Check for payslips with same name and month/year (potential duplicates)
        let nameMonthYearCombos = payslips.map { "\($0.name)_\($0.month)_\($0.year)" }
        let uniqueCombos = Set(nameMonthYearCombos)
        if nameMonthYearCombos.count != uniqueCombos.count {
            warnings.append(ValidationWarning(field: "data", message: "Potential duplicate payslips found (same name, month, year)"))
        }

        // Check chronological order if payslips seem to be in sequence
        if payslips.count > 1 {
            let sortedByDate = payslips.sorted { (p1, p2) -> Bool in
                if p1.year != p2.year {
                    return p1.year < p2.year
                }
                let months = ["January", "February", "March", "April", "May", "June",
                             "July", "August", "September", "October", "November", "December"]
                return (months.firstIndex(of: p1.month) ?? 0) < (months.firstIndex(of: p2.month) ?? 0)
            }

            let originalOrder = payslips.map { "\($0.month) \($0.year)" }
            let sortedOrder = sortedByDate.map { "\($0.month) \($0.year)" }

            if originalOrder != sortedOrder {
                warnings.append(ValidationWarning(field: "order", message: "Payslips are not in chronological order"))
            }
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult {
        var errors: [ValidationError] = []
        let warnings: [ValidationWarning] = []

        // Validate basic scenario properties
        if scenario.title.isEmpty {
            errors.append(ValidationError(field: "title", message: "Scenario title cannot be empty", severity: .error))
        }

        if scenario.description.isEmpty {
            errors.append(ValidationError(field: "description", message: "Scenario description cannot be empty", severity: .error))
        }

        if scenario.payslips.isEmpty {
            errors.append(ValidationError(field: "payslips", message: "Scenario must contain at least one payslip", severity: .error))
        }

        // Validate expected totals
        let calculatedCredits = scenario.payslips.reduce(0) { $0 + $1.credits }
        let calculatedDebits = scenario.payslips.reduce(0) { $0 + $1.debits + $1.dsop + $1.tax }
        let calculatedNet = calculatedCredits - calculatedDebits

        let tolerance = 0.01 // Allow for small floating point differences

        if abs(calculatedCredits - scenario.expectedTotalCredits) > tolerance {
            errors.append(ValidationError(
                field: "expectedTotalCredits",
                message: "Expected credits \(scenario.expectedTotalCredits) doesn't match calculated \(calculatedCredits)",
                severity: .error
            ))
        }

        if abs(calculatedDebits - scenario.expectedTotalDebits) > tolerance {
            errors.append(ValidationError(
                field: "expectedTotalDebits",
                message: "Expected debits \(scenario.expectedTotalDebits) doesn't match calculated \(calculatedDebits)",
                severity: .error
            ))
        }

        if abs(calculatedNet - scenario.expectedNetAmount) > tolerance {
            errors.append(ValidationError(
                field: "expectedNetAmount",
                message: "Expected net amount \(scenario.expectedNetAmount) doesn't match calculated \(calculatedNet)",
                severity: .error
            ))
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }
}
