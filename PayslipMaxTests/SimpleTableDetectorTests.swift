import XCTest
import CoreGraphics
@testable import PayslipMax

class SimpleTableDetectorTests: XCTestCase {
    
    var tableDetector: SimpleTableDetector!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        tableDetector = SimpleTableDetector()
    }
    
    override func tearDownWithError() throws {
        tableDetector = nil
        try super.tearDownWithError()
    }
    
    func testDetectTableStructure_WithSimpleGrid_ReturnsValidStructure() {
        let textElements = createSimpleGridElements()
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rows.count, 3)
        XCTAssertEqual(result?.columns.count, 2)
    }
    
    func testDetectTableStructure_WithEmptyArray_ReturnsNil() {
        let textElements: [TextElement] = []
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNil(result)
    }
    
    func testDetectTableStructure_WithSingleElement_ReturnsNil() {
        let textElements = [
            TextElement(text: "Single", bounds: CGRect(x: 0, y: 0, width: 50, height: 20), fontSize: 12, confidence: 0.9)
        ]
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNil(result)
    }
    
    func testDetectTableStructure_WithMilitaryPayslipFormat_DetectsTable() {
        let textElements = createMilitaryPayslipElements()
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result?.rows.count ?? 0, 2)
        XCTAssertGreaterThanOrEqual(result?.columns.count ?? 0, 2)
    }
    
    func testAnalyzeTableMetrics_WithValidStructure_ReturnsMetrics() {
        let textElements = createSimpleGridElements()
        guard let structure = tableDetector.detectTableStructure(from: textElements) else {
            XCTFail("Failed to detect table structure")
            return
        }
        
        let metrics = tableDetector.analyzeTableMetrics(structure: structure)
        
        XCTAssertEqual(metrics.rowCount, 3)
        XCTAssertEqual(metrics.columnCount, 2)
        XCTAssertGreaterThan(metrics.averageRowHeight, 0)
        XCTAssertGreaterThan(metrics.averageColumnWidth, 0)
        XCTAssertGreaterThan(metrics.tableArea, 0)
    }
    
    func testDetectTableStructure_WithAlignedElements_DetectsColumns() {
        let textElements = [
            TextElement(text: "Credit", bounds: CGRect(x: 50, y: 10, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Debit", bounds: CGRect(x: 150, y: 10, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "BPAY", bounds: CGRect(x: 50, y: 40, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "DSOP", bounds: CGRect(x: 150, y: 40, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "50000", bounds: CGRect(x: 50, y: 70, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "5000", bounds: CGRect(x: 150, y: 70, width: 40, height: 20), fontSize: 12, confidence: 0.9)
        ]
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.columns.count, 2)
        XCTAssertEqual(result?.rows.count, 3)
    }
    
    func testDetectTableStructure_WithMisalignedElements_HandlesGracefully() {
        let textElements = [
            TextElement(text: "Item1", bounds: CGRect(x: 10, y: 10, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Item2", bounds: CGRect(x: 45, y: 35, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Item3", bounds: CGRect(x: 80, y: 60, width: 50, height: 20), fontSize: 12, confidence: 0.9)
        ]
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNotNil(result)
    }
    
    func testDetectTableStructure_WithPCDAFormat_DetectsStructure() {
        let textElements = createPCDAFormatElements()
        
        let result = tableDetector.detectTableStructure(from: textElements)
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result?.rows.count ?? 0, 3)
        XCTAssertGreaterThanOrEqual(result?.columns.count ?? 0, 2)
    }

    func testDetectPCDATableStructure_BilingualHeaders_And_FourColumnInference() throws {
        // Create a realistic 4-column PCDA grid with bilingual headers and a right details panel
        // Columns: desc(20), amount(120), desc(220), amount(320)
        var elements: [TextElement] = []
        // Header row bilingual tokens
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 20, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 120, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 220, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 320, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        // Data rows
        elements.append(TextElement(text: "BASIC PAY", bounds: CGRect(x: 20, y: 40, width: 90, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "136400", bounds: CGRect(x: 120, y: 40, width: 70, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DSOPF SUBN", bounds: CGRect(x: 220, y: 40, width: 100, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "40000", bounds: CGRect(x: 320, y: 40, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DA", bounds: CGRect(x: 20, y: 70, width: 40, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "60000", bounds: CGRect(x: 120, y: 70, width: 70, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "AGIF", bounds: CGRect(x: 220, y: 70, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "4500", bounds: CGRect(x: 320, y: 70, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        // Right details panel (simulate name/address block)
        elements.append(TextElement(text: "Service No: 123456A", bounds: CGRect(x: 460, y: 35, width: 160, height: 18), fontSize: 11, confidence: 0.9))
        elements.append(TextElement(text: "Rank: Captain", bounds: CGRect(x: 460, y: 58, width: 120, height: 18), fontSize: 11, confidence: 0.9))
        elements.append(TextElement(text: "Unit: Signals", bounds: CGRect(x: 460, y: 81, width: 120, height: 18), fontSize: 11, confidence: 0.9))
        
        let pcda = tableDetector.detectPCDATableStructure(from: elements)
        XCTAssertNotNil(pcda)
        guard let pcda = pcda else { return }
        
        // Verify 4-column inference: credit desc/amount then debit desc/amount
        XCTAssertEqual(pcda.creditColumns.description, 0)
        XCTAssertEqual(pcda.creditColumns.amount, 1)
        XCTAssertEqual(pcda.debitColumns.description, 2)
        XCTAssertEqual(pcda.debitColumns.amount, 3)
        
        // Verify strict grid bounds exclude details panel and panel is detected
        XCTAssertTrue(pcda.pcdaTableBounds.maxX < (pcda.detailsPanelBounds?.minX ?? CGFloat.greatestFiniteMagnitude))
        XCTAssertNotNil(pcda.detailsPanelBounds)
    }

    func testDetectPCDATableStructure_NoDetailsPanel_ReturnsNilPanelBounds() throws {
        var elements: [TextElement] = []
        // Headers
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 30, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 140, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "विवरण/DESCRIPTION", bounds: CGRect(x: 260, y: 10, width: 180, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "राशि/AMOUNT", bounds: CGRect(x: 370, y: 10, width: 120, height: 20), fontSize: 12, confidence: 0.95))
        // Data rows
        elements.append(TextElement(text: "BASIC PAY", bounds: CGRect(x: 30, y: 40, width: 90, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "136400", bounds: CGRect(x: 140, y: 40, width: 70, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "DSOPF SUBN", bounds: CGRect(x: 260, y: 40, width: 100, height: 20), fontSize: 12, confidence: 0.95))
        elements.append(TextElement(text: "40000", bounds: CGRect(x: 370, y: 40, width: 60, height: 20), fontSize: 12, confidence: 0.95))
        
        let pcda = tableDetector.detectPCDATableStructure(from: elements)
        XCTAssertNotNil(pcda)
        XCTAssertNil(pcda?.detailsPanelBounds)
    }
    
    // MARK: - Helper Methods
    
    private func createSimpleGridElements() -> [TextElement] {
        return [
            TextElement(text: "Header1", bounds: CGRect(x: 0, y: 0, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Header2", bounds: CGRect(x: 100, y: 0, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Row1Col1", bounds: CGRect(x: 0, y: 30, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Row1Col2", bounds: CGRect(x: 100, y: 30, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Row2Col1", bounds: CGRect(x: 0, y: 60, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Row2Col2", bounds: CGRect(x: 100, y: 60, width: 80, height: 20), fontSize: 12, confidence: 0.9)
        ]
    }
    
    private func createMilitaryPayslipElements() -> [TextElement] {
        return [
            TextElement(text: "CREDIT", bounds: CGRect(x: 50, y: 10, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "DEBIT", bounds: CGRect(x: 200, y: 10, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "BPAY", bounds: CGRect(x: 50, y: 40, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "50000.00", bounds: CGRect(x: 110, y: 40, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "DSOP", bounds: CGRect(x: 200, y: 40, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "5000.00", bounds: CGRect(x: 250, y: 40, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "HRA", bounds: CGRect(x: 50, y: 70, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "15000.00", bounds: CGRect(x: 110, y: 70, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "ITAX", bounds: CGRect(x: 200, y: 70, width: 40, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "8000.00", bounds: CGRect(x: 250, y: 70, width: 60, height: 20), fontSize: 12, confidence: 0.9)
        ]
    }
    
    private func createPCDAFormatElements() -> [TextElement] {
        return [
            TextElement(text: "PCDA STATEMENT", bounds: CGRect(x: 50, y: 0, width: 120, height: 20), fontSize: 14, confidence: 0.9),
            TextElement(text: "Description", bounds: CGRect(x: 20, y: 30, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Credit", bounds: CGRect(x: 120, y: 30, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Debit", bounds: CGRect(x: 200, y: 30, width: 50, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "Basic Pay", bounds: CGRect(x: 20, y: 60, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "45000.00", bounds: CGRect(x: 120, y: 60, width: 60, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "DSOP Fund", bounds: CGRect(x: 20, y: 90, width: 80, height: 20), fontSize: 12, confidence: 0.9),
            TextElement(text: "4500.00", bounds: CGRect(x: 200, y: 90, width: 50, height: 20), fontSize: 12, confidence: 0.9)
        ]
    }
}