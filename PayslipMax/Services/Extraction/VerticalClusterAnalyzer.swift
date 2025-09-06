import Foundation
import CoreGraphics

/// Analyzes vertical clustering patterns for row detection
/// Extracted helper for single responsibility - vertical position analysis
final class VerticalClusterAnalyzer {
    
    // MARK: - Properties
    
    /// Configuration for clustering analysis
    private let configuration: RowAssociationConfiguration
    
    // MARK: - Initialization
    
    /// Initializes the vertical cluster analyzer
    /// - Parameter configuration: Configuration for clustering
    init(configuration: RowAssociationConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Identifies vertical clusters from Y-position data
    /// - Parameters:
    ///   - yPositions: Array of Y positions to cluster
    ///   - tolerance: Clustering tolerance
    /// - Returns: Array of identified vertical clusters
    /// - Throws: ClusteringError for analysis failures
    func identifyVerticalClusters(
        from yPositions: [CGFloat],
        tolerance: CGFloat
    ) async throws -> [VerticalCluster] {
        
        guard !yPositions.isEmpty else {
            return []
        }
        
        guard yPositions.count >= 2 else {
            return [VerticalCluster(
                centerY: yPositions[0],
                spread: 0.0,
                confidence: 1.0
            )]
        }
        
        let sortedPositions = yPositions.sorted()
        var clusters: [VerticalCluster] = []
        var currentClusterPositions: [CGFloat] = [sortedPositions[0]]
        
        for i in 1..<sortedPositions.count {
            let currentPos = sortedPositions[i]
            let previousPos = sortedPositions[i-1]
            let gap = currentPos - previousPos
            
            if gap <= tolerance {
                // Add to current cluster
                currentClusterPositions.append(currentPos)
            } else {
                // Finalize current cluster and start new one
                if currentClusterPositions.count >= 1 {
                    clusters.append(createVerticalCluster(from: currentClusterPositions))
                }
                currentClusterPositions = [currentPos]
            }
        }
        
        // Add final cluster
        if !currentClusterPositions.isEmpty {
            clusters.append(createVerticalCluster(from: currentClusterPositions))
        }
        
        return clusters
    }
    
    /// Analyzes cluster quality and confidence
    /// - Parameter clusters: Array of clusters to analyze
    /// - Returns: Quality metrics for the clustering
    func analyzeClusterQuality(_ clusters: [VerticalCluster]) async throws -> ClusterQualityMetrics {
        guard !clusters.isEmpty else {
            return ClusterQualityMetrics.empty
        }
        
        let spreadVariance = calculateSpreadVariance(clusters)
        let confidenceAverage = clusters.map { $0.confidence }.reduce(0, +) / Double(clusters.count)
        let clusterCount = clusters.count
        
        // Overall quality based on cluster consistency and confidence
        let qualityScore = min(confidenceAverage * (1.0 - min(spreadVariance / 100.0, 0.5)), 1.0)
        
        return ClusterQualityMetrics(
            clusterCount: clusterCount,
            averageConfidence: confidenceAverage,
            spreadVariance: spreadVariance,
            qualityScore: qualityScore,
            isHighQuality: qualityScore >= 0.7
        )
    }
    
    // MARK: - Private Implementation
    
    /// Creates a vertical cluster from position data
    private func createVerticalCluster(from positions: [CGFloat]) -> VerticalCluster {
        let centerY = positions.reduce(0, +) / CGFloat(positions.count)
        let minY = positions.min() ?? centerY
        let maxY = positions.max() ?? centerY
        let spread = maxY - minY
        
        // Confidence based on cluster density and spread
        let densityScore = Double(positions.count) / 10.0 // Normalize by expected max elements
        let spreadScore = spread <= 5.0 ? 1.0 : max(0.3, 1.0 - Double(spread) / 50.0)
        let confidence = min((densityScore * 0.4) + (spreadScore * 0.6), 1.0)
        
        return VerticalCluster(
            centerY: centerY,
            spread: spread,
            confidence: confidence
        )
    }
    
    /// Calculates variance in cluster spreads
    private func calculateSpreadVariance(_ clusters: [VerticalCluster]) -> Double {
        guard clusters.count > 1 else { return 0.0 }
        
        let spreads = clusters.map { Double($0.spread) }
        let average = spreads.reduce(0, +) / Double(spreads.count)
        
        let variance = spreads.reduce(0.0) { sum, spread in
            let diff = spread - average
            return sum + (diff * diff)
        } / Double(spreads.count - 1)
        
        return sqrt(variance)
    }
}

// MARK: - Supporting Types

/// Quality metrics for cluster analysis
struct ClusterQualityMetrics {
    let clusterCount: Int
    let averageConfidence: Double
    let spreadVariance: Double
    let qualityScore: Double
    let isHighQuality: Bool
    
    static let empty = ClusterQualityMetrics(
        clusterCount: 0,
        averageConfidence: 0.0,
        spreadVariance: 0.0,
        qualityScore: 0.0,
        isHighQuality: false
    )
}

/// Error types for clustering operations
enum ClusteringError: Error, LocalizedError {
    case insufficientData(count: Int)
    case analysisFailure(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .insufficientData(let count):
            return "Insufficient data for clustering: \(count) points"
        case .analysisFailure(let message):
            return "Clustering analysis failed: \(message)"
        case .invalidConfiguration:
            return "Invalid clustering configuration"
        }
    }
}
