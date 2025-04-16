import XCTest
import PDFKit
@testable import PayslipMax

class PayslipExtractionManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var extractionManager: PayslipExtractionManager!
    private var mockAnalysisService: MockDocumentAnalysisService!
    private var mockStrategyService: MockExtractionStrategyService!
    private var mockPDF: PDFDocument!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAnalysisService = MockDocumentAnalysisService()
        mockStrategyService = MockExtractionStrategyService()
        extractionManager = PayslipExtractionManager(
            analysisService: mockAnalysisService,
            strategyService: mockStrategyService
        )
        
        // Create a simple PDF document
        mockPDF = PDFDocument()
        let page = PDFPage()
        mockPDF.insert(page!, at: 0)
    }
    
    override func tearDown() {
        extractionManager = nil
        mockAnalysisService = nil
        mockStrategyService = nil
        mockPDF = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testExtractPayslipData() async throws {
        // Setup expected analysis results
        let analysis = DocumentAnalysis(
            pageCount: 1,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.8,
            estimatedMemoryRequirement: 10 * 1024 * 1024,
            containsTables: true
        )
        mockAnalysisService.mockAnalysisResult = analysis
        
        // Setup expected strategy
        let expectedStrategy = TextExtractionStrategy()
        mockStrategyService.mockStrategy = expectedStrategy
        
        // When extracting payslip data
        let _ = try await extractionManager.extractPayslipData(from: mockPDF)
        
        // Then the appropriate services should be called with expected parameters
        XCTAssertTrue(mockAnalysisService.analyzeDocumentCalled, "Document analysis should be performed")
        XCTAssertTrue(mockStrategyService.determineExtractionStrategyCalled, "Strategy determination should be performed")
        XCTAssertTrue(expectedStrategy.extractionCalled, "Extraction method should be called on the strategy")
    }
    
    func testExtractPayslipDataFromURL() async throws {
        // Setup test URL
        let testURL = URL(fileURLWithPath: "/test/path.pdf")
        
        // Setup expected analysis results
        let analysis = DocumentAnalysis(
            pageCount: 1,
            containsScannedContent: true,
            hasComplexLayout: false,
            textDensity: 0.2,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: false
        )
        mockAnalysisService.mockAnalysisResult = analysis
        
        // Setup expected strategy
        let expectedStrategy = OCRExtractionStrategy()
        mockStrategyService.mockStrategy = expectedStrategy
        
        // When extracting payslip data from URL
        let _ = try await extractionManager.extractPayslipData(from: testURL)
        
        // Then the appropriate services should be called with expected parameters
        XCTAssertTrue(mockAnalysisService.analyzeDocumentFromURLCalled, "Document analysis from URL should be performed")
        XCTAssertTrue(mockStrategyService.determineExtractionStrategyCalled, "Strategy determination should be performed")
        XCTAssertTrue(expectedStrategy.extractionCalled, "Extraction method should be called on the strategy")
    }
    
    func testExtractPayslipDataWithProgressReporting() async throws {
        // Setup expected analysis results
        let analysis = DocumentAnalysis(
            pageCount: 10,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.6,
            estimatedMemoryRequirement: 50 * 1024 * 1024,
            containsTables: true
        )
        mockAnalysisService.mockAnalysisResult = analysis
        
        // Setup expected strategy
        let expectedStrategy = HybridExtractionStrategy()
        mockStrategyService.mockStrategy = expectedStrategy
        
        // Setup progress tracking
        var progressUpdates: [Double] = []
        let progressHandler: (Double) -> Void = { progress in
            progressUpdates.append(progress)
        }
        
        // When extracting payslip data with progress reporting
        let _ = try await extractionManager.extractPayslipData(
            from: mockPDF,
            progressHandler: progressHandler
        )
        
        // Then progress updates should be received
        XCTAssertFalse(progressUpdates.isEmpty, "Progress updates should be received")
        if !progressUpdates.isEmpty {
            XCTAssertEqual(progressUpdates.last, 1.0, "Final progress should be 100%")
        }
    }
    
    func testExtractPayslipDataWithError() async {
        // Setup analysis service to throw an error
        let testError = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        mockAnalysisService.mockError = testError
        
        // When extracting payslip data with an error condition
        do {
            let _ = try await extractionManager.extractPayslipData(from: mockPDF)
            XCTFail("Method should throw an error")
        } catch {
            // Then the appropriate error should be thrown
            XCTAssertEqual((error as NSError).domain, testError.domain)
            XCTAssertEqual((error as NSError).code, testError.code)
        }
    }
}

// MARK: - Mock Classes

private class MockDocumentAnalysisService: DocumentAnalysisServiceProtocol {
    var analyzeDocumentCalled = false
    var analyzeDocumentFromURLCalled = false
    var mockAnalysisResult = DocumentAnalysis(
        pageCount: 1,
        containsScannedContent: false,
        hasComplexLayout: false,
        textDensity: 0.5,
        estimatedMemoryRequirement: 1024 * 1024,
        containsTables: false
    )
    var mockError: Error?
    
    func analyzeDocument(_ document: PDFDocument) throws -> DocumentAnalysis {
        analyzeDocumentCalled = true
        if let error = mockError {
            throw error
        }
        return mockAnalysisResult
    }
    
    func analyzeDocument(at url: URL) throws -> DocumentAnalysis {
        analyzeDocumentFromURLCalled = true
        if let error = mockError {
            throw error
        }
        return mockAnalysisResult
    }
}

private class MockExtractionStrategyService: ExtractionStrategyServiceProtocol {
    var determineExtractionStrategyCalled = false
    var mockStrategy: ExtractionStrategy = TextExtractionStrategy()
    
    func determineExtractionStrategy(for documentAnalysis: DocumentAnalysis, purpose: ExtractionPurpose) -> ExtractionStrategy {
        determineExtractionStrategyCalled = true
        return mockStrategy
    }
}

private class TextExtractionStrategy: ExtractionStrategy {
    var extractionCalled = false
    
    func extract(from document: PDFDocument, progressHandler: ((Double) -> Void)?) async throws -> PayslipData {
        extractionCalled = true
        progressHandler?(0.5)
        progressHandler?(1.0)
        return PayslipData()
    }
}

private class OCRExtractionStrategy: ExtractionStrategy {
    var extractionCalled = false
    
    func extract(from document: PDFDocument, progressHandler: ((Double) -> Void)?) async throws -> PayslipData {
        extractionCalled = true
        progressHandler?(0.5)
        progressHandler?(1.0)
        return PayslipData()
    }
}

private class HybridExtractionStrategy: ExtractionStrategy {
    var extractionCalled = false
    
    func extract(from document: PDFDocument, progressHandler: ((Double) -> Void)?) async throws -> PayslipData {
        extractionCalled = true
        
        // Simulate progress updates
        for i in 1...10 {
            progressHandler?(Double(i) / 10.0)
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
        }
        
        return PayslipData()
    }
} 