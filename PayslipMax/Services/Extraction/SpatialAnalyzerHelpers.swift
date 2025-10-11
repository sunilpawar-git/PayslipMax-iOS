import Foundation
import CoreGraphics

/// Helper methods for SpatialAnalyzer
/// Extracted to maintain <300 line constraint
final class SpatialAnalyzerHelpers {

    // MARK: - Classification Methods

    /// Classifies two elements as label and value based on content and position
    /// - Parameters:
    ///   - element1: First element to classify
    ///   - element2: Second element to classify
    /// - Returns: Tuple with label and value classification
    static func classifyLabelValue(
        element1: PositionalElement,
        element2: PositionalElement
    ) -> (label: PositionalElement, value: PositionalElement) {
        let element1IsNumeric = element1.isNumeric
        let element2IsNumeric = element2.isNumeric

        // Numeric content usually indicates value
        if element1IsNumeric && !element2IsNumeric {
            return (label: element2, value: element1)
        } else if element2IsNumeric && !element1IsNumeric {
            return (label: element1, value: element2)
        }

        // Use position-based classification (left = label, right = value)
        return element1.bounds.minX < element2.bounds.minX ?
            (label: element1, value: element2) :
            (label: element2, value: element1)
    }

    // MARK: - Deduplication Methods

    /// Removes duplicate pairs based on element overlap
    /// - Parameter pairs: Array of element pairs to deduplicate
    /// - Returns: Deduplicated array with unique element pairs
    static func removeDuplicatePairs(_ pairs: [ElementPair]) -> [ElementPair] {
        var deduplicatedPairs: [ElementPair] = []
        var usedElements: Set<UUID> = []

        for pair in pairs {
            if !usedElements.contains(pair.label.id) && !usedElements.contains(pair.value.id) {
                deduplicatedPairs.append(pair)
                usedElements.insert(pair.label.id)
                usedElements.insert(pair.value.id)
            }
        }

        return deduplicatedPairs
    }
}

