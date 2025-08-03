import Foundation

/// Mock implementation of TextPreprocessingServiceProtocol for testing purposes.
class MockTextPreprocessingService: TextPreprocessingServiceProtocol {
    
    /// Controls whether preprocessing should return modified text or original text
    var shouldModifyText: Bool = true
    
    /// Tracks the last preprocessing step applied
    var lastPreprocessingStep: ExtractorPattern.PreprocessingStep?
    
    /// Tracks the last postprocessing step applied
    var lastPostprocessingStep: ExtractorPattern.PostprocessingStep?
    
    /// Number of times applyPreprocessing was called
    var preprocessingCallCount = 0
    
    /// Number of times applyPostprocessing was called
    var postprocessingCallCount = 0
    
    /// Applies a preprocessing step to transform input text before pattern matching.
    /// - Parameters:
    ///   - step: The preprocessing transformation to apply
    ///   - text: The text to preprocess
    /// - Returns: The transformed text or original text based on shouldModifyText
    func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        preprocessingCallCount += 1
        lastPreprocessingStep = step
        
        guard shouldModifyText else {
            return text
        }
        
        // Apply simplified preprocessing for testing
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
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
    
    /// Applies a postprocessing step to refine extracted values.
    /// - Parameters:
    ///   - step: The postprocessing transformation to apply
    ///   - value: The extracted value to postprocess
    /// - Returns: The refined value or original value based on shouldModifyText
    func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        postprocessingCallCount += 1
        lastPostprocessingStep = step
        
        guard shouldModifyText else {
            return value
        }
        
        // Apply simplified postprocessing for testing
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            if let amount = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                return String(format: "%.2f", amount)
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
    
    /// Resets the mock to its initial state
    func reset() {
        shouldModifyText = true
        lastPreprocessingStep = nil
        lastPostprocessingStep = nil
        preprocessingCallCount = 0
        postprocessingCallCount = 0
    }
}