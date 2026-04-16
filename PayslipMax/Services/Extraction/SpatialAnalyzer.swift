import CoreGraphics
import Foundation

/// Default implementation of spatial analysis for positional elements
/// Analyzes geometric relationships between PDF elements to understand document structure
@MainActor
final class SpatialAnalyzer: SpatialAnalyzerProtocol {
    // MARK: - ServiceProtocol Conformance

    /// Whether the service is initialized
    var isInitialized: Bool = true

    /// Initializes the service (no async initialization needed for this service)
    func initialize() async throws {
        // No initialization required for spatial analyzer
    }

    // MARK: - Properties

    /// Configuration for spatial analysis operations
    let configuration: SpatialAnalysisConfiguration

    /// Helper for calculating spatial relationships
    let relationshipCalculator: SpatialRelationshipCalculator

    /// Helper for section classification
    private let sectionClassifier: SpatialSectionClassifier

    /// Helper for merged cell detection
    private let mergedCellDetector: MergedCellDetector

    // MARK: - Initialization

    /// Initializes the spatial analyzer with configuration
    /// - Parameter configuration: Analysis configuration (defaults to payslip optimized)
    init(
        configuration: SpatialAnalysisConfiguration = .payslipDefault,
        mergedCellDetector: MergedCellDetector? = nil
    ) {
        self.configuration = configuration
        self.relationshipCalculator = SpatialRelationshipCalculator(configuration: configuration)
        self.sectionClassifier = SpatialSectionClassifier(configuration: configuration)
        self.mergedCellDetector = mergedCellDetector ?? MergedCellDetector()
    }

    // MARK: - SpatialAnalyzerProtocol Implementation

    /// Finds related elements based on spatial proximity and alignment
    func findRelatedElements(
        _ elements: [PositionalElement],
        tolerance: CGFloat? = nil
    ) async throws -> [ElementPair] {
        try await performFindRelatedElements(elements, tolerance: tolerance)
    }

    /// Detects row structures by grouping elements with similar Y positions
    func detectRows(
        from elements: [PositionalElement],
        tolerance: CGFloat? = nil
    ) async throws -> [TableRow] {
        try await performDetectRows(from: elements, tolerance: tolerance)
    }

    /// Detects column boundaries based on element distribution
    func detectColumnBoundaries(
        from elements: [PositionalElement],
        minColumnWidth: CGFloat? = nil
    ) async throws -> [ColumnBoundary] {
        try await performDetectColumnBoundaries(from: elements, minColumnWidth: minColumnWidth)
    }

    /// Calculates proximity-based relationship scores between elements
    func calculateRelationshipScore(
        between element1: PositionalElement,
        and element2: PositionalElement
    ) async -> ElementRelationshipScore {
        return await relationshipCalculator.calculateRelationshipScore(
            between: element1,
            and: element2
        )
    }

    /// Groups elements into logical sections based on spatial clustering
    func groupIntoSections(
        _ elements: [PositionalElement],
        clusteringDistance: CGFloat? = nil
    ) async throws -> [ElementSection] {
        return try await sectionClassifier.groupIntoSections(elements, clusteringDistance: clusteringDistance)
    }

    /// Validates spatial analysis results for quality assurance
    func validateSpatialResults(_ pairs: [ElementPair]) async -> SpatialAnalysisValidationResult {
        var issues: [SpatialAnalysisIssue] = []
        var qualityScore: Double = 1.0

        let highConfidencePairs = pairs.filter { $0.confidence >= 0.7 }
        let highConfidenceRatio = pairs.isEmpty ? 0.0 : Double(highConfidencePairs.count) / Double(pairs.count)

        // Check for sufficient relationships
        if pairs.count < 3 {
            issues.append(.lowRelationshipCount)
            qualityScore *= 0.7
        }

        // Check confidence levels
        if highConfidenceRatio < 0.5 {
            issues.append(.poorConfidence)
            qualityScore *= 0.8
        }

        // Check for alignment consistency
        let alignmentConsistency = relationshipCalculator.calculateAlignmentConsistency(pairs: pairs)
        if alignmentConsistency < 0.6 {
            issues.append(.alignmentIssues)
            qualityScore *= 0.9
        }

        // Check for performance issues (placeholder)
        // In a real implementation, you might track processing time

        return SpatialAnalysisValidationResult(
            isValid: qualityScore >= 0.5,
            qualityScore: qualityScore,
            relationshipCount: pairs.count,
            highConfidenceCount: highConfidencePairs.count,
            issues: issues
        )
    }

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
    ) async -> [MergedCellInfo] {
        return mergedCellDetector.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
    }
    /// Detects merged cells within a complete table structure
    /// - Parameter tableStructure: The table structure to analyze
    /// - Returns: Array of detected merged cells
    func detectMergedCells(in tableStructure: TableStructure) async -> [MergedCellInfo] {
        return mergedCellDetector.detectMergedCells(in: tableStructure)
    }
    // MARK: - Helper Methods

    /// Classifies two elements as label and value based on content and position
    func classifyLabelValue(
        element1: PositionalElement,
        element2: PositionalElement
    ) -> (label: PositionalElement, value: PositionalElement) {
        return SpatialAnalyzerHelpers.classifyLabelValue(element1: element1, element2: element2)
    }

    /// Removes duplicate pairs based on element overlap
    func removeDuplicatePairs(_ pairs: [ElementPair]) -> [ElementPair] {
        return SpatialAnalyzerHelpers.removeDuplicatePairs(pairs)
    }
}
