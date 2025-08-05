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

public protocol SpatialTextAnalyzerProtocol {
    func associateTextWithCells(
        textElements: [TextElement],
        tableStructure: TableStructure
    ) -> SpatialTableStructure?
}

public class SpatialTextAnalyzer: SpatialTextAnalyzerProtocol {
    
    private let cellOverlapThreshold: CGFloat = 0.6
    private let textAlignmentTolerance: CGFloat = 5.0
    private let multiLineTolerance: CGFloat = 8.0
    private let headerDetectionThreshold: CGFloat = 0.15
    
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
        
        // Group text elements by spatial proximity
        let groupedElements = groupTextElementsByProximity(textElements)
        
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
}