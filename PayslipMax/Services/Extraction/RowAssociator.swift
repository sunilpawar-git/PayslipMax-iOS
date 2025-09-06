import Foundation
import CoreGraphics

/// Groups elements by approximate Y-position to identify table rows
/// Handles slight vertical misalignments and multi-line cell support
@MainActor
final class RowAssociator: ServiceProtocol {
    
    // MARK: - ServiceProtocol Conformance
    
    /// Whether the service is initialized
    var isInitialized: Bool = true
    
    /// Initializes the service (no async initialization needed)
    func initialize() async throws {
        // No initialization required for row associator
    }
    
    // MARK: - Properties
    
    /// Configuration for row association
    private let configuration: RowAssociationConfiguration
    
    /// Helper for vertical clustering analysis
    private let verticalClusterAnalyzer: VerticalClusterAnalyzer
    
    /// Validation service for row quality and consistency
    private let validationService: RowValidationService
    
    // MARK: - Initialization
    
    /// Initializes the row associator
    /// - Parameter configuration: Configuration for row association (defaults to payslip optimized)
    init(configuration: RowAssociationConfiguration = .payslipDefault) {
        self.configuration = configuration
        self.verticalClusterAnalyzer = VerticalClusterAnalyzer(configuration: configuration)
        self.validationService = RowValidationService(configuration: configuration)
    }
    
    // MARK: - Public Interface
    
