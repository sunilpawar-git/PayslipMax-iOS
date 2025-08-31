import Foundation

/// Protocol for pattern analysis functionality
@MainActor
public protocol PatternAnalyzerProtocol {
    func analyzeCorrection(_ correction: UserCorrection) async throws -> CorrectionPattern
    func updatePatternWeights(_ pattern: CorrectionPattern) async throws
    func identifyRecurringPatterns(_ corrections: [UserCorrection]) async throws -> [RecurringPattern]
    func generatePatternSuggestions(for field: String, corrections: [UserCorrection]) async throws -> [PatternSuggestion]
}

/// Analyzer for identifying patterns in user corrections
@MainActor
public class PatternAnalyzer: PatternAnalyzerProtocol {
    
    // MARK: - Properties
    
    private var patternWeights: [String: Double] = [:]
    private var patternFrequencies: [String: Int] = [:]
    private let minimumPatternOccurrences = 3
    
    // MARK: - Public Methods
    
    /// Analyze a correction to identify patterns
    public func analyzeCorrection(_ correction: UserCorrection) async throws -> CorrectionPattern {
        print("[PatternAnalyzer] Analyzing correction for field: \(correction.fieldName)")
        
        // Determine pattern type
        let patternType = determinePatternType(correction)
        
        // Extract pattern string
        let pattern = extractPattern(from: correction, type: patternType)
        
        // Calculate frequency
        let frequency = await updatePatternFrequency(pattern)
        
        // Calculate confidence
        let confidence = calculatePatternConfidence(pattern: pattern, frequency: frequency, correction: correction)
        
        // Calculate confidence adjustment
        let confidenceAdjustment = calculateConfidenceAdjustment(correction)
        
        return CorrectionPattern(
            fieldName: correction.fieldName,
            documentType: correction.documentType,
            patternType: patternType,
            pattern: pattern,
            frequency: frequency,
            confidence: confidence,
            confidenceAdjustment: confidenceAdjustment
        )
    }
    
    /// Update pattern weights based on analysis
    public func updatePatternWeights(_ pattern: CorrectionPattern) async throws {
        let patternKey = "\(pattern.fieldName):\(pattern.pattern)"
        
        // Update weight based on frequency and confidence
        let currentWeight = patternWeights[patternKey] ?? 0.0
        let newWeight = currentWeight + (pattern.confidence * 0.1)
        
        patternWeights[patternKey] = min(1.0, newWeight)
        
        print("[PatternAnalyzer] Updated pattern weight for \(patternKey): \(newWeight)")
    }
    
    /// Identify recurring patterns across corrections
    public func identifyRecurringPatterns(_ corrections: [UserCorrection]) async throws -> [RecurringPattern] {
        var patterns: [RecurringPattern] = []
        
        // Group corrections by field
        let fieldGroups = Dictionary(grouping: corrections) { $0.fieldName }
        
        for (fieldName, fieldCorrections) in fieldGroups {
            // Analyze value patterns
            let valuePatterns = try await analyzeValuePatterns(fieldCorrections, fieldName: fieldName)
            patterns.append(contentsOf: valuePatterns)
            
            // Analyze format patterns
            let formatPatterns = try await analyzeFormatPatterns(fieldCorrections, fieldName: fieldName)
            patterns.append(contentsOf: formatPatterns)
            
            // Analyze context patterns
            let contextPatterns = try await analyzeContextPatterns(fieldCorrections, fieldName: fieldName)
            patterns.append(contentsOf: contextPatterns)
        }
        
        // Filter patterns by minimum occurrences
        return patterns.filter { $0.occurrences >= minimumPatternOccurrences }
    }
    
