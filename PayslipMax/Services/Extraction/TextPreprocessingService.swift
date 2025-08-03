import Foundation

/// Protocol defining text preprocessing capabilities for PDF extraction.
///
/// This service handles all text preprocessing and postprocessing operations
/// required during the pattern-based extraction process. It provides standardized
/// text transformations that improve pattern matching reliability.
protocol TextPreprocessingServiceProtocol {
    /// Applies a preprocessing step to transform input text before pattern matching.
    /// - Parameters:
    ///   - step: The preprocessing transformation to apply
    ///   - text: The text to preprocess
    /// - Returns: The transformed text
    func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String
    
    /// Applies a postprocessing step to refine extracted values.
    /// - Parameters:
    ///   - step: The postprocessing transformation to apply
    ///   - value: The extracted value to postprocess
    /// - Returns: The refined value
    func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String
}

/// Service responsible for text preprocessing and postprocessing operations.
///
/// This service provides standardized text transformations that are applied
/// before pattern matching (preprocessing) and after value extraction (postprocessing).
/// These transformations ensure consistent text formatting and improve the reliability
/// of pattern matching across different document formats.
class TextPreprocessingService: TextPreprocessingServiceProtocol {
    
    /// Applies a specific preprocessing step to the input text.
    ///
    /// This method transforms the input text based on the specified `step`. Supported transformations include:
    /// - `normalizeNewlines`: Standardizes all newline characters (\r\n, \r) to \n.
    /// - `normalizeCase`: Converts the entire text to lowercase.
    /// - `removeWhitespace`: Removes all whitespace characters (spaces, tabs, newlines).
    /// - `normalizeSpaces`: Replaces sequences of multiple whitespace characters with a single space.
    /// - `trimLines`: Trims leading/trailing whitespace from each line individually.
    ///
    /// This preprocessing pipeline ensures consistent text formatting before pattern application,
    /// increasing the reliability of extraction patterns across different document formats.
    ///
    /// - Parameters:
    ///   - step: The `ExtractorPattern.PreprocessingStep` enum case specifying the transformation to apply.
    ///   - text: The text to preprocess.
    /// - Returns: The text after applying the specified preprocessing step.
    func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        case .normalizeCase:
            return text.lowercased()
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        case .trimLines:
            return text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }
    
    /// Applies a specific postprocessing step to the extracted value.
    ///
    /// This method transforms the extracted string value based on the specified `step`. Supported transformations include:
    /// - `trim`: Removes leading and trailing whitespace and newlines.
    /// - `formatAsCurrency`: Attempts to parse the string as a Double (after removing non-numeric characters except '.') and formats it using the current locale's currency style. If parsing fails, returns the original string.
    /// - `removeNonNumeric`: Removes all characters except digits (0-9) and the period (.).
    /// - `uppercase`: Converts the string to uppercase.
    /// - `lowercase`: Converts the string to lowercase.
    ///
    /// The postprocessing pipeline enables the refinement of extracted values, ensuring they are
    /// properly formatted for use in the PayslipItem model. This improves data consistency
    /// and reduces the need for downstream processing/formatting.
    ///
    /// - Parameters:
    ///   - step: The `ExtractorPattern.PostprocessingStep` enum case specifying the transformation to apply.
    ///   - value: The extracted string value to postprocess.
    /// - Returns: The value after applying the specified postprocessing step.
    func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            if let amount = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: NSNumber(value: amount)) ?? value
            }
            return value
        case .removeNonNumeric:
            return value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }
}