    /// Groups elements into table rows based on Y-position analysis
    /// - Parameters:
    ///   - elements: Array of positional elements to group
    ///   - tolerance: Vertical tolerance for grouping (optional)
    /// - Returns: Array of detected table rows
    /// - Throws: RowAssociationError for processing failures
    func associateElementsIntoRows(
        _ elements: [PositionalElement],
        tolerance: CGFloat? = nil
    ) async throws -> [TableRow] {
        
        guard !elements.isEmpty else {
            return []
        }
        
        guard elements.count >= configuration.minimumElementsForRowDetection else {
            // Create single row for minimal element sets
            return [createSingleRow(from: elements)]
        }
        
        let startTime = Date()
        let effectiveTolerance = tolerance ?? configuration.verticalAlignmentTolerance
        
        // Step 1: Analyze vertical distribution patterns
        let verticalAnalysis = try await analyzeVerticalDistribution(elements)
        
        // Step 2: Identify row clusters using Y-position
        let rowClusters = try await identifyRowClusters(
            from: verticalAnalysis,
            tolerance: effectiveTolerance
        )
        
        // Step 3: Refine clusters by handling misalignments
        let refinedClusters = try await refineRowClusters(
            clusters: rowClusters,
            elements: elements
        )
        
        // Step 4: Create table rows with proper ordering
        let tableRows = try await createTableRows(
            from: refinedClusters,
            elements: elements
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("[RowAssociator] Associated \(elements.count) elements into \(tableRows.count) rows in \(String(format: "%.3f", processingTime))s")
        
        return tableRows.sorted { $0.yPosition < $1.yPosition }
    }
    
    /// Detects multi-line cells within table rows
    /// - Parameters:
    ///   - rows: Array of table rows to analyze
    ///   - maxLinesToleranceRatio: Maximum ratio of line height variation (optional)
    /// - Returns: Array of rows with multi-line cells merged
    /// - Throws: RowAssociationError for detection failures
    func detectMultiLineCells(
        in rows: [TableRow],
        maxLinesToleranceRatio: Double? = nil
    ) async throws -> [TableRow] {
        
        return try await validationService.detectMultiLineCells(
            in: rows,
            maxLinesToleranceRatio: maxLinesToleranceRatio
        )
    }
    
    /// Validates row consistency across table structure
    /// - Parameters:
    ///   - rows: Array of table rows to validate
    ///   - expectedColumnCount: Expected number of columns (optional)
    /// - Returns: Validation result with consistency metrics
    /// - Throws: RowAssociationError for validation failures
    func validateRowConsistency(
        rows: [TableRow],
        expectedColumnCount: Int? = nil
    ) async throws -> RowConsistencyValidation {
        
        return try await validationService.validateRowConsistency(
            rows: rows,
            expectedColumnCount: expectedColumnCount
        )
    }
    
    // MARK: - Private Implementation
    
    /// Analyzes vertical distribution of elements
    private func analyzeVerticalDistribution(
        _ elements: [PositionalElement]
    ) async throws -> VerticalDistributionAnalysis {
        
        let yPositions = elements.map { $0.bounds.midY }.sorted()
        let topEdges = elements.map { $0.bounds.minY }
        let bottomEdges = elements.map { $0.bounds.maxY }
        
        // Calculate vertical clustering
        let clusters = try await verticalClusterAnalyzer.identifyVerticalClusters(
            from: yPositions,
            tolerance: configuration.verticalAlignmentTolerance
        )
        
        return VerticalDistributionAnalysis(
            yPositions: yPositions,
            topEdges: topEdges,
            bottomEdges: bottomEdges,
            clusters: clusters,
            elementCount: elements.count
        )
    }
    
    /// Identifies row clusters using Y-position analysis
    private func identifyRowClusters(
        from analysis: VerticalDistributionAnalysis,
        tolerance: CGFloat
    ) async throws -> [RowCluster] {
        
        var clusters: [RowCluster] = []
        
        for verticalCluster in analysis.clusters {
            let clusterY = verticalCluster.centerY
            let clusterTolerance = max(tolerance, verticalCluster.spread * 0.5)
            
            let cluster = RowCluster(
                centerY: clusterY,
                tolerance: clusterTolerance,
                elementIndices: [], // Will be populated later
                confidence: verticalCluster.confidence
            )
            
            clusters.append(cluster)
        }
        
        return clusters.sorted { $0.centerY < $1.centerY }
    }
    
    /// Refines row clusters by handling alignment issues
    private func refineRowClusters(
        clusters: [RowCluster],
        elements: [PositionalElement]
    ) async throws -> [RowCluster] {
        
        var refinedClusters: [RowCluster] = []
        
        for cluster in clusters {
            // Find elements that belong to this cluster
            let clusterElements = elements.enumerated().compactMap { (index, element) -> Int? in
                let yPosition = element.bounds.midY
                let distance = abs(yPosition - cluster.centerY)
                
                return distance <= cluster.tolerance ? index : nil
            }
            
            if clusterElements.count >= configuration.minimumElementsPerRow {
                let refinedCluster = RowCluster(
                    centerY: cluster.centerY,
                    tolerance: cluster.tolerance,
                    elementIndices: clusterElements,
                    confidence: cluster.confidence
                )
                refinedClusters.append(refinedCluster)
            }
        }
        
        return refinedClusters
    }
    
    /// Creates table rows from refined clusters
    private func createTableRows(
        from clusters: [RowCluster],
        elements: [PositionalElement]
    ) async throws -> [TableRow] {
        
        var tableRows: [TableRow] = []
        
        for (rowIndex, cluster) in clusters.enumerated() {
            let rowElements = cluster.elementIndices.map { elements[$0] }
            let sortedElements = rowElements.sorted { $0.bounds.minX < $1.bounds.minX }
            
            let averageY = cluster.centerY
            let _ = rowElements.map { $0.bounds.minY }.min() ?? averageY
            let _ = rowElements.map { $0.bounds.maxY }.max() ?? averageY
            
            let tableRow = TableRow(
                elements: sortedElements,
                rowIndex: rowIndex,
                metadata: [
                    "clusterTolerance": String(describing: cluster.tolerance),
                    "elementCount": String(sortedElements.count),
                    "confidence": String(describing: cluster.confidence)
                ]
            )
            
            tableRows.append(tableRow)
        }
        
        return tableRows
    }
    
    /// Creates a single row from minimal element sets
    private func createSingleRow(from elements: [PositionalElement]) -> TableRow {
        let sortedElements = elements.sorted { $0.bounds.minX < $1.bounds.minX }
        let averageY = elements.map { $0.bounds.midY }.reduce(0, +) / CGFloat(elements.count)
        let _ = elements.map { $0.bounds.minY }.min() ?? averageY
        let _ = elements.map { $0.bounds.maxY }.max() ?? averageY
        
        return TableRow(
            elements: sortedElements,
            rowIndex: 0,
            metadata: [
                "type": "single_row",
                "elementCount": String(elements.count),
                "confidence": "0.5"
            ]
        )
    }
    
}