    /// Generate pattern-based suggestions
    public func generatePatternSuggestions(for field: String, corrections: [UserCorrection]) async throws -> [PatternSuggestion] {
        let fieldCorrections = corrections.filter { $0.fieldName == field }
        guard fieldCorrections.count >= 2 else {
            return []
        }
        
        var suggestions: [PatternSuggestion] = []
        
        // Value suggestions
        let valueSuggestions = generateValueSuggestions(fieldCorrections)
        suggestions.append(contentsOf: valueSuggestions)
        
        // Format suggestions
        let formatSuggestions = generateFormatSuggestions(fieldCorrections)
        suggestions.append(contentsOf: formatSuggestions)
        
        // Validation suggestions
        let validationSuggestions = generateValidationSuggestions(fieldCorrections)
        suggestions.append(contentsOf: validationSuggestions)
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Private Methods
    
    /// Determine the type of pattern in the correction
    private func determinePatternType(_ correction: UserCorrection) -> PatternType {
        let originalValue = correction.originalValue
        let correctedValue = correction.correctedValue
        
        // Check if it's a regex pattern
        if isRegexPattern(originalValue, correctedValue) {
            return .regex
        }
        
        // Check if it's a format pattern
        if isFormatPattern(originalValue, correctedValue) {
            return .format
        }
        
        // Check if it's a position pattern
        if isPositionPattern(originalValue, correctedValue) {
            return .position
        }
        
        // Check if it's a context pattern
        if isContextPattern(originalValue, correctedValue) {
            return .context
        }
        
        // Default to value pattern
        return .value
    }
    
    /// Extract pattern string from correction
    private func extractPattern(from correction: UserCorrection, type: PatternType) -> String {
        switch type {
        case .regex:
            return extractRegexPattern(correction)
        case .format:
            return extractFormatPattern(correction)
        case .position:
            return extractPositionPattern(correction)
        case .context:
            return extractContextPattern(correction)
        case .value:
            return correction.correctedValue
        case .validationRule:
            return extractValidationRulePattern(correction)
        }
    }
    
    /// Update pattern frequency and return current count
    private func updatePatternFrequency(_ pattern: String) async -> Int {
        let currentCount = patternFrequencies[pattern] ?? 0
        let newCount = currentCount + 1
        patternFrequencies[pattern] = newCount
        return newCount
    }
    
    /// Calculate confidence for a pattern
    private func calculatePatternConfidence(pattern: String, frequency: Int, correction: UserCorrection) -> Double {
        // Base confidence on frequency
        let frequencyConfidence = min(1.0, Double(frequency) / 10.0)
        
        // Adjust based on pattern complexity
        let complexityBonus = calculateComplexityBonus(pattern)
        
        // Adjust based on field reliability
        let fieldReliability = getFieldReliability(correction.fieldName)
        
        return min(1.0, frequencyConfidence + complexityBonus + fieldReliability)
    }
    
    /// Calculate confidence adjustment impact
    private func calculateConfidenceAdjustment(_ correction: UserCorrection) -> Double {
        // Negative adjustment for corrections (indicating parser was wrong)
        let baseAdjustment = -0.1
        
        // Adjust based on confidence impact
        let impactAdjustment = correction.confidenceImpact * 0.5
        
        return baseAdjustment + impactAdjustment
    }
    
    /// Check if correction represents a regex pattern
    private func isRegexPattern(_ original: String, _ corrected: String) -> Bool {
        // Simple heuristic: if corrected value has regex-like characters
        let regexChars = CharacterSet(charactersIn: ".*+?[](){}|\\^$")
        return corrected.rangeOfCharacter(from: regexChars) != nil
    }
    
    /// Check if correction represents a format pattern
    private func isFormatPattern(_ original: String, _ corrected: String) -> Bool {
        // Check if values have similar structure but different content
        return hasSimilarStructure(original, corrected) && original != corrected
    }
    
    /// Check if correction represents a position pattern
    private func isPositionPattern(_ original: String, _ corrected: String) -> Bool {
        // Check if correction involves repositioning of text
        let originalWords = Set(original.components(separatedBy: .whitespaces))
        let correctedWords = Set(corrected.components(separatedBy: .whitespaces))
        
        return originalWords.intersection(correctedWords).count > 0 && original != corrected
    }
    
    /// Check if correction represents a context pattern
    private func isContextPattern(_ original: String, _ corrected: String) -> Bool {
        // Context patterns involve understanding surrounding text
        return original.count > 20 || corrected.count > 20
    }
    
    /// Extract regex pattern from correction
    private func extractRegexPattern(_ correction: UserCorrection) -> String {
        // Simplified regex pattern extraction
        let _ = correction.originalValue // Original value not used in this simplified implementation
        let corrected = correction.correctedValue

        // Create a pattern that would match the corrected value
        let escapedCorrected = NSRegularExpression.escapedPattern(for: corrected)
        return "\\b\(escapedCorrected)\\b"
    }

    /// Extract validation rule pattern from correction
    private func extractValidationRulePattern(_ correction: UserCorrection) -> String {
        // For validation rules, use the suggested validation rule if available
        if let suggestedRule = correction.suggestedValidationRule {
            return "\(suggestedRule.ruleType.rawValue)_\(suggestedRule.fieldName)"
        }

        // Otherwise, create a simple validation rule based on the corrected value
        let corrected = correction.correctedValue

        // Create a basic validation rule based on the corrected value pattern
        if corrected.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            // All digits - numeric validation
            return "numeric_only"
        } else if corrected.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
            // All letters - alphabetic validation
            return "alphabetic_only"
        } else {
            // Mixed - alphanumeric validation
            return "alphanumeric"
        }
    }
    
    /// Extract format pattern from correction
    private func extractFormatPattern(_ correction: UserCorrection) -> String {
        let corrected = correction.correctedValue
        
        // Extract format by replacing digits with placeholders
        var format = corrected
        format = format.replacingOccurrences(of: "\\d+", with: "{number}", options: .regularExpression)
        format = format.replacingOccurrences(of: "[A-Za-z]+", with: "{text}", options: .regularExpression)
        
        return format
    }
    
    /// Extract position pattern from correction
    private func extractPositionPattern(_ correction: UserCorrection) -> String {
        // Simplified position pattern - record the structure
        let corrected = correction.correctedValue
        let words = corrected.components(separatedBy: .whitespaces)
        
        return "position:\(words.count)words"
    }
    
    /// Extract context pattern from correction
    private func extractContextPattern(_ correction: UserCorrection) -> String {
        // Extract key context words
        let corrected = correction.correctedValue
        let words = corrected.components(separatedBy: .whitespaces)
        let keyWords = words.filter { $0.count > 3 } // Focus on longer words
        
        return "context:\(keyWords.joined(separator: "+"))"
    }
    
    /// Check if two strings have similar structure
    private func hasSimilarStructure(_ str1: String, _ str2: String) -> Bool {
        let pattern1 = createStructurePattern(str1)
        let pattern2 = createStructurePattern(str2)
        
        return pattern1 == pattern2
    }
    
    /// Create a structure pattern for a string
    private func createStructurePattern(_ string: String) -> String {
        var pattern = string
        pattern = pattern.replacingOccurrences(of: "\\d", with: "D", options: .regularExpression)
        pattern = pattern.replacingOccurrences(of: "[A-Za-z]", with: "L", options: .regularExpression)
        pattern = pattern.replacingOccurrences(of: "\\s", with: "S", options: .regularExpression)
        
        return pattern
    }
    
    /// Calculate complexity bonus for pattern confidence
    private func calculateComplexityBonus(_ pattern: String) -> Double {
        let complexity = Double(pattern.count) / 20.0 // Longer patterns get slight bonus
        return min(0.2, complexity * 0.1)
    }
    
    /// Get field reliability score
    private func getFieldReliability(_ fieldName: String) -> Double {
        // Some fields are more reliable than others
        let reliableFields = ["name", "id", "date"]
        let unreliableFields = ["amount", "description"]
        
        if reliableFields.contains(fieldName.lowercased()) {
            return 0.1
        } else if unreliableFields.contains(fieldName.lowercased()) {
            return -0.1
        }
        
        return 0.0
    }
    
    /// Analyze value patterns in corrections
    private func analyzeValuePatterns(_ corrections: [UserCorrection], fieldName: String) async throws -> [RecurringPattern] {
        let valueCounts = corrections.reduce(into: [:]) { counts, correction in
            counts[correction.correctedValue, default: 0] += 1
        }
        
        return valueCounts.compactMap { (value, count) in
            guard count >= minimumPatternOccurrences else { return nil }
            
            return RecurringPattern(
                fieldName: fieldName,
                patternType: .value,
                pattern: value,
                occurrences: count,
                confidence: Double(count) / Double(corrections.count),
                examples: corrections.filter { $0.correctedValue == value }.prefix(3).map { $0.originalValue }
            )
        }
    }
    
    /// Analyze format patterns in corrections
    private func analyzeFormatPatterns(_ corrections: [UserCorrection], fieldName: String) async throws -> [RecurringPattern] {
        let formatCounts = corrections.reduce(into: [String: Int]()) { counts, correction in
            let format = extractFormatPattern(correction)
            counts[format, default: 0] += 1
        }
        
        return formatCounts.compactMap { (format, count) -> RecurringPattern? in
            guard count >= minimumPatternOccurrences else { return nil }
            
            return RecurringPattern(
                fieldName: fieldName,
                patternType: .format,
                pattern: format,
                occurrences: count,
                confidence: Double(count) / Double(corrections.count),
                examples: corrections.prefix(3).map { $0.correctedValue }
            )
        }
    }
    
    /// Analyze context patterns in corrections
    private func analyzeContextPatterns(_ corrections: [UserCorrection], fieldName: String) async throws -> [RecurringPattern] {
        // For now, return empty array - context analysis would be more complex
        return []
    }
    
    /// Generate value-based suggestions
    private func generateValueSuggestions(_ corrections: [UserCorrection]) -> [PatternSuggestion] {
        let valueCounts = corrections.reduce(into: [:]) { counts, correction in
            counts[correction.correctedValue, default: 0] += 1
        }
        
        return valueCounts.compactMap { (value, count) in
            guard count >= 2 else { return nil }
            
            return PatternSuggestion(
                type: .autocomplete,
                suggestion: value,
                confidence: Double(count) / Double(corrections.count),
                rationale: "You've corrected to '\(value)' \(count) times"
            )
        }
    }
    
    /// Generate format-based suggestions
    private func generateFormatSuggestions(_ corrections: [UserCorrection]) -> [PatternSuggestion] {
        // Analyze common format patterns
        let formats = corrections.map { extractFormatPattern($0) }
        let formatCounts = formats.reduce(into: [:]) { counts, format in
            counts[format, default: 0] += 1
        }
        
        return formatCounts.compactMap { (format, count) in
            guard count >= 2 else { return nil }
            
            return PatternSuggestion(
                type: .validation,
                suggestion: "Expected format: \(format)",
                confidence: Double(count) / Double(corrections.count),
                rationale: "This format appears in \(count) corrections"
            )
        }
    }
    
    /// Generate validation-based suggestions
    private func generateValidationSuggestions(_ corrections: [UserCorrection]) -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        // Check for common validation rules
        let correctedValues = corrections.map { $0.correctedValue }
        
        // Length validation
        if let avgLength = calculateAverageLength(correctedValues) {
            suggestions.append(PatternSuggestion(
                type: .validation,
                suggestion: "Expected length around \(avgLength) characters",
                confidence: 0.6,
                rationale: "Based on correction patterns"
            ))
        }
        
        // Character type validation
        if let charType = detectCommonCharacterType(correctedValues) {
            suggestions.append(PatternSuggestion(
                type: .validation,
                suggestion: "Expected \(charType) format",
                confidence: 0.7,
                rationale: "All corrections follow this pattern"
            ))
        }
        
        return suggestions
    }
    
    /// Calculate average length of values
    private func calculateAverageLength(_ values: [String]) -> Int? {
        guard !values.isEmpty else { return nil }
        
        let totalLength = values.reduce(0) { $0 + $1.count }
        return totalLength / values.count
    }
    
    /// Detect common character type in values
    private func detectCommonCharacterType(_ values: [String]) -> String? {
        let allNumeric = values.allSatisfy { $0.allSatisfy { $0.isNumber } }
        let allAlpha = values.allSatisfy { $0.allSatisfy { $0.isLetter } }
        let allAlphanumeric = values.allSatisfy { $0.allSatisfy { $0.isLetter || $0.isNumber } }
        
        if allNumeric {
            return "numeric"
        } else if allAlpha {
            return "alphabetic"
        } else if allAlphanumeric {
            return "alphanumeric"
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Recurring pattern identified from corrections
public struct RecurringPattern {
    public let fieldName: String
    public let patternType: PatternType
    public let pattern: String
    public let occurrences: Int
    public let confidence: Double
    public let examples: [String]
}

/// Pattern-based suggestion
public struct PatternSuggestion {
    public let type: SuggestionType
    public let suggestion: String
    public let confidence: Double
    public let rationale: String
    
    public enum SuggestionType {
        case autocomplete
        case validation
        case format
        case replacement
    }
}
