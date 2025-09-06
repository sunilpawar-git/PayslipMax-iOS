import Foundation
import CoreGraphics

/// Represents a table row with associated elements
/// Used for organizing elements into structured table format
struct TableRow: Codable, Identifiable, Equatable {
    /// Unique identifier for this table row
    let id: UUID
    /// Array of elements in this row (ordered left to right)
    let elements: [PositionalElement]
    /// Y position representing this row (average of element centers)
    let yPosition: CGFloat
    /// Bounding rectangle encompassing all elements in the row
    let bounds: CGRect
    /// Row index within the table (0-based)
    let rowIndex: Int
    /// Additional metadata for this row
    let metadata: [String: String]
    
    /// Initializes a new table row
    /// - Parameters:
    ///   - elements: Array of elements in this row
    ///   - rowIndex: Row index within the table
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        elements: [PositionalElement],
        rowIndex: Int,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        let sortedElements = elements.sorted { $0.bounds.minX < $1.bounds.minX }
        self.elements = sortedElements
        self.rowIndex = rowIndex
        self.metadata = metadata
        
        // Calculate Y position as average of element centers
        self.yPosition = sortedElements.isEmpty ? 0 : 
            sortedElements.reduce(0) { $0 + $1.center.y } / CGFloat(sortedElements.count)
        
        // Calculate combined bounds
        if sortedElements.isEmpty {
            self.bounds = .zero
        } else {
            var minX = CGFloat.greatestFiniteMagnitude
            var maxX = -CGFloat.greatestFiniteMagnitude
            var minY = CGFloat.greatestFiniteMagnitude
            var maxY = -CGFloat.greatestFiniteMagnitude
            
            for element in sortedElements {
                minX = min(minX, element.bounds.minX)
                maxX = max(maxX, element.bounds.maxX)
                minY = min(minY, element.bounds.minY)
                maxY = max(maxY, element.bounds.maxY)
            }
            
            self.bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Number of elements in this row
    var elementCount: Int {
        return elements.count
    }
    
    /// Whether this row appears to be a table header
    var isLikelyHeader: Bool {
        // Check if most elements are bold or have header-like characteristics
        let boldElements = elements.filter { $0.isBold }
        return boldElements.count >= elements.count / 2
    }
    
    /// Combined text content of all elements in the row
    var combinedText: String {
        return elements.map { $0.text }.joined(separator: " ")
    }
    
    /// Elements grouped by probable columns based on X position
    var elementsByColumn: [Int: PositionalElement] {
        var columnMap: [Int: PositionalElement] = [:]
        
        for (index, element) in elements.enumerated() {
            columnMap[index] = element
        }
        
        return columnMap
    }
    
    // MARK: - Analysis Methods
    
    /// Detects column boundaries within this row
    /// - Parameter minColumnWidth: Minimum width for a valid column
    /// - Returns: Array of column boundary X positions
    func detectColumnBoundaries(minColumnWidth: CGFloat = 50.0) -> [CGFloat] {
        guard elementCount > 1 else { return [] }
        
        var boundaries: [CGFloat] = []
        
        for i in 0..<(elementCount - 1) {
            let currentElement = elements[i]
            let nextElement = elements[i + 1]
            
            let gap = nextElement.bounds.minX - currentElement.bounds.maxX
            
            // If there's a significant gap, it's likely a column boundary
            if gap >= minColumnWidth / 3 {
                boundaries.append(currentElement.bounds.maxX + gap / 2)
            }
        }
        
        return boundaries
    }
    
    /// Finds element pairs within this row
    /// - Returns: Array of element pairs found in this row
    func findElementPairs() -> [ElementPair] {
        var pairs: [ElementPair] = []
        
        for i in 0..<elementCount {
            for j in (i + 1)..<elementCount {
                let element1 = elements[i]
                let element2 = elements[j]
                
                // Determine which is label and which is value
                let (label, value) = classifyLabelValue(element1: element1, element2: element2)
                
                let confidence = calculatePairConfidence(label: label, value: value)
                let relationshipType: SpatialRelationshipType = .adjacentHorizontal
                
                pairs.append(ElementPair(
                    label: label,
                    value: value,
                    confidence: confidence,
                    relationshipType: relationshipType
                ))
            }
        }
        
        return pairs
    }
    
    /// Classifies two elements as label and value
    /// - Parameters:
    ///   - element1: First element
    ///   - element2: Second element
    /// - Returns: Tuple with label and value classification
    private func classifyLabelValue(
        element1: PositionalElement,
        element2: PositionalElement
    ) -> (label: PositionalElement, value: PositionalElement) {
        // Heuristics for classification:
        // 1. Numeric content usually indicates value
        // 2. Left position usually indicates label
        // 3. Bold text often indicates label
        
        let element1IsNumeric = element1.isNumeric
        let element2IsNumeric = element2.isNumeric
        
        if element1IsNumeric && !element2IsNumeric {
            return (label: element2, value: element1)
        } else if element2IsNumeric && !element1IsNumeric {
            return (label: element1, value: element2)
        } else {
            // Use position-based classification (left = label, right = value)
            return element1.bounds.minX < element2.bounds.minX ?
                (label: element1, value: element2) :
                (label: element2, value: element1)
        }
    }
    
    /// Calculates confidence score for element pairing
    /// - Parameters:
    ///   - label: Label element
    ///   - value: Value element
    /// - Returns: Confidence score (0.0 to 1.0)
    private func calculatePairConfidence(label: PositionalElement, value: PositionalElement) -> Double {
        var confidence: Double = 0.5
        
        // Distance factor (closer = higher confidence)
        let distance = label.distanceTo(value)
        if distance < 50 {
            confidence += 0.3
        } else if distance < 100 {
            confidence += 0.2
        } else if distance < 200 {
            confidence += 0.1
        }
        
        // Alignment factor
        if label.isHorizontallyAlignedWith(value, tolerance: 10) {
            confidence += 0.2
        }
        
        // Type classification factor
        if label.type == .label && value.type == .value {
            confidence += 0.2
        }
        
        // Content analysis factor
        if value.isNumeric || value.isCurrency {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: TableRow, rhs: TableRow) -> Bool {
        return lhs.id == rhs.id
    }
}
