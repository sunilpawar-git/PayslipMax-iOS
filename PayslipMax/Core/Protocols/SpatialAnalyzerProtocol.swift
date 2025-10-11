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

/// Represents a spatial relationship score between two elements
struct ElementRelationshipScore: Codable {
    /// Overall relationship score (0.0 to 1.0)
    let score: Double
    /// Type of spatial relationship detected
    let relationshipType: SpatialRelationshipType
    /// Distance between elements in points
    let distance: CGFloat
    /// Confidence in the relationship classification
    let confidence: Double
    /// Additional scoring details
    let scoringDetails: SpatialScoringDetails
    
    init(
        score: Double,
        relationshipType: SpatialRelationshipType,
        distance: CGFloat,
        confidence: Double,
        scoringDetails: SpatialScoringDetails
    ) {
        self.score = min(1.0, max(0.0, score))
        self.relationshipType = relationshipType
        self.distance = distance
        self.confidence = min(1.0, max(0.0, confidence))
        self.scoringDetails = scoringDetails
    }
}

/// Types of spatial relationships between elements
enum SpatialRelationshipType: String, Codable, CaseIterable {
    /// Elements are adjacent horizontally (same row)
    case adjacentHorizontal = "Adjacent Horizontal"
    /// Elements are adjacent vertically (same column)
    case adjacentVertical = "Adjacent Vertical"
    /// Elements are aligned horizontally
    case alignedHorizontal = "Aligned Horizontal"
    /// Elements are aligned vertically
    case alignedVertical = "Aligned Vertical"
    /// Elements are grouped in same section
    case grouped = "Grouped"
    /// Elements are part of same table
    case tabular = "Tabular"
    /// No clear spatial relationship
    case unrelated = "Unrelated"
    
    var description: String {
        return rawValue
    }
}

/// Detailed scoring information for spatial relationships
struct SpatialScoringDetails: Codable {
    /// Horizontal alignment score (0.0 to 1.0)
    let horizontalAlignment: Double
    /// Vertical alignment score (0.0 to 1.0)
    let verticalAlignment: Double
    /// Proximity score based on distance (0.0 to 1.0)
    let proximityScore: Double
    /// Size similarity score (0.0 to 1.0)
    let sizeSimilarity: Double
    /// Font similarity score (0.0 to 1.0)
    let fontSimilarity: Double
    
    init(
        horizontalAlignment: Double,
        verticalAlignment: Double,
        proximityScore: Double,
        sizeSimilarity: Double,
        fontSimilarity: Double
    ) {
        self.horizontalAlignment = min(1.0, max(0.0, horizontalAlignment))
        self.verticalAlignment = min(1.0, max(0.0, verticalAlignment))
        self.proximityScore = min(1.0, max(0.0, proximityScore))
        self.sizeSimilarity = min(1.0, max(0.0, sizeSimilarity))
        self.fontSimilarity = min(1.0, max(0.0, fontSimilarity))
    }
}

/// Result of spatial analysis validation
struct SpatialAnalysisValidationResult: Codable {
    /// Whether the analysis passed quality checks
    let isValid: Bool
    /// Overall quality score (0.0 to 1.0)
    let qualityScore: Double
    /// Number of relationships analyzed
    let relationshipCount: Int
    /// Number of high-confidence relationships
    let highConfidenceCount: Int
    /// Detected issues during analysis
    let issues: [SpatialAnalysisIssue]
    /// Validation timestamp
    let validatedAt: Date
    
    /// High-confidence relationship ratio
    var highConfidenceRatio: Double {
        guard relationshipCount > 0 else { return 0.0 }
        return Double(highConfidenceCount) / Double(relationshipCount)
    }
    
    init(
        isValid: Bool,
        qualityScore: Double,
        relationshipCount: Int,
        highConfidenceCount: Int,
        issues: [SpatialAnalysisIssue] = []
    ) {
        self.isValid = isValid
        self.qualityScore = min(1.0, max(0.0, qualityScore))
        self.relationshipCount = relationshipCount
        self.highConfidenceCount = highConfidenceCount
        self.issues = issues
        self.validatedAt = Date()
    }
}

/// Types of spatial analysis issues that can be detected
enum SpatialAnalysisIssue: String, Codable, CaseIterable {
    /// Too few relationships detected for document complexity
    case lowRelationshipCount = "Low relationship count"
    /// Many relationships have low confidence scores
    case poorConfidence = "Poor confidence scores"
    /// Inconsistent spatial patterns detected
    case inconsistentPatterns = "Inconsistent spatial patterns"
    /// Elements appear to be misaligned
    case alignmentIssues = "Alignment issues detected"
    /// Potential table structure not recognized
    case missedTableStructure = "Missed table structure"
    /// Performance degradation during analysis
    case performanceIssues = "Performance issues"
    
    var description: String {
        return rawValue
    }
}

/// Errors that can occur during spatial analysis
enum SpatialAnalysisError: Error, LocalizedError, Equatable {
    /// Insufficient elements for meaningful analysis
    case insufficientElements(count: Int)
    /// Analysis timeout exceeded
    case timeout
    /// Memory pressure during analysis
    case memoryError
    /// Invalid configuration parameters
    case invalidConfiguration(String)
    /// Element processing failed
    case processingFailed(String)
    /// Unknown error during analysis
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientElements(let count):
            return "Insufficient elements for analysis: \(count) found, minimum 2 required"
        case .timeout:
            return "Spatial analysis timeout exceeded"
        case .memoryError:
            return "Memory error during spatial analysis"
        case .invalidConfiguration(let message):
            return "Invalid spatial analysis configuration: \(message)"
        case .processingFailed(let message):
            return "Spatial analysis processing failed: \(message)"
        case .unknown(let message):
            return "Unknown spatial analysis error: \(message)"
        }
    }
}
