import XCTest
@testable import PayslipMax

@MainActor
final class MergedCellDetectorTests: XCTestCase {
    
    var sut: MergedCellDetector!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = MergedCellDetector(configuration: .payslipDefault)
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Horizontal Merged Cell Tests
    
    func testDetectHorizontalMergedCell_WhenElementSpansTwoColumns() {
        // Given: A table with a wide element spanning two columns
        let normalElement1 = createTestElement(text: "Col1", x: 0, y: 0, width: 100, height: 20)
        let mergedElement = createTestElement(text: "Merged Header", x: 150, y: 0, width: 200, height: 20)
        let normalElement2 = createTestElement(text: "Col3", x: 0, y: 30, width: 100, height: 20)
        
        let elements = [normalElement1, mergedElement, normalElement2]
        let columnBoundaries = [
            ColumnBoundary(xPosition: 130, confidence: 0.9, width: 20, detectionMethod: .statistical),
            ColumnBoundary(xPosition: 260, confidence: 0.9, width: 20, detectionMethod: .statistical)
        ]
        let tableBounds = CGRect(x: 0, y: 0, width: 400, height: 50)
        
        // When: Detecting merged cells
        let mergedCells = sut.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
        
        // Then: Should detect one horizontally merged cell
        XCTAssertGreaterThan(mergedCells.count, 0, "Should detect at least one merged cell")
        let horizontalMerges = mergedCells.filter { $0.spanDirection == .horizontal }
        XCTAssertFalse(horizontalMerges.isEmpty, "Should detect horizontal merge")
        
        if let firstMerge = horizontalMerges.first {
            XCTAssertGreaterThan(firstMerge.columnSpan, 1, "Should span multiple columns")
            XCTAssertGreaterThanOrEqual(firstMerge.confidence, 0.6, "Should have reasonable confidence")
        }
    }
    
    func testDetectHorizontalMergedCell_WhenNoMergedCells() {
        // Given: A table with normal-width elements
        let element1 = createTestElement(text: "Col1", x: 0, y: 0, width: 80, height: 20)
        let element2 = createTestElement(text: "Col2", x: 100, y: 0, width: 80, height: 20)
        let element3 = createTestElement(text: "Col3", x: 200, y: 0, width: 80, height: 20)
        
        let elements = [element1, element2, element3]
        let columnBoundaries = [
            ColumnBoundary(xPosition: 90, confidence: 0.9, width: 10, detectionMethod: .statistical),
            ColumnBoundary(xPosition: 190, confidence: 0.9, width: 10, detectionMethod: .statistical)
        ]
        let tableBounds = CGRect(x: 0, y: 0, width: 300, height: 30)
        
        // When: Detecting merged cells
        let mergedCells = sut.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
        
        // Then: Should not detect any merged cells
        let horizontalMerges = mergedCells.filter { $0.spanDirection == .horizontal }
        XCTAssertTrue(horizontalMerges.isEmpty, "Should not detect horizontal merges for normal cells")
    }
    
    // MARK: - Vertical Merged Cell Tests
    
    func testDetectVerticalMergedCell_WhenElementSpansMultipleRows() {
        // Given: A table with a tall element spanning rows
        let normalElement1 = createTestElement(text: "Row1", x: 0, y: 0, width: 100, height: 20)
        let mergedElement = createTestElement(text: "Spanning", x: 0, y: 30, width: 100, height: 60)
        let normalElement2 = createTestElement(text: "Row3", x: 0, y: 100, width: 100, height: 20)
        
        let elements = [normalElement1, mergedElement, normalElement2]
        let columnBoundaries: [ColumnBoundary] = []
        let tableBounds = CGRect(x: 0, y: 0, width: 100, height: 130)
        
        // When: Detecting merged cells
        let mergedCells = sut.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
        
        // Then: Should detect one vertically merged cell
        let verticalMerges = mergedCells.filter { $0.spanDirection == .vertical }
        XCTAssertFalse(verticalMerges.isEmpty, "Should detect vertical merge")
        
        if let firstMerge = verticalMerges.first {
            XCTAssertGreaterThan(firstMerge.rowSpan, 1, "Should span multiple rows")
            XCTAssertGreaterThanOrEqual(firstMerge.confidence, 0.6, "Should have reasonable confidence")
        }
    }
    
    // MARK: - Table Structure Integration Tests
    
