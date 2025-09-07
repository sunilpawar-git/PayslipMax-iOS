import Foundation
@testable import PayslipMax

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

/// Validator for test data integrity and consistency
class TestDataValidator: TestDataValidatorProtocol {

    // MARK: - TestDataValidatorProtocol Implementation

    func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

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

        // Validate month
        let validMonths = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
        if !validMonths.contains(payslip.month) {
            errors.append(ValidationError(field: "month", message: "Invalid month: \(payslip.month)", severity: .error))
        }

        // Validate year
        let currentYear = Calendar.current.component(.year, from: Date())
        if payslip.year < 2000 || payslip.year > currentYear + 10 {
            errors.append(ValidationError(field: "year", message: "Year \(payslip.year) is outside valid range", severity: .error))
        }

        // Validate financial values
        try validateFinancialValues(payslip, &errors, &warnings)

        // Validate ID
        if payslip.id.uuidString.isEmpty {
            errors.append(ValidationError(field: "id", message: "UUID cannot be empty", severity: .error))
        }

        // Generate warnings for edge cases
        generateWarnings(for: payslip, &warnings)

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
        try validatePayslipConsistency(payslips, &allErrors, &allWarnings)

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

    func validatePDFData(_ data: Data) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check if data is empty
        if data.isEmpty {
            errors.append(ValidationError(field: "pdfData", message: "PDF data cannot be empty", severity: .error))
            return .failure(errors: errors)
        }

        // Check minimum size (PDF header is typically small)
        if data.count < 100 {
            warnings.append(ValidationWarning(field: "pdfData", message: "PDF data is unusually small"))
        }

        // Check for PDF header
        let headerBytes = data.prefix(8)
        let headerString = String(data: headerBytes, encoding: .ascii) ?? ""

        if !headerString.hasPrefix("%PDF-") {
            errors.append(ValidationError(field: "pdfData", message: "Data does not appear to be a valid PDF", severity: .error))
        }

        // Check for PDF trailer
        let trailerString = String(data: data.suffix(1024), encoding: .ascii) ?? ""
        if !trailerString.contains("%%EOF") {
            errors.append(ValidationError(field: "pdfData", message: "PDF data is missing EOF marker", severity: .error))
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

    // MARK: - Private Helper Methods

    private func validateFinancialValues(_ payslip: PayslipItem, _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
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
    }

    private func generateWarnings(for payslip: PayslipItem, _ warnings: inout [ValidationWarning]) {
        // Warn about very small amounts
        if payslip.credits > 0 && payslip.credits < 100 {
            warnings.append(ValidationWarning(field: "credits", message: "Credits amount is very small"))
        }

        // Warn about round numbers (might indicate test data)
        if payslip.credits.truncatingRemainder(dividingBy: 1000) == 0 && payslip.credits > 0 {
            warnings.append(ValidationWarning(field: "credits", message: "Credits is a round thousand"))
        }

        // Warn about special characters in names
        if payslip.name.contains(where: { !$0.isLetter && !$0.isWhitespace && !$0.isPunctuation }) {
            warnings.append(ValidationWarning(field: "name", message: "Name contains special characters"))
        }

        // Warn about unusual PAN format
        if !isValidPANFormat(payslip.panNumber) {
            warnings.append(ValidationWarning(field: "panNumber", message: "PAN number format may be invalid"))
        }
    }

    private func validatePayslipConsistency(_ payslips: [PayslipItem], _ errors: inout [ValidationError], _ warnings: inout [ValidationWarning]) throws {
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
    }

    private func isValidPANFormat(_ pan: String) -> Bool {
        // Basic PAN format validation (AAAAA9999A)
        let panRegex = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", panRegex)
        return predicate.evaluate(with: pan)
    }
}
