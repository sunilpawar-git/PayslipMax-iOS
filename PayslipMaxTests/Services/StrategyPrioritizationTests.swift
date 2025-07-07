import XCTest
import PDFKit
@testable import PayslipMax

/// Tests focusing on strategy prioritization and various combinations of document characteristics
class StrategyPrioritizationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var analysisService: DocumentAnalysisService!
    private var strategyService: ExtractionStrategyService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        analysisService = DocumentAnalysisService()
        strategyService = ExtractionStrategyService()
    }
    
    override func tearDown() {
        analysisService = nil
        strategyService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testStrategySelectionPrioritization() {
        // Test priority order when multiple features are present
        
        // Create a PDF with multiple characteristics
        let mixedPDF = createMockPDFWithMixedContent()
        let mixedAnalysis = analysisService.analyzeDocument(mixedPDF)
        
        // Verify the analysis has multiple characteristics
        XCTAssertTrue(mixedAnalysis.containsScannedContent)
        XCTAssertTrue(mixedAnalysis.containsTables)
        XCTAssertTrue(mixedAnalysis.hasComplexLayout)
        
        // Get the strategy
        let mixedStrategy = strategyService.determineStrategy(for: mixedAnalysis)
        
        // Verify the prioritization (scanned content should take priority)
        XCTAssertEqual(mixedStrategy, .ocrExtraction)
    }
    
    func testStrategyCombinations() {
        // Test various combinations of document characteristics
        
        // Test cases to cover different combinations of document features
        let testCases: [(containsScannedContent: Bool, hasComplexLayout: Bool, isTextHeavy: Bool, isLargeDocument: Bool, containsTables: Bool, expectedStrategy: ExtractionStrategy)] = [
            // Scanned content takes highest priority
            (true, false, false, false, false, .ocrExtraction),
            (true, true, false, false, false, .ocrExtraction),
            (true, false, false, true, false, .ocrExtraction),
            (true, false, false, false, true, .ocrExtraction),
            
            // Large document takes second priority
            (false, false, false, true, false, .streamingExtraction),
            (false, true, false, true, false, .streamingExtraction),
            (false, false, true, true, false, .streamingExtraction),
            
            // Tables take third priority
            (false, false, false, false, true, .tableExtraction),
            (false, true, false, false, true, .tableExtraction),
            
            // Complex layout takes fourth priority
            (false, true, false, false, false, .hybridExtraction),
            (false, true, true, false, false, .hybridExtraction),
            
            // Text heavy takes fifth priority
            (false, false, true, false, false, .nativeTextExtraction),
            
            // Default case
            (false, false, false, false, false, .nativeTextExtraction)
        ]
        
        // Run all test cases
        for (index, testCase) in testCases.enumerated() {
            let analysis = DocumentAnalysis(
                pageCount: 1,
                containsScannedContent: testCase.containsScannedContent,
                hasComplexLayout: testCase.hasComplexLayout,
                textDensity: testCase.isTextHeavy ? 0.8 : 0.3,
                estimatedMemoryRequirement: testCase.isLargeDocument ? 50 * 1024 * 1024 : 10 * 1024 * 1024,
                containsTables: testCase.containsTables
            )
            
            let strategy = strategyService.determineStrategy(for: analysis)
            XCTAssertEqual(strategy, testCase.expectedStrategy, "Test case \(index) failed: Expected \(testCase.expectedStrategy) but got \(strategy)")
        }
    }
    
    func testComplexStrategyCombinations() {
        // Test edge cases and corner cases
        
        // Complex case 1: All features enabled (should pick highest priority - OCR)
        let allFeaturesAnalysis = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: true,
            hasComplexLayout: true,
            textDensity: 0.9,
            estimatedMemoryRequirement: 80 * 1024 * 1024,
            containsTables: true
        )
        let allFeaturesStrategy = strategyService.determineStrategy(for: allFeaturesAnalysis)
        XCTAssertEqual(allFeaturesStrategy, .ocrExtraction)
        
        // Complex case 2: Competing medium priorities
        let competingAnalysis = DocumentAnalysis(
            pageCount: 50,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.8,
            estimatedMemoryRequirement: 25 * 1024 * 1024,
            containsTables: true
        )
        let competingStrategy = strategyService.determineStrategy(for: competingAnalysis)
        
        // Tables should win over complex layout
        XCTAssertEqual(competingStrategy, .tableExtraction)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPDFWithMixedContent() -> PDFDocument {
        let pdfData = TestPDFGenerator.createPDFWithMixedContent()
        return PDFDocument(data: pdfData)!
    }
} 