import XCTest
import PDFKit
@testable import PayslipMax

class DocumentAnalysisServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    private var strategyService: ExtractionStrategyService!
    private var mockPDF: PDFDocument!
    private var mockPDFURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
        strategyService = ExtractionStrategyService()
        
        // Create a mock PDF for testing
        mockPDF = createMockPDF()
        
        // Create a temporary PDF URL
        mockPDFURL = FileManager.default.temporaryDirectory.appendingPathComponent("mockTest.pdf")
        try? mockPDF.write(to: mockPDFURL)
    }
    
    override func tearDown() {
        analysisService = nil
        strategyService = nil
        mockPDF = nil
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: mockPDFURL)
        mockPDFURL = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testAnalyzeDocument() {
        // When: Analyzing a mock PDF
        let analysis = analysisService.analyzeDocument(mockPDF)
        
        // Then: Should return valid analysis
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.pageCount, mockPDF.pageCount)
        XCTAssertFalse(analysis.containsScannedContent)
    }
    
    func testAnalyzeDocumentFromURL() {
        // When: Analyzing a mock PDF from URL
        let analysis = analysisService.analyzeDocument(at: mockPDFURL)
        
        // Then: Should return valid analysis
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.pageCount, mockPDF.pageCount)
    }
    
    func testDetectScannedContent() {
        // Given: A PDF with scanned content
        let scannedPDF = createMockPDFWithScannedContent()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(scannedPDF)
        
        // Then: Should detect scanned content
        XCTAssertTrue(analysis.containsScannedContent)
    }
    
    func testDetectComplexLayout() {
        // Given: A PDF with complex layout
        let complexPDF = createMockPDFWithComplexLayout()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(complexPDF)
        
        // Then: Should detect complex layout
        XCTAssertTrue(analysis.hasComplexLayout)
    }
    
    func testDetectTextHeavyDocument() {
        // Given: A text-heavy PDF
        let textHeavyPDF = createMockPDFWithHeavyText()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(textHeavyPDF)
        
        // Then: Should detect text-heavy content
        XCTAssertTrue(analysis.isTextHeavy)
    }
    
    func testLargeDocumentDetection() {
        // Given: A large PDF document
        let largePDF = createMockLargeDocument()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(largePDF)
        
        // Then: Should detect large document
        XCTAssertTrue(analysis.isLargeDocument)
    }
    
    func testTableDetection() {
        // Given: A PDF with tables
        let tablePDF = createMockPDFWithTables()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(tablePDF)
        
        // Then: Should detect tables
        XCTAssertTrue(analysis.containsTables)
    }
    
    func testDifferentiateDocumentTypes() {
        // Given: Different types of PDFs
        let scannedPDF = createMockPDFWithScannedContent()
        let tablePDF = createMockPDFWithTables()
        let complexPDF = createMockPDFWithComplexLayout()
        let textHeavyPDF = createMockPDFWithHeavyText()
        
        // When: Analyzing each document
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let complexAnalysis = analysisService.analyzeDocument(complexPDF)
        let textAnalysis = analysisService.analyzeDocument(textHeavyPDF)
        
        // Then: Each document should have the expected characteristics
        XCTAssertTrue(scannedAnalysis.containsScannedContent)
        XCTAssertTrue(tableAnalysis.containsTables)
        XCTAssertTrue(complexAnalysis.hasComplexLayout)
        XCTAssertTrue(textAnalysis.isTextHeavy)
    }
    
    func testMixedContentDocument() {
        // Given: A PDF with mixed content
        let mixedPDF = createMockPDFWithMixedContent()
        
        // When: Analyzing the document
        let analysis = analysisService.analyzeDocument(mixedPDF)
        
        // Then: Should detect multiple characteristics
        XCTAssertTrue(analysis.containsScannedContent)
        XCTAssertTrue(analysis.hasComplexLayout)
        XCTAssertTrue(analysis.containsTables)
    }
    
    func testIntegrationWithExtractionStrategyService() {
        // 1. Test with a standard text document
        let standardPDF = createMockPDF()
        let standardAnalysis = analysisService.analyzeDocument(standardPDF)
        let standardStrategy = strategyService.determineStrategy(for: standardAnalysis)
        
        // Standard text document should use native text extraction
        XCTAssertEqual(standardStrategy, .nativeTextExtraction)
        
        // 2. Test with a scanned document
        let scannedPDF = createMockPDFWithScannedContent()
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        
        // Scanned document should use OCR extraction
        XCTAssertEqual(scannedStrategy, .ocrExtraction)
        
        // 3. Test with a large document
        let largePDF = createMockLargeDocument()
        let largeAnalysis = analysisService.analyzeDocument(largePDF)
        let largeStrategy = strategyService.determineStrategy(for: largeAnalysis)
        
        // Large document should use streaming extraction
        XCTAssertEqual(largeStrategy, .streamingExtraction)
        
        // 4. Test with a table document
        let tablePDF = createMockPDFWithTables()
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        
        // Document with tables should use table extraction
        XCTAssertEqual(tableStrategy, .tableExtraction)
    }
    
    func testExtractionParametersMatchDocumentCharacteristics() {
        // 1. Test parameters for text-heavy document
        let textPDF = createMockPDFWithHeavyText()
        let textAnalysis = analysisService.analyzeDocument(textPDF)
        let textStrategy = strategyService.determineStrategy(for: textAnalysis)
        let textParams = strategyService.getExtractionParameters(for: textStrategy, with: textAnalysis)
        
        // Text-heavy document should have text formatting preserved
        XCTAssertTrue(textParams.preserveFormatting)
        XCTAssertTrue(textParams.maintainTextOrder)
        
        // 2. Test parameters for document with tables
        let tablePDF = createMockPDFWithTables()
        let tableAnalysis = analysisService.analyzeDocument(tablePDF)
        let tableStrategy = strategyService.determineStrategy(for: tableAnalysis)
        let tableParams = strategyService.getExtractionParameters(for: tableStrategy, with: tableAnalysis)
        
        // Document with tables should extract tables and use grid detection
        XCTAssertTrue(tableParams.extractTables)
        XCTAssertTrue(tableParams.useGridDetection)
        
        // 3. Test parameters for scanned document
        let scannedPDF = createMockPDFWithScannedContent()
        let scannedAnalysis = analysisService.analyzeDocument(scannedPDF)
        let scannedStrategy = strategyService.determineStrategy(for: scannedAnalysis)
        let scannedParams = strategyService.getExtractionParameters(for: scannedStrategy, with: scannedAnalysis)
        
        // Scanned document should use OCR
        XCTAssertTrue(scannedParams.useOCR)
        XCTAssertTrue(scannedParams.extractImages)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        let pdfData = createPDFWithText("This is a sample document for testing.")
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithScannedContent() -> PDFDocument {
        let pdfData = createPDFWithImage()
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithComplexLayout() -> PDFDocument {
        let pdfData = createPDFWithColumns(columnCount: 3)
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithHeavyText() -> PDFDocument {
        let pdfData = createPDFWithText(String(repeating: "This is a text-heavy document. ", count: 100))
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockLargeDocument() -> PDFDocument {
        let pdfData = createMultiPagePDF(pageCount: 100)
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithTables() -> PDFDocument {
        let pdfData = createPDFWithTable()
        return PDFDocument(data: pdfData)!
    }
    
    private func createMockPDFWithMixedContent() -> PDFDocument {
        let pdfData = createPDFWithMixedContent()
        return PDFDocument(data: pdfData)!
    }
    
    // Create a PDF with standard text
    private func createPDFWithText(_ text: String) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(in: pageRect.insetBy(dx: 50, dy: 50), withAttributes: attributes)
        })
        
        return pdfData as Data
    }
    
    // Create a PDF with an image (simulating scanned content)
    private func createPDFWithImage() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            // Create a mock image (a simple colored rectangle)
            let imageRect = pageRect.insetBy(dx: 50, dy: 50)
            context.cgContext.setFillColor(UIColor.lightGray.cgColor)
            context.cgContext.fill(imageRect)
            
            // Add minimal text to simulate OCR capabilities
            let text = "Sample scanned document"
            let textRect = CGRect(x: 100, y: 100, width: 400, height: 50)
            text.draw(in: textRect, withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
        })
        
        return pdfData as Data
    }
    
    // Create a PDF with multiple columns (complex layout)
    private func createPDFWithColumns(columnCount: Int) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let contentRect = pageRect.insetBy(dx: 50, dy: 50)
            let columnWidth = contentRect.width / CGFloat(columnCount)
            
            for i in 0..<columnCount {
                let columnRect = CGRect(
                    x: contentRect.minX + (columnWidth * CGFloat(i)),
                    y: contentRect.minY,
                    width: columnWidth,
                    height: contentRect.height
                ).insetBy(dx: 5, dy: 0)
                
                let text = "Column \(i+1): This is some sample text for column \(i+1). This text demonstrates a complex multi-column layout that would be typical in magazines, newspapers, or academic papers."
                
                text.draw(in: columnRect, withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
        })
        
        return pdfData as Data
    }
    
    // Create a PDF with multiple pages
    private func createMultiPagePDF(pageCount: Int) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            for i in 1...pageCount {
                context.beginPage()
                
                let text = "Page \(i) of \(pageCount)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                
                text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
            }
        })
        
        return pdfData as Data
    }
    
    // Create a PDF with a table
    private func createPDFWithTable() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let tableRect = pageRect.insetBy(dx: 100, dy: 200)
            let rowCount = 5
            let columnCount = 4
            let rowHeight = tableRect.height / CGFloat(rowCount)
            let columnWidth = tableRect.width / CGFloat(columnCount)
            
            // Draw table grid
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            
            // Draw horizontal lines
            for i in 0...rowCount {
                let y = tableRect.minY + (CGFloat(i) * rowHeight)
                context.cgContext.move(to: CGPoint(x: tableRect.minX, y: y))
                context.cgContext.addLine(to: CGPoint(x: tableRect.maxX, y: y))
            }
            
            // Draw vertical lines
            for i in 0...columnCount {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                context.cgContext.move(to: CGPoint(x: x, y: tableRect.minY))
                context.cgContext.addLine(to: CGPoint(x: x, y: tableRect.maxY))
            }
            
            context.cgContext.strokePath()
            
            // Add header text
            let headers = ["Header 1", "Header 2", "Header 3", "Header 4"]
            for (i, header) in headers.enumerated() {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                let headerRect = CGRect(x: x, y: tableRect.minY, width: columnWidth, height: rowHeight)
                
                header.draw(in: headerRect.insetBy(dx: 5, dy: 5), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10)
                ])
            }
            
            // Add cell data
            for row in 1..<rowCount {
                for col in 0..<columnCount {
                    let x = tableRect.minX + (CGFloat(col) * columnWidth)
                    let y = tableRect.minY + (CGFloat(row) * rowHeight)
                    let cellRect = CGRect(x: x, y: y, width: columnWidth, height: rowHeight)
                    
                    let cellText = "Cell \(row),\(col)"
                    cellText.draw(in: cellRect.insetBy(dx: 5, dy: 5), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10)
                    ])
                }
            }
        })
        
        return pdfData as Data
    }
    
    // Create a PDF with mixed content (tables, images, text)
    private func createPDFWithMixedContent() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            // Add title
            let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
            "Mixed Content Document".draw(in: titleRect, withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 18)
            ])
            
            // Add paragraph text
            let paragraphRect = CGRect(x: 50, y: 100, width: 512, height: 100)
            "This document contains a mixture of content types including text, tables, and images. This type of document would require sophisticated analysis to properly extract all content.".draw(in: paragraphRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12)
            ])
            
            // Add an image (simulating scanned content)
            let imageRect = CGRect(x: 50, y: 220, width: 200, height: 150)
            context.cgContext.setFillColor(UIColor.darkGray.cgColor)
            context.cgContext.fill(imageRect)
            
            // Add a small table
            let tableRect = CGRect(x: 300, y: 220, width: 250, height: 150)
            let rowCount = 3
            let columnCount = 2
            let rowHeight = tableRect.height / CGFloat(rowCount)
            let columnWidth = tableRect.width / CGFloat(columnCount)
            
            // Draw table grid
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            
            // Draw horizontal lines
            for i in 0...rowCount {
                let y = tableRect.minY + (CGFloat(i) * rowHeight)
                context.cgContext.move(to: CGPoint(x: tableRect.minX, y: y))
                context.cgContext.addLine(to: CGPoint(x: tableRect.maxX, y: y))
            }
            
            // Draw vertical lines
            for i in 0...columnCount {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                context.cgContext.move(to: CGPoint(x: x, y: tableRect.minY))
                context.cgContext.addLine(to: CGPoint(x: x, y: tableRect.maxY))
            }
            
            context.cgContext.strokePath()
            
            // Add columns at the bottom (complex layout)
            let columnRect = CGRect(x: 50, y: 400, width: 512, height: 300)
            let columns = 2
            let columnWidth2 = columnRect.width / CGFloat(columns)
            
            for i in 0..<columns {
                let colX = columnRect.minX + (columnWidth2 * CGFloat(i))
                let colRect = CGRect(x: colX, y: columnRect.minY, width: columnWidth2, height: columnRect.height).insetBy(dx: 10, dy: 0)
                
                let colText = "Column \(i+1): This is text in a multi-column layout section of the document. This demonstrates how the document has a complex layout with multiple sections and content types."
                
                colText.draw(in: colRect, withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
        })
        
        return pdfData as Data
    }
} 