import XCTest
@testable import PayslipMax
import CoreGraphics

@MainActor
final class SpatialRelationshipCalculatorTests: XCTestCase {
    
    var calculator: SpatialRelationshipCalculator!
    var configuration: SpatialAnalysisConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        configuration = .payslipDefault
        calculator = SpatialRelationshipCalculator(configuration: configuration)
    }
    
    override func tearDown() async throws {
        calculator = nil
        configuration = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Relationship Tests
    
    func testCalculateRelationshipScore_HorizontallyAligned() async throws {
        // Arrange: Two elements in same row (horizontally aligned)
        let element1 = PositionalElement(
            text: "Name:",
            bounds: CGRect(x: 10, y: 100, width: 50, height: 12),
            type: .label,
            fontSize: 10.0
        )
        let element2 = PositionalElement(
            text: "John Doe",
            bounds: CGRect(x: 70, y: 102, width: 80, height: 12),
            type: .value,
            fontSize: 10.0
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert
        XCTAssertGreaterThan(score.confidence, 0.5, "Horizontally aligned elements should have high confidence")
        XCTAssertTrue([.adjacentHorizontal, .alignedHorizontal].contains(score.relationshipType))
        XCTAssertGreaterThan(score.scoringDetails.horizontalAlignment, 0.7, "Should detect horizontal alignment")
    }
    
    func testCalculateRelationshipScore_VerticallyAligned() async throws {
        // Arrange: Two elements in same column (vertically aligned)
        let element1 = PositionalElement(
            text: "100,000",
            bounds: CGRect(x: 200, y: 100, width: 60, height: 12),
            type: .value,
            fontSize: 10.0
        )
        let element2 = PositionalElement(
            text: "150,000",
            bounds: CGRect(x: 202, y: 130, width: 60, height: 12),
            type: .value,
            fontSize: 10.0
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert
        XCTAssertGreaterThan(score.confidence, 0.4, "Vertically aligned elements should have reasonable confidence")
        XCTAssertTrue([.adjacentVertical, .alignedVertical].contains(score.relationshipType))
        XCTAssertGreaterThan(score.scoringDetails.verticalAlignment, 0.7, "Should detect vertical alignment")
    }
    
    func testCalculateRelationshipScore_UnrelatedElements() async throws {
        // Arrange: Two elements far apart with no alignment
        let element1 = PositionalElement(
            text: "Header",
            bounds: CGRect(x: 10, y: 10, width: 100, height: 16),
            type: .header,
            fontSize: 14.0,
            isBold: true
        )
        let element2 = PositionalElement(
            text: "Footer",
            bounds: CGRect(x: 400, y: 700, width: 80, height: 10),
            type: .label,
            fontSize: 8.0
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert
        XCTAssertLessThan(score.confidence, 0.4, "Unrelated elements should have low confidence")
        XCTAssertEqual(score.relationshipType, .unrelated)
        XCTAssertLessThan(score.scoringDetails.proximityScore, 0.3, "Should detect large distance")
    }
    
    // MARK: - Edge Case Tests
    
    func testCalculateRelationshipScore_IrregularSpacing() async throws {
        // Arrange: Elements with unusual spacing but good alignment
        let element1 = PositionalElement(
            text: "Employee ID:",
            bounds: CGRect(x: 10, y: 100, width: 80, height: 12),
            type: .label,
            fontSize: 10.0
        )
        let element2 = PositionalElement(
            text: "EMP12345",
            bounds: CGRect(x: 150, y: 101, width: 70, height: 12),
            type: .value,
            fontSize: 10.0
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert: Should trust excellent alignment despite distance
        XCTAssertGreaterThan(score.confidence, 0.4, "Good alignment should compensate for distance")
        XCTAssertGreaterThan(score.scoringDetails.horizontalAlignment, 0.8, "Should detect excellent alignment")
    }
    
    func testCalculateRelationshipScore_NoisyPDF() async throws {
        // Arrange: Elements with slight misalignment (noisy PDF)
        let element1 = PositionalElement(
            text: "Basic Pay",
            bounds: CGRect(x: 10, y: 100, width: 60, height: 12),
            type: .label,
            fontSize: 10.0
        )
        let element2 = PositionalElement(
            text: "50000",
            bounds: CGRect(x: 80, y: 103, width: 50, height: 11),
            type: .value,
            fontSize: 10.0
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert: Should still identify relationship despite noise
        XCTAssertGreaterThan(score.confidence, 0.5, "Should handle slight misalignment")
        XCTAssertGreaterThan(score.scoringDetails.horizontalAlignment, 0.6, "Should tolerate noise")
    }
    
    func testCalculateRelationshipScore_MultipleLowFactors() async throws {
        // Arrange: Elements with poor alignment and proximity
        let element1 = PositionalElement(
            text: "Text1",
            bounds: CGRect(x: 10, y: 100, width: 40, height: 12),
            type: .label
        )
        let element2 = PositionalElement(
            text: "Text2",
            bounds: CGRect(x: 200, y: 150, width: 40, height: 12),
            type: .value
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert: Should have reduced confidence (edge case penalty)
        XCTAssertLessThan(score.confidence, 0.35, "Poor alignment and proximity should reduce confidence")
    }
    
    func testCalculateRelationshipScore_MultipleHighFactors() async throws {
        // Arrange: Elements with excellent alignment, proximity, and similarity
        let element1 = PositionalElement(
            text: "Amount:",
            bounds: CGRect(x: 10, y: 100, width: 50, height: 12),
            type: .label,
            fontSize: 10.0,
            isBold: true
        )
        let element2 = PositionalElement(
            text: "1000.00",
            bounds: CGRect(x: 65, y: 100, width: 60, height: 12),
            type: .value,
            fontSize: 10.0,
            isBold: true
        )
        
        // Act
        let score = await calculator.calculateRelationshipScore(between: element1, and: element2)
        
        // Assert: Should get confidence boost for multi-factor agreement
        XCTAssertGreaterThan(score.confidence, 0.7, "Multiple high factors should boost confidence")
        XCTAssertGreaterThan(score.scoringDetails.fontSimilarity, 0.9, "Should detect font similarity")
        XCTAssertGreaterThanOrEqual(score.scoringDetails.proximityScore, 0.7, "Should detect close proximity")
    }
    
    // MARK: - Adaptive Weights Tests
    
    func testAdaptWeightsForElements_TabularLayout() async throws {
        // Arrange: Create tabular layout (multiple elements per row)
        var elements: [PositionalElement] = []
        for row in 0..<5 {
            for col in 0..<4 {
                let element = PositionalElement(
                    text: "Cell\(row)\(col)",
                    bounds: CGRect(x: CGFloat(col * 100), y: CGFloat(row * 20), width: 80, height: 12),
                    type: .tableCell
                )
                elements.append(element)
            }
        }
        
        // Act
        calculator.adaptWeightsForElements(elements)
        
        // Calculate score after adaptation
        let score = await calculator.calculateRelationshipScore(between: elements[0], and: elements[1])
        
        // Assert: Should adapt for tabular layout (no direct way to test weights, test behavior)
        XCTAssertNotNil(score, "Should calculate scores after weight adaptation")
        XCTAssertGreaterThan(score.scoringDetails.horizontalAlignment, 0.0, "Should consider alignment")
    }
    
    func testAdaptWeightsForElements_FreeFormLayout() async throws {
        // Arrange: Create free-form layout (scattered elements)
        let elements = [
            PositionalElement(text: "Title", bounds: CGRect(x: 50, y: 20, width: 100, height: 16), type: .header),
            PositionalElement(text: "Name:", bounds: CGRect(x: 10, y: 100, width: 50, height: 12), type: .label),
            PositionalElement(text: "John", bounds: CGRect(x: 70, y: 102, width: 80, height: 12), type: .value),
            PositionalElement(text: "Address:", bounds: CGRect(x: 10, y: 150, width: 60, height: 12), type: .label),
            PositionalElement(text: "123 St", bounds: CGRect(x: 80, y: 151, width: 100, height: 12), type: .value),
            PositionalElement(text: "Note", bounds: CGRect(x: 10, y: 200, width: 200, height: 10), type: .value)
        ]
        
        // Act
        calculator.adaptWeightsForElements(elements)
        
        // Calculate score after adaptation
        let score = await calculator.calculateRelationshipScore(between: elements[1], and: elements[2])
        
        // Assert: Should adapt for free-form layout
        XCTAssertNotNil(score, "Should calculate scores after weight adaptation")
        XCTAssertGreaterThan(score.scoringDetails.proximityScore, 0.0, "Should consider proximity")
    }
    
    func testAdaptWeightsForElements_InsufficientData() async throws {
        // Arrange: Too few elements for adaptation
        let elements = [
            PositionalElement(text: "A", bounds: CGRect(x: 10, y: 10, width: 20, height: 10), type: .label),
            PositionalElement(text: "B", bounds: CGRect(x: 40, y: 10, width: 20, height: 10), type: .value)
        ]
        
        // Act: Should not crash with insufficient data
        calculator.adaptWeightsForElements(elements)
        
        // Assert: Should still work with default weights
        let score = await calculator.calculateRelationshipScore(between: elements[0], and: elements[1])
        XCTAssertNotNil(score, "Should use default weights for insufficient data")
    }
    
    // MARK: - Confidence Weights Validation Tests
    
    func testConfidenceWeights_Standard() {
        // Assert
        XCTAssertTrue(ConfidenceWeights.standard.isValid, "Standard weights should be valid")
        XCTAssertEqual(ConfidenceWeights.standard.proximity, 0.40)
        XCTAssertEqual(ConfidenceWeights.standard.horizontalAlignment, 0.20)
    }
    
    func testConfidenceWeights_TabularOptimized() {
        // Assert
        XCTAssertTrue(ConfidenceWeights.tabularOptimized.isValid, "Tabular weights should be valid")
        XCTAssertGreaterThan(ConfidenceWeights.tabularOptimized.horizontalAlignment, ConfidenceWeights.standard.horizontalAlignment)
    }
    
    func testConfidenceWeights_FreeFormOptimized() {
        // Assert
        XCTAssertTrue(ConfidenceWeights.freeFormOptimized.isValid, "Free-form weights should be valid")
        XCTAssertGreaterThan(ConfidenceWeights.freeFormOptimized.proximity, ConfidenceWeights.standard.proximity)
    }
}

