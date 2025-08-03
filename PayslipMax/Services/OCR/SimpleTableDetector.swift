import Foundation
import CoreGraphics

public struct TableStructure {
    let rows: [TableRow]
    let columns: [TableColumn]
    let bounds: CGRect
    
    struct TableRow {
        let index: Int
        let yPosition: CGFloat
        let height: CGFloat
        let bounds: CGRect
    }
    
    struct TableColumn {
        let index: Int
        let xPosition: CGFloat
        let width: CGFloat
        let bounds: CGRect
    }
}

public struct TextElement {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat
    let confidence: Float
}

public protocol SimpleTableDetectorProtocol {
    func detectTableStructure(from textElements: [TextElement]) -> TableStructure?
}

public class SimpleTableDetector: SimpleTableDetectorProtocol {
    
    private let minimumRowSpacing: CGFloat = 5.0
    private let minimumColumnSpacing: CGFloat = 10.0
    private let alignmentTolerance: CGFloat = 3.0
    
    public init() {}
    
    public func detectTableStructure(from textElements: [TextElement]) -> TableStructure? {
        guard !textElements.isEmpty else { return nil }
        
        let sortedElements = textElements.sorted { $0.bounds.minY < $1.bounds.minY }
        
        let rows = detectRows(from: sortedElements)
        guard rows.count > 1 else { return nil }
        
        let columns = detectColumns(from: sortedElements, rows: rows)
        guard columns.count > 1 else { return nil }
        
        let bounds = calculateTableBounds(from: sortedElements)
        
        return TableStructure(rows: rows, columns: columns, bounds: bounds)
    }
    
    private func detectRows(from textElements: [TextElement]) -> [TableStructure.TableRow] {
        var rows: [TableStructure.TableRow] = []
        var currentRowElements: [TextElement] = []
        var lastYPosition: CGFloat = 0
        var rowIndex = 0
        
        for element in textElements {
            let elementY = element.bounds.minY
            
            if currentRowElements.isEmpty {
                currentRowElements.append(element)
                lastYPosition = elementY
            } else {
                let yDifference = abs(elementY - lastYPosition)
                
                if yDifference <= alignmentTolerance {
                    currentRowElements.append(element)
                } else {
                    if !currentRowElements.isEmpty {
                        let row = createRowFromElements(currentRowElements, index: rowIndex)
                        rows.append(row)
                        rowIndex += 1
                    }
                    
                    currentRowElements = [element]
                    lastYPosition = elementY
                }
            }
        }
        
        if !currentRowElements.isEmpty {
            let row = createRowFromElements(currentRowElements, index: rowIndex)
            rows.append(row)
        }
        
        return filterValidRows(rows)
    }
    
    private func createRowFromElements(_ elements: [TextElement], index: Int) -> TableStructure.TableRow {
        let minY = elements.map { $0.bounds.minY }.min() ?? 0
        let maxY = elements.map { $0.bounds.maxY }.max() ?? 0
        let height = maxY - minY
        
        let minX = elements.map { $0.bounds.minX }.min() ?? 0
        let maxX = elements.map { $0.bounds.maxX }.max() ?? 0
        let width = maxX - minX
        
        let bounds = CGRect(x: minX, y: minY, width: width, height: height)
        
        return TableStructure.TableRow(
            index: index,
            yPosition: minY,
            height: height,
            bounds: bounds
        )
    }
    
    private func filterValidRows(_ rows: [TableStructure.TableRow]) -> [TableStructure.TableRow] {
        guard rows.count > 1 else { return rows }
        
        var validRows: [TableStructure.TableRow] = []
        
        for i in 0..<rows.count {
            let currentRow = rows[i]
            
            if i == 0 {
                validRows.append(currentRow)
                continue
            }
            
            let previousRow = validRows.last!
            let spacing = currentRow.yPosition - previousRow.yPosition
            
            if spacing >= minimumRowSpacing {
                validRows.append(currentRow)
            }
        }
        
        return validRows
    }
    
