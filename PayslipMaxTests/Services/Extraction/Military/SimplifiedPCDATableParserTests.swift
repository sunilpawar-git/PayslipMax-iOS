import XCTest
import CoreGraphics
@testable import PayslipMax

class SimplifiedPCDATableParserTests: XCTestCase {
    
    var parser: SimplifiedPCDATableParser!
    var mockTableDetector: MockSimpleTableDetector!
    var mockSpatialAnalyzer: MockSpatialTextAnalyzer!
    
    override func setUp() {
        super.setUp()
        mockTableDetector = MockSimpleTableDetector()
        mockSpatialAnalyzer = MockSpatialTextAnalyzer()
        parser = SimplifiedPCDATableParser(
            tableDetector: mockTableDetector,
            spatialAnalyzer: mockSpatialAnalyzer
        )
    }
    
    override func tearDown() {
        parser = nil
        mockTableDetector = nil
        mockSpatialAnalyzer = nil
        super.tearDown()
    }
    
    // MARK: - PCDA Format Detection Tests
    
    func testPCDAFormatDetection() {
        // Test various PCDA header patterns
        let pcdaTexts = [
            "CREDIT DEBIT\nBPAY 50000 DSOP 5000",
            "Credits and Debits\nSalary 40000 Tax 3000",
            "EARNINGS DEDUCTIONS\nBasic 35000 AGIF 2000",
            "PCDA Format Table\nDA 10000 PLI 1000",
            "Principal Controller Format\nHRA 15000 IT 2000"
        ]
        
        for text in pcdaTexts {
            let (earnings, deductions) = parser.extractTableData(from: text)
            XCTAssertTrue(!earnings.isEmpty || !deductions.isEmpty, 
                         "Should extract data from PCDA format: \(text)")
        }
    }
    
    func testNonPCDAFormatDetection() {
        let nonPcdaTexts = [
            "Regular payslip without table format",
            "Some random text with numbers 123 456",
            "Invoice format\nItem Cost\nProduct1 100"
        ]
        
        for text in nonPcdaTexts {
            let (earnings, deductions) = parser.extractTableData(from: text)
            XCTAssertTrue(earnings.isEmpty && deductions.isEmpty, 
                         "Should not extract data from non-PCDA format: \(text)")
        }
    }
    
    // MARK: - Data Extraction Tests
    
    func testSimpleCodeAmountExtraction() {
        let text = "CREDIT DEBIT\nBPAY 50000\nDSOP 5000"
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        XCTAssertEqual(earnings["BPAY"], 50000)
        XCTAssertEqual(deductions["DSOP"], 5000)
    }
    
    func testMultipleCodesWithSingleAmount() {
        let text = "CREDIT DEBIT\nBPAY DA MSP 60000\nDSOP AGIF 8000"
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        // Should distribute amount equally among codes
        XCTAssertEqual(earnings["BPAY"], 20000) // 60000 / 3
        XCTAssertEqual(earnings["DA"], 20000)
        XCTAssertEqual(earnings["MSP"], 20000)
        XCTAssertEqual(deductions["DSOP"], 4000) // 8000 / 2
        XCTAssertEqual(deductions["AGIF"], 4000)
    }
    
    func testCodeAmountPairsExtraction() {
        let text = "CREDIT DEBIT\nBPAY 30000 DA 10000\nDSOP 3000 IT 2000"
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        XCTAssertEqual(earnings["BPAY"], 30000)
        XCTAssertEqual(earnings["DA"], 10000)
        XCTAssertEqual(deductions["DSOP"], 3000)
        XCTAssertEqual(deductions["IT"], 2000)
    }
    
    // MARK: - Spatial Analysis Tests
    
