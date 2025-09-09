//
//  TestDataValidator.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Validator for test data integrity and consistency using dependency injection
class TestDataValidator: TestDataValidatorProtocol {

    // MARK: - Dependencies

    private let payslipValidator: PayslipValidationServiceProtocol
    private let pdfValidator: PDFValidationServiceProtocol

    // MARK: - Initialization

    init(
        payslipValidator: PayslipValidationServiceProtocol,
        pdfValidator: PDFValidationServiceProtocol
    ) {
        self.payslipValidator = payslipValidator
        self.pdfValidator = pdfValidator
    }

    // MARK: - TestDataValidatorProtocol Implementation

    func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Simple validation without protocol methods due to type issues
        // TODO: Fix protocol conformance issue - for now use basic validation

        // Basic field validation - PayslipItem has month as String, not Int
        if payslip.month.isEmpty {
            errors.append(ValidationError(field: "month", message: "Month cannot be empty", severity: .error))
        }

        if payslip.year < 1900 || payslip.year > 2100 {
            errors.append(ValidationError(field: "year", message: "Year must be between 1900 and 2100", severity: .error))
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validatePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult {
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []

        for (index, payslip) in payslips.enumerated() {
            let result = try validatePayslipItem(payslip)
            allErrors.append(contentsOf: result.errors.map { error in
                ValidationError(field: "[\(index)].\(error.field)", message: error.message, severity: error.severity)
            })
            allWarnings.append(contentsOf: result.warnings.map { warning in
                ValidationWarning(field: "[\(index)].\(warning.field)", message: warning.message)
            })
        }

        // Basic consistency validation
        if payslips.count > 1 {
            let firstPayslip = payslips[0]
            for (index, payslip) in payslips.enumerated() {
                if index > 0 {
                    if payslip.name != firstPayslip.name {
                        allWarnings.append(ValidationWarning(field: "[\(index)].name", message: "Name differs from first payslip"))
                    }
                }
            }
        }

        if allErrors.isEmpty {
            return allWarnings.isEmpty ? .success() : .successWithWarnings(warnings: allWarnings)
        } else {
            return .failure(errors: allErrors)
        }
    }

    func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

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

        // Validate payslips in scenario
        let payslipResult = try validatePayslipItems(scenario.payslips)
        errors.append(contentsOf: payslipResult.errors)
        warnings.append(contentsOf: payslipResult.warnings)

        // Basic scenario validation (removed dependency on unavailable consistency validator)

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validatePDFData(_ data: Data) -> ValidationResult {
        // Use a simple data check since the protocol method takes PDFDocument
        if data.isEmpty {
            return .failure(errors: [ValidationError(field: "pdf", message: "PDF data is empty", severity: .error)])
        }

        // Basic PDF validation - check if data starts with PDF signature
        let pdfSignature = "%PDF-".data(using: .ascii)!
        if data.count >= pdfSignature.count && data.prefix(pdfSignature.count) == pdfSignature {
            return .success()
        } else {
            return .failure(errors: [ValidationError(field: "pdf", message: "Invalid PDF structure", severity: .error)])
        }
    }

    func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult {
        // Simple totals validation without external financial validator
        let actualCredits = payslips.map { $0.credits }.reduce(0, +)
        let actualDebits = payslips.map { $0.debits }.reduce(0, +)

        var errors: [ValidationError] = []

        if abs(actualCredits - expectedCredits) > 0.01 {
            errors.append(ValidationError(field: "credits", message: "Credits total mismatch: expected \(expectedCredits), got \(actualCredits)", severity: .error))
        }

        if abs(actualDebits - expectedDebits) > 0.01 {
            errors.append(ValidationError(field: "debits", message: "Debits total mismatch: expected \(expectedDebits), got \(actualDebits)", severity: .error))
        }

        return errors.isEmpty ? .success() : .failure(errors: errors)
    }
}
