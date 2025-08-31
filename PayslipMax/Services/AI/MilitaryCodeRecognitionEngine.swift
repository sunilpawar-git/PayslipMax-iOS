import Foundation

/// Engine responsible for recognizing military codes in text elements
public class MilitaryCodeRecognitionEngine {

    // MARK: - Public Methods

    /// Recognize military codes in text elements
    func recognizeCodes(in textElements: [LiteRTTextElement]) async throws -> MilitaryCodeRecognitionResult {
        var recognizedCodes: [MilitaryCode] = []
        var unrecognizedElements: [LiteRTTextElement] = []
        var suggestions: [MilitaryCodeSuggestion] = []

        for element in textElements {
            if let militaryCode = try await recognizeMilitaryCode(in: element) {
                recognizedCodes.append(militaryCode)
            } else {
                unrecognizedElements.append(element)

                // Generate suggestions for unrecognized elements
                if let suggestion = try await generateCodeSuggestion(for: element) {
                    suggestions.append(suggestion)
                }
            }
        }

        let confidence = calculateRecognitionConfidence(
            recognizedCount: recognizedCodes.count,
            totalCount: textElements.count
        )

        return MilitaryCodeRecognitionResult(
            recognizedCodes: recognizedCodes,
            confidence: confidence,
            unrecognizedElements: unrecognizedElements,
            suggestions: suggestions
        )
    }

    /// Expand military code abbreviation
    func expandAbbreviation(_ code: String) async throws -> MilitaryCodeExpansion? {
        let normalizedCode = normalizeCode(code)

        // Direct lookup
        if let expansion = MilitaryCodePatterns.patterns[normalizedCode] {
            return expansion
        }

        // Fuzzy matching for similar codes
        for (pattern, expansion) in MilitaryCodePatterns.patterns {
            if pattern.contains(normalizedCode) || normalizedCode.contains(pattern) {
                return expansion
            }
        }

        return nil
    }

    // MARK: - Private Methods

    /// Recognize military code in a text element
    private func recognizeMilitaryCode(in element: LiteRTTextElement) async throws -> MilitaryCode? {
        let text = element.text.uppercased()

        // Direct pattern matching
        for (pattern, expansion) in MilitaryCodePatterns.patterns {
            if text.contains(pattern) || pattern.contains(text) {
                return MilitaryCode(
                    originalText: element.text,
                    standardizedCode: pattern,
                    category: expansion.category,
                    confidence: 0.9,
                    bounds: element.bounds,
                    expansion: expansion
                )
            }
        }

        // Fuzzy matching for partial matches
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if word.count >= 2 && word.count <= 6 { // Typical military code length
                for (pattern, expansion) in MilitaryCodePatterns.patterns {
                    let similarity = calculateSimilarity(between: word, and: pattern)
                    if similarity > 0.7 {
                        return MilitaryCode(
                            originalText: element.text,
                            standardizedCode: pattern,
                            category: expansion.category,
                            confidence: similarity,
                            bounds: element.bounds,
                            expansion: expansion
                        )
                    }
                }
            }
        }

        return nil
    }

    /// Generate code suggestion for unrecognized element
    private func generateCodeSuggestion(for element: LiteRTTextElement) async throws -> MilitaryCodeSuggestion? {
        let text = element.text.uppercased()

        // Look for partial matches or similar patterns
        for (pattern, _) in MilitaryCodePatterns.patterns {
            let similarity = calculateSimilarity(between: text, and: pattern)
            if similarity > 0.5 {
                return MilitaryCodeSuggestion(
                    originalElement: element,
                    suggestedCode: pattern,
                    confidence: similarity,
                    reason: "Similar to known military code \(pattern)"
                )
            }
        }

        return nil
    }

    /// Normalize military code for consistent processing
    private func normalizeCode(_ code: String) -> String {
        return code.uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    /// Calculate string similarity
    private func calculateSimilarity(between string1: String, and string2: String) -> Double {
        let s1 = string1.uppercased()
        let s2 = string2.uppercased()

        if s1 == s2 { return 1.0 }

        let longer = s1.count > s2.count ? s1 : s2
        let _ = s1.count > s2.count ? s2 : s1

        if longer.count == 0 { return 1.0 }

        let distance = levenshteinDistance(s1, s2)
        return 1.0 - Double(distance) / Double(longer.count)
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)

        if s1.isEmpty { return s2.count }
        if s2.isEmpty { return s1.count }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count { matrix[i][0] = i }
        for j in 0...s2.count { matrix[0][j] = j }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }

        return matrix[s1.count][s2.count]
    }

    /// Calculate recognition confidence
    private func calculateRecognitionConfidence(recognizedCount: Int, totalCount: Int) -> Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(recognizedCount) / Double(totalCount)
    }
}
