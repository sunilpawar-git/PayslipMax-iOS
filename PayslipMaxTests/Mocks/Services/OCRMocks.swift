import XCTest
import Vision
import UIKit
@testable import PayslipMax

// MARK: - Shared OCR Mock Classes

/// Shared mock for AdvancedImageProcessor used across OCR tests
class MockAdvancedImageProcessor: AdvancedImageProcessor {
    
    var optimizeForOCRCalled = false
    var rectifyDocumentCalled = false
    var mockRectifiedImage: UIImage?
    var mockOptimizedImage: UIImage?
    
    override func optimizeForOCR(_ image: UIImage) -> UIImage {
        optimizeForOCRCalled = true
        // Return mock image if set, otherwise original image
        return mockOptimizedImage ?? image
    }
    
    override func rectifyDocument(_ image: UIImage, bounds: VNRectangleObservation?) -> UIImage {
        rectifyDocumentCalled = true
        // Return mock image if set, otherwise original image
        return mockRectifiedImage ?? image
    }
}

/// Mock for DocumentDetectionService
class MockDocumentDetectionService: DocumentDetectionService {
    
    var detectDocumentBoundsCalled = false
    var mockBounds: VNRectangleObservation?
    
    override func detectDocumentBounds(in image: UIImage) async -> VNRectangleObservation? {
        detectDocumentBoundsCalled = true
        return mockBounds
    }
}

/// Mock for ConfidenceCalculator
class MockConfidenceCalculator: ConfidenceCalculatorProtocol {
    
    var calculateConfidenceCalled = false
    var mockConfidence: Double = 0.8
    
    func calculateConfidence(from observations: [VNRecognizedTextObservation]) -> Double {
        calculateConfidenceCalled = true
        return mockConfidence
    }
}

/// Mock for LanguageDetector
class MockLanguageDetector: LanguageDetectorProtocol {
    
    var detectLanguageCalled = false
    var mockLanguage: String = "en-US"
    
    func detectLanguage(in text: String) -> String {
        detectLanguageCalled = true
        return mockLanguage
    }
}

/// Mock for GeometricTextAnalyzer
class MockGeometricTextAnalyzer: GeometricTextAnalyzer {
    
    var mockTableStructure: TableStructure?
    var mockStructuredData: StructuredTableData?
    var mockGeometricResult: GeometricTextResult?
    
    var buildTableStructureCalled = false
    var associateTextCalled = false
    
    override func buildTableStructure(
        textRectangles: [VNRecognizedTextObservation],
        documentSegments: [VNRectangleObservation]
    ) -> TableStructure {
        buildTableStructureCalled = true
        return mockTableStructure ?? createDefaultMockTableStructure()
    }
    
    private func createDefaultMockTableStructure() -> TableStructure {
        // Create a simple 2x2 table structure for testing
        let cells = [
            [createMockTableCell(row: 0, col: 0, text: "CREDIT"), createMockTableCell(row: 0, col: 1, text: "AMOUNT")],
            [createMockTableCell(row: 1, col: 0, text: "BASIC PAY"), createMockTableCell(row: 1, col: 1, text: "15000.00")]
        ]
        
        return TableStructure(regions: [], columns: [], rows: [], cells: cells)
    }
    
    private func createMockTableCell(row: Int, col: Int, text: String) -> TableCell {
        return TableCell(
            position: CellPosition(row: row, column: col),
            boundingBox: CGRect(x: Double(col) * 100, y: Double(row) * 50, width: 100, height: 50),
            observations: [], // Empty for now since we can't mock VNRecognizedTextObservation easily
            cellType: text.contains("AMOUNT") || text.contains("PAY") ? .code : .header,
            confidence: 0.9
        )
    }
    
    override func associateTextWithTableStructure(
        _ textResult: GeometricTextResult,
        _ tableStructure: TableStructure
    ) -> StructuredTableData {
        associateTextCalled = true
        return mockStructuredData ?? StructuredTableData()
    }
    
    override func analyzeTextGeometry(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> GeometricTextResult {
        return mockGeometricResult ?? GeometricTextResult.empty
    }
}

/// Mock CellExtractionService for testing
class MockCellExtractionService: CellExtractionService {
    
    var mockResult: CellExtractionResult?
    
    override func extractTextFromCells(
        _ cellMatrix: [[TableCell]],
        originalImage: UIImage
    ) async -> CellExtractionResult {
        
        // Return mock result if set, otherwise create a default one
        if let mockResult = mockResult {
            return mockResult
        }
        
        // Create a simple mock result - avoid complex structure creation for testing
        let extractedCells = cellMatrix.enumerated().map { (rowIndex, row) in
            row.enumerated().map { (colIndex, cell) in
                // Smart mock text based on cell type
                let mockText: String
                switch cell.cellType {
                case .amount:
                    mockText = "1500.00"
                case .total:
                    mockText = "3000.00"
                case .header:
                    mockText = "HEADER \(rowIndex),\(colIndex)"
                case .code:
                    mockText = "CODE\(rowIndex)\(colIndex)"
                case .empty:
                    mockText = ""
                case .unknown:
                    mockText = "Mock \(rowIndex),\(colIndex)"
                }
                return ExtractedCellData(
                    position: CellPosition(row: rowIndex, column: colIndex),
                    rawText: mockText,
                    processedText: mockText,
                    confidence: 0.9,
                    cellType: cell.cellType,
                    validationResult: CellValidationResult(
                        isValid: true,
                        errors: [],
                        confidenceAdjustment: 1.0
                    ),
                    boundingBox: cell.boundingBox,
                    textCandidates: [TextCandidate(text: mockText, confidence: 0.9, boundingBox: cell.boundingBox)],
                    metadata: CellMetadata(
                        multiLine: false,
                        hasNumericContent: mockText.range(of: #"[\d.]"#, options: .regularExpression) != nil,
                        languageDetection: .english
                    )
                )
            }
        }
        
        return CellExtractionResult(
            extractedCells: extractedCells,
            metrics: CellProcessingMetrics(
                totalCellsProcessed: cellMatrix.flatMap { $0 }.count,
                successfulExtractions: cellMatrix.flatMap { $0 }.count,
                totalProcessingTime: 0.1
            ),
            overallConfidence: 0.9
        )
    }
}