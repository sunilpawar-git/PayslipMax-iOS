import Foundation
import CoreGraphics

// MARK: - PositionalElement Extensions

extension PositionalElement {
    
    
    /// Checks if this element is horizontally aligned with another element
    /// - Parameters:
    ///   - other: Another positional element
    ///   - tolerance: Vertical tolerance for alignment
    /// - Returns: True if elements are horizontally aligned
    func isHorizontallyAligned(with other: PositionalElement, tolerance: CGFloat = 10.0) -> Bool {
        return abs(center.y - other.center.y) <= tolerance
    }
    
    /// Checks if this element is vertically aligned with another element
    /// - Parameters:
    ///   - other: Another positional element
    ///   - tolerance: Horizontal tolerance for alignment
    /// - Returns: True if elements are vertically aligned
    func isVerticallyAligned(with other: PositionalElement, tolerance: CGFloat = 10.0) -> Bool {
        return abs(center.x - other.center.x) <= tolerance
    }
    
}

// MARK: - Array Extensions for PositionalElement

extension Array where Element == PositionalElement {
    
    /// Groups elements by approximate Y position (rows)
    /// - Parameter tolerance: Vertical tolerance for grouping
    /// - Returns: Dictionary mapping row indices to elements
    func groupedByRows(tolerance: CGFloat = 15.0) -> [Int: [PositionalElement]] {
        guard !isEmpty else { return [:] }
        
        let sortedByY = self.sorted { $0.center.y < $1.center.y }
        var groups: [Int: [PositionalElement]] = [:]
        var currentRowIndex = 0
        var currentRowY = sortedByY[0].center.y
        
        for element in sortedByY {
            if abs(element.center.y - currentRowY) > tolerance {
                currentRowIndex += 1
                currentRowY = element.center.y
            }
            
            if groups[currentRowIndex] == nil {
                groups[currentRowIndex] = []
            }
            groups[currentRowIndex]?.append(element)
        }
        
        return groups
    }
    
    /// Groups elements by approximate X position (columns)
    /// - Parameter tolerance: Horizontal tolerance for grouping
    /// - Returns: Dictionary mapping column indices to elements
    func groupedByColumns(tolerance: CGFloat = 20.0) -> [Int: [PositionalElement]] {
        guard !isEmpty else { return [:] }
        
        let sortedByX = self.sorted { $0.center.x < $1.center.x }
        var groups: [Int: [PositionalElement]] = [:]
        var currentColumnIndex = 0
        var currentColumnX = sortedByX[0].center.x
        
        for element in sortedByX {
            if abs(element.center.x - currentColumnX) > tolerance {
                currentColumnIndex += 1
                currentColumnX = element.center.x
            }
            
            if groups[currentColumnIndex] == nil {
                groups[currentColumnIndex] = []
            }
            groups[currentColumnIndex]?.append(element)
        }
        
        return groups
    }
    
    /// Finds elements that match a specific type
    /// - Parameter type: Element type to filter by
    /// - Returns: Array of matching elements
    func elements(ofType type: ElementType) -> [PositionalElement] {
        return self.filter { $0.type == type }
    }
    
    /// Finds elements containing specific text
    /// - Parameters:
    ///   - text: Text to search for
    ///   - caseSensitive: Whether search should be case sensitive
    /// - Returns: Array of matching elements
    func elements(containing text: String, caseSensitive: Bool = false) -> [PositionalElement] {
        return self.filter { element in
            if caseSensitive {
                return element.text.contains(text)
            } else {
                return element.text.lowercased().contains(text.lowercased())
            }
        }
    }
    
    /// Calculates the bounding box that contains all elements
    /// - Returns: CGRect that encompasses all elements
    func boundingBox() -> CGRect {
        guard !isEmpty else { return .zero }
        
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        
        for element in self {
            minX = Swift.min(minX, element.bounds.minX)
            maxX = Swift.max(maxX, element.bounds.maxX)
            minY = Swift.min(minY, element.bounds.minY)
            maxY = Swift.max(maxY, element.bounds.maxY)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// Filters elements within a specific region
    /// - Parameter region: CGRect defining the region
    /// - Returns: Array of elements within the region
    func elements(in region: CGRect) -> [PositionalElement] {
        return self.filter { element in
            region.intersects(element.bounds)
        }
    }
}
