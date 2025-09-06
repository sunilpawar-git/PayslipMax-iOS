import Foundation
import CoreGraphics

/// Represents the type of a positional element in a PDF document
/// Used for classification and processing logic
enum ElementType: String, Codable, CaseIterable {
    /// A text label (e.g., "BPAY", "Basic Pay", "Name:")
    case label
    /// A numeric or text value (e.g., "144,700", "John Doe")
    case value
    /// A section header or title (e.g., "EARNINGS", "DEDUCTIONS")
    case header
    /// A cell within a table structure
    case tableCell
    /// A section divider or organizational element
    case section
    /// Unknown or unclassified element
    case unknown
    
    var description: String {
        switch self {
        case .label:
            return "Label"
        case .value:
            return "Value"
        case .header:
            return "Header"
        case .tableCell:
            return "Table Cell"
        case .section:
            return "Section"
        case .unknown:
            return "Unknown"
        }
    }
}

/// Represents a text element with its spatial position and classification
/// This is the foundational model for spatial parsing that preserves
/// geometric relationships between PDF elements
struct PositionalElement: Codable, Identifiable, Equatable {
    /// Unique identifier for this element
    let id: UUID
    /// The text content of this element
    let text: String
    /// The bounding rectangle defining the element's position and size
    let bounds: CGRect
    /// The classified type of this element
    let type: ElementType
    /// Confidence score for the type classification (0.0 to 1.0)
    let confidence: Double
    /// Additional metadata for this element
    let metadata: [String: String]
    /// Font information if available
    let fontSize: Double?
    /// Whether this element is bold text
    let isBold: Bool
    /// Page number this element appears on (0-based)
    let pageIndex: Int
    
    /// Initializes a new positional element
    /// - Parameters:
    ///   - text: The text content
    ///   - bounds: The bounding rectangle
    ///   - type: The element type classification
    ///   - confidence: Classification confidence (defaults to 0.5)
    ///   - metadata: Additional metadata (defaults to empty)
    ///   - fontSize: Font size if available
    ///   - isBold: Whether text is bold (defaults to false)
    ///   - pageIndex: Page number (0-based, defaults to 0)
    init(
        text: String,
        bounds: CGRect,
        type: ElementType,
        confidence: Double = 0.5,
        metadata: [String: String] = [:],
        fontSize: Double? = nil,
        isBold: Bool = false,
        pageIndex: Int = 0
    ) {
        self.id = UUID()
        self.text = text
        self.bounds = bounds
        self.type = type
        self.confidence = min(1.0, max(0.0, confidence)) // Clamp between 0 and 1
        self.metadata = metadata
        self.fontSize = fontSize
        self.isBold = isBold
        self.pageIndex = pageIndex
    }
    
    // MARK: - Convenience Properties
    
    /// The center point of this element
    var center: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// The width of this element
    var width: CGFloat {
        return bounds.width
    }
    
    /// The height of this element
    var height: CGFloat {
        return bounds.height
    }
    
    /// Whether this element appears to be numeric
    var isNumeric: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let numericPattern = #"^[\d,\.\-\+\s]+$"#
        return trimmed.range(of: numericPattern, options: .regularExpression) != nil
    }
    
    /// Whether this element appears to be currency formatted
    var isCurrency: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let currencyPattern = #"^[\₹\$\€\£]?[\d,\.\-\+\s]+[\₹\$\€\£]?$"#
        return trimmed.range(of: currencyPattern, options: .regularExpression) != nil
    }
    
    // MARK: - Spatial Analysis Helpers
    
    /// Calculates the distance to another element's center
    /// - Parameter other: The other element
    /// - Returns: Distance in points
    func distanceTo(_ other: PositionalElement) -> CGFloat {
        let dx = center.x - other.center.x
        let dy = center.y - other.center.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Checks if this element is horizontally aligned with another (same row)
    /// - Parameters:
    ///   - other: The other element
    ///   - tolerance: Vertical tolerance in points (default: 10)
    /// - Returns: True if elements are in the same row
    func isHorizontallyAlignedWith(_ other: PositionalElement, tolerance: CGFloat = 10) -> Bool {
        return abs(center.y - other.center.y) <= tolerance
    }
    
    /// Checks if this element is vertically aligned with another (same column)
    /// - Parameters:
    ///   - other: The other element
    ///   - tolerance: Horizontal tolerance in points (default: 10)
    /// - Returns: True if elements are in the same column
    func isVerticallyAlignedWith(_ other: PositionalElement, tolerance: CGFloat = 10) -> Bool {
        return abs(center.x - other.center.x) <= tolerance
    }
    
    /// Checks if this element is to the right of another element
    /// - Parameter other: The other element
    /// - Returns: True if this element is to the right
    func isRightOf(_ other: PositionalElement) -> Bool {
        return bounds.minX > other.bounds.maxX
    }
    
    /// Checks if this element is below another element
    /// - Parameter other: The other element
    /// - Returns: True if this element is below (higher Y value)
    func isBelow(_ other: PositionalElement) -> Bool {
        return bounds.minY > other.bounds.maxY
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: PositionalElement, rhs: PositionalElement) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Collection Extensions

extension Collection where Element == PositionalElement {
    /// Filters elements by type
    /// - Parameter type: The element type to filter by
    /// - Returns: Array of elements matching the type
    func elementsOfType(_ type: ElementType) -> [PositionalElement] {
        return filter { $0.type == type }
    }
    
    /// Finds elements within a specific bounds rectangle
    /// - Parameter bounds: The bounding rectangle to search within
    /// - Returns: Array of elements within the bounds
    func elementsWithin(_ bounds: CGRect) -> [PositionalElement] {
        return filter { bounds.intersects($0.bounds) }
    }
    
    /// Groups elements by approximate Y position (rows)
    /// - Parameter tolerance: Vertical grouping tolerance in points (default: 20)
    /// - Returns: Dictionary with Y position as key and elements array as value
    func groupedByRows(tolerance: CGFloat = 20) -> [Int: [PositionalElement]] {
        return Dictionary(grouping: self) { element in
            Int(element.center.y / tolerance) * Int(tolerance)
        }
    }
    
    /// Sorts elements by reading order (top to bottom, left to right)
    /// - Returns: Sorted array of elements
    func sortedByReadingOrder() -> [PositionalElement] {
        return sorted { first, second in
            // First sort by Y position (top to bottom)
            if abs(first.center.y - second.center.y) > 10 {
                return first.center.y < second.center.y
            }
            // Then sort by X position (left to right)
            return first.center.x < second.center.x
        }
    }
}