    func testDetectMergedCellsInTableStructure() {
        // Given: A complete table structure with merged cells
        let headerElement = createTestElement(text: "Full Width Header", x: 0, y: 0, width: 300, height: 25)
        let col1Row1 = createTestElement(text: "Data1", x: 0, y: 30, width: 90, height: 20)
        let col2Row1 = createTestElement(text: "Data2", x: 100, y: 30, width: 90, height: 20)
        let col3Row1 = createTestElement(text: "Data3", x: 200, y: 30, width: 90, height: 20)
        
        let elements = [headerElement, col1Row1, col2Row1, col3Row1]
        
        let row0 = TableRow(elements: [headerElement], rowIndex: 0)
        let row1 = TableRow(elements: [col1Row1, col2Row1, col3Row1], rowIndex: 1)
        
        let columnBoundaries = [
            ColumnBoundary(xPosition: 95, confidence: 0.9, width: 10, detectionMethod: .statistical),
            ColumnBoundary(xPosition: 195, confidence: 0.9, width: 10, detectionMethod: .statistical)
        ]
        
        let tableStructure = TableStructure(
            rows: [row0, row1],
            columnBoundaries: columnBoundaries,
            bounds: CGRect(x: 0, y: 0, width: 300, height: 60),
            metadata: [:]
        )
        
        // When: Detecting merged cells in table structure
        let mergedCells = sut.detectMergedCells(in: tableStructure)
        
        // Then: Should detect the merged header
        XCTAssertGreaterThan(mergedCells.count, 0, "Should detect merged cells in table")
        let horizontalMerges = mergedCells.filter { $0.spanDirection == .horizontal }
        XCTAssertFalse(horizontalMerges.isEmpty, "Should detect horizontal merge in header")
    }
    
    // MARK: - Edge Cases
    
    func testDetectMergedCells_WithEmptyElements() {
        // Given: Empty elements array
        let elements: [PositionalElement] = []
        let columnBoundaries: [ColumnBoundary] = []
        let tableBounds = CGRect.zero
        
        // When: Detecting merged cells
        let mergedCells = sut.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
        
        // Then: Should return empty array
        XCTAssertTrue(mergedCells.isEmpty, "Should return empty array for empty input")
    }
    
    func testDetectMergedCells_WithSingleElement() {
        // Given: Single element
        let element = createTestElement(text: "Single", x: 0, y: 0, width: 100, height: 20)
        let elements = [element]
        let columnBoundaries: [ColumnBoundary] = []
        let tableBounds = CGRect(x: 0, y: 0, width: 100, height: 20)
        
        // When: Detecting merged cells
        let mergedCells = sut.detectMergedCells(
            from: elements,
            columnBoundaries: columnBoundaries,
            tableBounds: tableBounds
        )
        
        // Then: Should not detect merged cells (no comparison possible)
        XCTAssertTrue(mergedCells.isEmpty, "Should not detect merge with single element")
    }
    
    // MARK: - Confidence Scoring Tests
    
    func testMergedCellInfo_IsHighConfidence() {
        // Given: A merged cell with high confidence
        let element = createTestElement(text: "Merged", x: 0, y: 0, width: 200, height: 20)
        let highConfidenceCell = MergedCellInfo(
            originalElement: element,
            startColumn: 0,
            endColumn: 1,
            startRow: 0,
            endRow: 0,
            columnSpan: 2,
            rowSpan: 1,
            confidence: 0.8,
            spanDirection: .horizontal
        )
        
        // When/Then: Should be high confidence
        XCTAssertTrue(highConfidenceCell.isHighConfidence, "Should be high confidence with 0.8 score")
    }
    
    func testMergedCellInfo_IsNotHighConfidence() {
        // Given: A merged cell with low confidence
        let element = createTestElement(text: "Maybe Merged", x: 0, y: 0, width: 120, height: 20)
        let lowConfidenceCell = MergedCellInfo(
            originalElement: element,
            startColumn: 0,
            endColumn: 1,
            startRow: 0,
            endRow: 0,
            columnSpan: 2,
            rowSpan: 1,
            confidence: 0.5,
            spanDirection: .horizontal
        )
        
        // When/Then: Should not be high confidence
        XCTAssertFalse(lowConfidenceCell.isHighConfidence, "Should not be high confidence with 0.5 score")
    }
    
    func testMergedCellInfo_ToLegacyMergedCell() {
        // Given: A MergedCellInfo instance
        let element = createTestElement(text: "Merged", x: 0, y: 0, width: 200, height: 20)
        let mergedCellInfo = MergedCellInfo(
            originalElement: element,
            startColumn: 0,
            endColumn: 2,
            startRow: 1,
            endRow: 1,
            columnSpan: 3,
            rowSpan: 1,
            confidence: 0.9,
            spanDirection: .horizontal
        )
        
        // When: Converting to legacy type
        let legacyCell = mergedCellInfo.toLegacyMergedCell()
        
        // Then: Should preserve all properties
        XCTAssertEqual(legacyCell.startColumn, 0)
        XCTAssertEqual(legacyCell.endColumn, 2)
        XCTAssertEqual(legacyCell.startRow, 1)
        XCTAssertEqual(legacyCell.endRow, 1)
        XCTAssertEqual(legacyCell.columnSpan, 3)
        XCTAssertEqual(legacyCell.rowSpan, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestElement(
        text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> PositionalElement {
        return PositionalElement(
            text: text,
            bounds: CGRect(x: x, y: y, width: width, height: height),
            type: .tableCell,
            confidence: 0.9,
            metadata: [:],
            fontSize: 12.0,
            isBold: false,
            pageIndex: 0
        )
    }
}

