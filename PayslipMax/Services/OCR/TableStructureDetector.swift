import Vision
import CoreGraphics
import UIKit

/// Advanced table structure detector with geometric grid analysis
class TableStructureDetector {
    
    // MARK: - Configuration
    private struct DetectionConfig {
        static let minCellWidth: Double = 0.05
        static let minCellHeight: Double = 0.02
        static let maxRowVariance: Double = 0.015
        static let maxColumnVariance: Double = 0.01
        static let minRowSeparation: Double = 0.008
        static let gridConfidenceThreshold: Double = 0.7
    }
    
    // MARK: - Grid Detection Pipeline
    func detectTableStructure(
        from textObservations: [VNRecognizedTextObservation],
        in imageSize: CGSize
    ) -> DetectedTableStructure {
        
        // 1. Analyze text distribution patterns
        let distributionAnalysis = analyzeTextDistribution(textObservations)
        
        // 2. Detect potential grid lines through alignment
        let gridLines = detectGridLines(from: textObservations)
        
        // 3. Identify table boundaries and regions
        let tableRegions = identifyTableRegions(gridLines, distributionAnalysis)
        
        // 4. Build precise cell matrix
        let cellMatrix = buildCellMatrix(gridLines, tableRegions, textObservations)
        
        // 5. Validate grid structure integrity
        let validatedStructure = validateGridStructure(cellMatrix, gridLines)
        
        return DetectedTableStructure(
            regions: tableRegions,
            gridLines: gridLines,
            cellMatrix: cellMatrix,
            confidence: validatedStructure.overallConfidence,
            metadata: TableMetadata(
                rowCount: cellMatrix.count,
                columnCount: cellMatrix.first?.count ?? 0,
                detectionMethod: .geometricAnalysis,
                processingTime: Date().timeIntervalSince1970
            )
        )
    }
    
    // MARK: - Text Distribution Analysis
    private func analyzeTextDistribution(_ observations: [VNRecognizedTextObservation]) -> TextDistributionAnalysis {
        
        // Analyze text density across different regions
        let horizontalDistribution = analyzeHorizontalDistribution(observations)
        let verticalDistribution = analyzeVerticalDistribution(observations)
        
        // Identify text clusters and gaps
        let textClusters = identifyTextClusters(observations)
        let significantGaps = identifySignificantGaps(observations)
        
        return TextDistributionAnalysis(
            horizontalDensity: horizontalDistribution,
            verticalDensity: verticalDistribution,
            textClusters: textClusters,
            gaps: significantGaps,
            uniformityScore: calculateUniformityScore(observations)
        )
    }
    
    private func analyzeHorizontalDistribution(_ observations: [VNRecognizedTextObservation]) -> [Double] {
        let bucketCount = 20
        var distribution = Array(repeating: 0.0, count: bucketCount)
        
        for observation in observations {
            let bucketIndex = min(Int(observation.boundingBox.midX * Double(bucketCount)), bucketCount - 1)
            distribution[bucketIndex] += 1.0
        }
        
        return distribution
    }
    
    private func analyzeVerticalDistribution(_ observations: [VNRecognizedTextObservation]) -> [Double] {
        let bucketCount = 30
        var distribution = Array(repeating: 0.0, count: bucketCount)
        
        for observation in observations {
            let bucketIndex = min(Int((1.0 - observation.boundingBox.midY) * Double(bucketCount)), bucketCount - 1)
            distribution[bucketIndex] += 1.0
        }
        
        return distribution
    }
    
    // MARK: - Grid Line Detection
    private func detectGridLines(from observations: [VNRecognizedTextObservation]) -> GridLines {
        
        // Detect horizontal grid lines (rows)
        let horizontalLines = detectHorizontalGridLines(observations)
        
        // Detect vertical grid lines (columns)
        let verticalLines = detectVerticalGridLines(observations)
        
        // Refine grid lines using intersection analysis
        let refinedLines = refineGridLines(horizontalLines, verticalLines, observations)
        
        return GridLines(
            horizontal: refinedLines.horizontal,
            vertical: refinedLines.vertical,
            confidence: calculateGridConfidence(refinedLines.horizontal, refinedLines.vertical)
        )
    }
    
