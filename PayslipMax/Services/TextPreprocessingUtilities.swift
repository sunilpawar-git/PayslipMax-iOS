import Foundation

/// Utility class for text preprocessing operations
/// Provides standardized text normalization for pattern matching
class TextPreprocessingUtilities: TextPreprocessingProtocol {

    /// Apply a preprocessing step to the input text
    /// - Parameters:
    ///   - step: The preprocessing step to apply
    ///   - text: The text to preprocess
    /// - Returns: The preprocessed text with transformations applied
    func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        case .normalizeCase:
            return text.lowercased()

        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\\r\\n|\\r", with: "\n", options: .regularExpression)

        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        case .trimLines:
            return text.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }

    /// Apply multiple preprocessing steps in sequence
    /// - Parameters:
    ///   - steps: Array of preprocessing steps to apply
    ///   - text: The text to preprocess
    /// - Returns: The text after applying all preprocessing steps
    func applyPreprocessingSteps(_ steps: [ExtractorPattern.PreprocessingStep], to text: String) -> String {
        var processedText = text
        for step in steps {
            processedText = applyPreprocessing(step, to: processedText)
        }
        return processedText
    }
}

/// Extension providing additional preprocessing utilities
extension TextPreprocessingUtilities {

    /// Normalize common payslip text formatting issues
    /// - Parameter text: The text to normalize
    /// - Returns: Normalized text ready for pattern matching
    func normalizePayslipText(_ text: String) -> String {
        var normalizedText = text

        // Remove excessive whitespace
        normalizedText = applyPreprocessing(.removeWhitespace, to: normalizedText)

        // Normalize line endings
        normalizedText = applyPreprocessing(.normalizeNewlines, to: normalizedText)

        // Trim individual lines
        normalizedText = applyPreprocessing(.trimLines, to: normalizedText)

        return normalizedText
    }

    /// Prepare text for financial data extraction
    /// - Parameter text: The text containing financial data
    /// - Returns: Text optimized for financial pattern matching
    func prepareFinancialText(_ text: String) -> String {
        var preparedText = text

        // Normalize spaces around numbers and currency symbols
        preparedText = preparedText.replacingOccurrences(
            of: "([₹$€£])\\s*(\\d)",
            with: "$1$2",
            options: .regularExpression
        )

        // Normalize decimal separators
        preparedText = preparedText.replacingOccurrences(
            of: "(\\d)[,.](\\d)",
            with: "$1.$2",
            options: .regularExpression
        )

        // Apply standard preprocessing
        preparedText = normalizePayslipText(preparedText)

        return preparedText
    }
}
