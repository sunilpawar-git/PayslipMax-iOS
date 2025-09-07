import Foundation

// MARK: - Preprocessing Step Extensions

extension ExtractorPattern.PreprocessingStep {
    var description: String {
        switch self {
        case .normalizeNewlines:
            return "Normalize Newlines"
        case .normalizeCase:
            return "Convert to Lowercase"
        case .removeWhitespace:
            return "Remove Whitespace"
        case .normalizeSpaces:
            return "Normalize Spaces"
        case .trimLines:
            return "Trim Lines"
        }
    }
}

// MARK: - Postprocessing Step Extensions

extension ExtractorPattern.PostprocessingStep {
    var description: String {
        switch self {
        case .trim:
            return "Trim Whitespace"
        case .formatAsCurrency:
            return "Format as Currency"
        case .removeNonNumeric:
            return "Remove Non-Numeric"
        case .uppercase:
            return "Convert to Uppercase"
        case .lowercase:
            return "Convert to Lowercase"
        }
    }
}
