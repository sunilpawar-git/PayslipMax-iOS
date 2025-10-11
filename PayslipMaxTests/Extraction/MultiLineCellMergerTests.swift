import XCTest
@testable import PayslipMax
import CoreGraphics

/// Tests for multi-line cell merging functionality
final class MultiLineCellMergerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: MultiLineCellMerger!
    private var clusterAnalyzer: VerticalClusterAnalyzer!
    private var configuration: RowAssociationConfiguration!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        configuration = .payslipDefault
        clusterAnalyzer = VerticalClusterAnalyzer(configuration: configuration)
        sut = MultiLineCellMerger(clusterAnalyzer: clusterAnalyzer)
    }
    
    override func tearDown() {
        sut = nil
        clusterAnalyzer = nil
        configuration = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testMergeMultiLineElements_EmptyRow_ReturnsEmptyRow() async throws {
        // Given
        let emptyRow = createTableRow(with: [])
        
        // When
        let result = try await sut.mergeMultiLineElements(in: emptyRow, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 0)
    }
    
    func testMergeMultiLineElements_SingleLineRow_ReturnsUnchanged() async throws {
        // Given
        let elements = [
            createPositionalElement(text: "BPAY", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "144700", x: 100, y: 100, width: 60, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 2)
        XCTAssertEqual(result.elements[0].text, "BPAY")
        XCTAssertEqual(result.elements[1].text, "144700")
    }
    
    func testMergeMultiLineElements_TwoLineCell_MergesCorrectly() async throws {
        // Given: Two elements in same column, vertically adjacent
        let elements = [
            // Column 1: Multi-line label
            createPositionalElement(text: "ARR", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "TPTA", x: 10, y: 118, width: 50, height: 15), // 3 points gap
            // Column 2: Single line value
            createPositionalElement(text: "3600", x: 100, y: 109, width: 60, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 2, "Should have 2 elements after merging")
        
        // Find the merged element (should contain both "ARR" and "TPTA")
        let mergedElement = result.elements.first { $0.text.contains("ARR") && $0.text.contains("TPTA") }
        XCTAssertNotNil(mergedElement, "Should find merged element")
        XCTAssertTrue(mergedElement?.text.contains("ARR") ?? false)
        XCTAssertTrue(mergedElement?.text.contains("TPTA") ?? false)
        XCTAssertEqual(mergedElement?.metadata["multiLineSource"], "merged")
    }
    
    func testMergeMultiLineElements_ThreeLineCell_MergesAllLines() async throws {
        // Given: Three elements in same column, vertically adjacent
        let elements = [
            // Column 1: Three-line label
            createPositionalElement(text: "SPECIAL", x: 10, y: 100, width: 60, height: 15),
            createPositionalElement(text: "ALLOWANCE", x: 10, y: 118, width: 60, height: 15),
            createPositionalElement(text: "ARREARS", x: 10, y: 136, width: 60, height: 15),
            // Column 2: Single line value
            createPositionalElement(text: "15000", x: 100, y: 118, width: 60, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 2, "Should have 2 elements after merging")
        
        // Find the merged element
        let mergedElement = result.elements.first {
            $0.text.contains("SPECIAL") && $0.text.contains("ALLOWANCE") && $0.text.contains("ARREARS")
        }
        XCTAssertNotNil(mergedElement, "Should find three-line merged element")
        XCTAssertEqual(mergedElement?.metadata["elementCount"], "3")
    }
    
    func testMergeMultiLineElements_MultipleColumns_MergesIndependently() async throws {
        // Given: Two columns, both with multi-line content
        let elements = [
            // Column 1: Two-line label
            createPositionalElement(text: "HOUSE", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "RENT", x: 10, y: 118, width: 50, height: 15),
            // Column 2: Two-line value
            createPositionalElement(text: "ALLOWANCE", x: 100, y: 100, width: 70, height: 15),
            createPositionalElement(text: "24000", x: 100, y: 118, width: 70, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 2, "Should have 2 elements after merging both columns")
        
        // Check first merged element
        let firstMerged = result.elements.first { $0.text.contains("HOUSE") && $0.text.contains("RENT") }
        XCTAssertNotNil(firstMerged)
        
        // Check second merged element
        let secondMerged = result.elements.first { $0.text.contains("ALLOWANCE") && $0.text.contains("24000") }
        XCTAssertNotNil(secondMerged)
    }
    
    func testMergeMultiLineElements_LargeGap_DoesNotMerge() async throws {
        // Given: Two elements in same column but with large vertical gap
        let elements = [
            createPositionalElement(text: "BPAY", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "MSP", x: 10, y: 150, width: 50, height: 15), // 35 points gap - too large
            createPositionalElement(text: "144700", x: 100, y: 100, width: 60, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.elements.count, 3, "Should not merge elements with large gap")
    }
    
    func testMergeMultiLineElements_PreservesReadingOrder() async throws {
        // Given: Multi-line elements in multiple columns
        let elements = [
            // Column 1
            createPositionalElement(text: "ARR", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "TPTA", x: 10, y: 118, width: 50, height: 15),
            // Column 2
            createPositionalElement(text: "3600", x: 100, y: 100, width: 60, height: 15),
            // Column 3
            createPositionalElement(text: "DSOP", x: 200, y: 100, width: 50, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then - Should be in left-to-right order
        XCTAssertEqual(result.elements.count, 3)
        XCTAssertTrue(result.elements[0].center.x < result.elements[1].center.x)
        XCTAssertTrue(result.elements[1].center.x < result.elements[2].center.x)
    }
    
    func testMergeMultiLineElements_UpdatesRowMetadata() async throws {
        // Given
        let elements = [
            createPositionalElement(text: "ARR", x: 10, y: 100, width: 50, height: 15),
            createPositionalElement(text: "TPTA", x: 10, y: 118, width: 50, height: 15)
        ]
        let row = createTableRow(with: elements)
        
        // When
        let result = try await sut.mergeMultiLineElements(in: row, toleranceRatio: 0.3)
        
        // Then
        XCTAssertEqual(result.metadata["multiLineMerged"], "true")
    }
    
    // MARK: - Helper Methods
    
    private func createPositionalElement(
        text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> PositionalElement {
        return PositionalElement(
            text: text,
            bounds: CGRect(x: x, y: y, width: width, height: height),
            type: .label,
            confidence: 0.9,
            metadata: [:],
            fontSize: 12.0,
            isBold: false,
            pageIndex: 0
        )
    }
    
    private func createTableRow(with elements: [PositionalElement]) -> TableRow {
        // TableRow initializer automatically calculates yPosition and bounds
        return TableRow(
            elements: elements,
            rowIndex: 0,
            metadata: [:]
        )
    }
}

