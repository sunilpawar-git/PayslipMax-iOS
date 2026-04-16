import Foundation

// MARK: - Date Validation

extension DataExtractionValidation {

    /// Validates extracted date information
    /// - Parameters:
    ///   - month: The extracted month name
    ///   - year: The extracted year
    /// - Returns: ValidationResult for the date
    func validateDate(month: String, year: Int) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        var qualityScore: Double = 1.0

        if !DateValidationRules.validYearRange.contains(year) {
            errors.append(.invalidYearRange(year: year))
            qualityScore = 0.0
        }

        if !DateValidationRules.validMonths.contains(month) {
            errors.append(.invalidMonthValue(month: month))
            qualityScore = 0.0
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        if year > currentYear {
            warnings.append("Future date detected: \(month) \(year)")
            qualityScore -= 0.1
        }

        if year < DateValidationRules.oldDateThreshold {
            warnings.append("Very old date detected: \(month) \(year)")
            qualityScore -= 0.05
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            qualityScore: max(0.0, qualityScore)
        )
    }

    /// Validates filename format and content
    /// - Parameter filename: The filename to validate
    /// - Returns: ValidationResult for the filename
    func validateFilename(_ filename: String) -> ValidationResult {
        var warnings: [String] = []
        var qualityScore: Double = 1.0

        if filename.count > 255 {
            warnings.append("Filename is very long")
            qualityScore -= 0.1
        }

        if filename.rangeOfCharacter(from: CharacterSet(charactersIn: "<>:\"|?*")) != nil {
            warnings.append("Filename contains problematic characters")
            qualityScore -= 0.1
        }

        if filename.range(of: "\\d{4}", options: .regularExpression) == nil {
            warnings.append("Filename doesn't contain a year")
            qualityScore -= 0.2
        }

        if !filename.lowercased().hasSuffix(".pdf") {
            warnings.append("File is not a PDF")
            qualityScore -= 0.1
        }

        return ValidationResult(isValid: true, errors: [], warnings: warnings, qualityScore: max(0.0, qualityScore))
    }
}
