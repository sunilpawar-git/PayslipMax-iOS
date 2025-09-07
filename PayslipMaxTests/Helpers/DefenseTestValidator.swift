import Foundation
@testable import PayslipMax

/// Protocol for validating defense-specific payslip data
protocol DefenseTestValidatorProtocol {
    func validateDefensePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult
    func validateDefensePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult
    func validateServiceBranchData(_ payslip: PayslipItem, branch: DefenseServiceBranch) -> ValidationResult
    func validateDefenseFinancials(_ payslip: PayslipItem) -> ValidationResult
}

/// Validator specifically for defense payslip data integrity
class DefenseTestValidator: DefenseTestValidatorProtocol {

    private let validationRules: DefenseValidationRulesProtocol

    init(validationRules: DefenseValidationRulesProtocol = DefenseValidationRules()) {
        self.validationRules = validationRules
    }

    // MARK: - DefenseTestValidatorProtocol Implementation

    func validateDefensePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate basic payslip structure
        try validateBasicStructure(payslip, &errors, &warnings)

        // Validate defense-specific fields
        validateDefenseSpecificFields(payslip, &errors, &warnings)

        // Validate service number format using extracted rules
        if let branch = detectServiceBranch(payslip.accountNumber) {
            if !validationRules.validateServiceNumberFormat(payslip.accountNumber, branch: branch) {
                warnings.append(ValidationWarning(
                    field: "serviceNumber",
                    message: "Service number format may be invalid for detected branch"
                ))
            }
        }

        // Validate financial integrity
        validateFinancialIntegrity(payslip, &errors, &warnings)

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validateDefensePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult {
        var allErrors: [ValidationError] = []
        var allWarnings: [ValidationWarning] = []

        for payslip in payslips {
            let result = try validateDefensePayslipItem(payslip)
            allErrors.append(contentsOf: result.errors)
            allWarnings.append(contentsOf: result.warnings)
        }

        // Cross-validation between payslips
        try validatePayslipConsistency(payslips, &allErrors, &allWarnings)

        if allErrors.isEmpty {
            return allWarnings.isEmpty ? .success() : .successWithWarnings(warnings: allWarnings)
        } else {
            return .failure(errors: allErrors)
        }
    }

    func validateServiceBranchData(_ payslip: PayslipItem, branch: DefenseServiceBranch) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate service branch specific patterns using extracted rules
        let branchResult: ValidationResult
        switch branch {
        case .army:
            branchResult = validationRules.validateArmySpecificData(payslip)
        case .navy:
            branchResult = validationRules.validateNavySpecificData(payslip)
        case .airForce:
            branchResult = validationRules.validateAirForceSpecificData(payslip)
        case .pcda:
            branchResult = validationRules.validatePCDASpecificData(payslip)
        }

        warnings.append(contentsOf: branchResult.warnings)

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    func validateDefenseFinancials(_ payslip: PayslipItem) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate defense-specific financial components
        validateDefenseFinancialComponents(payslip, &errors, &warnings)

        // Validate MSP (Military Service Pay) ranges
        if let msp = payslip.earnings?["Military Service Pay"], msp > 0 {
            if msp < 10000 || msp > 25000 {
                warnings.append(ValidationWarning(
                    field: "msp",
                    message: "MSP value \(msp) is outside typical range (₹10,000-25,000)"
                ))
            }
        }

        // Validate DSOP contribution ranges
        if payslip.dsop > 0 {
            if payslip.dsop < 500 || payslip.dsop > 5000 {
                warnings.append(ValidationWarning(
                    field: "dsop",
                    message: "DSOP value \(payslip.dsop) is outside typical range (₹500-5,000)"
                ))
            }
        }

        // Validate AGIF ranges
        if let agif = payslip.deductions?["AGIF"], agif > 0 {
            if agif < 100 || agif > 200 {
                warnings.append(ValidationWarning(
                    field: "agif",
                    message: "AGIF value \(agif) is outside typical range (₹100-200)"
                ))
            }
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }

    // MARK: - Private Validation Methods

