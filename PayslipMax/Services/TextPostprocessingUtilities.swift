import Foundation

/// Utility class for text postprocessing operations
/// Provides value refinement and formatting after pattern extraction
class TextPostprocessingUtilities: TextPostprocessingProtocol {

    /// Apply a postprocessing step to an extracted value
    /// - Parameters:
    ///   - step: The postprocessing step to apply
    ///   - value: The extracted value to process
    /// - Returns: The processed value after applying the transformation
    func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)

        case .removeNonNumeric:
            return value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        case .uppercase:
            return value.uppercased()

        case .lowercase:
            return value.lowercased()

        case .formatAsCurrency:
            return formatAsCurrency(value)
        }
    }

    /// Apply multiple postprocessing steps in sequence
    /// - Parameters:
    ///   - steps: Array of postprocessing steps to apply
    ///   - value: The value to postprocess
    /// - Returns: The value after applying all postprocessing steps
    func applyPostprocessingSteps(_ steps: [ExtractorPattern.PostprocessingStep], to value: String) -> String {
        var processedValue = value
        for step in steps {
            processedValue = applyPostprocessing(step, to: processedValue)
        }
        return processedValue
    }

    /// Format a value as currency by cleaning and standardizing numeric format
    /// - Parameter value: The raw value to format as currency
    /// - Returns: The formatted currency value
    private func formatAsCurrency(_ value: String) -> String {
        // Remove non-numeric characters except for decimal point and commas
        var numericValue = value.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)

        // Standardize to period as decimal separator
        numericValue = numericValue.replacingOccurrences(of: ",", with: ".")

        // If there are multiple periods, keep only the last one
        let components = numericValue.components(separatedBy: ".")
        if components.count > 2 {
            let integerPart = components.dropLast().joined()
            let decimalPart = components.last ?? ""
            numericValue = integerPart + "." + decimalPart
        }

        return numericValue
    }
}

/// Extension providing additional postprocessing utilities
extension TextPostprocessingUtilities {

    /// Clean and standardize extracted payslip values
    /// - Parameter value: The raw extracted value
    /// - Returns: Cleaned and standardized value
    func cleanPayslipValue(_ value: String) -> String {
        var cleanedValue = value

        // Apply standard trimming
        cleanedValue = applyPostprocessing(.trim, to: cleanedValue)

        // Remove any special characters that shouldn't be in payslip data
        cleanedValue = cleanedValue.replacingOccurrences(
            of: "[\\*\\+\\=\\|\\{\\}\\[\\]\\(\\)]",
            with: "",
            options: .regularExpression
        )

        return cleanedValue
    }

    /// Prepare extracted value for database storage
    /// - Parameter value: The extracted value to prepare
    /// - Returns: Value ready for storage
    func prepareForStorage(_ value: String) -> String {
        var preparedValue = value

        // Clean the value first
        preparedValue = cleanPayslipValue(preparedValue)

        // Ensure consistent encoding
        preparedValue = preparedValue.precomposedStringWithCanonicalMapping

        // Limit length to reasonable database field size
        if preparedValue.count > 1000 {
            preparedValue = String(preparedValue.prefix(1000))
        }

        return preparedValue
    }

    /// Validate extracted value for payslip data integrity
    /// - Parameter value: The value to validate
    /// - Returns: True if value appears valid for payslip data
    func isValidPayslipValue(_ value: String) -> Bool {
        let cleanedValue = cleanPayslipValue(value)

        // Check for minimum length
        guard cleanedValue.count >= 1 else { return false }

        // Check for maximum reasonable length
        guard cleanedValue.count <= 1000 else { return false }

        // Check for completely empty after cleaning
        guard !cleanedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        return true
    }
}
