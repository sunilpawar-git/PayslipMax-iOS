import XCTest
@testable import PayslipMax
import PDFKit

class ExtractorProfilerTests: XCTestCase {
    
    private var profiler: ExtractorProfiler!
    private var mockPDF: PDFDocument!
    
    override func setUp() {
        super.setUp()
        profiler = ExtractorProfiler()
        
        // Create a mock PDF for testing
        mockPDF = createMockPDF()
    }
    
    override func tearDown() {
        profiler = nil
        mockPDF = nil
        super.tearDown()
    }
    
    func testProfileStandardExtraction() async {
        let result = await profiler.profileStandardExtraction(on: mockPDF)
        
        // Verify result properties
        XCTAssertEqual(result.strategyName, "Standard")
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
        XCTAssertNil(result.detailedMetrics)
    }
    
    func testProfileOptimizedExtraction() async {
        let result = await profiler.profileOptimizedExtraction(on: mockPDF)
        
        // Verify result properties
        XCTAssertEqual(result.strategyName, "Optimized")
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
        XCTAssertNil(result.detailedMetrics)
    }
    
    func testProfileEnhancedExtractionWithSpeedPreset() async {
        let result = await profiler.profileEnhancedExtraction(on: mockPDF, preset: .speed)
        
        // Verify result properties
        XCTAssertTrue(result.strategyName.contains("Enhanced"))
        XCTAssertTrue(result.strategyName.contains("Parallel"))
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
    }
    
    func testProfileEnhancedExtractionWithQualityPreset() async {
        let result = await profiler.profileEnhancedExtraction(on: mockPDF, preset: .quality)
        
        // Verify result properties
        XCTAssertTrue(result.strategyName.contains("Enhanced"))
        XCTAssertTrue(result.strategyName.contains("Preprocess"))
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
    }
    
    func testProfileEnhancedExtractionWithMemoryEfficientPreset() async {
        let result = await profiler.profileEnhancedExtraction(on: mockPDF, preset: .memoryEfficient)
        
        // Verify result properties
        XCTAssertTrue(result.strategyName.contains("Enhanced"))
        XCTAssertTrue(result.strategyName.contains("MB thresh"))
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
    }
    
    func testProfileEnhancedExtractionWithCustomOptions() async {
        let customOptions = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 2,
            preprocessText: true,
            useAdaptiveBatching: true,
            maxBatchSize: 1_048_576, // 1MB
            collectDetailedMetrics: true,
            useCache: false,
            memoryThresholdMB: 50
        )
        
        let result = await profiler.profileEnhancedExtraction(on: mockPDF, options: customOptions)
        
        // Verify result properties
        XCTAssertTrue(result.strategyName.contains("Enhanced"))
        XCTAssertTrue(result.strategyName.contains("Parallel"))
        XCTAssertTrue(result.strategyName.contains("Preprocess"))
        XCTAssertTrue(result.strategyName.contains("Adaptive"))
        XCTAssertTrue(result.strategyName.contains("50MB thresh"))
        XCTAssertEqual(result.pageCount, mockPDF.pageCount)
        XCTAssertGreaterThan(result.extractionTime, 0)
        XCTAssertGreaterThan(result.characterCount, 0)
        XCTAssertGreaterThan(result.charactersPerSecond, 0)
        XCTAssertGreaterThan(result.pagesPerSecond, 0)
        XCTAssertGreaterThan(result.peakMemoryUsage, 0)
        XCTAssertNotNil(result.detailedMetrics)
        
        // Verify detailed metrics when they are collected
        if let metrics = result.detailedMetrics {
            XCTAssertNotNil(metrics["totalProcessingTime"])
            XCTAssertNotNil(metrics["textExtractionTime"])
            XCTAssertNotNil(metrics["preprocessingTime"])
            XCTAssertNotNil(metrics["batchCount"])
            XCTAssertNotNil(metrics["peakMemoryUsage"])
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDF() -> PDFDocument {
        // Create a simple PDF with text for testing
        let pdfData = createPDFWithText("This is a test PDF document for ExtractorProfiler testing.\n" +
                                        "It contains multiple lines of text to extract.\n" +
                                        "The text extraction should be measurable for profiling purposes.")
        
        guard let pdf = PDFDocument(data: pdfData) else {
            XCTFail("Failed to create mock PDF")
            return PDFDocument()
        }
        
        return pdf
    }
    
    private func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "ExtractorProfilerTests",
            kCGPDFContextAuthor: "PayslipMax"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let textFont = UIFont.systemFont(ofSize: 12.0)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let textAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            attributedText.draw(in: CGRect(x: 50, y: 50, width: pageRect.width - 100, height: pageRect.height - 100))
        }
        
        return data
    }
} 