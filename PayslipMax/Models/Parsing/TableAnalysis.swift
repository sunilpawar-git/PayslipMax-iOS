import Foundation
import CoreGraphics

// MARK: - Supporting Types

/// Represents a merged cell in table structure
struct MergedCell {
    let originalElement: PositionalElement
    let startColumn: Int
    let endColumn: Int
    let startRow: Int
    let endRow: Int
    let columnSpan: Int
    let rowSpan: Int
}

/// Extension for table structure analysis methods
extension TableStructure {
    
    /// Gets elements in a specific column
    /// - Parameter columnIndex: 0-based column index
    /// - Returns: Array of elements in that column across all rows
    func elementsInColumn(_ columnIndex: Int) -> [PositionalElement] {
        guard columnIndex >= 0 && columnIndex < columnCount else { return [] }
        
        var columnElements: [PositionalElement] = []
        
        for row in rows {
            let sortedRowElements = row.elements.sorted { $0.bounds.minX < $1.bounds.minX }
            
            if columnIndex < sortedRowElements.count {
                columnElements.append(sortedRowElements[columnIndex])
            }
        }
        
        return columnElements
    }
    
    /// Gets element at specific row and column
    /// - Parameters:
    ///   - rowIndex: 0-based row index
    ///   - columnIndex: 0-based column index
    /// - Returns: Element at that position, or nil if out of bounds
    func elementAt(row rowIndex: Int, column columnIndex: Int) -> PositionalElement? {
        guard rowIndex >= 0 && rowIndex < rowCount else { return nil }
        
        let targetRow = rows[rowIndex]
        let sortedRowElements = targetRow.elements.sorted { $0.bounds.minX < $1.bounds.minX }
        
        guard columnIndex >= 0 && columnIndex < sortedRowElements.count else { return nil }
        
        return sortedRowElements[columnIndex]
    }
    
    /// Finds all element pairs within this table structure
    /// - Returns: Array of element pairs with their relationships
    func findAllElementPairs() -> [ElementPair] {
        var allPairs: [ElementPair] = []
        
        // Get pairs from each row
        for row in rows {
            let rowPairs = row.findElementPairs()
            allPairs.append(contentsOf: rowPairs)
        }
        
        // Add cross-row pairs for column relationships
        for columnIndex in 0..<columnCount {
            let columnElements = elementsInColumn(columnIndex)
            
            for i in 0..<columnElements.count {
                for j in (i + 1)..<columnElements.count {
                    let element1 = columnElements[i]
                    let element2 = columnElements[j]
                    
                    // Create vertical relationship pair
                    let confidence = calculateVerticalPairConfidence(element1: element1, element2: element2)
                    
                    if confidence >= 0.5 {
                        let pair = ElementPair(
                            label: element1,
                            value: element2,
                            confidence: confidence,
                            relationshipType: .adjacentVertical,
                            metadata: [
                                "columnIndex": String(columnIndex),
                                "pairType": "column"
                            ]
                        )
                        allPairs.append(pair)
                    }
                }
            }
        }
        
        return allPairs
    }
    
    /// Extracts financial data from the table structure
    /// - Returns: Dictionary with earnings and deductions categorized
    func extractFinancialData() -> (earnings: [String: Double], deductions: [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        let pairs = findAllElementPairs()
        
        for pair in pairs where pair.isHighConfidence {
            // Try to extract financial amount from value element
            if let amount = extractAmount(from: pair.value.text) {
                let code = cleanCode(pair.label.text)
                
                if isEarningsCode(code) {
                    earnings[code] = amount
                } else if isDeductionCode(code) {
                    deductions[code] = amount
                }
            }
        }
        
        return (earnings: earnings, deductions: deductions)
    }
    
    /// Detects merged cells in the table structure
    /// - Returns: Array of merged cell information
    func detectMergedCells() -> [MergedCell] {
        var mergedCells: [MergedCell] = []
        
        // Look for elements that span multiple columns or rows
        for (rowIndex, row) in rows.enumerated() {
            for (elementIndex, element) in row.elements.enumerated() {
                // Check if this element is wider than typical column width
                let avgColumnWidth = bounds.width / CGFloat(columnCount)
                
                if element.bounds.width > avgColumnWidth * 1.5 {
                    // Potential column-spanning element
                    let columnSpan = max(1, Int(element.bounds.width / avgColumnWidth))
                    
                    let mergedCell = MergedCell(
                        originalElement: element,
                        startColumn: elementIndex,
                        endColumn: elementIndex + columnSpan - 1,
                        startRow: rowIndex,
                        endRow: rowIndex,
                        columnSpan: columnSpan,
                        rowSpan: 1
                    )
                    mergedCells.append(mergedCell)
                }
            }
        }
        
        return mergedCells
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculates confidence for vertical element pairing
    private func calculateVerticalPairConfidence(element1: PositionalElement, element2: PositionalElement) -> Double {
        var confidence: Double = 0.3
        
        // Vertical alignment factor
        if element1.isVerticallyAlignedWith(element2, tolerance: 15) {
            confidence += 0.4
        }
        
        // Distance factor (closer vertically = higher confidence)
        let verticalDistance = abs(element1.center.y - element2.center.y)
        if verticalDistance < 50 {
            confidence += 0.3
        } else if verticalDistance < 100 {
            confidence += 0.2
        }
        
        return min(1.0, confidence)
    }
    
    /// Extracts numeric amount from text
    private func extractAmount(from text: String) -> Double? {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedText)
    }
    
    /// Cleans financial code text
    private func cleanCode(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }
    
    /// Determines if code represents earnings
    private func isEarningsCode(_ code: String) -> Bool {
        let earningsCodes = ["BP", "BPAY", "DA", "MSP", "HRA", "CCA", "TA", "MEDICAL", "UNIFORM", "RH12", "TPTA", "TPTADA"]
        return earningsCodes.contains(code.uppercased())
    }
    
    /// Determines if code represents deductions
    private func isDeductionCode(_ code: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "TDS", "INS", "LOAN", "ADVANCE", "PF", "ESI", "EHCESS"]
        return deductionCodes.contains(code.uppercased())
    }
}
