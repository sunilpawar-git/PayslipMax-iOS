import Foundation
import CoreGraphics

/// Configuration for confidence score calculation weights
/// Allows adaptive weighting based on document characteristics
struct ConfidenceWeights: Codable {
    let proximity: Double
    let horizontalAlignment: Double
    let verticalAlignment: Double
    let sizeSimilarity: Double
    let fontSimilarity: Double

    /// Default weights optimized for general payslip parsing
    static let standard = ConfidenceWeights(
        proximity: 0.40,
        horizontalAlignment: 0.20,
        verticalAlignment: 0.10,
        sizeSimilarity: 0.15,
        fontSimilarity: 0.15
    )

    /// Weights optimized for tabular data (higher alignment importance)
    static let tabularOptimized = ConfidenceWeights(
        proximity: 0.30,
        horizontalAlignment: 0.30,
        verticalAlignment: 0.20,
        sizeSimilarity: 0.10,
        fontSimilarity: 0.10
    )

    /// Weights optimized for free-form layouts (higher proximity importance)
    static let freeFormOptimized = ConfidenceWeights(
        proximity: 0.50,
        horizontalAlignment: 0.15,
        verticalAlignment: 0.10,
        sizeSimilarity: 0.15,
        fontSimilarity: 0.10
    )

    /// Validates that weights sum to approximately 1.0
    var isValid: Bool {
        let sum = proximity + horizontalAlignment + verticalAlignment + sizeSimilarity + fontSimilarity
        return abs(sum - 1.0) < 0.01
    }
}

/// Helper class for calculating spatial relationships between elements
/// Extracted from SpatialAnalyzer to maintain 300-line limit compliance
@MainActor
final class SpatialRelationshipCalculator {

    // MARK: - Properties

    private let configuration: SpatialAnalysisConfiguration
    private var weights: ConfidenceWeights

    // MARK: - Initialization

    init(configuration: SpatialAnalysisConfiguration, weights: ConfidenceWeights = .standard) {
        self.configuration = configuration
        self.weights = weights.isValid ? weights : .standard
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

        // Calculate overall score using adaptive weights
        var score: Double = 0.0
        score += proximity * weights.proximity
        score += alignment.horizontal * weights.horizontalAlignment
        score += alignment.vertical * weights.verticalAlignment
        score += sizeSimilarity * weights.sizeSimilarity
        score += fontSimilarity * weights.fontSimilarity

        // Calculate confidence based on relationship type and score
        let confidence = calculateConfidence(
            score: score,
            relationshipType: relationshipType,
            scoringComponents: (proximity, alignment.horizontal, alignment.vertical, sizeSimilarity, fontSimilarity)
        )

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

    /// Calculates confidence score based on analysis results with enhanced edge case handling
    private func calculateConfidence(
        score: Double,
        relationshipType: SpatialRelationshipType,
        scoringComponents: (proximity: Double, hAlign: Double, vAlign: Double, size: Double, font: Double)
    ) -> Double {
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

        // Edge case handling: Penalize ambiguous relationships
        // If alignment scores are very low, reduce confidence even if proximity is good
        if scoringComponents.hAlign < 0.3 && scoringComponents.vAlign < 0.3 && relationshipType != .unrelated {
            confidence *= 0.85 // Poor alignment suggests weak relationship
        }

        // Edge case handling: Boost confidence for strong multi-factor agreement
        // When multiple scoring factors agree, increase confidence
        let highScoreCount = [
            scoringComponents.proximity > 0.7,
            scoringComponents.hAlign > 0.7,
            scoringComponents.vAlign > 0.7,
            scoringComponents.size > 0.7,
            scoringComponents.font > 0.7
        ].filter { $0 }.count

        if highScoreCount >= 3 {
            confidence *= 1.15 // Multiple strong indicators boost confidence
        }

        // Edge case handling: Handle noisy PDFs with irregular spacing
        // If proximity is poor but alignment is excellent, trust alignment
        if scoringComponents.proximity < 0.4 && (scoringComponents.hAlign > 0.8 || scoringComponents.vAlign > 0.8) {
            confidence *= 1.1 // Excellent alignment compensates for distance
        }

        return min(1.0, confidence)
    }

    /// Adapts confidence weights based on detected document characteristics
    /// - Parameter elements: Array of elements to analyze for layout patterns
    func adaptWeightsForElements(_ elements: [PositionalElement]) {
        guard elements.count >= 10 else { return } // Need sufficient data

        // Detect if document is primarily tabular
        let rowGroups = Dictionary(grouping: elements) { element in
            Int(element.center.y / 20.0)
        }

        let averageElementsPerRow = Double(elements.count) / Double(rowGroups.count)
        let isTabular = averageElementsPerRow >= 3.0 // Multiple elements per row suggests table

        // Switch weights based on detected layout
        weights = isTabular ? .tabularOptimized : .freeFormOptimized
    }
}
