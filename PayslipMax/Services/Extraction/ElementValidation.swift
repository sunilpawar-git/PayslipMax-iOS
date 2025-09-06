import Foundation
import CoreGraphics

/// Validation utilities for extracted positional elements
@MainActor
final class ElementValidation {
    
    /// Validates extraction results for quality assurance
    /// - Parameter elements: Array of extracted elements to validate
    /// - Returns: Validation result with quality metrics
    static func validateExtractionResults(_ elements: [PositionalElement]) async -> SpatialExtractionValidationResult {
        let elementCount = elements.count
        let classifiedCount = elements.filter { $0.type != .unknown }.count
        var issues: [SpatialValidationIssue] = []
        
        // Check for low element count
        if elementCount < 5 {
            issues.append(.lowElementCount)
        }
        
        // Check classification accuracy
        let classificationAccuracy = elementCount > 0 ? Double(classifiedCount) / Double(elementCount) : 0.0
        if classificationAccuracy < 0.7 {
            issues.append(.poorClassification)
        }
        
        // Check for overlapping elements
        let overlappingPairs = findOverlappingElements(elements)
        if overlappingPairs.count > elementCount / 20 { // More than 5% overlap
            issues.append(.overlappingElements)
        }
        
        // Check for elements with inconsistent sizing
        if hasInconsistentSizing(elements) {
            issues.append(.inconsistentSizing)
        }
        
        // Calculate quality score
        let qualityScore = calculateQualityScore(
            elementCount: elementCount,
            classificationAccuracy: classificationAccuracy,
            issueCount: issues.count
        )
        
        return SpatialExtractionValidationResult(
            isValid: issues.count < 3 && qualityScore > 0.5,
            qualityScore: qualityScore,
            elementCount: elementCount,
            classifiedCount: classifiedCount,
            issues: issues
        )
    }
    
    /// Finds overlapping elements in the array
    private static func findOverlappingElements(_ elements: [PositionalElement]) -> [(PositionalElement, PositionalElement)] {
        var overlappingPairs: [(PositionalElement, PositionalElement)] = []
        
        for i in 0..<elements.count {
            for j in (i + 1)..<elements.count {
                let first = elements[i]
                let second = elements[j]
                
                if first.bounds.intersects(second.bounds) {
                    overlappingPairs.append((first, second))
                }
            }
        }
        
        return overlappingPairs
    }
    
    /// Checks for inconsistent element sizing patterns
    private static func hasInconsistentSizing(_ elements: [PositionalElement]) -> Bool {
        guard elements.count > 10 else { return false }
        
        let areas = elements.map { $0.bounds.width * $0.bounds.height }
        let avgArea = areas.reduce(0, +) / Double(areas.count)
        let variance = areas.map { Foundation.pow($0 - avgArea, 2) }.reduce(0, +) / Double(areas.count)
        let standardDeviation = sqrt(variance)
        
        // If standard deviation is more than 200% of average, consider it inconsistent
        return standardDeviation > (avgArea * 2.0)
    }
    
    /// Calculates overall quality score for extraction results
    private static func calculateQualityScore(
        elementCount: Int,
        classificationAccuracy: Double,
        issueCount: Int
    ) -> Double {
        var score = 1.0
        
        // Penalize low element count
        if elementCount < 10 {
            score *= 0.7
        }
        
        // Factor in classification accuracy
        score *= classificationAccuracy
        
        // Penalize issues
        score *= max(0.0, 1.0 - (Double(issueCount) * 0.2))
        
        return score
    }
}
