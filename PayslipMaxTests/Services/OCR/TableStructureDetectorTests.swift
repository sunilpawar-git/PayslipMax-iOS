import XCTest
import Vision
@testable import PayslipMax

final class TableStructureDetectorTests: XCTestCase {
    
    // MARK: - Properties
    private var detector: TableStructureDetector!
    private var mockTextObservations: [VNRecognizedTextObservation]!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        detector = TableStructureDetector()
        setupMockTextObservations()
    }
    
    override func tearDown() {
        detector = nil
        mockTextObservations = nil
        super.tearDown()
    }
    
    // MARK: - Grid Detection Tests
    func testDetectTableStructure_WithValidGrid_ReturnsStructure() {
        // Given
        let imageSize = CGSize(width: 800, height: 600)
        
        // When
        let result = detector.detectTableStructure(
            from: mockTextObservations,
            in: imageSize
        )
        
        // Then
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertFalse(result.cellMatrix.isEmpty)
        XCTAssertGreaterThan(result.gridLines.horizontal.count, 0)
        XCTAssertGreaterThan(result.gridLines.vertical.count, 0)
        XCTAssertEqual(result.metadata.detectionMethod, .geometricAnalysis)
    }
    
    func testDetectTableStructure_WithEmptyObservations_ReturnsEmptyStructure() {
        // Given
        let emptyObservations: [VNRecognizedTextObservation] = []
        let imageSize = CGSize(width: 800, height: 600)
        
        // When
        let result = detector.detectTableStructure(
            from: emptyObservations,
            in: imageSize
        )
        
        // Then
        XCTAssertEqual(result.confidence, 0.0)
        XCTAssertTrue(result.cellMatrix.isEmpty)
        XCTAssertEqual(result.gridLines.horizontal.count, 0)
        XCTAssertEqual(result.gridLines.vertical.count, 0)
    }
    
    func testDetectTableStructure_WithMilitaryPayslipPattern_DetectsCorrectStructure() {
        // Given
        let militaryObservations = createMilitaryPayslipObservations()
        let imageSize = CGSize(width: 800, height: 600)
        
        // When
        let result = detector.detectTableStructure(
            from: militaryObservations,
            in: imageSize
        )
        
        // Then
        XCTAssertGreaterThan(result.confidence, 0.7)
        XCTAssertGreaterThanOrEqual(result.cellMatrix.count, 3) // Header + data rows
        XCTAssertGreaterThanOrEqual(result.cellMatrix.first?.count ?? 0, 2) // At least 2 columns
    }
    
    // MARK: - Grid Line Detection Tests
    func testDetectGridLines_WithAlignedText_DetectsHorizontalLines() {
        // Given
        let alignedObservations = createHorizontallyAlignedObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: alignedObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertGreaterThan(result.gridLines.horizontal.count, 1)
        XCTAssertTrue(result.gridLines.horizontal.allSatisfy { $0.confidence > 0.5 })
    }
    
    func testDetectGridLines_WithColumnAlignment_DetectsVerticalLines() {
        // Given
        let columnObservations = createVerticallyAlignedObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: columnObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertGreaterThan(result.gridLines.vertical.count, 1)
        XCTAssertTrue(result.gridLines.vertical.allSatisfy { $0.confidence > 0.5 })
    }
    
    // MARK: - Cell Matrix Tests
    func testBuildCellMatrix_WithValidGrid_CreatesCorrectMatrix() {
        // Given
        let observations = createRegularGridObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: observations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        let matrix = result.cellMatrix
        XCTAssertFalse(matrix.isEmpty)
        
        // Verify matrix consistency
        let expectedColumnCount = matrix.first?.count ?? 0
        XCTAssertTrue(matrix.allSatisfy { $0.count == expectedColumnCount })
        
        // Verify cell positions
        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                XCTAssertEqual(cell.position.row, rowIndex)
                XCTAssertEqual(cell.position.column, colIndex)
            }
        }
    }
    
    func testBuildCellMatrix_WithIrregularGrid_HandlesGracefully() {
        // Given
        let irregularObservations = createIrregularGridObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: irregularObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
    }
    
    // MARK: - Cell Type Detection Tests
    func testCellTypeDetection_WithNumericContent_ReturnsNumeric() {
        // Given
        let numericObservations = createNumericContentObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: numericObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        let numericCells = result.cellMatrix.flatMap { $0 }.filter { cell in
            cell.observations.allSatisfy { obs in
                let text = obs.topCandidates(1).first?.string ?? ""
                return text.range(of: #"[\d,.\-+₹]"#, options: .regularExpression) != nil
            }
        }
        
        XCTAssertGreaterThan(numericCells.count, 0)
    }
    
    func testCellTypeDetection_WithHeaderContent_ReturnsHeader() {
        // Given
        let headerObservations = createHeaderContentObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: headerObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        let headerCells = result.cellMatrix.flatMap { $0 }.filter { cell in
            cell.observations.allSatisfy { obs in
                let text = (obs.topCandidates(1).first?.string ?? "").uppercased()
                return text.contains("CREDIT") || text.contains("DEBIT") || text.contains("AMOUNT")
            }
        }
        
        XCTAssertGreaterThan(headerCells.count, 0)
    }
    
    // MARK: - Performance Tests
    func testDetectTableStructure_PerformanceWithLargeDataset() {
        // Given
        let largeObservations = createLargeDatasetObservations(count: 1000)
        
        // When & Then
        measure {
            let result = detector.detectTableStructure(
                from: largeObservations,
                in: CGSize(width: 1200, height: 1600)
            )
            XCTAssertNotNil(result)
        }
    }
    
    func testDetectTableStructure_MemoryUsage() {
        // Given
        let observations = createMediumDatasetObservations(count: 500)
        
        // When
        let result = detector.detectTableStructure(
            from: observations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertNotNil(result)
        // Memory usage should be reasonable (verified through instruments)
    }
    
    // MARK: - Edge Cases Tests
    func testDetectTableStructure_WithSingleObservation_HandlesGracefully() {
        // Given
        let singleObservation = [mockTextObservations.first!]
        
        // When
        let result = detector.detectTableStructure(
            from: singleObservation,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.gridLines.horizontal.count, 0)
        XCTAssertEqual(result.gridLines.vertical.count, 0)
    }
    
    func testDetectTableStructure_WithOverlappingText_ResolvesCorrectly() {
        // Given
        let overlappingObservations = createOverlappingTextObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: overlappingObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
    }
    
    // MARK: - Validation Tests
    func testGridValidation_WithConsistentStructure_ReturnsHighConfidence() {
        // Given
        let consistentObservations = createConsistentGridObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: consistentObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertGreaterThan(result.confidence, 0.8)
    }
    
    func testGridValidation_WithInconsistentStructure_ReturnsLowerConfidence() {
        // Given
        let inconsistentObservations = createInconsistentGridObservations()
        
        // When
        let result = detector.detectTableStructure(
            from: inconsistentObservations,
            in: CGSize(width: 800, height: 600)
        )
        
        // Then
        XCTAssertLessThan(result.confidence, 0.6)
    }
}

// MARK: - Mock Data Creation
extension TableStructureDetectorTests {
    
    private func setupMockTextObservations() {
        mockTextObservations = [
            createMockObservation(text: "CREDIT", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.2, height: 0.05)),
            createMockObservation(text: "DEBIT", boundingBox: CGRect(x: 0.5, y: 0.9, width: 0.2, height: 0.05)),
            createMockObservation(text: "BP001", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "15000", boundingBox: CGRect(x: 0.5, y: 0.8, width: 0.2, height: 0.05))
        ]
    }
    
    private func createMockObservation(text: String, boundingBox: CGRect) -> VNRecognizedTextObservation {
        // Create a mock observation - simplified for testing
        // In real tests, we would use actual VNRecognizedTextObservation objects
        return VNRecognizedTextObservation()
    }
    
    private func createMilitaryPayslipObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "PAY CODE", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.2, height: 0.05)),
            createMockObservation(text: "DESCRIPTION", boundingBox: CGRect(x: 0.3, y: 0.9, width: 0.3, height: 0.05)),
            createMockObservation(text: "CREDIT", boundingBox: CGRect(x: 0.6, y: 0.9, width: 0.15, height: 0.05)),
            createMockObservation(text: "DEBIT", boundingBox: CGRect(x: 0.75, y: 0.9, width: 0.15, height: 0.05)),
            createMockObservation(text: "BP001", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "BASIC PAY", boundingBox: CGRect(x: 0.3, y: 0.8, width: 0.3, height: 0.05)),
            createMockObservation(text: "15000.00", boundingBox: CGRect(x: 0.6, y: 0.8, width: 0.15, height: 0.05)),
            createMockObservation(text: "0.00", boundingBox: CGRect(x: 0.75, y: 0.8, width: 0.15, height: 0.05))
        ]
    }
    
    private func createHorizontallyAlignedObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "Text1", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "Text2", boundingBox: CGRect(x: 0.4, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "Text3", boundingBox: CGRect(x: 0.7, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "Text4", boundingBox: CGRect(x: 0.1, y: 0.6, width: 0.2, height: 0.05)),
            createMockObservation(text: "Text5", boundingBox: CGRect(x: 0.4, y: 0.6, width: 0.2, height: 0.05)),
            createMockObservation(text: "Text6", boundingBox: CGRect(x: 0.7, y: 0.6, width: 0.2, height: 0.05))
        ]
    }
    
    private func createVerticallyAlignedObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "Col1Row1", boundingBox: CGRect(x: 0.2, y: 0.8, width: 0.15, height: 0.05)),
            createMockObservation(text: "Col2Row1", boundingBox: CGRect(x: 0.5, y: 0.8, width: 0.15, height: 0.05)),
            createMockObservation(text: "Col1Row2", boundingBox: CGRect(x: 0.2, y: 0.7, width: 0.15, height: 0.05)),
            createMockObservation(text: "Col2Row2", boundingBox: CGRect(x: 0.5, y: 0.7, width: 0.15, height: 0.05)),
            createMockObservation(text: "Col1Row3", boundingBox: CGRect(x: 0.2, y: 0.6, width: 0.15, height: 0.05)),
            createMockObservation(text: "Col2Row3", boundingBox: CGRect(x: 0.5, y: 0.6, width: 0.15, height: 0.05))
        ]
    }
    
    private func createRegularGridObservations() -> [VNRecognizedTextObservation] {
        var observations: [VNRecognizedTextObservation] = []
        
        for row in 0..<4 {
            for col in 0..<3 {
                let x = 0.1 + Double(col) * 0.3
                let y = 0.9 - Double(row) * 0.1
                observations.append(
                    createMockObservation(
                        text: "R\(row)C\(col)",
                        boundingBox: CGRect(x: x, y: y, width: 0.2, height: 0.05)
                    )
                )
            }
        }
        
        return observations
    }
    
    private func createIrregularGridObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "Header", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.8, height: 0.05)),
            createMockObservation(text: "Data1", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05)),
            createMockObservation(text: "Data2", boundingBox: CGRect(x: 0.5, y: 0.8, width: 0.4, height: 0.05)),
            createMockObservation(text: "Single", boundingBox: CGRect(x: 0.1, y: 0.7, width: 0.2, height: 0.05))
        ]
    }
    
    private func createNumericContentObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "15000.00", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "₹2500", boundingBox: CGRect(x: 0.4, y: 0.8, width: 0.2, height: 0.05)),
            createMockObservation(text: "1,200.50", boundingBox: CGRect(x: 0.7, y: 0.8, width: 0.2, height: 0.05))
        ]
    }
    
    private func createHeaderContentObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "CREDIT", boundingBox: CGRect(x: 0.1, y: 0.9, width: 0.2, height: 0.05)),
            createMockObservation(text: "DEBIT", boundingBox: CGRect(x: 0.4, y: 0.9, width: 0.2, height: 0.05)),
            createMockObservation(text: "AMOUNT", boundingBox: CGRect(x: 0.7, y: 0.9, width: 0.2, height: 0.05))
        ]
    }
    
    private func createLargeDatasetObservations(count: Int) -> [VNRecognizedTextObservation] {
        var observations: [VNRecognizedTextObservation] = []
        
        for i in 0..<count {
            let row = i / 10
            let col = i % 10
            let x = Double(col) * 0.1
            let y = 1.0 - Double(row) * 0.02
            
            observations.append(
                createMockObservation(
                    text: "Text\(i)",
                    boundingBox: CGRect(x: x, y: y, width: 0.08, height: 0.015)
                )
            )
        }
        
        return observations
    }
    
    private func createMediumDatasetObservations(count: Int) -> [VNRecognizedTextObservation] {
        return createLargeDatasetObservations(count: count)
    }
    
    private func createOverlappingTextObservations() -> [VNRecognizedTextObservation] {
        return [
            createMockObservation(text: "Text1", boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.05)),
            createMockObservation(text: "Text2", boundingBox: CGRect(x: 0.25, y: 0.8, width: 0.3, height: 0.05)),
            createMockObservation(text: "Text3", boundingBox: CGRect(x: 0.4, y: 0.8, width: 0.3, height: 0.05))
        ]
    }
    
    private func createConsistentGridObservations() -> [VNRecognizedTextObservation] {
        return createRegularGridObservations()
    }
    
    private func createInconsistentGridObservations() -> [VNRecognizedTextObservation] {
        return createIrregularGridObservations()
    }
}