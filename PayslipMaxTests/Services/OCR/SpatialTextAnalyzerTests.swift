import XCTest
import CoreGraphics
@testable import PayslipMax

class SpatialTextAnalyzerTests: XCTestCase {
    
    var spatialAnalyzer: SpatialTextAnalyzer!
    
    override func setUp() {
        super.setUp()
        spatialAnalyzer = SpatialTextAnalyzer()
    }
    
    override func tearDown() {
        spatialAnalyzer = nil
        super.tearDown()
    }
    
    // MARK: - Basic Association Tests
    
    func testAssociateSimpleTextWithCells() {
        // Create a simple 2x2 table structure
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 200, height: 20)),
            TableStructure.TableRow(index: 1, yPosition: 25, height: 20, bounds: CGRect(x: 0, y: 25, width: 200, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 50)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 95, bounds: CGRect(x: 105, y: 0, width: 95, height: 50))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 200, height: 50)
        )
        
        // Create text elements that fit in the cells
        let textElements = [
            TextElement(text: "Cell 0,0", bounds: CGRect(x: 10, y: 5, width: 50, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Cell 0,1", bounds: CGRect(x: 110, y: 5, width: 50, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Cell 1,0", bounds: CGRect(x: 10, y: 30, width: 50, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Cell 1,1", bounds: CGRect(x: 110, y: 30, width: 50, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rowCount, 2)
        XCTAssertEqual(result?.columnCount, 2)
        
        // Verify cell content
        XCTAssertEqual(result?.cell(at: 0, column: 0)?.mergedText, "Cell 0,0")
        XCTAssertEqual(result?.cell(at: 0, column: 1)?.mergedText, "Cell 0,1")
        XCTAssertEqual(result?.cell(at: 1, column: 0)?.mergedText, "Cell 1,0")
        XCTAssertEqual(result?.cell(at: 1, column: 1)?.mergedText, "Cell 1,1")
    }
    
    func testMultiLineTextInSingleCell() {
        // Create table structure with one cell
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 40, bounds: CGRect(x: 0, y: 0, width: 100, height: 40))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 40))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 40)
        )
        
        // Create multi-line text elements (vertically stacked)
        let textElements = [
            TextElement(text: "Line 1", bounds: CGRect(x: 10, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Line 2", bounds: CGRect(x: 10, y: 18, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Line 3", bounds: CGRect(x: 10, y: 31, width: 40, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        let cell = result?.cell(at: 0, column: 0)
        XCTAssertEqual(cell?.textElements.count, 3)
        XCTAssertEqual(cell?.mergedText, "Line 1 Line 2 Line 3")
    }
    
    func testHorizontalTextGrouping() {
        // Create table structure
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 200, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 200, bounds: CGRect(x: 0, y: 0, width: 200, height: 20))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 200, height: 20)
        )
        
        // Create horizontally adjacent text elements that should be grouped
        let textElements = [
            TextElement(text: "Hello", bounds: CGRect(x: 10, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "World", bounds: CGRect(x: 45, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        let cell = result?.cell(at: 0, column: 0)
        XCTAssertEqual(cell?.textElements.count, 2)
        XCTAssertEqual(cell?.mergedText, "Hello World")
    }
    
    // MARK: - Header Detection Tests
    
    func testHeaderDetectionWithCommonKeywords() {
        // Create table structure with header row
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 200, height: 20)),
            TableStructure.TableRow(index: 1, yPosition: 25, height: 20, bounds: CGRect(x: 0, y: 25, width: 200, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 50)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 95, bounds: CGRect(x: 105, y: 0, width: 95, height: 50))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 200, height: 50)
        )
        
        // Create text elements with header keywords
        let textElements = [
            TextElement(text: "Description", bounds: CGRect(x: 10, y: 5, width: 60, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Amount", bounds: CGRect(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Data 1", bounds: CGRect(x: 10, y: 30, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "100.00", bounds: CGRect(x: 110, y: 30, width: 40, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.headers)
        XCTAssertEqual(result?.headers?.count, 2)
        XCTAssertTrue(result?.headers?.contains("Description") ?? false)
        XCTAssertTrue(result?.headers?.contains("Amount") ?? false)
    }
    
    func testNoHeaderDetectionForDataRows() {
        // Create table structure
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 200, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 20)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 95, bounds: CGRect(x: 105, y: 0, width: 95, height: 20))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 200, height: 20)
        )
        
        // Create text elements without header keywords
        let textElements = [
            TextElement(text: "Random Text", bounds: CGRect(x: 10, y: 5, width: 60, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "123.45", bounds: CGRect(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        XCTAssertNil(result?.headers)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyInputs() {
        let emptyTableStructure = TableStructure(rows: [], columns: [], bounds: .zero)
        
        let result1 = spatialAnalyzer.associateTextWithCells(
            textElements: [],
            tableStructure: emptyTableStructure
        )
        XCTAssertNil(result1)
        
        let validTableStructure = TableStructure(
            rows: [TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 100, height: 20))],
            columns: [TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 20))],
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20)
        )
        
        let result2 = spatialAnalyzer.associateTextWithCells(
            textElements: [],
            tableStructure: validTableStructure
        )
        XCTAssertNil(result2)
    }
    
    func testTextOutsideTableBounds() {
        // Create small table structure
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 100, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 20))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20)
        )
        
        // Create text element outside table bounds
        let textElements = [
            TextElement(text: "Outside", bounds: CGRect(x: 200, y: 200, width: 40, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        // Text should be associated with closest cell
        XCTAssertNotNil(result?.cell(at: 0, column: 0))
    }
    
    // MARK: - Military Payslip Patterns
    
    func testMilitaryPayslipCreditDebitPattern() {
        // Create table structure similar to military payslips
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 400, height: 20)),
            TableStructure.TableRow(index: 1, yPosition: 25, height: 20, bounds: CGRect(x: 0, y: 25, width: 400, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 50)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 95, bounds: CGRect(x: 105, y: 0, width: 95, height: 50)),
            TableStructure.TableColumn(index: 2, xPosition: 205, width: 90, bounds: CGRect(x: 205, y: 0, width: 90, height: 50)),
            TableStructure.TableColumn(index: 3, xPosition: 300, width: 100, bounds: CGRect(x: 300, y: 0, width: 100, height: 50))
        ]
        
        let tableStructure = TableStructure(
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 400, height: 50)
        )
        
        // Create text elements simulating military payslip
        let textElements = [
            // Headers
            TextElement(text: "Particulars", bounds: CGRect(x: 10, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Credit", bounds: CGRect(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Particulars", bounds: CGRect(x: 210, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Debit", bounds: CGRect(x: 310, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            
            // Data
            TextElement(text: "BPAY", bounds: CGRect(x: 10, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "50000.00", bounds: CGRect(x: 110, y: 30, width: 60, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "ITAX", bounds: CGRect(x: 210, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "5000.00", bounds: CGRect(x: 310, y: 30, width: 50, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let result = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        )
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.headers)
        XCTAssertEqual(result?.headers?.count, 4)
        XCTAssertTrue(result?.headers?.contains("Credit") ?? false)
        XCTAssertTrue(result?.headers?.contains("Debit") ?? false)
        
        // Verify data cells
        XCTAssertEqual(result?.cell(at: 1, column: 0)?.mergedText, "BPAY")
        XCTAssertEqual(result?.cell(at: 1, column: 1)?.mergedText, "50000.00")
        XCTAssertEqual(result?.cell(at: 1, column: 2)?.mergedText, "ITAX")
        XCTAssertEqual(result?.cell(at: 1, column: 3)?.mergedText, "5000.00")
    }
}