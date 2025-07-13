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
        
        // Create a mock analysis with multiple characteristics
        let mixedAnalysis = DocumentAnalysis(
            pageCount: 1,
            containsScannedContent: true,
            hasComplexLayout: true,
            textDensity: 0.5, // Not text-heavy
            estimatedMemoryRequirement: 10 * 1024 * 1024, // Not large document
            containsTables: true
        )
        
        // Get the strategy
        let mixedStrategy = strategyService.determineStrategy(for: mixedAnalysis)
        
        // Verify the prioritization (scanned content should take priority when not large)
        XCTAssertEqual(mixedStrategy, .ocrExtraction)
    }
    
    func testStrategyCombinations() {
        // Test various combinations of document characteristics
        
        // Test cases to cover different combinations of document features
        // Based on actual ExtractionStrategyService.determineStrategy implementation
        let testCases: [(containsScannedContent: Bool, hasComplexLayout: Bool, isTextHeavy: Bool, isLargeDocument: Bool, containsTables: Bool, expectedStrategy: ExtractionStrategy)] = [
            // Large document takes HIGHEST priority (with high memory requirement)
            (true, false, false, true, false, .streamingExtraction), // Large + scanned = streaming wins
            (false, false, false, true, false, .streamingExtraction),
            (false, true, false, true, false, .streamingExtraction),
            (false, false, true, true, false, .streamingExtraction),
            
            // Scanned content takes second priority (when not large)
            (true, false, false, false, false, .ocrExtraction),
            (true, true, false, false, false, .ocrExtraction),
            (true, false, false, false, true, .ocrExtraction),
            (true, true, true, false, false, .hybridExtraction), // Scanned + text-heavy = hybrid
            
            // Complex layout AND tables take third priority
            (false, true, true, false, true, .tableExtraction), // Need both complex layout AND tables
            
            // Default cases
            (false, true, false, false, false, .nativeTextExtraction), // Complex layout without tables
            (false, false, true, false, false, .nativeTextExtraction), // Text heavy only
            (false, false, false, false, true, .nativeTextExtraction), // Tables without complex layout
            (false, false, false, false, false, .nativeTextExtraction)  // Default case
        ]
        
        // Run all test cases
        for (index, testCase) in testCases.enumerated() {
            let analysis = DocumentAnalysis(
                pageCount: 1,
                containsScannedContent: testCase.containsScannedContent,
                hasComplexLayout: testCase.hasComplexLayout,
                textDensity: testCase.isTextHeavy ? 0.8 : 0.3,
                estimatedMemoryRequirement: testCase.isLargeDocument ? 600 * 1024 * 1024 : 10 * 1024 * 1024, // 600MB > 500MB threshold
                containsTables: testCase.containsTables
            )
            
            let strategy = strategyService.determineStrategy(for: analysis)
            XCTAssertEqual(strategy, testCase.expectedStrategy, "Test case \(index) failed: Expected \(testCase.expectedStrategy) but got \(strategy)")
        }
    }
    
    func testComplexStrategyCombinations() {
        // Test edge cases and corner cases
        
        // Complex case 1: All features enabled (should pick highest priority - streaming for large doc)
        let allFeaturesAnalysis = DocumentAnalysis(
            pageCount: 100,
            containsScannedContent: true,
            hasComplexLayout: true,
            textDensity: 0.9,
            estimatedMemoryRequirement: 600 * 1024 * 1024, // Large enough to trigger streaming
            containsTables: true
        )
        let allFeaturesStrategy = strategyService.determineStrategy(for: allFeaturesAnalysis)
        XCTAssertEqual(allFeaturesStrategy, .streamingExtraction)
        
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
        // Create a PDF with mixed content (text + table) for complex analysis
        let pdfData = TestDataGenerator.createPDFWithTable()
        return PDFDocument(data: pdfData)!
    }
} 