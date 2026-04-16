import Foundation
import CoreGraphics

// MARK: - Enhanced Spatial Methods (Phase 2)

extension TabularDataExtractor {

    /// Extracts table structure using spatial intelligence from positional elements
    @MainActor
    func extractTableStructure(from elements: [PositionalElement]) async throws -> TableStructure {
        guard let analyzer = spatialAnalyzer else {
            return createBasicTableStructure(from: elements)
        }

        let detectedRows = try await analyzer.detectRows(from: elements, tolerance: nil)
        let columnBoundaries = try await analyzer.detectColumnBoundaries(from: elements, minColumnWidth: nil)

        let tableStructure = TableStructure(
            rows: detectedRows,
            columnBoundaries: columnBoundaries,
            bounds: calculateTableBounds(from: elements),
            metadata: [
                "extractionMethod": "spatial",
                "elementCount": String(elements.count),
                "rowCount": String(detectedRows.count),
                "columnCount": String(columnBoundaries.count + 1)
            ]
        )

        let mergedCells = await analyzer.detectMergedCells(in: tableStructure)

        if !mergedCells.isEmpty {
            var enhancedMetadata = tableStructure.metadata
            enhancedMetadata["mergedCellCount"] = String(mergedCells.count)
            enhancedMetadata["hasMergedCells"] = "true"

            return TableStructure(
                rows: tableStructure.rows,
                columnBoundaries: tableStructure.columnBoundaries,
                bounds: tableStructure.bounds,
                metadata: enhancedMetadata
            )
        }

        return tableStructure
    }

    /// Extracts tabular financial data using spatial intelligence
    @MainActor
    func extractTabularDataWithSpatialIntelligence(
        from elements: [PositionalElement],
        into earnings: inout [String: Double],
        and deductions: inout [String: Double]
    ) async throws {
        guard let analyzer = spatialAnalyzer else {
            let combinedText = elements.map { $0.text }.joined(separator: " ")
            extractTabularStructure(from: combinedText, into: &earnings, and: &deductions)
            return
        }

        let elementPairs = try await analyzer.findRelatedElements(elements, tolerance: nil)

        for pair in elementPairs where pair.isHighConfidence {
            if let amount = extractFinancialAmount(from: pair.value.text) {
                let code = cleanFinancialCode(pair.label.text)

                if !shouldExcludeCode(code) {
                    if isEarningsCode(code) {
                        earnings[code] = amount
                    } else if isDeductionCode(code) {
                        deductions[code] = amount
                    }
                }
            }
        }
    }

    // MARK: - Spatial Helper Methods

    /// Creates a basic table structure without spatial analysis
    func createBasicTableStructure(from elements: [PositionalElement]) -> TableStructure {
        let rowGroups = elements.groupedByRows(tolerance: 20)
        var tableRows: [TableRow] = []

        for (index, (_, elementsInRow)) in rowGroups.enumerated() {
            if elementsInRow.count >= 2 {
                let row = TableRow(elements: elementsInRow, rowIndex: index)
                tableRows.append(row)
            }
        }

        return TableStructure(
            rows: tableRows.sorted { $0.yPosition < $1.yPosition },
            columnBoundaries: [],
            bounds: calculateTableBounds(from: elements),
            metadata: ["extractionMethod": "basic"]
        )
    }

    /// Calculates the overall bounds of a table from its elements
    func calculateTableBounds(from elements: [PositionalElement]) -> CGRect {
        guard !elements.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for element in elements {
            minX = min(minX, element.bounds.minX)
            maxX = max(maxX, element.bounds.maxX)
            minY = min(minY, element.bounds.minY)
            maxY = max(maxY, element.bounds.maxY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Extracts a financial amount from text
    func extractFinancialAmount(from text: String) -> Double? {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedText)
    }

    /// Cleans a financial code by removing extra characters
    func cleanFinancialCode(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }
}
