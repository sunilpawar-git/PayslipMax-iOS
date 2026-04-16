import CoreGraphics
import Foundation

// MARK: - Layout Detection Methods

extension SpatialAnalyzer {

    /// Finds related elements based on spatial proximity and alignment
    func performFindRelatedElements(
        _ elements: [PositionalElement],
        tolerance: CGFloat? = nil
    ) async throws -> [ElementPair] {
        guard elements.count >= 2 else {
            throw SpatialAnalysisError.insufficientElements(count: elements.count)
        }

        let startTime = Date()
        let analysisTimeout = configuration.timeoutSeconds

        relationshipCalculator.adaptWeightsForElements(elements)

        var pairs: [ElementPair] = []

        for i in 0..<elements.count {
            for j in (i + 1)..<elements.count {
                if Date().timeIntervalSince(startTime) > analysisTimeout {
                    throw SpatialAnalysisError.timeout
                }

                let element1 = elements[i]
                let element2 = elements[j]

                let relationshipScore = await calculateRelationshipScore(
                    between: element1, and: element2
                )

                if relationshipScore.confidence >= 0.3 {
                    let (label, value) = classifyLabelValue(element1: element1, element2: element2)

                    let pair = ElementPair(
                        label: label,
                        value: value,
                        confidence: relationshipScore.confidence,
                        relationshipType: relationshipScore.relationshipType,
                        metadata: [
                            "distance": String(describing: relationshipScore.distance),
                            "score": String(describing: relationshipScore.score)
                        ]
                    )

                    pairs.append(pair)
                }
            }
        }

        let sortedPairs = pairs.sorted { $0.confidence > $1.confidence }
        return removeDuplicatePairs(sortedPairs)
    }

    /// Detects row structures by grouping elements with similar Y positions
    func performDetectRows(
        from elements: [PositionalElement],
        tolerance: CGFloat? = nil
    ) async throws -> [TableRow] {
        guard !elements.isEmpty else {
            throw SpatialAnalysisError.insufficientElements(count: 0)
        }

        let rowTolerance = tolerance ?? configuration.rowGroupingTolerance

        let rowGroups = Dictionary(grouping: elements) { element in
            Int(element.center.y / rowTolerance) * Int(rowTolerance)
        }

        var tableRows: [TableRow] = []

        for (index, (_, elementsInRow)) in rowGroups.enumerated() {
            if elementsInRow.count >= 2 {
                let tableRow = TableRow(
                    elements: elementsInRow,
                    rowIndex: index,
                    metadata: [
                        "yPosition": String(describing: elementsInRow.first?.center.y ?? 0),
                        "elementCount": String(elementsInRow.count)
                    ]
                )
                tableRows.append(tableRow)
            }
        }

        let sortedRows = tableRows.sorted { $0.yPosition < $1.yPosition }

        var finalRows: [TableRow] = []
        for (index, row) in sortedRows.enumerated() {
            finalRows.append(TableRow(
                elements: row.elements,
                rowIndex: index,
                metadata: row.metadata
            ))
        }

        return finalRows
    }

    /// Detects column boundaries based on element distribution
    func performDetectColumnBoundaries(
        from elements: [PositionalElement],
        minColumnWidth: CGFloat? = nil
    ) async throws -> [ColumnBoundary] {
        guard !elements.isEmpty else {
            throw SpatialAnalysisError.insufficientElements(count: 0)
        }

        let minimumWidth = minColumnWidth ?? configuration.minimumColumnWidth
        let sortedElements = elements.sorted { $0.bounds.minX < $1.bounds.minX }

        var boundaries: [ColumnBoundary] = []
        var previousMaxX: CGFloat = sortedElements.first?.bounds.maxX ?? 0

        for element in sortedElements.dropFirst() {
            let gap = element.bounds.minX - previousMaxX

            if gap >= minimumWidth / 3 {
                let boundaryX = previousMaxX + gap / 2
                let confidence = relationshipCalculator.calculateBoundaryConfidence(
                    gap: gap,
                    minimumWidth: minimumWidth
                )

                boundaries.append(ColumnBoundary(
                    xPosition: boundaryX,
                    confidence: confidence,
                    width: gap,
                    detectionMethod: .statistical,
                    metadata: [
                        "gap": String(describing: gap),
                        "minimumWidth": String(describing: minimumWidth)
                    ]
                ))
            }

            previousMaxX = max(previousMaxX, element.bounds.maxX)
        }

        return boundaries
    }
}
