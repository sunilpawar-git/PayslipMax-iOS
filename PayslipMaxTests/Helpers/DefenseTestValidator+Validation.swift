import Foundation
@testable import PayslipMax

extension DefenseTestValidator {

    func validateBasicStructure(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
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

    func validateServiceNumber(_ serviceNumber: String, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        if serviceNumber.isEmpty {
            errors.append(ValidationError(field: "serviceNumber", message: "Service number cannot be empty", severity: .error))
            return
        }

        let validPatterns = [
            "^IC-\\d{5}$",
            "^NAV-\\d{5}$",
            "^IAF-\\d{5}$",
            "^PCDA-\\d{5}$"
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

    func validateFinancialIntegrity(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) {
        if payslip.credits < 0 {
            errors.append(ValidationError(field: "credits", message: "Credits cannot be negative", severity: .error))
        }

        if payslip.dsop < 0 {
            errors.append(ValidationError(field: "dsop", message: "DSOP cannot be negative", severity: .error))
        }

        let maxReasonableAmount = 200_000.0
        if payslip.credits > maxReasonableAmount {
            warnings.append(ValidationWarning(field: "credits", message: "Credits value is unusually large"))
        }

        let calculatedNetPay = payslip.credits - payslip.debits
        if abs(calculatedNetPay - (payslip.credits - payslip.dsop - payslip.tax)) > 0.01 {
            warnings.append(ValidationWarning(
                field: "netPay",
                message: "Net pay calculation may be inconsistent"
            ))
        }
    }

    func validatePayslipConsistency(_ payslips: [PayslipItem], _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
        let serviceNumbers = payslips.map { $0.accountNumber }
        let uniqueServiceNumbers = Set(serviceNumbers)
        if serviceNumbers.count != uniqueServiceNumbers.count {
            errors.append(ValidationError(
                field: "serviceNumbers",
                message: "Duplicate service numbers found",
                severity: .error
            ))
        }

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

    func detectServiceBranch(_ serviceNumber: String) -> DefenseServiceBranch? {
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