    private func detectHorizontalGridLines(_ observations: [VNRecognizedTextObservation]) -> [GridLine] {
        var horizontalLines: [GridLine] = []
        
        // Group observations by Y position with tolerance
        let yPositions = observations.map { Double(1.0 - $0.boundingBox.midY) }
        let clusteredY = clusterPositions(yPositions, tolerance: DetectionConfig.maxRowVariance)
        
        for cluster in clusteredY {
            if cluster.positions.count >= 2 {
                let averageY = cluster.positions.reduce(0.0, +) / Double(cluster.positions.count)
                let confidence = calculateLineConfidence(cluster.positions.count, totalObservations: observations.count)
                
                horizontalLines.append(GridLine(
                    position: averageY,
                    orientation: .horizontal,
                    confidence: confidence,
                    supportingObservations: cluster.observationIndices
                ))
            }
        }
        
        return horizontalLines.sorted { $0.position < $1.position }
    }
    
    private func detectVerticalGridLines(_ observations: [VNRecognizedTextObservation]) -> [GridLine] {
        var verticalLines: [GridLine] = []
        
        // Analyze text alignment and spacing patterns
        let xPositions = observations.flatMap { [Double($0.boundingBox.minX), Double($0.boundingBox.maxX)] }
        let clusteredX = clusterPositions(xPositions, tolerance: DetectionConfig.maxColumnVariance)
        
        for cluster in clusteredX {
            if cluster.positions.count >= 2 {
                let averageX = cluster.positions.reduce(0.0, +) / Double(cluster.positions.count)
                let confidence = calculateLineConfidence(cluster.positions.count, totalObservations: observations.count * 2)
                
                verticalLines.append(GridLine(
                    position: averageX,
                    orientation: .vertical,
                    confidence: confidence,
                    supportingObservations: cluster.observationIndices
                ))
            }
        }
        
        return verticalLines.sorted { $0.position < $1.position }
    }
    
    // MARK: - Cell Matrix Construction
    private func buildCellMatrix(
        _ gridLines: GridLines,
        _ regions: [TableRegion],
        _ observations: [VNRecognizedTextObservation]
    ) -> [[TableCell]] {
        
        guard gridLines.horizontal.count >= 2 && gridLines.vertical.count >= 2 else {
            return []
        }
        
        var cellMatrix: [[TableCell]] = []
        
        // Create cells based on grid intersections
        for rowIndex in 0..<(gridLines.horizontal.count - 1) {
            var rowCells: [TableCell] = []
            
            let topY = gridLines.horizontal[rowIndex].position
            let bottomY = gridLines.horizontal[rowIndex + 1].position
            
            for colIndex in 0..<(gridLines.vertical.count - 1) {
                let leftX = gridLines.vertical[colIndex].position
                let rightX = gridLines.vertical[colIndex + 1].position
                
                let cellBounds = CGRect(
                    x: leftX,
                    y: 1.0 - topY,
                    width: rightX - leftX,
                    height: topY - bottomY
                )
                
                // Find text observations within this cell
                let cellObservations = findObservationsInCell(cellBounds, observations)
                
                let cell = TableCell(
                    position: CellPosition(row: rowIndex, column: colIndex),
                    boundingBox: cellBounds,
                    observations: cellObservations,
                    cellType: determineCellType(cellObservations),
                    confidence: calculateCellConfidence(cellObservations, cellBounds)
                )
                
                rowCells.append(cell)
            }
            
            cellMatrix.append(rowCells)
        }
        
        return cellMatrix
    }
    
    // MARK: - Helper Methods
    private func clusterPositions(_ positions: [Double], tolerance: Double) -> [PositionCluster] {
        var clusters: [PositionCluster] = []
        let sortedPositions = positions.enumerated().sorted { $0.element < $1.element }
        
        // Handle empty positions array
        guard !sortedPositions.isEmpty else { return clusters }
        
        var currentCluster = PositionCluster(positions: [sortedPositions[0].element], observationIndices: [sortedPositions[0].offset])
        
        for i in 1..<sortedPositions.count {
            let position = sortedPositions[i].element
            let index = sortedPositions[i].offset
            
            if abs(position - currentCluster.positions.last!) < tolerance {
                currentCluster.positions.append(position)
                currentCluster.observationIndices.append(index)
            } else {
                clusters.append(currentCluster)
                currentCluster = PositionCluster(positions: [position], observationIndices: [index])
            }
        }
        
        clusters.append(currentCluster)
        return clusters
    }
    
