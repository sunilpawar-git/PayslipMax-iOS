import Foundation
@testable import PayslipMax

/// Protocol for defense-specific validation rules
protocol DefenseValidationRulesProtocol {
    func validateArmySpecificData(_ payslip: PayslipItem) -> ValidationResult
    func validateNavySpecificData(_ payslip: PayslipItem) -> ValidationResult
    func validateAirForceSpecificData(_ payslip: PayslipItem) -> ValidationResult
    func validatePCDASpecificData(_ payslip: PayslipItem) -> ValidationResult
    func validateServiceNumberFormat(_ serviceNumber: String, branch: DefenseServiceBranch) -> Bool
    func validateDefensePANFormat(_ pan: String) -> Bool
}

/// Component handling defense-specific validation rules
class DefenseValidationRules: DefenseValidationRulesProtocol {

    func validateArmySpecificData(_ payslip: PayslipItem) -> ValidationResult {
        var warnings: [ValidationWarning] = []

        // Army-specific validation rules
        if let rank = extractRankFromName(payslip.name) {
            validateArmyRank(rank, &warnings)
        }

        // Army service numbers should start with IC-
        if !payslip.accountNumber.hasPrefix("IC-") {
            warnings.append(ValidationWarning(
                field: "serviceNumber",
                message: "Army service numbers typically start with IC-"
            ))
        }

        return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
    }

    func validateNavySpecificData(_ payslip: PayslipItem) -> ValidationResult {
        var warnings: [ValidationWarning] = []

        // Navy-specific validation rules
        if !payslip.accountNumber.hasPrefix("NAV-") {
            warnings.append(ValidationWarning(
                field: "serviceNumber",
                message: "Navy service numbers typically start with NAV-"
            ))
        }

        return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
    }

    func validateAirForceSpecificData(_ payslip: PayslipItem) -> ValidationResult {
        var warnings: [ValidationWarning] = []

        // Air Force-specific validation rules
        if !payslip.accountNumber.hasPrefix("IAF-") {
            warnings.append(ValidationWarning(
                field: "serviceNumber",
                message: "Air Force service numbers typically start with IAF-"
            ))
        }

        return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
    }

    func validatePCDASpecificData(_ payslip: PayslipItem) -> ValidationResult {
        var warnings: [ValidationWarning] = []

        // PCDA-specific validation rules
        if !payslip.accountNumber.hasPrefix("PCDA-") {
            warnings.append(ValidationWarning(
                field: "serviceNumber",
                message: "PCDA service numbers typically start with PCDA-"
            ))
        }

        return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
    }

    func validateServiceNumberFormat(_ serviceNumber: String, branch: DefenseServiceBranch) -> Bool {
        if serviceNumber.isEmpty {
            return false
        }

        let pattern: String
        switch branch {
        case .army:
            pattern = "^IC-\\d{5}$"
        case .navy:
            pattern = "^NAV-\\d{5}$"
        case .airForce:
            pattern = "^IAF-\\d{5}$"
        case .pcda:
            pattern = "^PCDA-\\d{5}$"
        }

        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: serviceNumber)
    }

    func validateDefensePANFormat(_ pan: String) -> Bool {
        // Defense personnel PAN typically starts with service-specific prefixes
        let defensePANPattern = "^(ARMY|NAVY|IAF|PCDA)[A-Z0-9]{9}[A-Z]$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", defensePANPattern)
        return predicate.evaluate(with: pan)
    }

    // MARK: - Private Helper Methods

    private func extractRankFromName(_ name: String) -> String? {
        let rankPattern = "(Capt|Major|Lt|Col|Sepoy|Naik|Havildar|Subedar)"
        if let regex = try? NSRegularExpression(pattern: rankPattern, options: []),
           let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
            return (name as NSString).substring(with: match.range(at: 1))
        }
        return nil
    }

    private func validateArmyRank(_ rank: String, _ warnings: inout [ValidationWarning]) {
        let validArmyRanks = ["Sepoy", "Lance Naik", "Naik", "Havildar", "Naib Subedar",
                             "Subedar", "Subedar Major", "Lt", "Capt", "Major", "Lt Col", "Col"]

        if !validArmyRanks.contains(rank) {
            warnings.append(ValidationWarning(
                field: "rank",
                message: "Rank '\(rank)' may not be a valid Army rank"
            ))
        }
    }
}
