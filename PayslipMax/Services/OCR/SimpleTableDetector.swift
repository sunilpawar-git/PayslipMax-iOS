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

// PCDATableStructure is declared in `PCDATableDetector.swift`

public struct TextElement {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat
    let confidence: Float
}

protocol SimpleTableDetectorProtocol {
    func detectTableStructure(from textElements: [TextElement]) -> TableStructure?
    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure?
}

public class SimpleTableDetector: SimpleTableDetectorProtocol {
    
    private let minimumRowSpacing: CGFloat = 5.0
    private let minimumColumnSpacing: CGFloat = 10.0
    private let alignmentTolerance: CGFloat = 3.0
    private let adverseSpacingToleranceMultiplier: CGFloat = 1.5 // tolerate irregular spacing
    
    public init() {}
    
    func detectTableStructure(from textElements: [TextElement]) -> TableStructure? {
        guard !textElements.isEmpty else { return nil }
        
        let sortedElements = textElements.sorted { $0.bounds.minY < $1.bounds.minY }
        
        let rows = detectRows(from: sortedElements)
        guard rows.count > 1 else { return nil }
        
        let columns = detectColumns(from: sortedElements, rows: rows)
        guard columns.count > 1 else { return nil }
        
        let bounds = calculateTableBounds(from: sortedElements)
        
        return TableStructure(rows: rows, columns: columns, bounds: bounds)
    }
    
    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure? {
        guard !textElements.isEmpty else { return nil }
        
        // Feature gate: legacy PCDA hardening
        if let flags = ServiceRegistry.shared.resolve(FeatureFlagProtocol.self),
           flags.isEnabled(.pcdaLegacyHardening) == false {
            return nil
        }

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
        
        // Determine column layout using numeric clustering (amount columns) with fallback
        let columnLayout = determinePCDAColumnLayout(baseStructure: baseStructure, textElements: textElements)

        // Compute strict grid bounds (exclude right details panel) and detect details panel bounds
        let (gridBounds, panelBounds) = computePCDABounds(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            columnLayout: columnLayout,
            textElements: textElements
        )
        
        return PCDATableStructure(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            creditColumns: columnLayout.credit,
            debitColumns: columnLayout.debit,
            isPCDAFormat: true,
            pcdaTableBounds: gridBounds,
            detailsPanelBounds: panelBounds
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
            let hasNext = index < sortedPositions.count - 1
            let nextPosition = hasNext ? sortedPositions[index + 1] : (xPosition + maxWidth)
            // Use gap-based width to avoid overlapping columns; fall back to intrinsic width for the last column
            let width: CGFloat = hasNext ? max(1, nextPosition - xPosition - minimumColumnSpacing) : maxWidth
            
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
        
        // Check for tabulated structure (header + at least 1 data row)
        let hasTabularStructure = baseStructure.rows.count >= 2
        
        // Require at least: (bilingual OR PCDA terms) AND 4+ columns
        return (hasbilingualHeaders || hasPCDATerms) && hasTabularStructure
    }
    
    private func detectBilingualHeaders(textElements: [TextElement]) -> Bool {
        // Support bilingual and mixed-script headers for PCDA legacy:
        // "जमा/CREDIT", "नावे/DEBIT", "विवरण/DESCRIPTION", "राशि/AMOUNT"
        let englishTokens = ["DESCRIPTION", "AMOUNT", "CREDIT", "DEBIT", "EARNINGS", "DEDUCTIONS"]
        let hindiTokens = ["विवरण", "राशि", "जमा", "नावे"] // commonly observed in legacy PCDA
        
        let joined = textElements.map { $0.text }.joined(separator: " ")
        let upper = joined.uppercased()
        
        // Check slash-separated or space-separated bilingual patterns
        func containsPair(_ a: String, _ b: String) -> Bool {
            return upper.contains("\(a.uppercased())/\(b)") || upper.contains("\(b)/\(a.uppercased())") ||
                   upper.contains("\(a.uppercased()) \(b)") || upper.contains("\(b) \(a.uppercased())")
        }
        
        // Any combination of Hindi+English tokens indicates bilingual header presence
        for h in hindiTokens {
            for e in englishTokens {
                if containsPair(h, e) { return true }
            }
        }
        
        // Also accept presence of at least one Hindi header token alongside an English header token anywhere on the same top band
        let headerBandY: CGFloat? = textElements.min(by: { $0.bounds.minY < $1.bounds.minY })?.bounds.minY
        if let headerY = headerBandY {
            let headerBand = textElements.filter { abs($0.bounds.minY - headerY) <= alignmentTolerance * 2 }
            let headerTextUpper = headerBand.map { $0.text.uppercased() }.joined(separator: " ")
            let hasHindi = hindiTokens.contains { headerTextUpper.contains($0.uppercased()) }
            let hasEnglish = englishTokens.contains { headerTextUpper.contains($0) }
            return hasHindi && hasEnglish
        }
        
        return false
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
    
    private func determinePCDAColumnLayout(
        baseStructure: TableStructure,
        textElements: [TextElement]
    ) -> (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int)) {
        // Prefer numeric clustering for amount columns, then infer description columns
        if let inferred = inferColumnsByNumericClustering(baseStructure: baseStructure, textElements: textElements) {
            return inferred
        }
        
        // Fallback to positional assumption
        let columnCount = baseStructure.columns.count
        if columnCount >= 4 {
            return (credit: (0, 1), debit: (2, 3))
        } else if columnCount == 3 {
            return (credit: (0, 1), debit: (0, 2))
        } else {
            return (
                credit: (description: 0, amount: min(1, max(1, columnCount - 1))),
                debit: (description: min(2, max(1, columnCount - 1)), amount: min(3, max(1, columnCount - 1)))
            )
        }
    }

    private func inferColumnsByNumericClustering(
        baseStructure: TableStructure,
        textElements: [TextElement]
    ) -> (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int))? {
        // Select numeric-like tokens as candidate amounts
        let numericPattern = try? NSRegularExpression(pattern: "^[\\p{Sc}]?\\s*[0-9,.()]+$", options: [])
        let numericElements = textElements.filter { element in
            guard let regex = numericPattern else { return false }
            let ns = element.text as NSString
            return regex.firstMatch(in: element.text, options: [], range: NSRange(location: 0, length: ns.length)) != nil
        }
        guard numericElements.count >= 2 else { return nil }
        
        // Simple 2-mean clustering on x centers
        let xs = numericElements.map { $0.bounds.midX }
        guard let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return nil }
        var c1 = minX
        var c2 = maxX
        for _ in 0..<5 {
            var left: [CGFloat] = []
            var right: [CGFloat] = []
            for x in xs {
                if abs(x - c1) <= abs(x - c2) { left.append(x) } else { right.append(x) }
            }
            if !left.isEmpty { c1 = left.reduce(0, +) / CGFloat(left.count) }
            if !right.isEmpty { c2 = right.reduce(0, +) / CGFloat(right.count) }
        }
        let amountCenters = [c1, c2].sorted()
        
