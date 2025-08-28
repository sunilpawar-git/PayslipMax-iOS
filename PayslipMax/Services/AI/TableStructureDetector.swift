import Foundation
import Vision
import CoreGraphics
import UIKit

/// Protocol for table structure detection services
public protocol TableStructureDetectorProtocol {
    func detectTableStructure(in image: UIImage) async throws -> LiteRTTableStructure
    func detectPCDATableBounds(in image: UIImage) async throws -> CGRect?
    func identifyBilingualHeaders(in textElements: [TextElement]) -> [BilingualHeader]
    func mapCellsToGrid(cells: [LiteRTTableCell], bounds: CGRect) -> TableGrid
}

/// Errors specific to table structure detection
public enum TableDetectionError: Error, LocalizedError {
    case noTableFound
    case invalidImageFormat
    case processingFailed(Error)
    case insufficientTextElements
    
    public var errorDescription: String? {
        switch self {
        case .noTableFound:
            return "No table structure found in the image"
        case .invalidImageFormat:
            return "Invalid image format for table detection"
        case .processingFailed(let error):
            return "Table detection processing failed: \(error.localizedDescription)"
        case .insufficientTextElements:
            return "Insufficient text elements for table structure analysis"
        }
    }
}

/// Advanced table structure detector with PCDA format specialization
public class TableStructureDetector: TableStructureDetectorProtocol {
    
    // MARK: - Properties
    
    private let visionTextExtractor: VisionTextExtractorProtocol
    private let minimumCellSize: CGSize = CGSize(width: 30, height: 15)
    private let pcdaKeywords = ["विवरण", "DESCRIPTION", "राशि", "AMOUNT", "PCDA"]
    
    // MARK: - Initialization
    
    public init(visionTextExtractor: VisionTextExtractorProtocol = VisionTextExtractor()) {
        self.visionTextExtractor = visionTextExtractor
        print("[TableStructureDetector] Initialized with Vision text extractor")
    }
    
    // MARK: - Public Methods
    
    /// Detect comprehensive table structure in an image
    public func detectTableStructure(in image: UIImage) async throws -> LiteRTTableStructure {
        print("[TableStructureDetector] Starting table structure detection")
        
        do {
            // Extract text elements using Vision
            let textElements = try await extractTextElements(from: image)
            guard !textElements.isEmpty else {
                throw TableDetectionError.insufficientTextElements
            }
            
            // Detect overall table bounds
            let tableBounds = try await detectTableBounds(in: image, textElements: textElements)
            
            // Identify bilingual headers (PCDA-specific)
            let bilingualHeaders = identifyBilingualHeaders(in: textElements)
            
            // Detect columns and rows
            let columns = try detectColumns(from: textElements, headers: bilingualHeaders, bounds: tableBounds)
            let rows = try detectRows(from: textElements, bounds: tableBounds)
            
            // Map cells to grid structure
            let cells = try mapTextElementsToCells(textElements: textElements, columns: columns, rows: rows)
            
            // Determine if this is PCDA format
            let isPCDAFormat = detectPCDAFormat(headers: bilingualHeaders, textElements: textElements)
            
            // Calculate confidence based on structure quality
            let confidence = calculateStructureConfidence(
                tableBounds: tableBounds,
                columns: columns,
                rows: rows,
                cells: cells,
                isPCDA: isPCDAFormat
            )
            
            let tableStructure = LiteRTTableStructure(
                bounds: tableBounds,
                columns: columns,
                rows: rows,
                cells: cells,
                confidence: confidence,
                isPCDAFormat: isPCDAFormat
            )
            
            print("[TableStructureDetector] Table structure detected with confidence: \(confidence)")
            return tableStructure
            
        } catch {
            print("[TableStructureDetector] Table detection failed: \(error)")
            throw TableDetectionError.processingFailed(error)
        }
    }
    
