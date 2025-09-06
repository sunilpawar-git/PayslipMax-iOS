import Foundation
import CoreGraphics

/// Helper class for calculating spatial relationships between elements
/// Extracted from SpatialAnalyzer to maintain 300-line limit compliance
@MainActor
final class SpatialRelationshipCalculator {
    
    // MARK: - Properties
    
    private let configuration: SpatialAnalysisConfiguration
    
    // MARK: - Initialization
    
    init(configuration: SpatialAnalysisConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Relationship Calculation Methods
    
    /// Calculates proximity-based relationship scores between elements
    func calculateRelationshipScore(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) async -> ElementRelationshipScore {
        let distance = element1.distanceTo(element2)
        let alignment = calculateAlignment(between: element1, and: element2)
        let proximity = calculateProximityScore(distance: distance)
        let sizeSimilarity = calculateSizeSimilarity(between: element1, and: element2)
        let fontSimilarity = calculateFontSimilarity(between: element1, and: element2)
        
        // Determine relationship type
        let relationshipType = determineRelationshipType(
            element1: element1,
            element2: element2,
            alignment: alignment
        )
        
        // Calculate overall score
        var score: Double = 0.0
        score += proximity * 0.4        // Distance is most important
        score += alignment.horizontal * 0.2  // Horizontal alignment important for rows
        score += alignment.vertical * 0.1    // Vertical alignment for columns
        score += sizeSimilarity * 0.15       // Size consistency
        score += fontSimilarity * 0.15       // Font consistency
        
        // Calculate confidence based on relationship type and score
        let confidence = calculateConfidence(score: score, relationshipType: relationshipType)
        
        let scoringDetails = SpatialScoringDetails(
            horizontalAlignment: alignment.horizontal,
            verticalAlignment: alignment.vertical,
            proximityScore: proximity,
            sizeSimilarity: sizeSimilarity,
            fontSimilarity: fontSimilarity
        )
        
        return ElementRelationshipScore(
            score: score,
            relationshipType: relationshipType,
            distance: distance,
            confidence: confidence,
            scoringDetails: scoringDetails
        )
    }
    
    /// Calculates confidence for vertical element pairing
    func calculateVerticalPairConfidence(element1: PositionalElement, element2: PositionalElement) -> Double {
        var confidence: Double = 0.3
        
        // Vertical alignment factor
        if element1.isVerticallyAlignedWith(element2, tolerance: 15) {
            confidence += 0.4
        }
        
        // Distance factor (closer vertically = higher confidence)
        let verticalDistance = abs(element1.center.y - element2.center.y)
        if verticalDistance < 50 {
            confidence += 0.3
        } else if verticalDistance < 100 {
            confidence += 0.2
        }
        
        return min(1.0, confidence)
    }
    
    /// Calculates boundary confidence based on gap size
    func calculateBoundaryConfidence(gap: CGFloat, minimumWidth: CGFloat) -> Double {
        let ratio = gap / minimumWidth
        return min(1.0, Double(ratio) / 2.0) // Higher gaps get higher confidence
    }
    
    /// Calculates alignment consistency across pairs
    func calculateAlignmentConsistency(pairs: [ElementPair]) -> Double {
        guard !pairs.isEmpty else { return 0.0 }
        
        let alignedPairs = pairs.filter { pair in
            pair.areHorizontallyAligned || pair.areVerticallyAligned
        }
        
        return Double(alignedPairs.count) / Double(pairs.count)
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculates alignment scores between two elements
    private func calculateAlignment(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> (horizontal: Double, vertical: Double) {
        let horizontalDiff = abs(element1.center.y - element2.center.y)
        let verticalDiff = abs(element1.center.x - element2.center.x)
        
        let horizontalAlignment = max(0.0, 1.0 - Double(horizontalDiff) / Double(configuration.alignmentTolerance))
        let verticalAlignment = max(0.0, 1.0 - Double(verticalDiff) / Double(configuration.alignmentTolerance))
        
        return (horizontal: horizontalAlignment, vertical: verticalAlignment)
    }
    
    /// Calculates proximity score based on distance
    private func calculateProximityScore(distance: CGFloat) -> Double {
        // Inverse relationship: closer distance = higher score
        let maxDistance: CGFloat = 200.0
        return max(0.0, 1.0 - Double(distance) / Double(maxDistance))
    }
    
    /// Calculates size similarity between elements
    private func calculateSizeSimilarity(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> Double {
        let area1 = element1.bounds.width * element1.bounds.height
        let area2 = element2.bounds.width * element2.bounds.height
        
        let ratio = min(area1, area2) / max(area1, area2)
        return Double(ratio)
    }
    
    /// Calculates font similarity between elements
    private func calculateFontSimilarity(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> Double {
        // If both have font information, compare sizes
        if let fontSize1 = element1.fontSize, let fontSize2 = element2.fontSize {
            let ratio = min(fontSize1, fontSize2) / max(fontSize1, fontSize2)
            return ratio
        }
        
        // Compare bold status
        if element1.isBold == element2.isBold {
            return 0.8
        }
        
        return 0.5 // Default similarity when no font info available
    }
    
    /// Determines the type of spatial relationship between elements
    private func determineRelationshipType(
        element1: PositionalElement,
        element2: PositionalElement,
        alignment: (horizontal: Double, vertical: Double)
    ) -> SpatialRelationshipType {
        if alignment.horizontal > 0.7 {
            return element1.isRightOf(element2) || element2.isRightOf(element1) ?
                .adjacentHorizontal : .alignedHorizontal
        } else if alignment.vertical > 0.7 {
            return element1.isBelow(element2) || element2.isBelow(element1) ?
                .adjacentVertical : .alignedVertical
        } else {
            return .unrelated
        }
    }
    
    /// Calculates confidence score based on analysis results
    private func calculateConfidence(score: Double, relationshipType: SpatialRelationshipType) -> Double {
        var confidence = score
        
        // Boost confidence for strong relationship types
        switch relationshipType {
        case .adjacentHorizontal, .adjacentVertical:
            confidence *= 1.2
        case .alignedHorizontal, .alignedVertical:
            confidence *= 1.1
        case .tabular:
            confidence *= 1.3
        case .unrelated:
            confidence *= 0.7
        default:
            break
        }
        
        return min(1.0, confidence)
    }
}