    private func calculateLineConfidence(_ supportCount: Int, totalObservations: Int) -> Double {
        let ratio = Double(supportCount) / Double(totalObservations)
        return min(ratio * 2.0, 1.0)
    }
    
    private func findObservationsInCell(
        _ cellBounds: CGRect,
        _ observations: [VNRecognizedTextObservation]
    ) -> [VNRecognizedTextObservation] {
        
        return observations.filter { observation in
            let center = CGPoint(
                x: observation.boundingBox.midX,
                y: observation.boundingBox.midY
            )
            return cellBounds.contains(center)
        }
    }
    
    private func determineCellType(_ observations: [VNRecognizedTextObservation]) -> CellType {
        guard !observations.isEmpty else { return .empty }
        
        let combinedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: " ")
        
        // Check for numeric content
        if isNumericContent(combinedText) {
            return .amount
        }
        
        // Check for header patterns
        if isHeaderContent(combinedText) {
            return .header
        }
        
        return .code
    }
    
    private func isNumericContent(_ text: String) -> Bool {
        let numericPattern = #"^\s*[\d,.\-+₹\s]+\s*$"#
        return text.range(of: numericPattern, options: .regularExpression) != nil
    }
    
    private func isHeaderContent(_ text: String) -> Bool {
        let headerPatterns = ["CREDIT", "DEBIT", "AMOUNT", "CODE", "DESCRIPTION", "TOTAL"]
        let upperText = text.uppercased()
        return headerPatterns.contains { pattern in
            upperText.contains(pattern)
        }
    }
    
    private func calculateCellConfidence(
        _ observations: [VNRecognizedTextObservation],
        _ cellBounds: CGRect
    ) -> Double {
        
        guard !observations.isEmpty else { return 0.0 }
        
        let textConfidence = observations.reduce(0.0) { sum, obs in
            sum + Double(obs.confidence)
        } / Double(observations.count)
        
        let coverageRatio = calculateTextCoverage(observations, in: cellBounds)
        
        return (textConfidence + coverageRatio) / 2.0
    }
    
    private func calculateTextCoverage(_ observations: [VNRecognizedTextObservation], in bounds: CGRect) -> Double {
        let totalTextArea = observations.reduce(0.0) { sum, obs in
            sum + (obs.boundingBox.width * obs.boundingBox.height)
        }
        
        let cellArea = bounds.width * bounds.height
        return min(totalTextArea / cellArea, 1.0)
    }
    
    private func identifyTableRegions(_ gridLines: GridLines, _ distribution: TextDistributionAnalysis) -> [TableRegion] {
        // Implementation for identifying coherent table regions
        guard gridLines.horizontal.count >= 2 && gridLines.vertical.count >= 2 else {
            return []
        }
        
        // Calculate bounding box components separately to avoid complex expression
        let leftX = gridLines.vertical.first?.position ?? 0.0
        let topY = 1.0 - (gridLines.horizontal.first?.position ?? 1.0)
        let rightX = gridLines.vertical.last?.position ?? 1.0
        let bottomY = gridLines.horizontal.last?.position ?? 0.0
        
        let mainRegion = TableRegion(
            boundingBox: CGRect(
                x: leftX,
                y: topY,
                width: rightX - leftX,
                height: (gridLines.horizontal.first?.position ?? 1.0) - bottomY
            ),
            regionType: .dataRows,
            confidence: Double(gridLines.confidence),
            cellCount: estimateGridCellCount(gridLines)
        )
        
        return [mainRegion]
    }
    
    private func estimateGridCellCount(_ gridLines: GridLines) -> Int {
        let horizontalLines = gridLines.horizontal.count
        let verticalLines = gridLines.vertical.count
        
        // Estimate cells based on grid line intersections
        if horizontalLines > 1 && verticalLines > 1 {
            return (horizontalLines - 1) * (verticalLines - 1)
        }
        
        // Fallback estimation
        return max(1, horizontalLines * verticalLines / 2)
    }
    
    private func refineGridLines(_ horizontal: [GridLine], _ vertical: [GridLine], _ observations: [VNRecognizedTextObservation]) -> (horizontal: [GridLine], vertical: [GridLine]) {
        // Grid line refinement logic
        return (horizontal: horizontal, vertical: vertical)
    }
    
    private func calculateGridConfidence(_ horizontal: [GridLine], _ vertical: [GridLine]) -> Double {
        let horizontalConfidence = horizontal.reduce(0.0) { sum, line in sum + line.confidence } / Double(max(horizontal.count, 1))
        let verticalConfidence = vertical.reduce(0.0) { sum, line in sum + line.confidence } / Double(max(vertical.count, 1))
        
        return (horizontalConfidence + verticalConfidence) / 2.0
    }
    
    private func validateGridStructure(_ cellMatrix: [[TableCell]], _ gridLines: GridLines) -> GridValidationResult {
        let structuralConsistency = calculateStructuralConsistency(cellMatrix)
        let alignmentQuality = calculateAlignmentQuality(gridLines)
        
        return GridValidationResult(
            overallConfidence: (structuralConsistency + alignmentQuality) / 2.0,
            structuralConsistency: structuralConsistency,
            alignmentQuality: alignmentQuality
        )
    }
    
    private func calculateStructuralConsistency(_ cellMatrix: [[TableCell]]) -> Double {
        // Check for consistent row and column counts
        guard !cellMatrix.isEmpty else { return 0.0 }
        
        let expectedColumnCount = cellMatrix[0].count
        let consistentRows = cellMatrix.filter { $0.count == expectedColumnCount }.count
        
        return Double(consistentRows) / Double(cellMatrix.count)
    }
    
    private func calculateAlignmentQuality(_ gridLines: GridLines) -> Double {
        let horizontalQuality = calculateLineAlignmentQuality(gridLines.horizontal)
        let verticalQuality = calculateLineAlignmentQuality(gridLines.vertical)
        
        return (horizontalQuality + verticalQuality) / 2.0
    }
    
    private func calculateLineAlignmentQuality(_ lines: [GridLine]) -> Double {
        guard lines.count >= 2 else { return 0.0 }
        
        return lines.reduce(0.0) { sum, line in sum + line.confidence } / Double(lines.count)
    }
    
    private func identifyTextClusters(_ observations: [VNRecognizedTextObservation]) -> [TextCluster] {
        // Simplified clustering implementation
        return []
    }
    
    private func identifySignificantGaps(_ observations: [VNRecognizedTextObservation]) -> [SignificantGap] {
        // Gap detection implementation
        return []
    }
    
    private func calculateUniformityScore(_ observations: [VNRecognizedTextObservation]) -> Double {
        // Text uniformity calculation
        return 0.8
    }
}

