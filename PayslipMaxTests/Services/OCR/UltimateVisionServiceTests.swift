import XCTest
import Vision
import UIKit
@testable import PayslipMax

class UltimateVisionServiceTests: XCTestCase {
    
    var sut: UltimateVisionService!
    var mockDocumentDetector: MockDocumentDetectionService!
    var mockTextAnalyzer: MockGeometricTextAnalyzer!
    var mockImageProcessor: MockAdvancedImageProcessor!
    var mockConfidenceCalculator: MockConfidenceCalculator!
    var mockLanguageDetector: MockLanguageDetector!
    
    override func setUp() {
        super.setUp()
        mockDocumentDetector = MockDocumentDetectionService()
        mockTextAnalyzer = MockGeometricTextAnalyzer()
        mockImageProcessor = MockAdvancedImageProcessor()
        mockConfidenceCalculator = MockConfidenceCalculator()
        mockLanguageDetector = MockLanguageDetector()
        
        sut = UltimateVisionService(
            documentDetector: mockDocumentDetector,
            textAnalyzer: mockTextAnalyzer,
            imageProcessor: mockImageProcessor,
            confidenceCalculator: mockConfidenceCalculator,
            languageDetector: mockLanguageDetector
        )
    }
    
    override func tearDown() {
        sut = nil
        mockDocumentDetector = nil
        mockTextAnalyzer = nil
        mockImageProcessor = nil
        mockConfidenceCalculator = nil
        mockLanguageDetector = nil
        super.tearDown()
    }
    
    func testPerformUltimateOCR_WithValidImage_ReturnsResult() async {
        // Given
        let testImage = createTestImage()
        
        mockDocumentDetector.mockBounds = createMockRectangleObservation()
        mockImageProcessor.mockRectifiedImage = testImage
        mockImageProcessor.mockOptimizedImage = testImage
        mockTextAnalyzer.mockTableStructure = createMockTableStructure()
        mockTextAnalyzer.mockStructuredData = createMockStructuredData()
        mockTextAnalyzer.mockGeometricResult = createMockGeometricResult()
        
        // When
        let result = await sut.performUltimateOCR(testImage)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertNotNil(result.tableStructure)
        XCTAssertNotNil(result.structuredData)
    }
    
    func testPerformUltimateOCR_WithNilImage_HandlesGracefully() async {
        // Given
        let testImage = UIImage()
        
        // When
        let result = await sut.performUltimateOCR(testImage)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.confidence, 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    private func createMockRectangleObservation() -> VNRectangleObservation {
        // Create a mock rectangle observation using the normalized coordinates
        // Since the initializer is deprecated and properties are read-only,
        // we'll create a basic rectangle observation for testing
        let observation = VNRectangleObservation()
        return observation
    }
    
    private func createMockTableStructure() -> TableStructure {
        return TableStructure(
            regions: [],
            columns: [],
            rows: [],
            cells: []
        )
    }
    
    private func createMockStructuredData() -> StructuredTableData {
        return StructuredTableData()
    }
    
    private func createMockGeometricResult() -> GeometricTextResult {
        return GeometricTextResult(
            text: "Test OCR Result",
            observations: [],
            confidence: 0.85,
            metrics: ProcessingMetrics()
        )
    }
}

// MARK: - Mock Classes

// Mock classes now available in shared OCRMocks.swift