    private func detectColumns(from textElements: [TextElement], rows: [TableStructure.TableRow]) -> [TableStructure.TableColumn] {
        var columnPositions: Set<CGFloat> = Set()
        
        for element in textElements {
            columnPositions.insert(element.bounds.minX)
        }
        
        let sortedPositions = Array(columnPositions).sorted()
        var columns: [TableStructure.TableColumn] = []
        
        for (index, xPosition) in sortedPositions.enumerated() {
            let elementsInColumn = textElements.filter { 
                abs($0.bounds.minX - xPosition) <= alignmentTolerance
            }
            
            guard !elementsInColumn.isEmpty else { continue }
            
            let minY = elementsInColumn.map { $0.bounds.minY }.min() ?? 0
            let maxY = elementsInColumn.map { $0.bounds.maxY }.max() ?? 0
            let height = maxY - minY
            
            let maxWidth = elementsInColumn.map { $0.bounds.width }.max() ?? 0
            
            let nextPosition = index < sortedPositions.count - 1 ? sortedPositions[index + 1] : xPosition + maxWidth
            let width = max(maxWidth, nextPosition - xPosition - minimumColumnSpacing)
            
            let bounds = CGRect(x: xPosition, y: minY, width: width, height: height)
            
            let column = TableStructure.TableColumn(
                index: index,
                xPosition: xPosition,
                width: width,
                bounds: bounds
            )
            
            columns.append(column)
        }
        
        return filterValidColumns(columns)
    }
    
    private func filterValidColumns(_ columns: [TableStructure.TableColumn]) -> [TableStructure.TableColumn] {
        guard columns.count > 1 else { return columns }
        
        var validColumns: [TableStructure.TableColumn] = []
        
        for i in 0..<columns.count {
            let currentColumn = columns[i]
            
            if i == 0 {
                validColumns.append(currentColumn)
                continue
            }
            
            let previousColumn = validColumns.last!
            let spacing = currentColumn.xPosition - (previousColumn.xPosition + previousColumn.width)
            
            if spacing >= -minimumColumnSpacing {
                validColumns.append(currentColumn)
            }
        }
        
        return validColumns
    }
    
    private func calculateTableBounds(from textElements: [TextElement]) -> CGRect {
        guard !textElements.isEmpty else { return .zero }
        
        let minX = textElements.map { $0.bounds.minX }.min() ?? 0
        let minY = textElements.map { $0.bounds.minY }.min() ?? 0
        let maxX = textElements.map { $0.bounds.maxX }.max() ?? 0
        let maxY = textElements.map { $0.bounds.maxY }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension SimpleTableDetector {
    public func analyzeTableMetrics(structure: TableStructure) -> TableMetrics {
        return TableMetrics(
            rowCount: structure.rows.count,
            columnCount: structure.columns.count,
            averageRowHeight: calculateAverageRowHeight(structure.rows),
            averageColumnWidth: calculateAverageColumnWidth(structure.columns),
            tableArea: structure.bounds.width * structure.bounds.height
        )
    }
    
    private func calculateAverageRowHeight(_ rows: [TableStructure.TableRow]) -> CGFloat {
        guard !rows.isEmpty else { return 0 }
        let totalHeight = rows.reduce(0) { $0 + $1.height }
        return totalHeight / CGFloat(rows.count)
    }
    
    private func calculateAverageColumnWidth(_ columns: [TableStructure.TableColumn]) -> CGFloat {
        guard !columns.isEmpty else { return 0 }
        let totalWidth = columns.reduce(0) { $0 + $1.width }
        return totalWidth / CGFloat(columns.count)
    }
}

public struct TableMetrics {
    let rowCount: Int
    let columnCount: Int
    let averageRowHeight: CGFloat
    let averageColumnWidth: CGFloat
    let tableArea: CGFloat
}