    /// Detect PCDA-specific table bounds
    public func detectPCDATableBounds(in image: UIImage) async throws -> CGRect? {
        let textElements = try await extractTextElements(from: image)
        
        // Look for PCDA-specific markers
        let pcdaElements = textElements.filter { element in
            pcdaKeywords.contains { keyword in
                element.text.localizedCaseInsensitiveContains(keyword)
            }
        }
        
        guard !pcdaElements.isEmpty else {
            return nil
        }
        
        // Calculate bounds that encompass all PCDA-related elements
        let allBounds = pcdaElements.map { $0.bounds }
        return calculateEnclosingBounds(from: allBounds, imageSize: image.size)
    }
    
    /// Identify bilingual headers in text elements
    public func identifyBilingualHeaders(in textElements: [TextElement]) -> [BilingualHeader] {
        var bilingualHeaders: [BilingualHeader] = []
        
        // Define bilingual pairs for PCDA documents
        let bilingualPairs = [
            ("विवरण", "DESCRIPTION"),
            ("राशि", "AMOUNT"),
            ("क्रम", "SL"),
            ("योग", "TOTAL")
        ]
        
        for (hindi, english) in bilingualPairs {
            let hindiElement = textElements.first { $0.text.contains(hindi) }
            let englishElement = textElements.first { $0.text.contains(english) }
            
            if let hindi = hindiElement, let english = englishElement {
                let header = BilingualHeader(
                    hindiElement: hindi,
                    englishElement: english,
                    combinedBounds: hindi.bounds.union(english.bounds),
                    headerType: determineHeaderType(hindi: hindi.text, english: english.text)
                )
                bilingualHeaders.append(header)
            }
        }
        
        print("[TableStructureDetector] Found \(bilingualHeaders.count) bilingual headers")
        return bilingualHeaders
    }
    
    /// Map cells to a structured grid
    public func mapCellsToGrid(cells: [LiteRTTableCell], bounds: CGRect) -> TableGrid {
        // Group cells by rows and columns
        let sortedCells = cells.sorted { cell1, cell2 in
            if abs(cell1.bounds.midY - cell2.bounds.midY) < 10 {
                return cell1.bounds.midX < cell2.bounds.midX
            }
            return cell1.bounds.midY < cell2.bounds.midY
        }
        
        // Create grid structure
        var grid: [[LiteRTTableCell?]] = []
        var currentRow: [LiteRTTableCell?] = []
        var lastY: CGFloat = 0
        
        for cell in sortedCells {
            if abs(cell.bounds.midY - lastY) > 10 && !currentRow.isEmpty {
                grid.append(currentRow)
                currentRow = []
            }
            currentRow.append(cell)
            lastY = cell.bounds.midY
        }
        
        if !currentRow.isEmpty {
            grid.append(currentRow)
        }
        
        return TableGrid(
            grid: grid,
            rowCount: grid.count,
            columnCount: grid.first?.count ?? 0,
            bounds: bounds
        )
    }
    
    // MARK: - Private Methods
    
