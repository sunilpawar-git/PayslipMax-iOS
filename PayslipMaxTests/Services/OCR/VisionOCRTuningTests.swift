import XCTest
@testable import PayslipMax
import CoreGraphics

final class VisionOCRTuningTests: XCTestCase {
    func testPCDADetection_BilingualHeadersAndAmounts() {
        // Arrange: build a realistic bilingual header + four-column grid with a right-side details panel
        var elements: [TextElement] = []
        // Header (y ~ 10)
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 20, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 120, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 220, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 320, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        // Data rows (y ~ 40, 60)
        elements.append(TextElement(text: "BASIC PAY", bounds: CGRect(x: 20, y: 40, width: 100, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "136400", bounds: CGRect(x: 120, y: 40, width: 70, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DSOPF SUBN", bounds: CGRect(x: 220, y: 40, width: 110, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "40000", bounds: CGRect(x: 320, y: 40, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DA", bounds: CGRect(x: 20, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "52000", bounds: CGRect(x: 120, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "AGIF", bounds: CGRect(x: 220, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "5000", bounds: CGRect(x: 320, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        // Details panel to the right (x >= 470)
        elements.append(TextElement(text: "Service No & Name", bounds: CGRect(x: 480, y: 30, width: 160, height: 18), fontSize: 11, confidence: 0.95))

        // Act
        let detector = PCDATableDetector()
        let structure = detector.detectPCDATableStructure(from: elements)

        // Assert
        XCTAssertNotNil(structure)
        XCTAssertGreaterThanOrEqual(structure?.baseStructure.columns.count ?? 0, 4)
        XCTAssertGreaterThanOrEqual(structure?.dataRowCount ?? 0, 2)
        if let grid = structure?.pcdaTableBounds, let panel = structure?.detailsPanelBounds {
            XCTAssertLessThan(grid.maxX, panel.minX, "Grid should end before panel starts")
        }
    }

    func testPCDADetection_WithCustomVocabularyLikeTokens_DoesNotBreakDetection() {
        // Arrange: include tokens we target in customWords (INCM TAX, EDUC CESS, LICENSE FEE) among headers
        var elements: [TextElement] = []
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 20, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 120, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 220, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 320, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "INCM TAX", bounds: CGRect(x: 220, y: 40, width: 110, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "15000", bounds: CGRect(x: 320, y: 40, width: 70, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "EDUC CESS", bounds: CGRect(x: 220, y: 60, width: 110, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "1200", bounds: CGRect(x: 320, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "LICENSE FEE", bounds: CGRect(x: 220, y: 80, width: 130, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "800", bounds: CGRect(x: 320, y: 80, width: 60, height: 20), fontSize: 12, confidence: 0.95))

        // Act
        let detector = PCDATableDetector()
        let structure = detector.detectPCDATableStructure(from: elements)

        // Assert
        XCTAssertNotNil(structure)
        XCTAssertEqual(structure?.baseStructure.columns.count ?? 0, 4)
        XCTAssertGreaterThan(structure?.dataRowCount ?? 0, 0)
    }

    func testPCDABounds_ComputationProducesTightGrid() {
        // Arrange: two data rows under header, check bounds match top/bottom and left/right of the four columns
        var elements: [TextElement] = []
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 40, y: 10, width: 160, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 200, y: 10, width: 100, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 300, y: 10, width: 160, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 460, y: 10, width: 100, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "BPAY", bounds: CGRect(x: 40, y: 40, width: 70, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "100000", bounds: CGRect(x: 200, y: 40, width: 80, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DSOPF", bounds: CGRect(x: 300, y: 40, width: 70, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "20000", bounds: CGRect(x: 460, y: 40, width: 70, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DA", bounds: CGRect(x: 40, y: 60, width: 50, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "40000", bounds: CGRect(x: 200, y: 60, width: 70, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "AGIF", bounds: CGRect(x: 300, y: 60, width: 60, height: 18), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "5000", bounds: CGRect(x: 460, y: 60, width: 60, height: 18), fontSize: 12, confidence: 0.95))

        let detector = PCDATableDetector()
        let structure = detector.detectPCDATableStructure(from: elements)
        XCTAssertNotNil(structure)
        guard let pcda = structure else { return }

        // Expected grid should start near header minY and end at last row maxY
        let expectedTopY = 10.0
        let expectedBottomY = 78.0 // 60 + height 18
        XCTAssertGreaterThanOrEqual(pcda.pcdaTableBounds.minY, expectedTopY - 2.0)
        XCTAssertLessThanOrEqual(pcda.pcdaTableBounds.maxY, expectedBottomY + 2.0)
        // Expected left and right around first and last amount column centers
        XCTAssertLessThan(pcda.pcdaTableBounds.minX, 50.0)
        XCTAssertGreaterThan(pcda.pcdaTableBounds.maxX, 500.0 - 50.0)
    }
}


