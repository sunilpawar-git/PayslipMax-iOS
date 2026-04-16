import Foundation
import CoreGraphics

// MARK: - Scoring Helper Methods

extension SpatialRelationshipCalculator {

    func calculateAlignment(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> (horizontal: Double, vertical: Double) {
        let horizontalDiff = abs(element1.center.y - element2.center.y)
        let verticalDiff = abs(element1.center.x - element2.center.x)

        let horizontalAlignment = max(0.0, 1.0 - Double(horizontalDiff) / Double(configuration.alignmentTolerance))
        let verticalAlignment = max(0.0, 1.0 - Double(verticalDiff) / Double(configuration.alignmentTolerance))

        return (horizontal: horizontalAlignment, vertical: verticalAlignment)
    }

    func calculateProximityScore(distance: CGFloat) -> Double {
        let maxDistance: CGFloat = 200.0
        return max(0.0, 1.0 - Double(distance) / Double(maxDistance))
    }

    func calculateSizeSimilarity(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> Double {
        let area1 = element1.bounds.width * element1.bounds.height
        let area2 = element2.bounds.width * element2.bounds.height

        let ratio = min(area1, area2) / max(area1, area2)
        return Double(ratio)
    }

    func calculateFontSimilarity(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) -> Double {
        if let fontSize1 = element1.fontSize, let fontSize2 = element2.fontSize {
            let ratio = min(fontSize1, fontSize2) / max(fontSize1, fontSize2)
            return ratio
        }

        if element1.isBold == element2.isBold {
            return 0.8
        }

        return 0.5
    }

    // MARK: - Relationship Type Determination

    func determineRelationshipType(
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

    // MARK: - Confidence Calculation

    func calculateConfidence(
        score: Double,
        relationshipType: SpatialRelationshipType,
        scoringComponents: (proximity: Double, hAlign: Double, vAlign: Double, size: Double, font: Double)
    ) -> Double {
        var confidence = score

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

        if scoringComponents.hAlign < 0.3 && scoringComponents.vAlign < 0.3 && relationshipType != .unrelated {
            confidence *= 0.85
        }

        let highScoreCount = [
            scoringComponents.proximity > 0.7,
            scoringComponents.hAlign > 0.7,
            scoringComponents.vAlign > 0.7,
            scoringComponents.size > 0.7,
            scoringComponents.font > 0.7
        ].filter { $0 }.count

        if highScoreCount >= 3 {
            confidence *= 1.15
        }

        if scoringComponents.proximity < 0.4 && (scoringComponents.hAlign > 0.8 || scoringComponents.vAlign > 0.8) {
            confidence *= 1.1
        }

        return min(1.0, confidence)
    }

    // MARK: - Adaptive Weights

    func adaptWeightsForElements(_ elements: [PositionalElement]) {
        guard elements.count >= 10 else { return }

        let rowGroups = Dictionary(grouping: elements) { element in
            Int(element.center.y / 20.0)
        }

        let averageElementsPerRow = Double(elements.count) / Double(rowGroups.count)
        let isTabular = averageElementsPerRow >= 3.0

        weights = isTabular ? .tabularOptimized : .freeFormOptimized
    }
}