    func testSpatialTableAnalysis() {
        // Create mock table structure
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 400, height: 20)),
            TableStructure.TableRow(index: 1, yPosition: 25, height: 20, bounds: CGRect(x: 0, y: 25, width: 400, height: 20))
        ]
        
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 50)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 90, bounds: CGRect(x: 105, y: 0, width: 90, height: 50)),
            TableStructure.TableColumn(index: 2, xPosition: 200, width: 100, bounds: CGRect(x: 200, y: 0, width: 100, height: 50)),
            TableStructure.TableColumn(index: 3, xPosition: 305, width: 95, bounds: CGRect(x: 305, y: 0, width: 95, height: 50))
        ]
        
        let tableStructure = TableStructure(rows: rows, columns: columns, bounds: CGRect(x: 0, y: 0, width: 400, height: 50))
        mockTableDetector.mockTableStructure = tableStructure
        
        // Create mock spatial table structure
        let cells = [
            [
                TableCell(row: 0, column: 0, bounds: CGRect(x: 0, y: 0, width: 100, height: 20), textElements: [
                    TextElement(text: "Particulars", bounds: CGRect(x: 10, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 0, column: 1, bounds: CGRect(x: 105, y: 0, width: 90, height: 20), textElements: [
                    TextElement(text: "Credit", bounds: CGRect(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 0, column: 2, bounds: CGRect(x: 200, y: 0, width: 100, height: 20), textElements: [
                    TextElement(text: "Particulars", bounds: CGRect(x: 210, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 0, column: 3, bounds: CGRect(x: 305, y: 0, width: 95, height: 20), textElements: [
                    TextElement(text: "Debit", bounds: CGRect(x: 310, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9)
                ])
            ],
            [
                TableCell(row: 1, column: 0, bounds: CGRect(x: 0, y: 25, width: 100, height: 20), textElements: [
                    TextElement(text: "BPAY", bounds: CGRect(x: 10, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 1, column: 1, bounds: CGRect(x: 105, y: 25, width: 90, height: 20), textElements: [
                    TextElement(text: "50000", bounds: CGRect(x: 110, y: 30, width: 40, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 1, column: 2, bounds: CGRect(x: 200, y: 25, width: 100, height: 20), textElements: [
                    TextElement(text: "DSOP", bounds: CGRect(x: 210, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)
                ]),
                TableCell(row: 1, column: 3, bounds: CGRect(x: 305, y: 25, width: 95, height: 20), textElements: [
                    TextElement(text: "5000", bounds: CGRect(x: 310, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)
                ])
            ]
        ]
        
        let spatialTable = SpatialTableStructure(
            cells: cells,
            rows: rows,
            columns: columns,
            bounds: CGRect(x: 0, y: 0, width: 400, height: 50),
            headers: ["Particulars", "Credit", "Particulars", "Debit"]
        )
        mockSpatialAnalyzer.mockSpatialTable = spatialTable
        
        // Create text elements
        let textElements = [
            TextElement(text: "Particulars", bounds: CGRect(x: 10, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Credit", bounds: CGRect(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Particulars", bounds: CGRect(x: 210, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "Debit", bounds: CGRect(x: 310, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "BPAY", bounds: CGRect(x: 10, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "50000", bounds: CGRect(x: 110, y: 30, width: 40, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "DSOP", bounds: CGRect(x: 210, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9),
            TextElement(text: "5000", bounds: CGRect(x: 310, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)
        ]
        
        let (earnings, deductions) = parser.extractTableData(from: textElements)
        
        // The spatial analyzer should extract the data correctly
        XCTAssertFalse(earnings.isEmpty || deductions.isEmpty, "Should extract some data")
        print("Extracted earnings: \(earnings)")
        print("Extracted deductions: \(deductions)")
    }
    
    // MARK: - Military Code Recognition Tests
    
    func testMilitaryEarningCodes() {
        let text = """
        CREDIT DEBIT
        BPAY 30000
        DA 10000
        HRA 15000
        TA 5000
        MSP 8000
        """
        
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        XCTAssertEqual(earnings["BPAY"], 30000)
        XCTAssertEqual(earnings["DA"], 10000)
        XCTAssertEqual(earnings["HRA"], 15000)
        XCTAssertEqual(earnings["TA"], 5000)
        XCTAssertEqual(earnings["MSP"], 8000)
        XCTAssertTrue(deductions.isEmpty)
    }
    
    func testMilitaryDeductionCodes() {
        let text = """
        CREDIT DEBIT
        DSOP 3000
        AGIF 2000
        ITAX 4000
        PLI 1500
        CGEIS 500
        """
        
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        XCTAssertEqual(deductions["DSOP"], 3000)
        XCTAssertEqual(deductions["AGIF"], 2000)
        XCTAssertEqual(deductions["ITAX"], 4000)
        XCTAssertEqual(deductions["PLI"], 1500)
        XCTAssertEqual(deductions["CGEIS"], 500)
        XCTAssertTrue(earnings.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyInput() {
        let (earnings, deductions) = parser.extractTableData(from: "")
        XCTAssertTrue(earnings.isEmpty)
        XCTAssertTrue(deductions.isEmpty)
    }
    
    func testNoNumericData() {
        let text = "CREDIT DEBIT\nSome text without numbers"
        let (earnings, deductions) = parser.extractTableData(from: text)
        XCTAssertTrue(earnings.isEmpty)
        XCTAssertTrue(deductions.isEmpty)
    }
    
    func testMixedValidInvalidData() {
        let text = """
        CREDIT DEBIT
        BPAY 50000
        Invalid line with no number
        DSOP 5000
        Another invalid line
        """
        
        let (earnings, deductions) = parser.extractTableData(from: text)
        
        XCTAssertEqual(earnings["BPAY"], 50000)
        XCTAssertEqual(deductions["DSOP"], 5000)
    }
}

// MARK: - Mock Classes

class MockSimpleTableDetector: SimpleTableDetectorProtocol {
    var mockTableStructure: TableStructure?
    var mockPCDATableStructure: PCDATableStructure?
    
    func detectTableStructure(from textElements: [TextElement]) -> TableStructure? {
        return mockTableStructure
    }
    
    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure? {
        return mockPCDATableStructure
    }
}

class MockSpatialTextAnalyzer: SpatialTextAnalyzerProtocol {
    var mockSpatialTable: SpatialTableStructure?
    var mockPCDASpatialTable: PCDASpatialTable?
    
    func associateTextWithCells(textElements: [TextElement], tableStructure: TableStructure) -> SpatialTableStructure? {
        return mockSpatialTable
    }
    
    func associateTextWithPCDACells(textElements: [TextElement], pcdaStructure: PCDATableStructure) -> PCDASpatialTable? {
        return mockPCDASpatialTable
    }
}