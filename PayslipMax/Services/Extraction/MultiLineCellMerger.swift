import Foundation
import CoreGraphics

/// Helper service for merging multi-line cell content within table rows
/// Extracted component for single responsibility - multi-line text reconstruction
final class MultiLineCellMerger {

    // MARK: - Properties

    /// Vertical cluster analyzer for grouping elements
    private let clusterAnalyzer: VerticalClusterAnalyzer

    // MARK: - Initialization

    /// Initializes the multi-line cell merger
    /// - Parameter clusterAnalyzer: Analyzer for vertical clustering
    init(clusterAnalyzer: VerticalClusterAnalyzer) {
        self.clusterAnalyzer = clusterAnalyzer
    }

    // MARK: - Public Interface

    /// Merges multi-line elements within a row
    /// - Parameters:
    ///   - row: The table row to process
    ///   - toleranceRatio: Maximum ratio of line height variation for merging
    /// - Returns: Processed row with merged multi-line cells
    /// - Throws: MultiLineMergeError for processing failures
    func mergeMultiLineElements(
        in row: TableRow,
        toleranceRatio: Double
    ) async throws -> TableRow {

        guard row.elements.count > 0 else {
            return row
        }

        // Group elements by column (X-position)
        let columnGroups = groupElementsByColumn(row.elements)

        // For each column, identify and merge vertically adjacent elements
        var mergedElements: [PositionalElement] = []

        for (_, elements) in columnGroups.sorted(by: { $0.key < $1.key }) {
            let merged = try await mergeVerticallyAdjacentElements(
                elements,
                toleranceRatio: toleranceRatio
            )
            mergedElements.append(contentsOf: merged)
        }

        // Reconstruct the row with merged elements
        return reconstructRow(from: row, with: mergedElements)
    }

    // MARK: - Private Implementation

    /// Groups elements by their column (X-position)
    private func groupElementsByColumn(_ elements: [PositionalElement]) -> [Int: [PositionalElement]] {
        // Use X-position with tolerance to group into columns
        let columnTolerance: CGFloat = 20.0
        var columnGroups: [Int: [PositionalElement]] = [:]

        for element in elements {
            let columnKey = Int(element.center.x / columnTolerance)
            columnGroups[columnKey, default: []].append(element)
        }

        return columnGroups
    }

    /// Merges vertically adjacent elements in the same column
    private func mergeVerticallyAdjacentElements(
        _ elements: [PositionalElement],
        toleranceRatio: Double
    ) async throws -> [PositionalElement] {

        guard elements.count > 1 else {
            return elements
        }

        // Sort elements by Y-position (top to bottom)
        let sortedElements = elements.sorted { $0.center.y < $1.center.y }

        // Calculate average element height for tolerance
        let averageHeight = sortedElements.map { $0.height }.reduce(0, +) / CGFloat(sortedElements.count)
        let verticalTolerance = averageHeight * CGFloat(toleranceRatio)

        // Group elements into vertical clusters
        var mergedElements: [PositionalElement] = []
        var currentGroup: [PositionalElement] = [sortedElements[0]]

        for i in 1..<sortedElements.count {
            let current = sortedElements[i]
            let previous = sortedElements[i - 1]

            // Check if current element is close enough to be part of same cell
            let verticalGap = current.bounds.minY - previous.bounds.maxY

            if verticalGap <= verticalTolerance {
                // Add to current group
                currentGroup.append(current)
            } else {
                // Finalize current group and start new one
                let merged = mergeElementGroup(currentGroup)
                mergedElements.append(merged)
                currentGroup = [current]
            }
        }

        // Add final group
        if !currentGroup.isEmpty {
            let merged = mergeElementGroup(currentGroup)
            mergedElements.append(merged)
        }

        return mergedElements
    }

    /// Merges a group of elements into a single element
    private func mergeElementGroup(_ elements: [PositionalElement]) -> PositionalElement {
        guard elements.count > 1 else {
            return elements[0]
        }

        // Combine text content with proper spacing
        let combinedText = elements.map { $0.text }.joined(separator: " ")

        // Calculate unified bounding box
        let minX = elements.map { $0.bounds.minX }.min() ?? 0
        let minY = elements.map { $0.bounds.minY }.min() ?? 0
        let maxX = elements.map { $0.bounds.maxX }.max() ?? 0
        let maxY = elements.map { $0.bounds.maxY }.max() ?? 0
        let unifiedBounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        // Use the type and confidence of the first element
        let primaryElement = elements[0]

        // Combine metadata
        var combinedMetadata = primaryElement.metadata
        combinedMetadata["multiLineSource"] = "merged"
        combinedMetadata["elementCount"] = String(elements.count)

        // Average confidence across merged elements
        let averageConfidence = elements.map { $0.confidence }.reduce(0, +) / Double(elements.count)

        return PositionalElement(
            text: combinedText,
            bounds: unifiedBounds,
            type: primaryElement.type,
            confidence: averageConfidence,
            metadata: combinedMetadata,
            fontSize: primaryElement.fontSize,
            isBold: primaryElement.isBold,
            pageIndex: primaryElement.pageIndex
        )
    }

    /// Reconstructs a table row with merged elements
    private func reconstructRow(
        from originalRow: TableRow,
        with mergedElements: [PositionalElement]
    ) -> TableRow {

        // Sort merged elements by reading order
        let sortedElements = mergedElements.sortedByReadingOrder()

        // Update metadata
        var updatedMetadata = originalRow.metadata
        updatedMetadata["multiLineMerged"] = "true"

        // Create new row with merged elements
        // Note: TableRow initializer automatically calculates yPosition and bounds
        return TableRow(
            elements: sortedElements,
            rowIndex: originalRow.rowIndex,
            metadata: updatedMetadata
        )
    }
}

// MARK: - Error Types

/// Errors that can occur during multi-line merging
enum MultiLineMergeError: Error, LocalizedError {
    case invalidRowStructure
    case mergingFailure(String)
    case insufficientElements

    var errorDescription: String? {
        switch self {
        case .invalidRowStructure:
            return "Invalid row structure for multi-line merging"
        case .mergingFailure(let message):
            return "Multi-line merging failed: \(message)"
        case .insufficientElements:
            return "Insufficient elements for multi-line detection"
        }
    }
}