        // Map centers to nearest base columns
        func nearestColumnIndex(to x: CGFloat) -> Int? {
            let pairs = baseStructure.columns.map { ($0.index, abs($0.xPosition + $0.width/2 - x)) }
            return pairs.min(by: { $0.1 < $1.1 })?.0
        }
        guard let leftAmountCol = nearestColumnIndex(to: amountCenters[0]),
              let rightAmountCol = nearestColumnIndex(to: amountCenters[1]) else { return nil }
        
        // For descriptions, choose immediate columns to the left of each amount column
        let sortedCols = baseStructure.columns.sorted(by: { $0.xPosition < $1.xPosition })
        func descriptionColumn(leftOf amountIdx: Int) -> Int {
            let amountX = baseStructure.columns.first(where: { $0.index == amountIdx })?.xPosition ?? 0
            var candidate: Int = amountIdx
            for col in sortedCols {
                if col.xPosition < amountX { candidate = col.index } else { break }
            }
            return candidate
        }
        let creditDesc = descriptionColumn(leftOf: leftAmountCol)
        let debitDesc = descriptionColumn(leftOf: rightAmountCol)
        
        return (credit: (description: creditDesc, amount: leftAmountCol),
                debit: (description: debitDesc, amount: rightAmountCol))
    }

    private func computePCDABounds(
        baseStructure: TableStructure,
        headerRow: TableStructure.TableRow?,
        dataRows: [TableStructure.TableRow],
        columnLayout: (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int)),
        textElements: [TextElement]
    ) -> (grid: CGRect, panel: CGRect?) {
        // Determine horizontal grid span from leftmost description to rightmost amount
        let cols = baseStructure.columns
        guard let leftDesc = cols.first(where: { $0.index == columnLayout.credit.description }),
              let leftAmt = cols.first(where: { $0.index == columnLayout.credit.amount }),
              let rightDesc = cols.first(where: { $0.index == columnLayout.debit.description }),
              let rightAmt = cols.first(where: { $0.index == columnLayout.debit.amount }) else {
            return (baseStructure.bounds, nil)
        }
        let minX = min(leftDesc.bounds.minX, leftAmt.bounds.minX, rightDesc.bounds.minX, rightAmt.bounds.minX)
        let maxX = max(leftDesc.bounds.maxX, leftAmt.bounds.maxX, rightDesc.bounds.maxX, rightAmt.bounds.maxX)
        
        // Vertical extent from header to last data row
        let topY = headerRow?.bounds.minY ?? baseStructure.rows.first?.bounds.minY ?? baseStructure.bounds.minY
        let bottomY = dataRows.last?.bounds.maxY ?? baseStructure.rows.last?.bounds.maxY ?? baseStructure.bounds.maxY
        let gridBounds = CGRect(x: minX, y: topY, width: maxX - minX, height: max(0, bottomY - topY))
        
        // Detect right details panel: dense text to the right of grid within similar vertical band
        let margin: CGFloat = 6.0
        let panelCandidates = textElements.filter { el in
            let inVerticalBand = el.bounds.maxY >= topY - margin && el.bounds.minY <= bottomY + margin
            return inVerticalBand && el.bounds.minX >= gridBounds.maxX + minimumColumnSpacing
        }
        if panelCandidates.isEmpty { return (gridBounds, nil) }
        let panelMinX = panelCandidates.map { $0.bounds.minX }.min() ?? 0
        let panelMaxX = panelCandidates.map { $0.bounds.maxX }.max() ?? 0
        let panelMinY = panelCandidates.map { $0.bounds.minY }.min() ?? 0
        let panelMaxY = panelCandidates.map { $0.bounds.maxY }.max() ?? 0
        let panelBounds = CGRect(x: panelMinX, y: panelMinY, width: panelMaxX - panelMinX, height: panelMaxY - panelMinY)
        
        // Heuristic: require panel width to be at least 20% of grid width to reduce false positives
        if panelBounds.width >= max(40, gridBounds.width * 0.2) {
            return (gridBounds, panelBounds)
        } else {
            return (gridBounds, nil)
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