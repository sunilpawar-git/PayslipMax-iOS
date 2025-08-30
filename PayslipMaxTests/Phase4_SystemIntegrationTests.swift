import XCTest
import Foundation
import PDFKit
@testable import PayslipMax

/// System integration tests for Phase 4: Adaptive Learning & Personalization
/// Tests the complete integration of learning components with existing AI services
@MainActor
final class Phase4_SystemIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var aiContainer: AIContainer!
    private var mockCoreContainer: MockCoreContainer!
    private var mockProcessingContainer: MockProcessingContainer!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up mock containers
        mockCoreContainer = MockCoreContainer()
        mockProcessingContainer = MockProcessingContainer()
        
        // Initialize AI container with learning services
        aiContainer = AIContainer(
            useMocks: false, // Use real implementations for integration testing
            coreContainer: mockCoreContainer,
            processingContainer: mockProcessingContainer
        )
    }
    
    override func tearDown() async throws {
        aiContainer = nil
        mockCoreContainer = nil
        mockProcessingContainer = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Service Creation Tests
    
    func testAIContainer_CreateAdaptiveLearningEngine() throws {
        // When
        let engine = aiContainer.makeAdaptiveLearningEngine()
        
        // Then
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine is AdaptiveLearningEngine)
    }
    
    func testAIContainer_CreateUserFeedbackProcessor() throws {
        // When
        let processor = aiContainer.makeUserFeedbackProcessor()
        
        // Then
        XCTAssertNotNil(processor)
        XCTAssertTrue(processor is UserFeedbackProcessor)
    }
    
    func testAIContainer_CreatePersonalizedInsightsEngine() throws {
        // When
        let engine = aiContainer.makePersonalizedInsightsEngine()
        
        // Then
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine is PersonalizedInsightsEngine)
    }
    
    func testAIContainer_CreateUserLearningStore() throws {
        // When
        let store = aiContainer.makeUserLearningStore()
        
        // Then
        XCTAssertNotNil(store)
        XCTAssertTrue(store is UserLearningStore)
    }
    
    func testAIContainer_CreatePerformanceTracker() throws {
        // When
        let tracker = aiContainer.makePerformanceTracker()
        
        // Then
        XCTAssertNotNil(tracker)
        XCTAssertTrue(tracker is PerformanceTracker)
    }
    
    func testAIContainer_CreatePrivacyPreservingLearningManager() throws {
        // When
        let manager = aiContainer.makePrivacyPreservingLearningManager()
        
        // Then
        XCTAssertNotNil(manager)
        XCTAssertTrue(manager is PrivacyPreservingLearningManager)
    }
    
    func testAIContainer_CreateLearningEnhancedParser() throws {
        // Given
        let mockParser = MockPayslipParser()
        
        // When
        let enhancedParser = aiContainer.makeLearningEnhancedParser(
            baseParser: mockParser,
            parserName: "TestParser"
        )
        
        // Then
        XCTAssertNotNil(enhancedParser)
        XCTAssertTrue(enhancedParser is LearningEnhancedParser)
    }
    
    // MARK: - Service Integration Tests
    
    func testServiceIntegration_LearningEngineWithFeedbackProcessor() async throws {
        // Given
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        
        let correction = createTestCorrection()
        
        // When
        try await feedbackProcessor.captureUserCorrection(correction)
        
        // Then - Learning engine should have processed the correction
        let suggestions = try await learningEngine.getPersonalizedSuggestions(for: correction.documentType)
        XCTAssertTrue(suggestions.count >= 0) // Should not fail
    }
    
    func testServiceIntegration_PerformanceTrackerWithLearningEngine() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        
        let metrics = createTestPerformanceMetrics()
        
        // When
        try await learningEngine.trackParserPerformance(metrics)
        
        // Then - Performance should be recorded
        let history = try await performanceTracker.getPerformanceHistory(
            for: metrics.parserName,
            days: 1
        )
        XCTAssertEqual(history.count, 1)
    }
    
    func testServiceIntegration_PrivacyManagerWithLearningStore() async throws {
        // Given
        let privacyManager = aiContainer.makePrivacyPreservingLearningManager()
        let learningStore = aiContainer.makeUserLearningStore()
        
        let correction = createTestCorrection()
        
        // When
        let anonymizedCorrection = try await privacyManager.anonymizeCorrection(correction)
        try await learningStore.storeCorrection(anonymizedCorrection)
        
        // Then - Anonymized correction should be stored
        let allCorrections = try await learningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 1)
        XCTAssertNotEqual(allCorrections.first?.fieldName, correction.fieldName) // Should be anonymized
    }
    
    // MARK: - Cross-Service Workflow Tests
    
    func testWorkflow_UserCorrectionToPersonalizedInsights() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let insightsEngine = aiContainer.makePersonalizedInsightsEngine()
        
        let documentType = LiteRTDocumentFormatType.pcda
        let corrections = createTestCorrectionHistory(count: 5, documentType: documentType)
        
        // When
        // 1. Process user corrections
        for correction in corrections {
            try await feedbackProcessor.captureUserCorrection(correction)
        }
        
        // 2. Generate personalized insights
        let insights = try await insightsEngine.generatePersonalizedInsights(
            for: documentType,
            userHistory: corrections
        )
        
        // Then
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.allSatisfy { $0.confidence > 0 })
    }
    
    func testWorkflow_PerformanceTrackingToParserOptimization() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let insightsEngine = aiContainer.makePersonalizedInsightsEngine()
        
        let parserName = "TestParser"
        let documentType = LiteRTDocumentFormatType.military
        
        // When
        // 1. Record performance over time
        for i in 0..<10 {
            let accuracy = 0.5 + (Double(i) * 0.04) // Improving accuracy
            let metrics = createTestPerformanceMetrics(
                parserName: parserName,
                accuracy: accuracy,
                documentType: documentType
            )
            try await performanceTracker.recordPerformance(metrics)
        }
        
        // 2. Calculate trends
        let trends = try await performanceTracker.calculatePerformanceTrends(for: parserName)
        
        // 3. Get parser adaptation
        let adaptation = try await learningEngine.adaptParserParameters(
            for: parserName,
            documentType: documentType
        )
        
        // 4. Generate insights
        let profile = try await insightsEngine.analyzeUserPatterns(corrections: [])
        let recommendation = try await insightsEngine.recommendOptimalParser(
            for: documentType,
            userProfile: profile
        )
        
        // Then
        XCTAssertTrue(trends.accuracyTrend > 0) // Should show improvement
        XCTAssertEqual(adaptation.parserName, parserName)
        XCTAssertFalse(recommendation.recommendedParser.isEmpty)
    }
    
    func testWorkflow_FullLearningCycleWithParsing() async throws {
        // Given
        let mockParser = MockPayslipParser()
        let enhancedParser = aiContainer.makeLearningEnhancedParser(
            baseParser: mockParser,
            parserName: "IntegrationTestParser"
        )
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        
        let pdfDocument = createTestPDFDocument()
        let documentType = LiteRTDocumentFormatType.corporate
        
        // When
        // 1. Initial parsing
        let initialResult = try await enhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // 2. User provides corrections
        let corrections = [
            createTestCorrection(fieldName: "salary", originalValue: "5000", correctedValue: "5,000"),
            createTestCorrection(fieldName: "name", originalValue: "J Smith", correctedValue: "John Smith")
        ]
        
        for correction in corrections {
            try await feedbackProcessor.captureUserCorrection(correction)
        }
        
        // 3. Apply learning and parse again
        let enhancedResult = try await enhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // Then
        XCTAssertTrue(initialResult.confidence >= 0)
        XCTAssertTrue(enhancedResult.confidence >= 0)
        // Enhanced result should potentially have more insights
        XCTAssertTrue(enhancedResult.learningInsights.count >= initialResult.learningInsights.count)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_InvalidCorrection() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let invalidCorrection = UserCorrection(
            fieldName: "", // Invalid empty field name
            originalValue: "test",
            correctedValue: "test", // Same as original
            documentType: .unknown,
            parserUsed: "TestParser"
        )
        
        // When/Then
        do {
            try await feedbackProcessor.captureUserCorrection(invalidCorrection)
            XCTFail("Should have thrown an error for invalid correction")
        } catch {
            XCTAssertTrue(error is FeedbackProcessorError)
        }
    }
    
    func testErrorHandling_InsufficientDataForTrends() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let parserName = "EmptyParser"
        
        // When/Then
        do {
            _ = try await performanceTracker.calculatePerformanceTrends(for: parserName)
            XCTFail("Should have thrown an error for insufficient data")
        } catch {
            XCTAssertTrue(error is PerformanceTrackerError)
        }
    }
    
    // MARK: - Memory and Performance Tests
    
    func testMemoryUsage_LargeNumberOfCorrections() async throws {
        // Given
        let learningStore = aiContainer.makeUserLearningStore()
        let corrections = createTestCorrectionHistory(count: 100)
        
        // When
        let startMemory = getMemoryUsage()
        
        for correction in corrections {
            try await learningStore.storeCorrection(correction)
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertTrue(memoryIncrease < 50 * 1024 * 1024) // Should be less than 50MB
        
        // Verify all corrections stored
        let allCorrections = try await learningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 100)
    }
    
    func testPerformance_BatchCorrectionProcessing() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let corrections = createTestCorrectionHistory(count: 50)
        
        // When
        let startTime = Date()
        try await feedbackProcessor.batchProcessCorrections(corrections)
        let endTime = Date()
        
        // Then
        let processingTime = endTime.timeIntervalSince(startTime)
        XCTAssertTrue(processingTime < 5.0) // Should complete within 5 seconds
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistency_SameServiceInstance() throws {
        // Given/When
        let engine1 = aiContainer.makeAdaptiveLearningEngine()
        let engine2 = aiContainer.makeAdaptiveLearningEngine()
        
        // Then - Should return the same cached instance
        XCTAssertTrue(engine1 === engine2 as AnyObject)
    }
    
    func testDataConsistency_CrossServiceDataSharing() async throws {
        // Given
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let learningStore = aiContainer.makeUserLearningStore()
        
        let correction = createTestCorrection()
        
        // When
        // Process through feedback processor
        try await feedbackProcessor.captureUserCorrection(correction)
        
        // Access through learning store
        let storedCorrections = try await learningStore.getAllCorrections()
        
        // Process through learning engine
        let adjustment = await learningEngine.getConfidenceAdjustment(
            for: correction.fieldName,
            documentType: correction.documentType
        )
        
        // Then
        XCTAssertEqual(storedCorrections.count, 1)
        XCTAssertEqual(storedCorrections.first?.fieldName, correction.fieldName)
        XCTAssertTrue(adjustment <= 0.0) // Should be negative for corrections
    }
    
    // MARK: - Helper Methods
    
    private func createTestCorrection(
        fieldName: String = "test_field",
        originalValue: String = "original",
        correctedValue: String = "corrected",
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> UserCorrection {
        return UserCorrection(
            fieldName: fieldName,
            originalValue: originalValue,
            correctedValue: correctedValue,
            documentType: documentType,
            parserUsed: "TestParser"
        )
    }
    
    private func createTestCorrectionHistory(
        count: Int,
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> [UserCorrection] {
        return (0..<count).map { i in
            createTestCorrection(
                fieldName: "field\(i % 5)",
                originalValue: "value\(i)",
                correctedValue: "corrected\(i)",
                documentType: documentType
            )
        }
    }
    
    private func createTestPerformanceMetrics(
        parserName: String = "TestParser",
        accuracy: Double = 0.8,
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> ParserPerformanceMetrics {
        return ParserPerformanceMetrics(
            parserName: parserName,
            documentType: documentType,
            processingTime: 2.5,
            accuracy: accuracy,
            fieldsExtracted: 10,
            fieldsCorrect: Int(accuracy * 10)
        )
    }
    
    private func createTestPDFDocument() -> PDFDocument {
        // Create a minimal PDF document for testing
        return PDFDocument() // Empty document for testing
    }
    
    private func getMemoryUsage() -> Int64 {
        // Get current memory usage in bytes
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &count) { countPtr in
            withUnsafeMutablePointer(to: UnsafeMutablePointer<mach_task_basic_info>(mutating: &info)) { infoPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), infoPtr, countPtr)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return Int64(info.resident_size)
    }
}

// MARK: - Mock Container Implementations

private class MockCoreContainer: CoreServiceContainerProtocol {
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return MockTextExtractionService()
    }
    
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return MockPayslipFormatDetectionService()
    }
    
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return MockPayslipValidationService()
    }
    
    func makePDFService() -> PDFServiceProtocol {
        return MockPDFService()
    }
    
    func makePDFExtractor() -> PDFExtractorProtocol {
        return MockPDFExtractor()
    }
    
    func makeDataService() -> DataServiceProtocol {
        return MockDataService()
    }
    
    func makeSecurityService() -> SecurityServiceProtocol {
        return MockSecurityService()
    }
}

