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
        let errors: [ValidationError] = []
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
        let errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Validate MSP (Military Service Pay) ranges
        if let msp = payslip.earnings["Military Service Pay"], msp > 0 {
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
        if let agif = payslip.deductions["AGIF"], agif > 0 {
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

    private func validateDefenseSpecificFields(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        let defenseKeywords = ["Capt", "Major", "Lt", "Col", "Sepoy", "Naik", "Havildar"]
        let hasDefenseTitle = defenseKeywords.contains { payslip.name.contains($0) }

        if !hasDefenseTitle && !payslip.name.contains("Personnel") {
            warnings.append(ValidationWarning(
                field: "name",
                message: "Name does not contain typical defense personnel title"
            ))
        }

        if !validationRules.validateDefensePANFormat(payslip.panNumber) {
            warnings.append(ValidationWarning(
                field: "panNumber",
                message: "PAN format may not be valid for defense personnel"
            ))
        }
    }
}
