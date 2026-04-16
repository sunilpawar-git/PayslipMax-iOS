import Foundation
import CoreGraphics

/// Protocol for analyzing spatial relationships between positional elements
/// Provides methods to understand geometric relationships and structure in PDF documents
@MainActor
protocol SpatialAnalyzerProtocol: ServiceProtocol {

    /// Configuration for spatial analysis operations
    var configuration: SpatialAnalysisConfiguration { get }

    /// Finds related elements based on spatial proximity and alignment
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - tolerance: Spatial tolerance for relationship detection (defaults to configuration)
    /// - Returns: Array of element pairs with relationship information
    /// - Throws: SpatialAnalysisError if analysis fails
    func findRelatedElements(
        _ elements: [PositionalElement],
        tolerance: CGFloat?
    ) async throws -> [ElementPair]

    /// Detects row structures by grouping elements with similar Y positions
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - tolerance: Vertical tolerance for row grouping
    /// - Returns: Array of table rows with associated elements
    /// - Throws: SpatialAnalysisError if analysis fails
    func detectRows(
        from elements: [PositionalElement],
        tolerance: CGFloat?
    ) async throws -> [TableRow]

    /// Detects column boundaries based on element distribution
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - minColumnWidth: Minimum width for a valid column
    /// - Returns: Array of column boundary positions
    /// - Throws: SpatialAnalysisError if analysis fails
    func detectColumnBoundaries(
        from elements: [PositionalElement],
        minColumnWidth: CGFloat?
    ) async throws -> [ColumnBoundary]

    /// Calculates proximity-based relationship scores between elements
    /// - Parameters:
    ///   - element1: First element for comparison
    ///   - element2: Second element for comparison
    /// - Returns: Relationship score and type information
    func calculateRelationshipScore(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) async -> ElementRelationshipScore

    /// Groups elements into logical sections based on spatial clustering
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - clusteringDistance: Maximum distance for section grouping
    /// - Returns: Array of element sections
    /// - Throws: SpatialAnalysisError if analysis fails
    func groupIntoSections(
        _ elements: [PositionalElement],
        clusteringDistance: CGFloat?
    ) async throws -> [ElementSection]

    /// Validates spatial analysis results for quality assurance
    /// - Parameter pairs: Array of element pairs to validate
    /// - Returns: Validation result with quality metrics
    func validateSpatialResults(_ pairs: [ElementPair]) async -> SpatialAnalysisValidationResult

    /// Detects merged cells in table structures using advanced spatial analysis
    /// - Parameters:
    ///   - elements: Array of positional elements to analyze
    ///   - columnBoundaries: Detected column boundaries for reference
    ///   - tableBounds: Overall bounds of the table
    /// - Returns: Array of detected merged cells with confidence metadata
    func detectMergedCells(
        from elements: [PositionalElement],
        columnBoundaries: [ColumnBoundary],
        tableBounds: CGRect
    ) async -> [MergedCellInfo]

    /// Detects merged cells within a complete table structure
    /// - Parameter tableStructure: The table structure to analyze
    /// - Returns: Array of detected merged cells
    func detectMergedCells(in tableStructure: TableStructure) async -> [MergedCellInfo]
}

/// Configuration options for spatial analysis operations
struct SpatialAnalysisConfiguration: Codable {
    /// Default tolerance for element alignment detection
    let alignmentTolerance: CGFloat
    /// Default tolerance for row grouping
    let rowGroupingTolerance: CGFloat
    /// Minimum column width for boundary detection
    let minimumColumnWidth: CGFloat
    /// Maximum distance for section clustering
    let sectionClusteringDistance: CGFloat
    /// Timeout for analysis operations in seconds
    let timeoutSeconds: TimeInterval
    /// Whether to enable advanced proximity scoring
    let enableAdvancedScoring: Bool

    /// Default configuration optimized for payslip analysis
    static let payslipDefault = SpatialAnalysisConfiguration(
        alignmentTolerance: 10.0,
        rowGroupingTolerance: 20.0,
        minimumColumnWidth: 50.0,
        sectionClusteringDistance: 40.0,
        timeoutSeconds: 30.0,
        enableAdvancedScoring: true
    )

    /// Fast configuration for preview analysis
    static let fastPreview = SpatialAnalysisConfiguration(
        alignmentTolerance: 15.0,
        rowGroupingTolerance: 25.0,
        minimumColumnWidth: 60.0,
        sectionClusteringDistance: 50.0,
        timeoutSeconds: 10.0,
        enableAdvancedScoring: false
    )
}