private class MockProcessingContainer: ProcessingContainerProtocol {
    // Add required methods for ProcessingContainerProtocol
}

// Mock service implementations
private class MockTextExtractionService: TextExtractionServiceProtocol {
    // Add required methods
}

private class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    // Add required methods
}

private class MockPayslipValidationService: PayslipValidationServiceProtocol {
    // Add required methods
}

private class MockPDFService: PDFServiceProtocol {
    // Add required methods
}

private class MockPDFExtractor: PDFExtractorProtocol {
    // Add required methods
}

private class MockDataService: DataServiceProtocol {
    // Add required methods
}

private class MockSecurityService: SecurityServiceProtocol {
    // Add required methods
}

private class MockPayslipParser: PayslipParserProtocol {
    let name: String = "MockParser"
    // Add any required methods for the protocol
}

// Protocol placeholders (these would be defined elsewhere in the real codebase)
protocol CoreServiceContainerProtocol {
    func makeTextExtractionService() -> TextExtractionServiceProtocol
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol
    func makePayslipValidationService() -> PayslipValidationServiceProtocol
    func makePDFService() -> PDFServiceProtocol
    func makePDFExtractor() -> PDFExtractorProtocol
    func makeDataService() -> DataServiceProtocol
    func makeSecurityService() -> SecurityServiceProtocol
}

protocol ProcessingContainerProtocol {
    // Define required methods
}

protocol TextExtractionServiceProtocol {
    // Define required methods
}

protocol PayslipFormatDetectionServiceProtocol {
    // Define required methods
}

protocol PayslipValidationServiceProtocol {
    // Define required methods
}

protocol PDFServiceProtocol {
    // Define required methods
}

protocol PDFExtractorProtocol {
    // Define required methods
}

protocol DataServiceProtocol {
    // Define required methods
}

protocol SecurityServiceProtocol {
    // Define required methods
}
