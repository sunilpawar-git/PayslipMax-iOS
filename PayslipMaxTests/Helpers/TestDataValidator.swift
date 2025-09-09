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
    private let financialValidator: FinancialValidationServiceProtocol
    private let pdfValidator: PDFValidationServiceProtocol
    private let consistencyValidator: ConsistencyValidationServiceProtocol
    private let panValidator: PANValidationServiceProtocol
    private let warningGenerator: WarningGenerationServiceProtocol

    // MARK: - Initialization

    init(
        payslipValidator: PayslipValidationServiceProtocol,
        financialValidator: FinancialValidationServiceProtocol,
        pdfValidator: PDFValidationServiceProtocol,
        consistencyValidator: ConsistencyValidationServiceProtocol,
        panValidator: PANValidationServiceProtocol,
        warningGenerator: WarningGenerationServiceProtocol
    ) {
        self.payslipValidator = payslipValidator
        self.financialValidator = financialValidator
        self.pdfValidator = pdfValidator
        self.consistencyValidator = consistencyValidator
        self.panValidator = panValidator
        self.warningGenerator = warningGenerator
    }

    // MARK: - TestDataValidatorProtocol Implementation

    func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate basic fields
        let basicResult = try payslipValidator.validateBasicFields(payslip)
        errors.append(contentsOf: basicResult.errors)
        warnings.append(contentsOf: basicResult.warnings)

        // Validate month and year
        let monthResult = payslipValidator.validateMonth(payslip.month)
        let yearResult = payslipValidator.validateYear(payslip.year)
        let idResult = payslipValidator.validateID(payslip.id)

        errors.append(contentsOf: monthResult.errors)
        errors.append(contentsOf: yearResult.errors)
        errors.append(contentsOf: idResult.errors)

        // Validate financial values
        let financialResult = try financialValidator.validateFinancialValues(payslip)
        errors.append(contentsOf: financialResult.errors)
        warnings.append(contentsOf: financialResult.warnings)

        // Generate additional warnings
        warnings.append(contentsOf: financialValidator.generateFinancialWarnings(payslip))
        warnings.append(contentsOf: panValidator.generatePANWarnings(payslip.panNumber))
        warnings.append(contentsOf: warningGenerator.generateWarnings(for: payslip))

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

        // Cross-validation between payslips
        let consistencyResult = try consistencyValidator.validatePayslipConsistency(payslips)
        allErrors.append(contentsOf: consistencyResult.errors)
        allWarnings.append(contentsOf: consistencyResult.warnings)

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

        // Validate expected totals using consistency validator
        let scenarioResult = try consistencyValidator.validateTestScenario(scenario)
        errors.append(contentsOf: scenarioResult.errors)
        warnings.append(contentsOf: scenarioResult.warnings)

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validatePDFData(_ data: Data) -> ValidationResult {
        return pdfValidator.validatePDFData(data)
    }

    func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult {
        return financialValidator.validateTotals(payslips: payslips, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }
}
