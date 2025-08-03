
import Vision
import CoreGraphics

/// Analyzes the geometric layout of text detected by Vision to identify lines, paragraphs, and tables.
final class GeometricTextAnalyzer {

    // MARK: - Public Data Structures

    struct Cell {
        let observations: [VNTextObservation]
        let boundingBox: CGRect
        var text: String? // Will be populated after recognition
    }

    struct Row {
        let cells: [Cell]
        let boundingBox: CGRect
    }

    struct Table {
        let rows: [Row]
        let boundingBox: CGRect
    }

    struct GroupedTextResult {
        let lines: [[VNTextObservation]]
        let paragraphs: [[[VNTextObservation]]]
        var tables: [Table]
    }

    // MARK: - Public API

    /// Groups text observations into lines, paragraphs, and tables.
    ///
    /// - Parameter textObservations: An array of `VNTextObservation` from a Vision request.
    /// - Returns: A `GroupedTextResult` containing the structured text and tables.
    func groupTextObservations(_ textObservations: [VNTextObservation]) -> GroupedTextResult {
        let lines = groupIntoLines(textObservations)
        let tables = detectTables(from: lines)
        
        // For now, paragraphs are simple line groupings. This can be enhanced later.
        let paragraphs = groupIntoParagraphs(lines)
        
        return GroupedTextResult(lines: lines, paragraphs: paragraphs, tables: tables)
    }

    // MARK: - Table Detection Logic

    /// Detects tables from a collection of text lines.
    private func detectTables(from lines: [[VNTextObservation]]) -> [Table] {
        guard !lines.isEmpty else { return [] }

        // 1. Identify Column Boundaries
        let columnBoundaries = identifyColumnBoundaries(from: lines.flatMap { $0 })
        
        guard columnBoundaries.count > 1 else { return [] } // Must have at least two columns for a table

        // 2. Create a Grid and Assign Cells
        var tableRows: [Row] = []
        for line in lines {
            var cells: [Cell] = []
            for i in 0..<(columnBoundaries.count - 1) {
                let columnLeft = columnBoundaries[i]
                let columnRight = columnBoundaries[i+1]
                
                let cellObservations = line.filter { observation in
                    let observationMidX = observation.boundingBox.midX
                    return observationMidX >= columnLeft && observationMidX < columnRight
                }
                
                if !cellObservations.isEmpty {
                    let cellBox = cellObservations.reduce(CGRect.null) { $0.union($1.boundingBox) }
                    cells.append(Cell(observations: cellObservations, boundingBox: cellBox))
                } else {
                    // Add an empty cell to maintain table structure
                    let approxLineHeight = line.first?.boundingBox.height ?? 0
                    let lineMidY = line.first?.boundingBox.midY ?? 0
                    let emptyCellBox = CGRect(x: columnLeft, y: lineMidY - approxLineHeight / 2, width: columnRight - columnLeft, height: approxLineHeight)
                    cells.append(Cell(observations: [], boundingBox: emptyCellBox))
                }
            }
            
            if !cells.isEmpty {
                 let rowBox = cells.reduce(CGRect.null) { $0.union($1.boundingBox) }
                 tableRows.append(Row(cells: cells, boundingBox: rowBox))
            }
        }
        
        // For this implementation, we assume a single table.
        // Multi-table detection would require additional clustering logic.
        if tableRows.isEmpty {
            return []
        } else {
            let tableBox = tableRows.reduce(CGRect.null) { $0.union($1.boundingBox) }
            return [Table(rows: tableRows, boundingBox: tableBox)]
        }
    }

    /// Identifies vertical column boundaries from a flat list of text observations.
    private func identifyColumnBoundaries(from observations: [VNTextObservation]) -> [CGFloat] {
        var xCoordinates: [CGFloat] = []
        for observation in observations {
            xCoordinates.append(observation.boundingBox.minX)
            xCoordinates.append(observation.boundingBox.maxX)
        }
        
        // Create a histogram of X-coordinates to find gaps between columns
        let sortedX = xCoordinates.sorted()
        guard let minX = sortedX.first, let maxX = sortedX.last else { return [] }
        
        let numBins = 100 // Heuristic, can be adjusted
        let binWidth = (maxX - minX) / CGFloat(numBins)
        var bins = [Int](repeating: 0, count: numBins)
        
        for x in sortedX {
            let binIndex = min(Int((x - minX) / binWidth), numBins - 1)
            bins[binIndex] += 1
        }
        
        // Find gaps (empty bins) which represent column separators
        var boundaries: [CGFloat] = [minX]
        for i in 1..<(numBins - 1) {
            if bins[i] == 0 && bins[i-1] > 0 && bins[i+1] > 0 {
                let boundaryX = minX + (CGFloat(i) + 0.5) * binWidth
                boundaries.append(boundaryX)
            }
        }
        boundaries.append(maxX)
        
        // Merge close boundaries
        let mergedBoundaries = mergeCloseBoundaries(boundaries, minGap: binWidth * 2)
        
        return mergedBoundaries
    }
    
    private func mergeCloseBoundaries(_ boundaries: [CGFloat], minGap: CGFloat) -> [CGFloat] {
        guard boundaries.count > 1 else { return boundaries }
        var merged: [CGFloat] = [boundaries[0]]
        for i in 1..<boundaries.count {
            if boundaries[i] - merged.last! > minGap {
                merged.append(boundaries[i])
            } else {
                // If the boundary is too close, we skip it, effectively merging the columns.
                // A more sophisticated approach could average them.
            }
        }
        return merged
    }


    // MARK: - Line and Paragraph Grouping

    /// Groups text observations into lines based on their vertical alignment.
    private func groupIntoLines(_ observations: [VNTextObservation]) -> [[VNTextObservation]] {
        var lines: [[VNTextObservation]] = []
        var currentLine: [VNTextObservation] = []

        // Sort observations primarily by Y-coordinate to process top-to-bottom
        let sortedObservations = observations.sorted { $0.boundingBox.minY > $1.boundingBox.minY }

        for observation in sortedObservations {
            if currentLine.isEmpty {
                currentLine.append(observation)
            } else if let lastObservation = currentLine.last, isSameLine(observation1: lastObservation, observation2: observation) {
                currentLine.append(observation)
            } else {
                // Sort the completed line by X-coordinate before adding it
                lines.append(currentLine.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX }))
                currentLine = [observation]
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX }))
        }

        return lines
    }

    /// Determines if two text observations belong to the same line using vertical overlap.
    private func isSameLine(observation1: VNTextObservation, observation2: VNTextObservation) -> Bool {
        let yDifference = abs(observation1.boundingBox.midY - observation2.boundingBox.midY)
        let avgHeight = (observation1.boundingBox.height + observation2.boundingBox.height) / 2
        // Use a tolerance based on the average height of the observations
        return yDifference < avgHeight * 0.7
    }

    /// Groups lines of text into paragraphs.
    /// Note: This is a basic implementation. Can be improved with more sophisticated logic.
    private func groupIntoParagraphs(_ lines: [[VNTextObservation]]) -> [[[VNTextObservation]]] {
        // For now, we will treat each line as a separate paragraph.
        return lines.map { [$0] }
    }
}
