
import Foundation

/// The ultimate OCR validation framework for military payslip accuracy measurement.
final class UltimateOCRValidator {

    /// Validates a parsed military payslip by cross-referencing key financial fields.
    ///
    /// - Parameter payslip: The `MilitaryPayslip` to validate.
    /// - Returns: A `OCRValidationResult` indicating the accuracy of the payslip.
    func validate(payslip: MilitaryPayslip) -> OCRValidationResult {
        guard let allowancesStr = payslip.fields["ALLOWANCES"],
              let deductionsStr = payslip.fields["DEDUCTIONS"],
              let netPayStr = payslip.fields["NET PAY"] else {
            return OCRValidationResult(isValid: false, validationNotes: "Missing one or more key financial fields (Allowances, Deductions, Net Pay).")
        }

        guard let allowances = Double(fromFinancialString: allowancesStr),
              let deductions = Double(fromFinancialString: deductionsStr),
              let netPay = Double(fromFinancialString: netPayStr) else {
            return OCRValidationResult(isValid: false, validationNotes: "Could not parse financial values to numbers.")
        }

        let calculatedNetPay = allowances - deductions
        let tolerance = 0.05 // Allow for small rounding discrepancies

        if abs(calculatedNetPay - netPay) < tolerance {
            return OCRValidationResult(isValid: true, validationNotes: "Validation successful: Allowances - Deductions = Net Pay.")
        } else {
            let notes = "Validation failed: Calculated Net Pay (\(calculatedNetPay)) does not match extracted Net Pay (\(netPay))."
            return OCRValidationResult(isValid: false, validationNotes: notes)
        }
    }
}

/// Represents the result of a validation check.
struct OCRValidationResult {
    let isValid: Bool
    let validationNotes: String
}


extension Double {
    /// Initializes a Double from a string that may contain commas.
    init?(fromFinancialString: String) {
        let cleanedString = fromFinancialString.replacingOccurrences(of: ",", with: "")
        self.init(cleanedString)
    }
}
