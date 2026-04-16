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

    let configuration: SpatialAnalysisConfiguration
    var weights: ConfidenceWeights

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

        let relationshipType = determineRelationshipType(
            element1: element1,
            element2: element2,
            alignment: alignment
        )

        var score: Double = 0.0
        score += proximity * weights.proximity
        score += alignment.horizontal * weights.horizontalAlignment
        score += alignment.vertical * weights.verticalAlignment
        score += sizeSimilarity * weights.sizeSimilarity
        score += fontSimilarity * weights.fontSimilarity

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

        if element1.isVerticallyAlignedWith(element2, tolerance: 15) {
            confidence += 0.4
        }

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
        return min(1.0, Double(ratio) / 2.0)
    }

    /// Calculates alignment consistency across pairs
    func calculateAlignmentConsistency(pairs: [ElementPair]) -> Double {
        guard !pairs.isEmpty else { return 0.0 }

        let alignedPairs = pairs.filter { pair in
            pair.areHorizontallyAligned || pair.areVerticallyAligned
        }

        return Double(alignedPairs.count) / Double(pairs.count)
    }
}
