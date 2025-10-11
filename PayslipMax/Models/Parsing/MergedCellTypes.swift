import Foundation
import CoreGraphics

// MARK: - Supporting Types

/// Enhanced merged cell information with confidence and metadata
struct MergedCellInfo: Identifiable, Codable {
    let id: UUID
    let originalElement: PositionalElement
    let startColumn: Int
    let endColumn: Int
    let startRow: Int
    let endRow: Int
    let columnSpan: Int
    let rowSpan: Int
    let confidence: Double
    let spanDirection: SpanDirection
    let metadata: [String: String]

    init(
        originalElement: PositionalElement,
        startColumn: Int,
        endColumn: Int,
        startRow: Int,
        endRow: Int,
        columnSpan: Int,
        rowSpan: Int,
        confidence: Double,
        spanDirection: SpanDirection,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.originalElement = originalElement
        self.startColumn = startColumn
        self.endColumn = endColumn
        self.startRow = startRow
        self.endRow = endRow
        self.columnSpan = columnSpan
        self.rowSpan = rowSpan
        self.confidence = confidence
        self.spanDirection = spanDirection
        self.metadata = metadata
    }

    /// Whether this is a high-confidence merged cell detection
    var isHighConfidence: Bool {
        return confidence >= 0.7
    }

    /// Converts to legacy MergedCell type
    func toLegacyMergedCell() -> MergedCell {
        return MergedCell(
            originalElement: originalElement,
            startColumn: startColumn,
            endColumn: endColumn,
            startRow: startRow,
            endRow: endRow,
            columnSpan: columnSpan,
            rowSpan: rowSpan
        )
    }
}

/// Direction of cell spanning
enum SpanDirection: String, Codable {
    case horizontal = "horizontal"
    case vertical = "vertical"
    case both = "both"
}

// MARK: - Helper Methods

/// Helper methods for merged cell detection calculations
struct MergedCellDetectionHelpers {

    /// Calculates the column span boundaries for a merged cell
    /// - Parameters:
    ///   - element: The element to analyze
    ///   - columnBoundaries: Array of column boundaries
    ///   - calculatedSpan: Calculated span from width ratio
    /// - Returns: Tuple with start and end column indices
    static func calculateColumnSpan(
        element: PositionalElement,
        columnBoundaries: [ColumnBoundary],
        calculatedSpan: Int
    ) -> (startColumn: Int, endColumn: Int) {
        guard !columnBoundaries.isEmpty else {
            return (0, calculatedSpan - 1)
        }

        let elementMinX = element.bounds.minX
        let elementMaxX = element.bounds.maxX

        // Find which columns this element spans
        var startColumn = 0
        var endColumn = calculatedSpan - 1

        for (index, boundary) in columnBoundaries.enumerated() {
            if elementMinX >= boundary.xPosition {
                startColumn = index + 1
            }
            if elementMaxX <= boundary.xPosition {
                endColumn = index
                break
            }
        }

        return (startColumn, endColumn)
    }

    /// Groups elements by their horizontal position (column)
    /// - Parameters:
    ///   - elements: Array of elements to group
    ///   - tolerance: Alignment tolerance for grouping
    /// - Returns: Dictionary with column index as key and elements as value
    static func groupElementsByColumn(
        elements: [PositionalElement],
        tolerance: CGFloat
    ) -> [Int: [PositionalElement]] {
        return Dictionary(grouping: elements) { element in
            Int(element.center.x / tolerance)
        }
    }

    /// Calculates average vertical spacing between elements
    /// - Parameter elements: Array of elements sorted by Y position
    /// - Returns: Average spacing in points
    static func calculateAverageVerticalSpacing(elements: [PositionalElement]) -> CGFloat {
        guard elements.count > 1 else { return 0 }

        var totalSpacing: CGFloat = 0
        var spacingCount = 0

        for i in 0..<(elements.count - 1) {
            let spacing = elements[i + 1].bounds.minY - elements[i].bounds.maxY
            if spacing > 0 {
                totalSpacing += spacing
                spacingCount += 1
            }
        }

        return spacingCount > 0 ? totalSpacing / CGFloat(spacingCount) : 0
    }

    /// Calculates confidence score for merged cell detection
    /// - Parameters:
    ///   - spanRatio: Ratio of element size to average size
    ///   - alignment: Direction of spanning
    /// - Returns: Confidence score (0.0 to 1.0)
    static func calculateMergedCellConfidence(
        spanRatio: CGFloat,
        alignment: SpanDirection
    ) -> Double {
        var confidence: Double = 0.5

        // Higher span ratio = higher confidence
        if spanRatio >= 2.5 {
            confidence += 0.3
        } else if spanRatio >= 2.0 {
            confidence += 0.2
        } else if spanRatio >= 1.5 {
            confidence += 0.1
        }

        // Horizontal merges typically more reliable than vertical
        if alignment == .horizontal {
            confidence += 0.1
        }

        return min(1.0, confidence)
    }
}