    /// Extract text elements from image using Vision
    private func extractTextElements(from image: UIImage) async throws -> [TextElement] {
        return try await withCheckedThrowingContinuation { continuation in
            visionTextExtractor.extractText(from: image) { result in
                switch result {
                case .success(let elements):
                    continuation.resume(returning: elements)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Detect overall table bounds
    private func detectTableBounds(in image: UIImage, textElements: [TextElement]) async throws -> CGRect {
        // Try PCDA-specific detection first
        if let pcdaBounds = try await detectPCDATableBounds(in: image) {
            return pcdaBounds
        }
        
        // Fallback to general table detection
        let allBounds = textElements.map { $0.bounds }
        return calculateEnclosingBounds(from: allBounds, imageSize: image.size)
    }
    
    /// Detect table columns from text elements and headers
    private func detectColumns(from textElements: [TextElement], headers: [BilingualHeader], bounds: CGRect) throws -> [LiteRTTableColumn] {
        var columns: [LiteRTTableColumn] = []
        
        // Use bilingual headers to define columns
        for header in headers {
            let columnBounds = CGRect(
                x: header.combinedBounds.minX,
                y: bounds.minY,
                width: header.combinedBounds.width,
                height: bounds.height
            )
            
            let column = LiteRTTableColumn(
                bounds: columnBounds,
                headerText: "\(header.hindiElement.text)/\(header.englishElement.text)",
                columnType: header.headerType
            )
            columns.append(column)
        }
        
        // If no headers found, use heuristic column detection
        if columns.isEmpty {
            columns = detectColumnsHeuristically(from: textElements, bounds: bounds)
        }
        
        print("[TableStructureDetector] Detected \(columns.count) columns")
        return columns
    }
    
    /// Detect table rows from text elements
    private func detectRows(from textElements: [TextElement], bounds: CGRect) throws -> [LiteRTTableRow] {
        // Group text elements by Y-coordinate (rows)
        let rowGroups = Dictionary(grouping: textElements) { element in
            Int(element.bounds.midY / 20) * 20 // Group by 20-point bands
        }
        
        let sortedRowKeys = rowGroups.keys.sorted()
        var rows: [LiteRTTableRow] = []
        
        for (index, yPosition) in sortedRowKeys.enumerated() {
            guard let elements = rowGroups[yPosition] else { continue }
            
            let minX = elements.map { $0.bounds.minX }.min() ?? bounds.minX
            let maxX = elements.map { $0.bounds.maxX }.max() ?? bounds.maxX
            let minY = elements.map { $0.bounds.minY }.min() ?? CGFloat(yPosition)
            let maxY = elements.map { $0.bounds.maxY }.max() ?? CGFloat(yPosition + 20)
            
            let rowBounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            let isHeader = isHeaderRow(elements: elements)
            
            let row = LiteRTTableRow(
                bounds: rowBounds,
                rowIndex: index,
                isHeader: isHeader
            )
            rows.append(row)
        }
        
        print("[TableStructureDetector] Detected \(rows.count) rows")
        return rows
    }
    
    /// Map text elements to table cells
    private func mapTextElementsToCells(textElements: [TextElement], columns: [LiteRTTableColumn], rows: [LiteRTTableRow]) throws -> [LiteRTTableCell] {
        var cells: [LiteRTTableCell] = []
        
        for element in textElements {
            // Find which column and row this element belongs to
            let columnIndex = findColumnIndex(for: element, in: columns)
            let rowIndex = findRowIndex(for: element, in: rows)
            
            let cell = LiteRTTableCell(
                bounds: element.bounds,
                text: element.text,
                confidence: Double(element.confidence),
                columnIndex: columnIndex,
                rowIndex: rowIndex
            )
            cells.append(cell)
        }
        
        print("[TableStructureDetector] Mapped \(cells.count) cells")
        return cells
    }
    
    /// Detect columns using heuristic approach
    private func detectColumnsHeuristically(from textElements: [TextElement], bounds: CGRect) -> [LiteRTTableColumn] {
        // Group elements by X-coordinate to find column boundaries
        _ = textElements.sorted { $0.bounds.minX < $1.bounds.minX } // Sort for future analysis
        var columns: [LiteRTTableColumn] = []
        
        // Simple column detection based on X-position clustering
        let columnWidth = bounds.width / 3 // Assume 3 columns as default
        
        for i in 0..<3 {
            let columnX = bounds.minX + CGFloat(i) * columnWidth
            let columnBounds = CGRect(
                x: columnX,
                y: bounds.minY,
                width: columnWidth,
                height: bounds.height
            )
            
            let columnType: LiteRTColumnType = i == 0 ? .description : (i == 1 ? .amount : .other)
            
            let column = LiteRTTableColumn(
                bounds: columnBounds,
                headerText: nil,
                columnType: columnType
            )
            columns.append(column)
        }
        
        return columns
    }
    
    /// Determine if elements form a header row
    private func isHeaderRow(elements: [TextElement]) -> Bool {
        let headerKeywords = ["विवरण", "DESCRIPTION", "राशि", "AMOUNT", "SL", "क्रम"]
        
        return elements.contains { element in
            headerKeywords.contains { keyword in
                element.text.localizedCaseInsensitiveContains(keyword)
            }
        }
    }
    
    /// Find column index for a text element
    private func findColumnIndex(for element: TextElement, in columns: [LiteRTTableColumn]) -> Int {
        for (index, column) in columns.enumerated() {
            let elementCenter = CGPoint(x: element.bounds.midX, y: element.bounds.midY)
            if column.bounds.contains(elementCenter) {
                return index
            }
        }
        return 0 // Default to first column
    }
    
    /// Find row index for a text element
    private func findRowIndex(for element: TextElement, in rows: [LiteRTTableRow]) -> Int {
        for (index, row) in rows.enumerated() {
            if abs(row.bounds.midY - element.bounds.midY) < 10 {
                return index
            }
        }
        return 0 // Default to first row
    }
    
    /// Calculate enclosing bounds from multiple rectangles
    private func calculateEnclosingBounds(from bounds: [CGRect], imageSize: CGSize) -> CGRect {
        guard !bounds.isEmpty else {
            return CGRect(origin: .zero, size: imageSize)
        }
        
        let minX = bounds.map { $0.minX }.min() ?? 0
        let minY = bounds.map { $0.minY }.min() ?? 0
        let maxX = bounds.map { $0.maxX }.max() ?? imageSize.width
        let maxY = bounds.map { $0.maxY }.max() ?? imageSize.height
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// Detect PCDA format based on headers and text content
    private func detectPCDAFormat(headers: [BilingualHeader], textElements: [TextElement]) -> Bool {
        // Check for bilingual headers
        let hasBilingualHeaders = !headers.isEmpty
        
        // Check for PCDA-specific keywords
        let allText = textElements.map { $0.text }.joined(separator: " ")
        let hasPCDAKeywords = pcdaKeywords.contains { keyword in
            allText.localizedCaseInsensitiveContains(keyword)
        }
        
        return hasBilingualHeaders && hasPCDAKeywords
    }
    
    /// Determine header type from bilingual text
    private func determineHeaderType(hindi: String, english: String) -> LiteRTColumnType {
        if hindi.contains("विवरण") || english.contains("DESCRIPTION") {
            return .description
        } else if hindi.contains("राशि") || english.contains("AMOUNT") {
            return .amount
        } else if hindi.contains("क्रम") || english.contains("SL") {
            return .code
        }
        return .other
    }
    
    /// Calculate structure confidence based on detection quality
    private func calculateStructureConfidence(tableBounds: CGRect, columns: [LiteRTTableColumn], rows: [LiteRTTableRow], cells: [LiteRTTableCell], isPCDA: Bool) -> Double {
        var confidence = 0.0
        
        // Base confidence from table bounds
        confidence += tableBounds.width > 0 && tableBounds.height > 0 ? 0.2 : 0.0
        
        // Confidence from column detection
        confidence += Double(min(columns.count, 5)) * 0.1
        
        // Confidence from row detection
        confidence += Double(min(rows.count, 10)) * 0.05
        
        // Confidence from cell mapping
        confidence += Double(min(cells.count, 20)) * 0.01
        
        // Bonus for PCDA format detection
        confidence += isPCDA ? 0.2 : 0.0
        
        // Ensure confidence is between 0 and 1
        return min(max(confidence, 0.0), 1.0)
    }
}

// MARK: - Supporting Data Types

/// Bilingual header structure for PCDA documents
public struct BilingualHeader {
    let hindiElement: TextElement
    let englishElement: TextElement
    let combinedBounds: CGRect
    let headerType: LiteRTColumnType
}

/// Table grid structure
public struct TableGrid {
    let grid: [[LiteRTTableCell?]]
    let rowCount: Int
    let columnCount: Int
    let bounds: CGRect
}

// MARK: - Extensions

// CGRect center extension already exists in the project
