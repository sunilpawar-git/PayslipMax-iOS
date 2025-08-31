import Foundation
import CoreGraphics

public struct TableCell {
    let row: Int
    let column: Int
    let bounds: CGRect
    let textElements: [TextElement]
    let mergedText: String
    
    init(row: Int, column: Int, bounds: CGRect, textElements: [TextElement]) {
        self.row = row
        self.column = column
        self.bounds = bounds
        self.textElements = textElements
        self.mergedText = textElements.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct SpatialTableStructure {
    let cells: [[TableCell?]]
    let rows: [TableStructure.TableRow]
    let columns: [TableStructure.TableColumn]
    let bounds: CGRect
    let headers: [String]?
    
    var rowCount: Int { rows.count }
    var columnCount: Int { columns.count }
    
    func cell(at row: Int, column: Int) -> TableCell? {
        guard row >= 0, row < cells.count,
              column >= 0, column < cells[row].count else {
            return nil
        }
        return cells[row][column]
    }
    
    func cellsInRow(_ rowIndex: Int) -> [TableCell] {
        guard rowIndex >= 0, rowIndex < cells.count else { return [] }
        return cells[rowIndex].compactMap { $0 }
    }
    
    func cellsInColumn(_ columnIndex: Int) -> [TableCell] {
        var columnCells: [TableCell] = []
        for row in cells {
            if columnIndex < row.count, let cell = row[columnIndex] {
                columnCells.append(cell)
            }
        }
        return columnCells
    }
}

struct PCDASpatialTable {
    let spatialStructure: SpatialTableStructure
    let pcdaStructure: PCDATableStructure
    let dataRows: [PCDATableRow]
    
    var creditColumnIndices: (description: Int, amount: Int) {
        return pcdaStructure.creditColumns
    }
    
    var debitColumnIndices: (description: Int, amount: Int) {
        return pcdaStructure.debitColumns
    }
}

public struct PCDATableRow {
    let rowIndex: Int
    let creditDescription: TableCell?
    let creditAmount: TableCell?
    let debitDescription: TableCell?
    let debitAmount: TableCell?
    
    var isValid: Bool {
        return creditDescription != nil || debitDescription != nil
    }
    
    func getCreditData() -> (description: String, amount: Double?)? {
        guard let desc = creditDescription?.mergedText.trimmingCharacters(in: .whitespacesAndNewlines),
              !desc.isEmpty else { return nil }
        
        let amount = creditAmount?.mergedText.extractAmount()
        return (desc, amount)
    }
    
    func getDebitData() -> (description: String, amount: Double?)? {
        guard let desc = debitDescription?.mergedText.trimmingCharacters(in: .whitespacesAndNewlines),
              !desc.isEmpty else { return nil }
        
        let amount = debitAmount?.mergedText.extractAmount()
        return (desc, amount)
    }
}

protocol SpatialTextAnalyzerProtocol {
    func associateTextWithCells(
        textElements: [TextElement],
        tableStructure: TableStructure
    ) -> SpatialTableStructure?
    
    func associateTextWithPCDACells(
        textElements: [TextElement],
        pcdaStructure: PCDATableStructure
    ) -> PCDASpatialTable?
}

public class SpatialTextAnalyzer: SpatialTextAnalyzerProtocol {
    
    private let cellOverlapThreshold: CGFloat = 0.6
    private let textAlignmentTolerance: CGFloat = 5.0
    private let multiLineTolerance: CGFloat = 8.0
    private let headerDetectionThreshold: CGFloat = 0.15
    private let pcdaCellOverlapThreshold: CGFloat = 0.4  // More lenient for PCDA tables
    private let multiLinePCDATolerance: CGFloat = 12.0   // Allow more spacing for military payslips
    private let rotationToleranceDegrees: CGFloat = 10.0 // Handle rotated/skewed scans up to ±10°
    
    public init() {}
    
    public func associateTextWithCells(
        textElements: [TextElement], 
        tableStructure: TableStructure
    ) -> SpatialTableStructure? {
        
        guard !textElements.isEmpty, 
              !tableStructure.rows.isEmpty, 
              !tableStructure.columns.isEmpty else {
            return nil
        }
        
        // Create cell grid
        var cellGrid: [[TableCell?]] = Array(
            repeating: Array(repeating: nil, count: tableStructure.columns.count),
            count: tableStructure.rows.count
        )
        
        // Normalize for slight rotation/skew before grouping
        let normalizedElements = normalizeForRotation(textElements)
        // Group text elements by spatial proximity
        let groupedElements = groupTextElementsByProximity(normalizedElements)
        
        // Associate grouped elements with cells
        for elementGroup in groupedElements {
            if let cellPosition = findBestCellForTextGroup(
                elementGroup, 
                tableStructure: tableStructure
            ) {
                let cellBounds = calculateCellBounds(
                    row: cellPosition.row,
                    column: cellPosition.column,
                    tableStructure: tableStructure
                )
                
                let cell = TableCell(
                    row: cellPosition.row,
                    column: cellPosition.column,
                    bounds: cellBounds,
                    textElements: elementGroup
                )
                
                cellGrid[cellPosition.row][cellPosition.column] = cell
            }
        }
        
        // Detect headers
        let headers = detectHeaders(from: cellGrid, tableStructure: tableStructure)
        
        return SpatialTableStructure(
            cells: cellGrid,
            rows: tableStructure.rows,
            columns: tableStructure.columns,
            bounds: tableStructure.bounds,
            headers: headers
        )
    }
    
    private func groupTextElementsByProximity(_ textElements: [TextElement]) -> [[TextElement]] {
        var groups: [[TextElement]] = []
        var processed = Set<Int>()
        
        for (index, element) in textElements.enumerated() {
            if processed.contains(index) { continue }
            
            var group = [element]
            processed.insert(index)
            
            // Find nearby elements that should be grouped together (iterative approach)
            var foundNewElements = true
            while foundNewElements {
                foundNewElements = false
                
                for (otherIndex, otherElement) in textElements.enumerated() {
                    if processed.contains(otherIndex) { continue }
                    
                    // Check if this element should be grouped with any element in the current group
                    for groupElement in group {
                        if shouldGroupElements(groupElement, otherElement) {
                            group.append(otherElement)
                            processed.insert(otherIndex)
                            foundNewElements = true
                            break
                        }
                    }
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    private func shouldGroupElements(_ element1: TextElement, _ element2: TextElement) -> Bool {
        let bounds1 = element1.bounds
        let bounds2 = element2.bounds
        
        // Check for vertical alignment (same line)
        let verticalOverlap = min(bounds1.maxY, bounds2.maxY) - max(bounds1.minY, bounds2.minY)
        let isOnSameLine = verticalOverlap > max(bounds1.height, bounds2.height) * 0.5
        
        if isOnSameLine {
            // Check horizontal proximity
            let horizontalGap = max(0, min(abs(bounds1.maxX - bounds2.minX), abs(bounds2.maxX - bounds1.minX)))
            return horizontalGap < multiLineTolerance
        }
        
        // Check for multi-line cell content (vertically stacked, similar x-position)
        let horizontalOverlap = min(bounds1.maxX, bounds2.maxX) - max(bounds1.minX, bounds2.minX)
        let hasHorizontalOverlap = horizontalOverlap > max(bounds1.width, bounds2.width) * 0.3
        
        if hasHorizontalOverlap {
            let verticalGap = max(0, min(abs(bounds1.maxY - bounds2.minY), abs(bounds2.maxY - bounds1.minY)))
            return verticalGap < multiLineTolerance
        }
        
        return false
    }

    // MARK: - Rotation/Skew Normalization
    private func normalizeForRotation(_ elements: [TextElement]) -> [TextElement] {
        guard elements.count >= 3 else { return elements }

        // Estimate rotation angle from text baselines: use linear regression over (x, y) of element centers
        let points = elements.map { CGPoint(x: $0.bounds.minX, y: $0.bounds.minY) }
        let angle = estimateSkewAngle(points: points)
        if abs(angle) < degreesToRadians(rotationToleranceDegrees) {
            return rotate(elements, by: -angle)
        }
        return elements
    }

    private func estimateSkewAngle(points: [CGPoint]) -> CGFloat {
        // Simple least squares fit slope; angle = atan(slope)
        let n = CGFloat(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }
        let denominator = (n * sumXX - sumX * sumX)
        guard abs(denominator) > 1e-3 else { return 0 }
        let slope = (n * sumXY - sumX * sumY) / denominator
        return atan(slope)
    }

    private func rotate(_ elements: [TextElement], by angle: CGFloat) -> [TextElement] {
        guard angle != 0 else { return elements }
        let cosA = cos(angle)
        let sinA = sin(angle)
        return elements.map { element in
            let rect = element.bounds
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let rotatedCenter = CGPoint(
                x: center.x * cosA - center.y * sinA,
                y: center.x * sinA + center.y * cosA
            )
            let newRect = CGRect(
                x: rotatedCenter.x - rect.width / 2,
                y: rotatedCenter.y - rect.height / 2,
                width: rect.width,
                height: rect.height
            )
            return TextElement(text: element.text, bounds: newRect, fontSize: element.fontSize, confidence: element.confidence)
        }
    }

    private func degreesToRadians(_ degrees: CGFloat) -> CGFloat { degrees * .pi / 180 }
    
    private func findBestCellForTextGroup(
        _ textGroup: [TextElement],
        tableStructure: TableStructure
    ) -> (row: Int, column: Int)? {
        
        let groupBounds = calculateGroupBounds(textGroup)
        var bestMatch: (row: Int, column: Int, overlap: CGFloat)?
        
        for (rowIndex, _) in tableStructure.rows.enumerated() {
            for (columnIndex, _) in tableStructure.columns.enumerated() {
                let cellBounds = calculateCellBounds(
                    row: rowIndex,
                    column: columnIndex,
                    tableStructure: tableStructure
                )
                
                let overlapArea = calculateOverlapArea(groupBounds, cellBounds)
                let overlapRatio = overlapArea / groupBounds.width / groupBounds.height
                
                if overlapRatio > cellOverlapThreshold {
                    if bestMatch == nil || overlapRatio > bestMatch!.overlap {
                        bestMatch = (rowIndex, columnIndex, overlapRatio)
                    }
                }
            }
        }
        
        if let match = bestMatch {
            return (match.row, match.column)
        }
        
        // Fallback: find closest cell by center distance
        return findClosestCellByCenter(groupBounds, tableStructure: tableStructure)
    }
    
    private func calculateGroupBounds(_ textGroup: [TextElement]) -> CGRect {
        guard !textGroup.isEmpty else { return .zero }
        
        let minX = textGroup.map { $0.bounds.minX }.min() ?? 0
        let minY = textGroup.map { $0.bounds.minY }.min() ?? 0
        let maxX = textGroup.map { $0.bounds.maxX }.max() ?? 0
        let maxY = textGroup.map { $0.bounds.maxY }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func calculateCellBounds(
        row: Int,
        column: Int,
        tableStructure: TableStructure
    ) -> CGRect {
        guard row < tableStructure.rows.count,
              column < tableStructure.columns.count else {
            return .zero
        }
        
        let tableRow = tableStructure.rows[row]
        let tableColumn = tableStructure.columns[column]
        
        return CGRect(
            x: tableColumn.xPosition,
            y: tableRow.yPosition,
            width: tableColumn.width,
            height: tableRow.height
        )
    }
    
    private func calculateOverlapArea(_ rect1: CGRect, _ rect2: CGRect) -> CGFloat {
        let intersection = rect1.intersection(rect2)
        return intersection.isNull ? 0 : intersection.width * intersection.height
    }
    
    private func findClosestCellByCenter(
        _ groupBounds: CGRect,
        tableStructure: TableStructure
    ) -> (row: Int, column: Int)? {
        
        let groupCenter = CGPoint(
            x: groupBounds.midX,
            y: groupBounds.midY
        )
        
        var closestCell: (row: Int, column: Int, distance: CGFloat)?
        
        for (rowIndex, row) in tableStructure.rows.enumerated() {
            for (columnIndex, column) in tableStructure.columns.enumerated() {
                let cellCenter = CGPoint(
                    x: column.xPosition + column.width / 2,
                    y: row.yPosition + row.height / 2
                )
                
                let distance = sqrt(
                    pow(groupCenter.x - cellCenter.x, 2) +
                    pow(groupCenter.y - cellCenter.y, 2)
                )
                
                if closestCell == nil || distance < closestCell!.distance {
                    closestCell = (rowIndex, columnIndex, distance)
                }
            }
        }
        
        return closestCell.map { ($0.row, $0.column) }
    }
    
    private func detectHeaders(
        from cellGrid: [[TableCell?]],
        tableStructure: TableStructure
    ) -> [String]? {
        
        guard !cellGrid.isEmpty else { return nil }
        
        // Check if first row contains headers based on content patterns
        let firstRowCells = cellGrid[0]
        let headerCandidates = firstRowCells.compactMap { $0?.mergedText }
        
        guard !headerCandidates.isEmpty else { return nil }
        
        // Simple header detection based on common patterns
        let headerKeywords = ["credit", "debit", "amount", "description", "date", "particular", "remarks"]
        let matchCount = headerCandidates.reduce(0) { count, text in
            let lowercased = text.lowercased()
            return count + (headerKeywords.contains { lowercased.contains($0) } ? 1 : 0)
        }
        
        let headerMatchRatio = Double(matchCount) / Double(headerCandidates.count)
        
        return headerMatchRatio > headerDetectionThreshold ? headerCandidates : nil
    }
    
    // MARK: - PCDA-Specific Cell Association
    
    func associateTextWithPCDACells(
        textElements: [TextElement],
        pcdaStructure: PCDATableStructure
    ) -> PCDASpatialTable? {
        
        // First create general spatial structure
        guard let spatialStructure = associateTextWithCells(
            textElements: textElements,
            tableStructure: pcdaStructure.baseStructure
        ) else {
            return nil
        }
        
        // Create PCDA-specific row structures
        let pcdaRows = createPCDARows(
            from: spatialStructure,
            pcdaStructure: pcdaStructure
        )
        
        return PCDASpatialTable(
            spatialStructure: spatialStructure,
            pcdaStructure: pcdaStructure,
            dataRows: pcdaRows
        )
    }
    
    private func createPCDARows(
        from spatialStructure: SpatialTableStructure,
        pcdaStructure: PCDATableStructure
    ) -> [PCDATableRow] {
        
        var pcdaRows: [PCDATableRow] = []
        
        // Skip header row and process data rows
        let startIndex = pcdaStructure.headerRow != nil ? 1 : 0
        
        for rowIndex in startIndex..<spatialStructure.rowCount {
            let creditDesc = spatialStructure.cell(
                at: rowIndex,
                column: pcdaStructure.creditColumns.description
            )
            
            let creditAmount = spatialStructure.cell(
                at: rowIndex,
                column: pcdaStructure.creditColumns.amount
            )
            
            let debitDesc = spatialStructure.cell(
                at: rowIndex,
                column: pcdaStructure.debitColumns.description
            )
            
            let debitAmount = spatialStructure.cell(
                at: rowIndex,
                column: pcdaStructure.debitColumns.amount
            )
            
            let pcdaRow = PCDATableRow(
                rowIndex: rowIndex,
                creditDescription: creditDesc,
                creditAmount: creditAmount,
                debitDescription: debitDesc,
                debitAmount: debitAmount
            )
            
            // Only add rows that have some valid data
            if pcdaRow.isValid {
                pcdaRows.append(pcdaRow)
            }
        }
        
        return pcdaRows
    }
}

// MARK: - String Extensions for Amount Extraction

extension String {
    func extractAmount() -> Double? {
        // Remove common formatting and extract numeric value
        let cleaned = self
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use regex to find numeric value
        let regex = try? NSRegularExpression(pattern: "\\d+(?:\\.\\d+)?", options: [])
        let range = NSRange(location: 0, length: cleaned.count)
        
        if let match = regex?.firstMatch(in: cleaned, options: [], range: range) {
            let matchedString = (cleaned as NSString).substring(with: match.range)
            return Double(matchedString)
        }
        
        return nil
    }
}