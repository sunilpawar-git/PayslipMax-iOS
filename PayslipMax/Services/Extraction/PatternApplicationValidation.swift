import Foundation

/// Handles validation logic for pattern application operations
final class PatternApplicationValidation {
    
    // MARK: - Pattern Validation
    
    /// Validates that a pattern is properly formatted and contains required elements
    /// - Parameter pattern: The pattern to validate
    /// - Returns: True if pattern is valid
    func validatePattern(_ pattern: ExtractorPattern) -> Bool {
        guard !pattern.pattern.isEmpty else {
            Logger.warning("Pattern string is empty", category: "PatternValidation")
            return false
        }
        
        switch pattern.type {
        case .regex:
            return validateRegexPattern(pattern.pattern)
        case .keyword:
            return validateKeywordPattern(pattern.pattern)
        case .positionBased:
            return validatePositionBasedPattern(pattern.pattern)
        }
    }
    
    /// Validates the extracted value meets quality criteria
    /// - Parameter value: The extracted value to validate
    /// - Returns: True if value is valid and useful
    func validateExtractedValue(_ value: String?) -> Bool {
        guard let value = value, !value.isEmpty else {
            return false
        }
        
        // Remove whitespace for validation
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must have actual content
        guard !trimmedValue.isEmpty else {
            return false
        }
        
        // Should not be just punctuation or special characters
        let alphanumericSet = CharacterSet.alphanumerics
        let hasAlphanumeric = trimmedValue.unicodeScalars.contains { alphanumericSet.contains($0) }
        
        return hasAlphanumeric
    }
    
    // MARK: - Private Validation Methods
    
    /// Validates a regex pattern for basic syntax correctness
    /// - Parameter pattern: The regex pattern string
    /// - Returns: True if regex is valid
    private func validateRegexPattern(_ pattern: String) -> Bool {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [])
            return true
        } catch {
            Logger.error("Invalid regex pattern '\(pattern)': \(error.localizedDescription)", category: "PatternValidation")
            return false
        }
    }
    
    /// Validates a keyword pattern has required structure
    /// - Parameter pattern: The keyword pattern string
    /// - Returns: True if keyword pattern is valid
    private func validateKeywordPattern(_ pattern: String) -> Bool {
        let parts = pattern.split(separator: "|", omittingEmptySubsequences: false)
        
        // Must have at least one part
        guard !parts.isEmpty else {
            Logger.warning("Keyword pattern has no parts", category: "PatternValidation")
            return false
        }
        
        // Find the keyword (second part if delimited, first part otherwise)
        let keywordIndex = parts.count > 1 ? 1 : 0
        guard keywordIndex < parts.count else {
            Logger.warning("Keyword pattern missing keyword part", category: "PatternValidation")
            return false
        }
        
        let keyword = parts[keywordIndex].trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else {
            Logger.warning("Keyword pattern has empty keyword", category: "PatternValidation")
            return false
        }
        
        return true
    }
    
    /// Validates a position-based pattern has required parameters
    /// - Parameter pattern: The position-based pattern string
    /// - Returns: True if position pattern is valid
    private func validatePositionBasedPattern(_ pattern: String) -> Bool {
        let parts = pattern.split(separator: ",")
        var hasLineOffset = false
        
        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespaces)
            
            if trimmedPart.starts(with: "lineOffset:") {
                let offsetString = trimmedPart.dropFirst("lineOffset:".count)
                if Int(offsetString) != nil {
                    hasLineOffset = true
                } else {
                    Logger.warning("Position pattern has invalid lineOffset value: '\(offsetString)'", category: "PatternValidation")
                    return false
                }
            } else if trimmedPart.starts(with: "start:") {
                let startString = trimmedPart.dropFirst("start:".count)
                if Int(startString) == nil {
                    Logger.warning("Position pattern has invalid start value: '\(startString)'", category: "PatternValidation")
                    return false
                }
            } else if trimmedPart.starts(with: "end:") {
                let endString = trimmedPart.dropFirst("end:".count)
                if Int(endString) == nil {
                    Logger.warning("Position pattern has invalid end value: '\(endString)'", category: "PatternValidation")
                    return false
                }
            }
        }
        
        guard hasLineOffset else {
            Logger.warning("Position pattern missing required 'lineOffset' parameter", category: "PatternValidation")
            return false
        }
        
        return true
    }
}
