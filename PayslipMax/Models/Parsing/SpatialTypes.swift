import Foundation
import CoreGraphics

/// Represents a column boundary detected in table analysis
struct ColumnBoundary: Codable, Identifiable, Equatable {
    /// Unique identifier for this column boundary
    let id: UUID
    /// X position of the boundary
    let xPosition: CGFloat
    /// Confidence score for this boundary (0.0 to 1.0)
    let confidence: Double
    /// Width of the column to the left of this boundary
    let leftColumnWidth: CGFloat?
    /// Width of the column to the right of this boundary
    let rightColumnWidth: CGFloat?
    /// Additional metadata
    let metadata: [String: String]
    
    /// Initializes a new column boundary
    /// - Parameters:
    ///   - xPosition: X position of the boundary
    ///   - confidence: Confidence score
    ///   - leftColumnWidth: Width of left column (optional)
    ///   - rightColumnWidth: Width of right column (optional)
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        xPosition: CGFloat,
        confidence: Double,
        leftColumnWidth: CGFloat? = nil,
        rightColumnWidth: CGFloat? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.xPosition = xPosition
        self.confidence = min(1.0, max(0.0, confidence))
        self.leftColumnWidth = leftColumnWidth
        self.rightColumnWidth = rightColumnWidth
        self.metadata = metadata
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: ColumnBoundary, rhs: ColumnBoundary) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Represents a logical section of elements grouped by spatial clustering
struct ElementSection: Codable, Identifiable, Equatable {
    /// Unique identifier for this section
    let id: UUID
    /// Array of elements in this section
    let elements: [PositionalElement]
    /// Section type (earnings, deductions, header, etc.)
    let sectionType: SectionType
    /// Bounding rectangle encompassing all elements
    let bounds: CGRect
    /// Confidence score for section classification
    let confidence: Double
    /// Additional metadata
    let metadata: [String: String]
    
    /// Initializes a new element section
    /// - Parameters:
    ///   - elements: Array of elements in this section
    ///   - sectionType: Type of section
    ///   - confidence: Confidence score
    ///   - metadata: Additional metadata (defaults to empty)
    init(
        elements: [PositionalElement],
        sectionType: SectionType,
        confidence: Double,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.elements = elements
        self.sectionType = sectionType
        self.confidence = min(1.0, max(0.0, confidence))
        self.metadata = metadata
        
        // Calculate combined bounds
        if elements.isEmpty {
            self.bounds = .zero
        } else {
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
            
            self.bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Number of elements in this section
    var elementCount: Int {
        return elements.count
    }
    
    /// Combined text content of all elements
    var combinedText: String {
        return elements.map { $0.text }.joined(separator: " ")
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: ElementSection, rhs: ElementSection) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Types of document sections that can be detected
enum SectionType: String, Codable, CaseIterable {
    /// Section containing earnings/income information
    case earnings = "Earnings"
    /// Section containing deductions/taxes
    case deductions = "Deductions"
    /// Header section with document title/info
    case header = "Header"
    /// Footer section with totals/signatures
    case footer = "Footer"
    /// Personal information section
    case personalInfo = "Personal Information"
    /// Table section with structured data
    case table = "Table"
    /// Unknown or unclassified section
    case unknown = "Unknown"
    
    var description: String {
        return rawValue
    }
}

/// Represents a merged cell spanning multiple rows or columns
struct MergedCell: Codable, Identifiable, Equatable {
    /// Unique identifier for this merged cell
    let id: UUID
    /// The element representing this merged cell
    let element: PositionalElement
    /// Starting row index (0-based)
    let startRow: Int
    /// Ending row index (0-based, inclusive)
    let endRow: Int
    /// Starting column index (0-based)
    let startColumn: Int
    /// Ending column index (0-based, inclusive)
    let endColumn: Int
    
    /// Initializes a merged cell
    init(
        element: PositionalElement,
        startRow: Int,
        endRow: Int,
        startColumn: Int,
        endColumn: Int
    ) {
        self.id = UUID()
        self.element = element
        self.startRow = startRow
        self.endRow = endRow
        self.startColumn = startColumn
        self.endColumn = endColumn
    }
    
    /// Number of rows spanned
    var rowSpan: Int {
        return endRow - startRow + 1
    }
    
    /// Number of columns spanned
    var columnSpan: Int {
        return endColumn - startColumn + 1
    }
    
    /// Whether this cell spans multiple rows
    var spansMultipleRows: Bool {
        return rowSpan > 1
    }
    
    /// Whether this cell spans multiple columns
    var spansMultipleColumns: Bool {
        return columnSpan > 1
    }
    
    static func == (lhs: MergedCell, rhs: MergedCell) -> Bool {
        return lhs.id == rhs.id
    }
}
