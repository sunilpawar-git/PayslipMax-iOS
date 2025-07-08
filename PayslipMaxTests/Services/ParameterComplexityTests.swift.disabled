import XCTest
import PDFKit
@testable import PayslipMax

/// Tests focusing on how document complexity affects extraction parameters
class ParameterComplexityTests: XCTestCase {
    
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
    
    func testParameterCustomizationBasedOnComplexity() {
        // Test how complexity score affects parameters
        
        // Create documents with same characteristics but different complexity scores
        let lowComplexity = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.7,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        let highComplexity = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.9,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        // Get strategies (should be the same for both)
        let lowStrategy = strategyService.determineStrategy(for: lowComplexity)
        let highStrategy = strategyService.determineStrategy(for: highComplexity)
        
        XCTAssertEqual(lowStrategy, highStrategy, "Strategy should be the same regardless of complexity score")
        
        // Get parameters
        let lowParams = strategyService.getExtractionParameters(for: lowStrategy, with: lowComplexity)
        let highParams = strategyService.getExtractionParameters(for: highStrategy, with: highComplexity)
        
        // High complexity documents might require more aggressive parameters
        // This is implementation-dependent, but we can test for parameter differences
        // For example, high complexity might trigger specialized handling
        
        // Both should extract tables since that's the primary feature
        XCTAssertTrue(lowParams.extractTables)
        XCTAssertTrue(highParams.extractTables)
        
        // Both should use grid detection for tables
        XCTAssertTrue(lowParams.useGridDetection)
        XCTAssertTrue(highParams.useGridDetection)
    }
    
    func testComplexityThresholdBoundaries() {
        // Create documents at complexity threshold boundaries
        let justBelowThreshold = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.49,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        let justAboveThreshold = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.51,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        // Get parameters for both analyses
        let strategy = strategyService.determineStrategy(for: justBelowThreshold)  // Strategies should be the same
        let belowParams = strategyService.getExtractionParameters(for: strategy, with: justBelowThreshold)
        let aboveParams = strategyService.getExtractionParameters(for: strategy, with: justAboveThreshold)
        
        // Test if the parameters are consistent across small threshold differences
        // Exact assertions depend on the implementation details
        XCTAssertEqual(belowParams.extractTables, aboveParams.extractTables)
        XCTAssertEqual(belowParams.useOCR, aboveParams.useOCR)
    }
    
    func testExtremeComplexityValues() {
        // Test with extreme complexity values
        let zeroComplexity = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 0.0,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        let maxComplexity = DocumentAnalysis(
            pageCount: 5,
            containsScannedContent: false,
            hasComplexLayout: true,
            textDensity: 1.0,
            estimatedMemoryRequirement: 15 * 1024 * 1024,
            containsTables: true
        )
        
        // Get parameters
        let zeroStrategy = strategyService.determineStrategy(for: zeroComplexity)
        let maxStrategy = strategyService.determineStrategy(for: maxComplexity)
        
        XCTAssertEqual(zeroStrategy, maxStrategy, "Strategy selection should not be affected by complexity score alone")
        
        let zeroParams = strategyService.getExtractionParameters(for: zeroStrategy, with: zeroComplexity)
        let maxParams = strategyService.getExtractionParameters(for: maxStrategy, with: maxComplexity)
        
        // Both should extract tables since that's the primary feature in both cases
        XCTAssertTrue(zeroParams.extractTables)
        XCTAssertTrue(maxParams.extractTables)
    }
    
    func testProgressiveComplexityLevels() {
        // Test parameters across a range of complexity scores
        let complexityLevels = [0.1, 0.3, 0.5, 0.7, 0.9]
        var extractionParameters: [ExtractionParameters] = []
        
        // Generate parameters for different complexity levels
        for complexity in complexityLevels {
            let analysis = DocumentAnalysis(
                pageCount: 5,
                containsScannedContent: false,
                hasComplexLayout: true,
                textDensity: complexity,
                estimatedMemoryRequirement: 15 * 1024 * 1024,
                containsTables: true
            )
            
            let strategy = strategyService.determineStrategy(for: analysis)
            let params = strategyService.getExtractionParameters(for: strategy, with: analysis)
            extractionParameters.append(params)
        }
        
        // Verify that all parameters maintain core functionality regardless of complexity
        for params in extractionParameters {
            XCTAssertTrue(params.extractTables, "All complexity levels should extract tables")
            XCTAssertTrue(params.useGridDetection, "All complexity levels should use grid detection")
        }
    }
} 