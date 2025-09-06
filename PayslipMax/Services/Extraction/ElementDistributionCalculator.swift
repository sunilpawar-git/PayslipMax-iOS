import Foundation
import CoreGraphics

/// Calculates statistical distribution metrics for positional elements
/// Extracted component for single responsibility - statistical analysis of element positioning
final class ElementDistributionCalculator {
    
    // MARK: - Properties
    
    /// Configuration for statistical calculations
    private let configuration: ColumnBoundaryConfiguration
    
    // MARK: - Initialization
    
    /// Initializes the distribution calculator
    /// - Parameter configuration: Configuration for statistical analysis
    init(configuration: ColumnBoundaryConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Calculates comprehensive statistics for element positions
    /// - Parameter positions: Array of position values to analyze
    /// - Returns: Statistical analysis results
    /// - Throws: StatisticsError for calculation failures
    func calculateStatistics(for positions: [CGFloat]) async throws -> ElementStatistics {
        guard !positions.isEmpty else {
            throw StatisticsError.emptyDataSet
        }
        
        guard positions.count >= 2 else {
            return ElementStatistics.singleElement(position: positions[0])
        }
        
        let sortedPositions = positions.sorted()
        
        // Basic statistics
        let mean = calculateMean(sortedPositions)
        let median = calculateMedian(sortedPositions)
        let standardDeviation = calculateStandardDeviation(sortedPositions, mean: mean)
        let range = calculateRange(sortedPositions)
        
        // Distribution characteristics
        let gaps = calculateGaps(sortedPositions)
        let clusters = try await identifyStatisticalClusters(sortedPositions)
        
        return ElementStatistics(
            count: positions.count,
            mean: mean,
            median: median,
            standardDeviation: standardDeviation,
            range: range,
            minimum: sortedPositions.first!,
            maximum: sortedPositions.last!,
            gaps: gaps,
            clusters: clusters,
            outliers: identifyOutliers(sortedPositions, mean: mean, standardDeviation: standardDeviation)
        )
    }
    
    /// Analyzes gap distribution in positions
    /// - Parameter positions: Sorted array of positions
    /// - Returns: Array of gap measurements
    func calculateGaps(_ positions: [CGFloat]) -> [CGFloat] {
        guard positions.count > 1 else { return [] }
        
        var gaps: [CGFloat] = []
        for i in 1..<positions.count {
            gaps.append(positions[i] - positions[i-1])
        }
        
        return gaps.sorted()
    }
    
    /// Identifies statistical clusters using gap analysis
    /// - Parameter positions: Array of positions to cluster
    /// - Returns: Array of identified clusters
    /// - Throws: StatisticsError for clustering failures
    func identifyStatisticalClusters(_ positions: [CGFloat]) async throws -> [StatisticalCluster] {
        guard positions.count >= 2 else {
            return []
        }
        
        let sortedPositions = positions.sorted()
        let gaps = calculateGaps(sortedPositions)
        
        // Find significant gaps (larger than average + 1 standard deviation)
        let gapMean = gaps.reduce(0, +) / CGFloat(gaps.count)
        let gapStdDev = calculateGapStandardDeviation(gaps, mean: gapMean)
        let significantGapThreshold = gapMean + gapStdDev
        
        var clusters: [StatisticalCluster] = []
        var currentClusterPositions: [CGFloat] = [sortedPositions[0]]
        
        for i in 1..<sortedPositions.count {
            let gap = sortedPositions[i] - sortedPositions[i-1]
            
            if gap <= significantGapThreshold {
                currentClusterPositions.append(sortedPositions[i])
            } else {
                // Finalize current cluster
                if currentClusterPositions.count >= 2 {
                    clusters.append(createStatisticalCluster(from: currentClusterPositions))
                }
                currentClusterPositions = [sortedPositions[i]]
            }
        }
        
        // Add final cluster
        if currentClusterPositions.count >= 2 {
            clusters.append(createStatisticalCluster(from: currentClusterPositions))
        }
        
        return clusters
    }
    
    // MARK: - Private Implementation
    
    /// Calculates arithmetic mean of positions
    private func calculateMean(_ positions: [CGFloat]) -> CGFloat {
        return positions.reduce(0, +) / CGFloat(positions.count)
    }
    
    /// Calculates median of positions
    private func calculateMedian(_ sortedPositions: [CGFloat]) -> CGFloat {
        let count = sortedPositions.count
        if count % 2 == 0 {
            let mid1 = sortedPositions[count / 2 - 1]
            let mid2 = sortedPositions[count / 2]
            return (mid1 + mid2) / 2
        } else {
            return sortedPositions[count / 2]
        }
    }
    
    /// Calculates standard deviation
    private func calculateStandardDeviation(_ positions: [CGFloat], mean: CGFloat) -> CGFloat {
        guard positions.count > 1 else { return 0 }
        
        let variance = positions.reduce(0) { sum, position in
            let diff = position - mean
            return sum + (diff * diff)
        } / CGFloat(positions.count - 1)
        
        return sqrt(variance)
    }
    
    /// Calculates range (max - min)
    private func calculateRange(_ sortedPositions: [CGFloat]) -> CGFloat {
        guard let min = sortedPositions.first,
              let max = sortedPositions.last else { return 0 }
        return max - min
    }
    
    /// Calculates standard deviation for gaps
    private func calculateGapStandardDeviation(_ gaps: [CGFloat], mean: CGFloat) -> CGFloat {
        guard gaps.count > 1 else { return 0 }
        
        let variance = gaps.reduce(0) { sum, gap in
            let diff = gap - mean
            return sum + (diff * diff)
        } / CGFloat(gaps.count - 1)
        
        return sqrt(variance)
    }
    
    /// Identifies statistical outliers using standard score
    private func identifyOutliers(
        _ positions: [CGFloat],
        mean: CGFloat,
        standardDeviation: CGFloat
    ) -> [CGFloat] {
        guard standardDeviation > 0 else { return [] }
        
        let outlierThreshold: CGFloat = 2.0 // 2 standard deviations
        
        return positions.filter { position in
            let standardScore = abs(position - mean) / standardDeviation
            return standardScore > outlierThreshold
        }
    }
    
    /// Creates a statistical cluster from positions
    private func createStatisticalCluster(from positions: [CGFloat]) -> StatisticalCluster {
        let mean = calculateMean(positions)
        let stdDev = calculateStandardDeviation(positions, mean: mean)
        
        return StatisticalCluster(
            center: mean,
            standardDeviation: stdDev,
            positions: positions,
            elementCount: positions.count,
            spread: positions.max()! - positions.min()!
        )
    }
}

// MARK: - Supporting Types

/// Comprehensive statistics for element positions
struct ElementStatistics {
    let count: Int
    let mean: CGFloat
    let median: CGFloat
    let standardDeviation: CGFloat
    let range: CGFloat
    let minimum: CGFloat
    let maximum: CGFloat
    let gaps: [CGFloat]
    let clusters: [StatisticalCluster]
    let outliers: [CGFloat]
    
    /// Creates statistics for a single element
    static func singleElement(position: CGFloat) -> ElementStatistics {
        return ElementStatistics(
            count: 1,
            mean: position,
            median: position,
            standardDeviation: 0,
            range: 0,
            minimum: position,
            maximum: position,
            gaps: [],
            clusters: [],
            outliers: []
        )
    }
}

/// Statistical cluster of positions
struct StatisticalCluster {
    let center: CGFloat
    let standardDeviation: CGFloat
    let positions: [CGFloat]
    let elementCount: Int
    let spread: CGFloat
}

/// Error types for statistical calculations
enum StatisticsError: Error, LocalizedError {
    case emptyDataSet
    case insufficientData(count: Int)
    case calculationFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyDataSet:
            return "Cannot calculate statistics for empty data set"
        case .insufficientData(let count):
            return "Insufficient data for statistical analysis: \(count) elements"
        case .calculationFailure(let message):
            return "Statistical calculation failed: \(message)"
        }
    }
}