    private func validateBasicStructure(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
        // Validate required fields
        if payslip.name.isEmpty {
            errors.append(ValidationError(field: "name", message: "Name cannot be empty", severity: .error))
        }

        if payslip.accountNumber.isEmpty {
            errors.append(ValidationError(field: "accountNumber", message: "Service number cannot be empty", severity: .error))
        }

        if payslip.month.isEmpty {
            errors.append(ValidationError(field: "month", message: "Month cannot be empty", severity: .error))
        }

        if payslip.year < 2020 || payslip.year > 2030 {
            warnings.append(ValidationWarning(field: "year", message: "Year \(payslip.year) seems unusual"))
        }
    }

    private func validateDefenseSpecificFields(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        // Check for defense-specific keywords in name
        let defenseKeywords = ["Capt", "Major", "Lt", "Col", "Sepoy", "Naik", "Havildar"]
        let hasDefenseTitle = defenseKeywords.contains { payslip.name.contains($0) }

        if !hasDefenseTitle && !payslip.name.contains("Personnel") {
            warnings.append(ValidationWarning(
                field: "name",
                message: "Name does not contain typical defense personnel title"
            ))
        }

        // Validate PAN format for defense personnel using extracted rules
        if !validationRules.validateDefensePANFormat(payslip.panNumber) {
            warnings.append(ValidationWarning(
                field: "panNumber",
                message: "PAN format may not be valid for defense personnel"
            ))
        }
    }

    private func validateServiceNumber(_ serviceNumber: String, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        if serviceNumber.isEmpty {
            errors.append(ValidationError(field: "serviceNumber", message: "Service number cannot be empty", severity: .error))
            return
        }

        // Check for valid defense service number patterns
        let validPatterns = [
            "^IC-\\d{5}$",      // Army: IC-12345
            "^NAV-\\d{5}$",     // Navy: NAV-12345
            "^IAF-\\d{5}$",     // Air Force: IAF-12345
            "^PCDA-\\d{5}$"     // PCDA: PCDA-12345
        ]

        let isValidFormat = validPatterns.contains { pattern in
            NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: serviceNumber)
        }

        if !isValidFormat {
            warnings.append(ValidationWarning(
                field: "serviceNumber",
                message: "Service number format may be invalid"
            ))
        }
    }

    private func validateFinancialIntegrity(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        // Check for negative values
        if payslip.credits < 0 {
            errors.append(ValidationError(field: "credits", message: "Credits cannot be negative", severity: .error))
        }

        if payslip.dsop < 0 {
            errors.append(ValidationError(field: "dsop", message: "DSOP cannot be negative", severity: .error))
        }

        // Check for unrealistic values
        let maxReasonableAmount = 200_000.0 // 2 lakhs for defense personnel
        if payslip.credits > maxReasonableAmount {
            warnings.append(ValidationWarning(field: "credits", message: "Credits value is unusually large"))
        }

        // Validate net pay calculation
        let calculatedNetPay = payslip.credits - payslip.debits
        if abs(calculatedNetPay - (payslip.credits - payslip.dsop - payslip.tax)) > 0.01 {
            warnings.append(ValidationWarning(
                field: "netPay",
                message: "Net pay calculation may be inconsistent"
            ))
        }
    }

    private func validatePayslipConsistency(_ payslips: [PayslipItem], _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
        // Check for duplicate service numbers
        let serviceNumbers = payslips.map { $0.accountNumber }
        let uniqueServiceNumbers = Set(serviceNumbers)
        if serviceNumbers.count != uniqueServiceNumbers.count {
            errors.append(ValidationError(
                field: "serviceNumbers",
                message: "Duplicate service numbers found",
                severity: .error
            ))
        }

        // Check chronological order
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
                warnings.append(ValidationWarning(
                    field: "order",
                    message: "Payslips are not in chronological order"
                ))
            }
        }
    }

    // MARK: - Helper Methods

    private func detectServiceBranch(_ serviceNumber: String) -> DefenseServiceBranch? {
        if serviceNumber.hasPrefix("IC-") {
            return .army
        } else if serviceNumber.hasPrefix("NAV-") {
            return .navy
        } else if serviceNumber.hasPrefix("IAF-") {
            return .airForce
        } else if serviceNumber.hasPrefix("PCDA-") {
            return .pcda
        }
        return nil
    }
}
