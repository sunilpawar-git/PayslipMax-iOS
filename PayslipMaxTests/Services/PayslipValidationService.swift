//
//  PayslipValidationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for payslip validation services
protocol PayslipValidationServiceProtocol {
    /// Validates a single PayslipItem for basic data integrity
    func validateBasicFields(_ payslip: PayslipItem) throws -> ValidationResult

    /// Validates month field
    func validateMonth(_ month: String) -> ValidationResult

    /// Validates year field
    func validateYear(_ year: Int) -> ValidationResult

    /// Validates ID field
    func validateID(_ id: UUID) -> ValidationResult
}

/// Service responsible for validating individual payslip items
class PayslipValidationService: PayslipValidationServiceProtocol {

    // MARK: - PayslipValidationServiceProtocol Implementation

    func validateBasicFields(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate required fields
        if payslip.name.isEmpty {
            errors.append(ValidationError(field: "name", message: "Name cannot be empty", severity: .error))
        }

        if payslip.accountNumber.isEmpty {
            errors.append(ValidationError(field: "accountNumber", message: "Account number cannot be empty", severity: .error))
        }

        if payslip.panNumber.isEmpty {
            errors.append(ValidationError(field: "panNumber", message: "PAN number cannot be empty", severity: .error))
        }

        return errors.isEmpty ? .success() : .failure(errors: errors)
    }

    func validateMonth(_ month: String) -> ValidationResult {
        let validMonths = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

        if !validMonths.contains(month) {
            return .failure(errors: [
                ValidationError(field: "month", message: "Invalid month: \(month)", severity: .error)
            ])
        }

        return .success()
    }

    func validateYear(_ year: Int) -> ValidationResult {
        let currentYear = Calendar.current.component(.year, from: Date())
        if year < 2000 || year > currentYear + 10 {
            return .failure(errors: [
                ValidationError(field: "year", message: "Year \(year) is outside valid range", severity: .error)
            ])
        }

        return .success()
    }

    func validateID(_ id: UUID) -> ValidationResult {
        if id.uuidString.isEmpty {
            return .failure(errors: [
                ValidationError(field: "id", message: "UUID cannot be empty", severity: .error)
            ])
        }

        return .success()
    }
}
