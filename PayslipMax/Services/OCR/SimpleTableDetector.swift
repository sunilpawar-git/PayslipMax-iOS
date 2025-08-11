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

public struct PCDATableStructure {
    let baseStructure: TableStructure
    let headerRow: TableStructure.TableRow?
    let dataRows: [TableStructure.TableRow]
    let creditColumns: (description: Int, amount: Int)  // Column indices for credit side
    let debitColumns: (description: Int, amount: Int)   // Column indices for debit side
    let isPCDAFormat: Bool
    
    var bounds: CGRect { baseStructure.bounds }
    var columnCount: Int { baseStructure.columns.count }
    var totalRowCount: Int { baseStructure.rows.count }
    var dataRowCount: Int { dataRows.count }
}

public struct TextElement {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat
    let confidence: Float
}

public protocol SimpleTableDetectorProtocol {
    func detectTableStructure(from textElements: [TextElement]) -> TableStructure?
    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure?
}

public class SimpleTableDetector: SimpleTableDetectorProtocol {
    
    private let minimumRowSpacing: CGFloat = 5.0
    private let minimumColumnSpacing: CGFloat = 10.0
    private let alignmentTolerance: CGFloat = 3.0
    private let adverseSpacingToleranceMultiplier: CGFloat = 1.5 // tolerate irregular spacing
    
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
    
    public func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure? {
        guard !textElements.isEmpty else { return nil }
        
        // First detect general table structure
        guard let baseStructure = detectTableStructure(from: textElements) else {
            return nil
        }
        
        // Validate PCDA format characteristics
        guard isPCDATableFormat(baseStructure: baseStructure, textElements: textElements) else {
            return nil
        }
        
        // Identify header and data rows
        let (headerRow, dataRows) = identifyPCDARows(from: baseStructure, textElements: textElements)
        
        // Determine column layout for PCDA 4-column structure
        let columnLayout = determinePCDAColumnLayout(baseStructure: baseStructure)
        
        return PCDATableStructure(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            creditColumns: columnLayout.credit,
            debitColumns: columnLayout.debit,
            isPCDAFormat: true
        )
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
            
            if spacing >= minimumRowSpacing / adverseSpacingToleranceMultiplier {
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
            
            if spacing >= -minimumColumnSpacing * adverseSpacingToleranceMultiplier {
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
    
    // MARK: - PCDA Table Detection Methods
    
    private func isPCDATableFormat(baseStructure: TableStructure, textElements: [TextElement]) -> Bool {
        // PCDA tables should have 4 columns for the 4-column structure
        guard baseStructure.columns.count >= 4 else { return false }
        
        // Check for bilingual headers (Hindi/English)
        let hasbilingualHeaders = detectBilingualHeaders(textElements: textElements)
        
        // Check for PCDA-specific terms
        let hasPCDATerms = detectPCDATerms(textElements: textElements)
        
        // Check for tabulated structure (multiple rows with data)
        let hasTabularStructure = baseStructure.rows.count >= 3  // Header + at least 2 data rows
        
        return hasbilingualHeaders || hasPCDATerms || hasTabularStructure
    }
    
    private func detectBilingualHeaders(textElements: [TextElement]) -> Bool {
        let bilingualPatterns = [
            "विवरण / DESCRIPTION",
            "विवरण/DESCRIPTION", 
            "राशि / AMOUNT",
            "राशि/AMOUNT",
            "DESCRIPTION / विवरण",
            "AMOUNT / राशि"
        ]
        
        let allText = textElements.map { $0.text.uppercased() }.joined(separator: " ")
        
        return bilingualPatterns.contains { pattern in
            allText.contains(pattern.uppercased())
        }
    }
    
    private func detectPCDATerms(textElements: [TextElement]) -> Bool {
        let pcdaTerms = [
            "PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS",
            "DSOPF", "AGIF", "MSP", "MILITARY SERVICE PAY",
            "BASIC PAY", "DA", "DEARNESS ALLOWANCE",
            "TPTALLC", "TRANSPORT ALLOWANCE",
            "INCM TAX", "INCOME TAX",
            "TOTAL CREDIT", "TOTAL DEBIT", "NET REMITTANCE"
        ]
        
        let allText = textElements.map { $0.text.uppercased() }.joined(separator: " ")
        
        let matchCount = pcdaTerms.filter { term in
            allText.contains(term)
        }.count
        
        // Require at least 3 PCDA terms for positive identification
        return matchCount >= 3
    }
    
    private func identifyPCDARows(from baseStructure: TableStructure, textElements: [TextElement]) -> (header: TableStructure.TableRow?, data: [TableStructure.TableRow]) {
        guard !baseStructure.rows.isEmpty else {
            return (nil, [])
        }
        
        // First row is typically the header in PCDA format
        let headerRow = baseStructure.rows.first
        
        // Skip header row and take remaining as data rows
        let dataRows = Array(baseStructure.rows.dropFirst())
        
        // Validate that header row contains typical header text
        let headerRowValid = headerRow.map { row in
            let headerElements = textElements.filter { element in
                element.bounds.intersects(row.bounds)
            }
            let headerText = headerElements.map { $0.text.uppercased() }.joined(separator: " ")
            return headerText.contains("DESCRIPTION") || headerText.contains("AMOUNT") || headerText.contains("विवरण") || headerText.contains("राशि")
        } ?? false
        
        return (headerRowValid ? headerRow : nil, dataRows)
    }
    
    private func determinePCDAColumnLayout(baseStructure: TableStructure) -> (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int)) {
        // PCDA standard layout: Description1 | Amount1 | Description2 | Amount2
        // Credit side: columns 0,1    Debit side: columns 2,3
        
        let columnCount = baseStructure.columns.count
        
        if columnCount >= 4 {
            // Standard 4-column PCDA layout
            return (
                credit: (description: 0, amount: 1),
                debit: (description: 2, amount: 3)
            )
        } else if columnCount == 3 {
            // 3-column variant: Description | CreditAmount | DebitAmount
            return (
                credit: (description: 0, amount: 1),
                debit: (description: 0, amount: 2)
            )
        } else {
            // Fallback for other column counts
            return (
                credit: (description: 0, amount: min(1, columnCount - 1)),
                debit: (description: min(2, columnCount - 1), amount: min(3, columnCount - 1))
            )
        }
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