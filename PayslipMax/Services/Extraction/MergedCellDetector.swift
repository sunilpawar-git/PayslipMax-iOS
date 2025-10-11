import Foundation
import CoreGraphics

/// Detects merged cells in table structures
/// Identifies cells that span multiple columns or rows through spatial analysis
/// Extracted from SpatialAnalyzer to maintain <300 line constraint
@MainActor
final class MergedCellDetector {

    // MARK: - Configuration

    /// Configuration for merged cell detection
    struct Configuration {
        /// Minimum span ratio to consider a cell as merged (1.5 = 50% larger than average)
        let minimumSpanRatio: CGFloat
        /// Tolerance for horizontal alignment detection
        let horizontalAlignmentTolerance: CGFloat
        /// Tolerance for vertical alignment detection
        let verticalAlignmentTolerance: CGFloat
        /// Minimum confidence for merged cell detection
        let minimumConfidence: Double

        static let payslipDefault = Configuration(
            minimumSpanRatio: 1.5,
            horizontalAlignmentTolerance: 10.0,
            verticalAlignmentTolerance: 10.0,
            minimumConfidence: 0.6
        )
    }

    // MARK: - Properties

    /// Configuration for detection operations
    private let configuration: Configuration

    // MARK: - Initialization

    /// Initializes the merged cell detector with configuration
    /// - Parameter configuration: Detection configuration (defaults to payslip optimized)
    init(configuration: Configuration = .payslipDefault) {
        self.configuration = configuration
    }

    // MARK: - Detection Methods

    /// Detects merged cells from an array of positional elements
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - columnBoundaries: Detected column boundaries for reference
    ///   - tableBounds: Overall bounds of the table
    /// - Returns: Array of detected merged cells with metadata
    func detectMergedCells(
        from elements: [PositionalElement],
        columnBoundaries: [ColumnBoundary],
        tableBounds: CGRect
    ) -> [MergedCellInfo] {
        guard !elements.isEmpty else { return [] }

        var mergedCells: [MergedCellInfo] = []
        let columnCount = columnBoundaries.count + 1
        let avgColumnWidth = columnCount > 0 ? tableBounds.width / CGFloat(columnCount) : tableBounds.width

        // Detect horizontally merged cells (spanning columns)
        let horizontalMerges = detectHorizontallyMergedCells(
            from: elements,
            averageColumnWidth: avgColumnWidth,
            columnBoundaries: columnBoundaries
        )
        mergedCells.append(contentsOf: horizontalMerges)

        // Detect vertically merged cells (spanning rows)
        let verticalMerges = detectVerticallyMergedCells(
            from: elements,
            tableBounds: tableBounds
        )
        mergedCells.append(contentsOf: verticalMerges)

        return mergedCells
    }

    /// Detects merged cells within a table structure
    /// - Parameter tableStructure: The table structure to analyze
    /// - Returns: Array of detected merged cells
    func detectMergedCells(in tableStructure: TableStructure) -> [MergedCellInfo] {
        return detectMergedCells(
            from: tableStructure.allElements,
            columnBoundaries: tableStructure.columnBoundaries,
            tableBounds: tableStructure.bounds
        )
    }

    // MARK: - Private Detection Methods

    /// Detects cells that span multiple columns horizontally
    private func detectHorizontallyMergedCells(
        from elements: [PositionalElement],
        averageColumnWidth: CGFloat,
        columnBoundaries: [ColumnBoundary]
    ) -> [MergedCellInfo] {
        var mergedCells: [MergedCellInfo] = []

        for element in elements {
            let elementWidth = element.bounds.width
            let spanRatio = elementWidth / averageColumnWidth

            // Check if element is significantly wider than average column
            if spanRatio >= configuration.minimumSpanRatio {
                let columnSpan = Int(ceil(spanRatio))
                let (startColumn, endColumn) = MergedCellDetectionHelpers.calculateColumnSpan(
                    element: element,
                    columnBoundaries: columnBoundaries,
                    calculatedSpan: columnSpan
                )

                let confidence = MergedCellDetectionHelpers.calculateMergedCellConfidence(
                    spanRatio: spanRatio,
                    alignment: .horizontal
                )

                if confidence >= configuration.minimumConfidence {
                    let mergedCell = MergedCellInfo(
                        originalElement: element,
                        startColumn: startColumn,
                        endColumn: endColumn,
                        startRow: 0,
                        endRow: 0,
                        columnSpan: columnSpan,
                        rowSpan: 1,
                        confidence: confidence,
                        spanDirection: .horizontal,
                        metadata: [
                            "spanRatio": String(format: "%.2f", spanRatio),
                            "elementWidth": String(format: "%.2f", elementWidth),
                            "avgColumnWidth": String(format: "%.2f", averageColumnWidth)
                        ]
                    )
                    mergedCells.append(mergedCell)
                }
            }
        }

        return mergedCells
    }

    /// Detects cells that span multiple rows vertically
    private func detectVerticallyMergedCells(
        from elements: [PositionalElement],
        tableBounds: CGRect
    ) -> [MergedCellInfo] {
        var mergedCells: [MergedCellInfo] = []

        // Group elements by approximate X position to identify columns
        let columnGroups = MergedCellDetectionHelpers.groupElementsByColumn(
            elements: elements,
            tolerance: configuration.horizontalAlignmentTolerance
        )

        for (_, columnElements) in columnGroups {
            let sortedByY = columnElements.sorted { $0.center.y < $1.center.y }

            // Calculate average vertical spacing between elements
            let avgVerticalSpacing = MergedCellDetectionHelpers.calculateAverageVerticalSpacing(
                elements: sortedByY
            )

            for element in sortedByY {
                let elementHeight = element.bounds.height

                // Check if element is significantly taller than average
                if avgVerticalSpacing > 0 {
                    let spanRatio = elementHeight / avgVerticalSpacing

                    if spanRatio >= configuration.minimumSpanRatio {
                        let rowSpan = Int(ceil(spanRatio))
                        let confidence = MergedCellDetectionHelpers.calculateMergedCellConfidence(
                            spanRatio: spanRatio,
                            alignment: .vertical
                        )

                        if confidence >= configuration.minimumConfidence {
                            let mergedCell = MergedCellInfo(
                                originalElement: element,
                                startColumn: 0,
                                endColumn: 0,
                                startRow: 0,
                                endRow: rowSpan - 1,
                                columnSpan: 1,
                                rowSpan: rowSpan,
                                confidence: confidence,
                                spanDirection: .vertical,
                                metadata: [
                                    "spanRatio": String(format: "%.2f", spanRatio),
                                    "elementHeight": String(format: "%.2f", elementHeight),
                                    "avgVerticalSpacing": String(format: "%.2f", avgVerticalSpacing)
                                ]
                            )
                            mergedCells.append(mergedCell)
                        }
                    }
                }
            }
        }

        return mergedCells
    }
}
