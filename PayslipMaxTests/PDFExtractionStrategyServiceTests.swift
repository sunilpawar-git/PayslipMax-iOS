import XCTest
import PDFKit
@testable import PayslipMax

final class PDFExtractionStrategyServiceTests: XCTestCase {
    
    var pdfURL: URL!
    var pdfDocument: PDFDocument!
    var extractionService: PDFExtractionStrategyService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create mock PDF for testing
        pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("mockExtraction.pdf")
        pdfDocument = createMockPDFDocument()
        extractionService = PDFExtractionStrategyService()
    }
    
    override func tearDownWithError() throws {
        // Clean up test PDF file
        try? FileManager.default.removeItem(at: pdfURL)
        pdfDocument = nil
        extractionService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Basic Extraction Functionality
    
    func testBasicTextExtraction() throws {
        // Test basic text extraction
        let result = extractionService.extractText(from: pdfDocument, using: .standard)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("Sample Document"))
        XCTAssertTrue(result.contains("This is a test document"))
    }
    
    func testVisionBasedTextExtraction() throws {
        // Test Vision-based text extraction
        let result = extractionService.extractText(from: pdfDocument, using: .visionBased)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("Sample Document"))
    }
    
    // MARK: - Test Extraction Benchmarking
    
    func testExtractionBenchmarking() throws {
        // Benchmark different extraction strategies
        let standardBenchmark = extractionService.benchmarkExtraction(from: pdfDocument, using: .standard)
        
        // Verify benchmark result properties
        XCTAssertEqual(standardBenchmark.strategyName, "standard")
        XCTAssertGreaterThan(standardBenchmark.executionTime, 0)
        XCTAssertGreaterThan(standardBenchmark.memoryUsage, 0)
        XCTAssertGreaterThan(standardBenchmark.outputSize, 0)
        XCTAssertTrue(standardBenchmark.success)
        
        // Test another strategy
        let visionBenchmark = extractionService.benchmarkExtraction(from: pdfDocument, using: .visionBased)
        XCTAssertEqual(visionBenchmark.strategyName, "visionBased")
        
        // Compare strategies
        XCTAssertNotEqual(standardBenchmark.executionTime, visionBenchmark.executionTime)
    }
    
    func testDetailedTextExtractionBenchmarking() throws {
        // Create a standard benchmark result first
        let standardBenchmark = extractionService.benchmarkExtraction(from: pdfDocument, using: .standard)
        
        // Create a detailed text extraction benchmark
        let textExtractionBenchmark = PDFBenchmarkingTools.TextExtractionBenchmarkResult(
            baseResult: standardBenchmark,
            textQualityScore: 85.0,
            structurePreservationScore: 75.0,
            textOrderAccuracy: 90.0,
            characterErrorRate: 0.05
        )
        
        // Test the detailed benchmark properties
        XCTAssertEqual(textExtractionBenchmark.strategyName, standardBenchmark.strategyName)
        XCTAssertEqual(textExtractionBenchmark.executionTime, standardBenchmark.executionTime)
        XCTAssertEqual(textExtractionBenchmark.textQualityScore, 85.0)
        
        // Test summary generation
        let summary = textExtractionBenchmark.getSummary()
        XCTAssertTrue(summary.contains("standard"))
        XCTAssertTrue(summary.contains("Quality: 85.0%"))
        XCTAssertTrue(summary.contains("Structure: 75.0%"))
        XCTAssertTrue(summary.contains("Order: 90.0%"))
        XCTAssertTrue(summary.contains("CER: 5.00%"))
    }
    
    func testCompareExtractionStrategies() throws {
        // Benchmark multiple strategies for comparison
        let strategies: [PDFExtractionStrategy] = [.standard, .visionBased, .optimized]
        var benchmarks: [PDFBenchmarkingTools.BenchmarkResult] = []
        
        for strategy in strategies {
            let benchmark = extractionService.benchmarkExtraction(from: pdfDocument, using: strategy)
            benchmarks.append(benchmark)
        }
        
        // Verify we have results for all strategies
        XCTAssertEqual(benchmarks.count, strategies.count)
        
        // Find fastest strategy
        let fastestStrategy = benchmarks.min { $0.executionTime < $1.executionTime }
        XCTAssertNotNil(fastestStrategy)
        
        // Find most memory efficient
        let mostMemoryEfficient = benchmarks.min { $0.memoryUsage < $1.memoryUsage }
        XCTAssertNotNil(mostMemoryEfficient)
        
        // Print comparison for debugging
        print("Strategy comparison:")
        for benchmark in benchmarks {
            print(benchmark.getSummary())
        }
    }
    
    // MARK: - Test Content Extraction
    
    func testTableContentExtraction() throws {
        // Test the extraction of tabular data
        let result = extractionService.extractText(from: pdfDocument, using: .tableOptimized)
        
        // Check if the table headers were extracted
        XCTAssertTrue(result.contains("Name"))
        XCTAssertTrue(result.contains("Date"))
        XCTAssertTrue(result.contains("Amount"))
        
        // Check if table content was extracted
        XCTAssertTrue(result.contains("John Doe"))
        XCTAssertTrue(result.contains("$1,200.00"))
        XCTAssertTrue(result.contains("Jane Smith"))
        XCTAssertTrue(result.contains("$1,450.00"))
        XCTAssertTrue(result.contains("Total"))
        XCTAssertTrue(result.contains("$2,650.00"))
        
        // Benchmark table extraction specifically
        let benchmark = extractionService.benchmarkExtraction(from: pdfDocument, using: .tableOptimized)
        
        // Verify the benchmark shows this is a table-optimized extraction
        XCTAssertEqual(benchmark.strategyName, "tableOptimized")
        
        // Test structural analysis of the extracted content
        let structuralAnalysis = extractionService.analyzeTableStructure(from: result)
        XCTAssertNotNil(structuralAnalysis)
        XCTAssertGreaterThan(structuralAnalysis.tableCount, 0)
        XCTAssertEqual(structuralAnalysis.columnCount, 3)
        XCTAssertEqual(structuralAnalysis.rowCount, 4) // Headers + 3 data rows
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDFDocument() -> PDFDocument {
        // Create a PDF document with some test content
        let pdfMetaData = [
            kCGPDFContextCreator: "XCTest",
            kCGPDFContextAuthor: "PayslipMax Test Suite"
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let pdfContext = CGContext(pdfURL as CFURL, mediaBox: &CGRect(pageRect), pdfMetaData as CFDictionary) else {
            fatalError("Failed to create PDF context")
        }
        
        // Start first page
        pdfContext.beginPage(mediaBox: &CGRect(pageRect))
        
        // Add some text content
        let font = CTFontCreateWithName("Helvetica" as CFString, 24, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        // Title
        let titleString = NSAttributedString(string: "Sample Document", attributes: attributes)
        let titleLine = CTLineCreateWithAttributedString(titleString)
        pdfContext.textPosition = CGPoint(x: 50, y: 700)
        CTLineDraw(titleLine, pdfContext)
        
        // Body text
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName("Helvetica" as CFString, 12, nil),
            .foregroundColor: UIColor.black
        ]
        
        let bodyString = NSAttributedString(
            string: "This is a test document for the PayslipMax PDF extraction system. " +
                    "It contains various text elements to test extraction quality and performance.",
            attributes: bodyAttributes
        )
        
        let bodyLine = CTLineCreateWithAttributedString(bodyString)
        pdfContext.textPosition = CGPoint(x: 50, y: 650)
        CTLineDraw(bodyLine, pdfContext)
        
        // Add a simple table
        drawTable(in: pdfContext, rect: CGRect(x: 50, y: 450, width: 500, height: 150))
        
        // End page and close PDF
        pdfContext.endPage()
        pdfContext.closePDF()
        
        // Create PDFDocument from the generated file
        guard let document = PDFDocument(url: pdfURL) else {
            fatalError("Failed to create PDF document from URL")
        }
        
        return document
    }
    
    private func drawTable(in context: CGContext, rect: CGRect) {
        // Draw table outline
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(rect)
        
        // Draw table rows
        let rowHeight = rect.height / 4
        for i in 1..<4 {
            let y = rect.origin.y + rowHeight * CGFloat(i)
            context.move(to: CGPoint(x: rect.origin.x, y: y))
            context.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: y))
            context.strokePath()
        }
        
        // Draw table columns
        let columnWidth = rect.width / 3
        for i in 1..<3 {
            let x = rect.origin.x + columnWidth * CGFloat(i)
            context.move(to: CGPoint(x: x, y: rect.origin.y))
            context.addLine(to: CGPoint(x: x, y: rect.origin.y + rect.height))
            context.strokePath()
        }
        
        // Add some text in cells
        let font = CTFontCreateWithName("Helvetica" as CFString, 10, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let headers = ["Name", "Date", "Amount"]
        let row1 = ["John Doe", "2023-01-15", "$1,200.00"]
        let row2 = ["Jane Smith", "2023-01-31", "$1,450.00"]
        let row3 = ["Total", "", "$2,650.00"]
        
        func drawTextInCell(_ text: String, row: Int, col: Int) {
            let x = rect.origin.x + columnWidth * CGFloat(col) + 5
            let y = rect.origin.y + rect.height - rowHeight * CGFloat(row) - 15
            
            let string = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(string)
            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(line, context)
        }
        
        // Draw headers
        for (i, header) in headers.enumerated() {
            drawTextInCell(header, row: 0, col: i)
        }
        
        // Draw data rows
        for (i, text) in row1.enumerated() {
            drawTextInCell(text, row: 1, col: i)
        }
        
        for (i, text) in row2.enumerated() {
            drawTextInCell(text, row: 2, col: i)
        }
        
        for (i, text) in row3.enumerated() {
            drawTextInCell(text, row: 3, col: i)
        }
    }
} 