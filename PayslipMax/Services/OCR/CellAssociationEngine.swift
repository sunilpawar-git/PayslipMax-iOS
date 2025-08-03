import Foundation
import Vision
import CoreGraphics

/// Advanced cell association engine for mapping text to table cells in military payslips
class CellAssociationEngine {
    
    // MARK: - Properties
    private let confidenceThreshold: Double = 0.6
    private let spatialToleranceX: CGFloat = 0.02 // 2% tolerance for X alignment
    private let spatialToleranceY: CGFloat = 0.01 // 1% tolerance for Y alignment
    
    // MARK: - Main Association Methods
    
    /// Associate text observations with table structure cells
    func associateTextWithCells(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> [CellTextAssociation] {
        
        var associations: [CellTextAssociation] = []
        
        for observation in observations {
            if let association = findBestCellAssociation(
                observation: observation,
                tableStructure: tableStructure
            ) {
                associations.append(association)
            }
        }
        
        return associations
    }
    
    /// Map text observations to specific cell positions
    func mapTextToCellPositions(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> [CellPosition: [VNRecognizedTextObservation]] {
        
        var positionMap: [CellPosition: [VNRecognizedTextObservation]] = [:]
        
        for observation in observations {
            if let position = findCellPosition(
                observation: observation,
                tableStructure: tableStructure
            ) {
                if positionMap[position] == nil {
                    positionMap[position] = []
                }
                positionMap[position]?.append(observation)
            }
        }
        
        return positionMap
    }
    
    /// Create comprehensive cell data with associated text
    func createCellDataAssociations(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> [CellDataAssociation] {
        
        var cellAssociations: [CellDataAssociation] = []
        
        // Group observations by their closest cell
        let positionMap = mapTextToCellPositions(
            observations: observations,
            tableStructure: tableStructure
        )
        
        for (position, associatedObservations) in positionMap {
            let cellData = createCellData(
                position: position,
                observations: associatedObservations,
                tableStructure: tableStructure
            )
            
            let association = CellDataAssociation(
                cellData: cellData,
                observations: associatedObservations,
                position: position,
                confidence: calculateAssociationConfidence(associatedObservations)
            )
            
            cellAssociations.append(association)
        }
        
        return cellAssociations
    }
    
    // MARK: - Cell Finding Algorithms
    
    /// Find the best cell association for a text observation
    private func findBestCellAssociation(
        observation: VNRecognizedTextObservation,
        tableStructure: TableStructure
    ) -> CellTextAssociation? {
        
        var bestAssociation: CellTextAssociation?
        var bestScore: Double = 0.0
        
        // Check each cell in the table structure
        for rowIndex in 0..<tableStructure.cells.count {
            for columnIndex in 0..<tableStructure.cells[rowIndex].count {
                let cell = tableStructure.cells[rowIndex][columnIndex]
                
                let score = calculateAssociationScore(
                    observation: observation,
                    cell: cell
                )
                
                if score > bestScore && score > confidenceThreshold {
                    bestScore = score
                    bestAssociation = CellTextAssociation(
                        observation: observation,
                        cell: cell,
                        score: score,
                        associationType: determineAssociationType(observation, cell)
                    )
                }
            }
        }
        
        return bestAssociation
    }
    
    /// Find cell position for a text observation
    private func findCellPosition(
        observation: VNRecognizedTextObservation,
        tableStructure: TableStructure
    ) -> CellPosition? {
        
        let observationBounds = observation.boundingBox
        
        // Find row based on Y position
        guard let rowIndex = findRowIndex(
            yPosition: observationBounds.midY,
            tableStructure: tableStructure
        ) else {
            return nil
        }
        
        // Find column based on X position
        guard let columnIndex = findColumnIndex(
            xPosition: observationBounds.midX,
            tableStructure: tableStructure
        ) else {
            return nil
        }
        
        return CellPosition(row: rowIndex, column: columnIndex)
    }
    
    /// Find row index based on Y position
    private func findRowIndex(
        yPosition: CGFloat,
        tableStructure: TableStructure
    ) -> Int? {
        
        for (index, row) in tableStructure.rows.enumerated() {
            let rowY = CGFloat(row.yPosition)
            let tolerance = spatialToleranceY
            
            if abs(yPosition - rowY) <= tolerance {
                return index
            }
        }
        
        // Fallback: find closest row
        let rowDistances = tableStructure.rows.enumerated().map { index, row in
            (index: index, distance: abs(yPosition - CGFloat(row.yPosition)))
        }
        
        return rowDistances.min { $0.distance < $1.distance }?.index
    }
    
    /// Find column index based on X position
    private func findColumnIndex(
        xPosition: CGFloat,
        tableStructure: TableStructure
    ) -> Int? {
        
        for boundary in tableStructure.columns {
            let columnX = CGFloat(boundary.xPosition)
            let tolerance = spatialToleranceX
            
            if abs(xPosition - columnX) <= tolerance {
                return boundary.columnIndex
            }
        }
        
        // Fallback: find closest column
        let columnDistances = tableStructure.columns.map { boundary in
            (index: boundary.columnIndex, distance: abs(xPosition - CGFloat(boundary.xPosition)))
        }
        
        return columnDistances.min { $0.distance < $1.distance }?.index
    }
    
    // MARK: - Scoring and Confidence
    
    /// Calculate association score between observation and cell
    private func calculateAssociationScore(
        observation: VNRecognizedTextObservation,
        cell: TableCell
    ) -> Double {
        
        let spatialScore = calculateSpatialScore(observation, cell)
        let contentScore = calculateContentScore(observation, cell)
        let confidenceScore = Double(observation.confidence)
        
        // Weighted combination
        return (spatialScore * 0.5) + (contentScore * 0.3) + (confidenceScore * 0.2)
    }
    
    /// Calculate spatial alignment score
    private func calculateSpatialScore(
        _ observation: VNRecognizedTextObservation,
        _ cell: TableCell
    ) -> Double {
        
        let observationBounds = observation.boundingBox
        let cellBounds = cell.boundingBox
        
        // Calculate overlap ratio
        let intersection = observationBounds.intersection(cellBounds)
        let unionArea = observationBounds.union(cellBounds)
        
        guard unionArea.width > 0 && unionArea.height > 0 else { return 0.0 }
        
        let overlapRatio = (intersection.width * intersection.height) / 
                          (unionArea.width * unionArea.height)
        
        return Double(overlapRatio)
    }
    
    /// Calculate content compatibility score
    private func calculateContentScore(
        _ observation: VNRecognizedTextObservation,
        _ cell: TableCell
    ) -> Double {
        
        guard let recognizedText = observation.topCandidates(1).first?.string else {
            return 0.0
        }
        
        // Content-based scoring for military payslips
        switch cell.cellType {
        case .header:
            return recognizedText.containsMilitaryHeader() ? 1.0 : 0.5
        case .amount:
            return recognizedText.isNumericAmount() ? 1.0 : 0.2
        case .code:
            return recognizedText.isMilitaryCode() ? 1.0 : 0.7
        case .total:
            return recognizedText.containsTotalKeyword() ? 1.0 : 0.3
        case .empty:
            return recognizedText.isEmpty ? 1.0 : 0.0
        case .unknown:
            return 0.5
        }
    }
    
    /// Calculate overall association confidence
    private func calculateAssociationConfidence(
        _ observations: [VNRecognizedTextObservation]
    ) -> Double {
        
        guard !observations.isEmpty else { return 0.0 }
        
        let totalConfidence = observations.reduce(0.0) { sum, obs in
            sum + Double(obs.confidence)
        }
        
        return totalConfidence / Double(observations.count)
    }
    
    /// Determine association type based on content
    private func determineAssociationType(
        _ observation: VNRecognizedTextObservation,
        _ cell: TableCell
    ) -> CellAssociationType {
        
        guard let text = observation.topCandidates(1).first?.string else {
            return .unknown
        }
        
        if text.isNumericAmount() {
            return .amount
        } else if text.isMilitaryCode() {
            return .code
        } else if text.containsMilitaryHeader() {
            return .header
        } else {
            return .description
        }
    }
    
    /// Create cell data from observations and position
    private func createCellData(
        position: CellPosition,
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> CellData {
        
        // Combine text from multiple observations
        let combinedText = observations.compactMap { 
            $0.topCandidates(1).first?.string 
        }.joined(separator: " ")
        
        // Calculate average confidence
        let averageConfidence = calculateAssociationConfidence(observations)
        
        // Calculate bounding box
        let boundingBox = observations.reduce(CGRect.zero) { result, observation in
            return result.union(observation.boundingBox)
        }
        
        return CellData(
            text: combinedText,
            confidence: Float(averageConfidence),
            boundingBox: boundingBox,
            cellPosition: position
        )
    }
}

// MARK: - Association Data Models

/// Association between text observation and table cell
struct CellTextAssociation {
    let observation: VNRecognizedTextObservation
    let cell: TableCell
    let score: Double
    let associationType: CellAssociationType
}

/// Association between cell data and observations
struct CellDataAssociation {
    let cellData: CellData
    let observations: [VNRecognizedTextObservation]
    let position: CellPosition
    let confidence: Double
}

/// Types of cell associations
enum CellAssociationType {
    case header      // Header text association
    case code        // Code/description association
    case amount      // Numeric amount association
    case description // General description association
    case unknown     // Unknown association type
}

// MARK: - String Extensions for Military Content Analysis

private extension String {
    
    /// Check if string contains military header patterns
    func containsMilitaryHeader() -> Bool {
        let patterns = HeaderType.militaryEarningsPatterns + HeaderType.militaryDeductionsPatterns
        return patterns.contains { self.uppercased().contains($0) }
    }
    
    /// Check if string is a numeric amount
    func isNumericAmount() -> Bool {
        let numericPattern = #"^\d+(?:\.\d{1,2})?$"#
        return self.range(of: numericPattern, options: .regularExpression) != nil
    }
    
    /// Check if string is a military code
    func isMilitaryCode() -> Bool {
        let militaryCodes = ["DA", "HRA", "CCA", "TA", "IT", "PT", "DSOP", "CGEGIS", "NPS", "GPF"]
        return militaryCodes.contains(self.uppercased())
    }
    
    /// Check if string contains total keywords
    func containsTotalKeyword() -> Bool {
        let totalKeywords = ["TOTAL", "SUM", "NET", "GROSS", "AMOUNT"]
        return totalKeywords.contains { self.uppercased().contains($0) }
    }
}