// MARK: - Supporting Data Structures
struct DetectedTableStructure {
    let regions: [TableRegion]
    let gridLines: GridLines
    let cellMatrix: [[TableCell]]
    let confidence: Double
    let metadata: TableMetadata
}

struct GridLines {
    let horizontal: [GridLine]
    let vertical: [GridLine]
    let confidence: Double
}

struct GridLine {
    let position: Double
    let orientation: LineOrientation
    let confidence: Double
    let supportingObservations: [Int]
}

enum LineOrientation {
    case horizontal
    case vertical
}

struct PositionCluster {
    var positions: [Double]
    var observationIndices: [Int]
}

struct TextDistributionAnalysis {
    let horizontalDensity: [Double]
    let verticalDensity: [Double]
    let textClusters: [TextCluster]
    let gaps: [SignificantGap]
    let uniformityScore: Double
}

struct TextCluster {
    let observations: [VNRecognizedTextObservation]
    let centroid: CGPoint
    let density: Double
}

struct SignificantGap {
    let location: CGRect
    let gapType: GapType
    let significance: Double
}

enum GapType {
    case horizontal
    case vertical
}

struct TableMetadata {
    let rowCount: Int
    let columnCount: Int
    let detectionMethod: DetectionMethod
    let processingTime: TimeInterval
}

enum DetectionMethod {
    case geometricAnalysis
    case patternMatching
    case hybrid
}

struct GridValidationResult {
    let overallConfidence: Double
    let structuralConsistency: Double
    let alignmentQuality: Double
}

