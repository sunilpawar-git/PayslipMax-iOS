import Foundation
import CoreGraphics

/// Helper class for pattern validation and financial data processing
/// Extracted from ContextualPatternMatcher to maintain 300-line compliance
@MainActor
final class PatternValidationHelper {
    
    // MARK: - Pattern Validation Methods
    
    /// Validates a text match using spatial context
    /// - Parameters:
    ///   - textMatch: Text match to validate
    ///   - elementPairs: Available element pairs for spatial analysis
    ///   - elements: All elements in the document
    ///   - validationMode: Validation strictness mode
    /// - Returns: Contextual match with validation results
    static func validateMatch(
        textMatch: TextMatch,
        elementPairs: [ElementPair],
        elements: [PositionalElement],
        validationMode: SpatialValidationMode
    ) async -> ContextualMatch {
        var confidence: Double = 0.5
        var spatialEvidence: [String: Any] = [:]
        var isValid = true
        
        // Find pairs involving this element
        let relatedPairs = elementPairs.filter { pair in
            pair.label.id == textMatch.element.id || pair.value.id == textMatch.element.id
        }
        
        if relatedPairs.isEmpty {
            // No spatial relationships found
            confidence *= 0.6
            spatialEvidence["isolation"] = "No spatial relationships found"
            
            if validationMode == .strict {
                isValid = false
            }
        } else {
            // Evaluate spatial relationships
            let avgPairConfidence = relatedPairs.map { $0.confidence }.reduce(0, +) / Double(relatedPairs.count)
            confidence *= (0.5 + avgPairConfidence * 0.5)
            
            spatialEvidence["pairCount"] = relatedPairs.count
            spatialEvidence["avgPairConfidence"] = avgPairConfidence
            
            // Check for appropriate relationship types
            let appropriateRelationships = relatedPairs.filter { pair in
                pair.relationshipType == .adjacentHorizontal || pair.relationshipType == .adjacentVertical
            }
            
            if appropriateRelationships.count >= relatedPairs.count / 2 {
                confidence *= 1.2
                spatialEvidence["appropriateRelationships"] = true
            }
        }
        
        // Extract structured data from the match
        var extractedData: [String: Any] = [:]
        if textMatch.captureGroups.count >= 2 {
            extractedData["code"] = textMatch.captureGroups[0]
            extractedData["amount"] = textMatch.captureGroups[1]
        }
        
        return ContextualMatch(
            textMatch: textMatch,
            confidence: min(1.0, confidence),
            isValid: isValid,
            spatialEvidence: spatialEvidence,
            extractedData: extractedData,
            validationMode: validationMode
        )
    }
    
    /// Extracts text matches using traditional regex pattern matching
    /// - Parameters:
    ///   - pattern: Regular expression pattern
    ///   - elements: Elements to search within
    /// - Returns: Array of text matches found
    /// - Throws: ContextualMatchingError if pattern is invalid
    static func extractTextMatches(pattern: String, from elements: [PositionalElement]) throws -> [TextMatch] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        var textMatches: [TextMatch] = []
        
        for element in elements {
            let matches = regex.matches(
                in: element.text,
                options: [],
                range: NSRange(location: 0, length: element.text.utf16.count)
            )
            
            for match in matches {
                if let matchRange = Range(match.range, in: element.text) {
                    let matchedText = String(element.text[matchRange])
                    
                    var captureGroups: [String] = []
                    for i in 1..<match.numberOfRanges {
                        if let groupRange = Range(match.range(at: i), in: element.text) {
                            captureGroups.append(String(element.text[groupRange]))
                        }
                    }
                    
                    let textMatch = TextMatch(
                        text: matchedText,
                        captureGroups: captureGroups,
                        element: element,
                        range: matchRange
                    )
                    
                    textMatches.append(textMatch)
                }
            }
        }
        
        return textMatches
    }
    
    /// Calculates overall confidence for a collection of matches
    /// - Parameter matches: Array of contextual matches
    /// - Returns: Overall confidence score (0.0 to 1.0)
    static func calculateOverallConfidence(matches: [ContextualMatch]) -> Double {
        guard !matches.isEmpty else { return 0.0 }
        
        let totalConfidence = matches.map { $0.confidence }.reduce(0, +)
        return totalConfidence / Double(matches.count)
    }
    
    // MARK: - Financial Code Classification
    
    /// Determines if a code represents earnings
    /// - Parameter code: Financial code to classify
    /// - Returns: True if code represents earnings
    static func isEarningsCode(_ code: String) -> Bool {
        let earningsCodes = ["BP", "BPAY", "DA", "MSP", "HRA", "CCA", "TA", "MEDICAL", "UNIFORM", "RH12", "TPTA", "TPTADA"]
        return earningsCodes.contains(code.uppercased())
    }
    
    /// Determines if a code represents deductions
    /// - Parameter code: Financial code to classify
    /// - Returns: True if code represents deductions
    static func isDeductionCode(_ code: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "TDS", "INS", "LOAN", "ADVANCE", "PF", "ESI", "EHCESS"]
        return deductionCodes.contains(code.uppercased())
    }
    
    /// Validates financial code against expected codes list
    /// - Parameters:
    ///   - code: Code to validate
    ///   - expectedCodes: Array of expected codes (empty means accept all)
    /// - Returns: True if code is valid
    static func isValidFinancialCode(_ code: String, expectedCodes: [String]) -> Bool {
        if expectedCodes.isEmpty {
            return true
        }
        return expectedCodes.contains(code.uppercased())
    }
    
    /// Parses financial amount from text string
    /// - Parameter text: Text containing financial amount
    /// - Returns: Parsed amount or nil if parsing fails
    static func parseFinancialAmount(from text: String) -> Double? {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedText)
    }
}

/// Extension for validation result processing
extension Array where Element == ContextualMatch {
    /// Filters matches by confidence threshold
    /// - Parameter threshold: Minimum confidence (0.0 to 1.0)
    /// - Returns: Filtered array of high-confidence matches
    func highConfidence(threshold: Double = 0.7) -> [ContextualMatch] {
        return filter { $0.confidence >= threshold }
    }
    
    /// Groups matches by validation mode
    /// - Returns: Dictionary with validation mode as key
    func groupedByValidationMode() -> [SpatialValidationMode: [ContextualMatch]] {
        return Dictionary(grouping: self) { $0.validationMode }
    }
    
    /// Calculates success rate (valid matches / total matches)
    /// - Returns: Success rate as percentage (0.0 to 1.0)
    func successRate() -> Double {
        guard !isEmpty else { return 0.0 }
        let validMatches = filter { $0.isValid }
        return Double(validMatches.count) / Double(count)
    }
}
